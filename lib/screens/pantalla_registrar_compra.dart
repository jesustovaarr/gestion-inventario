import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../database/daos/compra_dao.dart';
import '../database/daos/producto_dao.dart';
import '../database/daos/tienda_dao.dart';
import '../models/tienda_model.dart';
import '../presentation/controlador_carrito.dart';
import '../presentation/modelos_vista_alacena.dart';
import '../presentation/modelos_vista_compra.dart';
import '../utils/importes.dart';
import '../utils/cantidades.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../widgets/editor_articulo_compra.dart';
import '../widgets/encabezado_seccion.dart';
import '../widgets/selector_productos_compra.dart';
import '../widgets/tarjeta_articulo_compra.dart';
import 'formulario_tienda.dart';

class RegisterPurchaseScreen extends StatefulWidget {
  const RegisterPurchaseScreen({
    super.key,
    this.product,
    this.productoId,
    this.initialItems,
    this.useShoppingList = false,
    this.stayAfterSave = false,
  });
  final PantryProductPreview? product;
  final int? productoId;
  final List<ShoppingListItemPreview>? initialItems;
  final bool useShoppingList;
  final bool stayAfterSave;
  @override
  State<RegisterPurchaseScreen> createState() => _RegisterPurchaseScreenState();
}

class _RegisterPurchaseScreenState extends State<RegisterPurchaseScreen> {
  final _productoDao = ProductoDao();
  final _tiendaDao = TiendaDao();
  final _compraDao = CompraDao();
  ShoppingListsPreviewController? _cart;
  List<PantryProductPreview> _catalog = [];
  List<Tienda> _stores = [];
  List<PurchaseArticleDraft> _items = [];
  int? _storeId;
  late DateTime _purchaseDate;
  bool _started = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Future<void> _draftWrites = Future.value();
  int _pendingDraftWrites = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _purchaseDate = DateTime(now.year, now.month, now.day);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cart = ShoppingListsPreviewScope.maybeOf(context);
    if (!identical(cart, _cart)) {
      _cart?.removeListener(_onCartChanged);
      _cart = cart;
      if (widget.useShoppingList) _cart?.addListener(_onCartChanged);
    }
    if (!_started) {
      _started = true;
      _load();
    }
  }

  @override
  void dispose() {
    _cart?.removeListener(_onCartChanged);
    super.dispose();
  }

  PurchaseArticleDraft _draft(PantryProductPreview p) =>
      PurchaseArticleDraft.fromProduct(p);
  Future<void> _load() async {
    try {
      if (widget.useShoppingList) await _cart?.cargarDesdeBD();
      final products = await _productoDao.obtenerConStock();
      final stores = await _tiendaDao.obtenerTodas();
      if (!mounted) return;
      final catalog = products.map((p) => p.toPreview()).toList();
      final byId = {for (final p in products) p.id: p.toPreview()};
      final arguments = ModalRoute.of(context)?.settings.arguments;
      final initial =
          widget.initialItems ??
          (arguments is List<ShoppingListItemPreview> ? arguments : null) ??
          (widget.useShoppingList ? _cart?.current.items : null) ??
          [];
      final entries = <String, PurchaseArticleDraft>{};
      for (final item in initial) {
        final p = byId[item.product.id];
        if (p != null) {
          entries[item.key] = item.copyWith(product: p);
        }
      }
      final productId = widget.productoId ?? widget.product?.id;
      if (entries.isEmpty && productId != null && byId[productId] != null) {
        final item = _draft(widget.product ?? byId[productId]!);
        entries[item.key] = item;
      }
      setState(() {
        _catalog = catalog;
        _stores = stores;
        _items = entries.values.toList();
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudieron cargar los productos y las tiendas.';
        });
      }
    }
  }

  void _onCartChanged() {
    if (!mounted ||
        _loading ||
        _saving ||
        _pendingDraftWrites > 0 ||
        !widget.useShoppingList ||
        _cart == null) {
      return;
    }
    setState(() => _items = _cart!.current.items.toList());
  }

  Future<void> _updateDraft(PurchaseArticleDraft item) {
    if (!mounted) return Future.value();
    setState(
      () => _items = _items.map((i) => i.key == item.key ? item : i).toList(),
    );
    if (!widget.useShoppingList || _cart == null) return Future.value();
    _pendingDraftWrites++;
    _draftWrites = _draftWrites
        .then((_) => _cart!.setItem(item))
        .catchError((Object error) {
          if (mounted) {
            _message('No se pudieron guardar los cambios del artículo.');
          }
        })
        .whenComplete(() => _pendingDraftWrites--);
    return _draftWrites;
  }

  Future<void> _changeCount(PurchaseArticleDraft item, int delta) async {
    final next = item.packaging.esEnvase
        ? item.copyWith(packageCount: item.packageCount + delta)
        : item.copyWith(quantity: item.quantity + delta);
    if (next.packageCount < 1 ||
        next.packageCount > 999999 ||
        !cantidadValida(next.quantity)) {
      return;
    }
    await _updateDraft(next);
  }

  Future<void> _selectProducts() async {
    final selected = await showModalBottomSheet<List<PantryProductPreview>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => PurchaseProductSelector(
        products: _catalog,
        selectedKeys: _items.map((i) => i.key).toSet(),
      ),
    );
    if (selected == null || !mounted) return;
    final previous = {for (final i in _items) i.key: i};
    if (widget.useShoppingList && _cart != null) {
      final selectedKeys = selected.map((p) => _draft(p).key).toSet();
      for (final old in _cart!.current.items.toList()) {
        if (!selectedKeys.contains(old.key)) {
          await _cart!.removeItem(old);
        }
      }
      for (final p in selected) {
        if (!_cart!.current.items.any((i) => i.key == _draft(p).key)) {
          await _cart!.addProduct(p);
        }
      }
    }
    if (!mounted) return;
    setState(() {
      _catalog = {
        for (final p in [..._catalog, ...selected]) _draft(p).key: p,
      }.values.toList();
      _items = selected
          .map(
            (p) => previous[_draft(p).key]?.copyWith(product: p) ?? _draft(p),
          )
          .toList();
    });
  }

  Future<void> _remove(PurchaseArticleDraft item) async {
    if (widget.useShoppingList && _cart != null) {
      await _cart!.removeItem(item);
    }
    if (mounted) {
      setState(() => _items.removeWhere((i) => i.key == item.key));
    }
  }

  Future<void> _edit(PurchaseArticleDraft item) async {
    final edited = await showModalBottomSheet<PurchaseArticleDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (_) => PurchaseArticleEditor(
        item: item,
        purchaseDate: _purchaseDate,
        onChanged: _updateDraft,
      ),
    );
    if (!mounted) return;
    if (edited != null) await _updateDraft(edited);
    await _draftWrites;
    try {
      final products = await _productoDao.obtenerConStock();
      if (!mounted) return;
      final byId = {for (final p in products) p.id: p.toPreview()};
      if (!mounted) return;
      setState(() {
        _catalog = byId.values.toList();
        _items = _items.map((i) {
          final next = i;
          return next.copyWith(product: byId[next.product.id] ?? next.product);
        }).toList();
      });
    } catch (_) {
      if (mounted) {
        _message('No se pudo actualizar el artículo. Inténtalo de nuevo.');
      }
    }
  }

  Future<void> _addStore() async {
    final ids = _stores.map((s) => s.id).toSet();
    final result = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const StoreFormScreen()));
    if (result != true || !mounted) return;
    try {
      final stores = await _tiendaDao.obtenerTodas();
      if (mounted) {
        setState(() {
          _stores = stores;
          _storeId =
              stores.where((s) => !ids.contains(s.id)).firstOrNull?.id ??
              _storeId;
        });
      }
    } catch (_) {
      if (mounted) {
        _message('No se pudo cargar la tienda. Vuelve a abrir la compra.');
      }
    }
  }

  Future<void> _changePurchaseDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year, now.month, now.day),
    );
    if (mounted && date != null) setState(() => _purchaseDate = date);
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _save() async {
    if (_saving || _items.isEmpty) return;
    if (_storeId == null) {
      _message('Selecciona la tienda o supermercado.');
      return;
    }
    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];
      if (item.priceCents == null ||
          item.expiryDate == null ||
          item.expiryDate!.isBefore(_purchaseDate)) {
        _message('Completa precio y caducidad de ${item.product.name}.');
        await _edit(item);
        if (!mounted) return;
        final updated = _items.where((i) => i.key == item.key).firstOrNull;
        if (updated == null ||
            updated.priceCents == null ||
            updated.expiryDate == null ||
            updated.expiryDate!.isBefore(_purchaseDate)) {
          return;
        }
      }
    }
    setState(() => _saving = true);
    try {
      await _draftWrites;
      final saved = await _compraDao.registrarCompraCompleta(
        tiendaId: _storeId!,
        fechaCompra: _purchaseDate.toIso8601String().substring(0, 10),
        articulos: _items.map((i) => i.toModel()).toList(),
        quitarDelCarrito: widget.useShoppingList,
      );
      await _cart?.cargarDesdeBD();
      if (!mounted) return;
      _message(
        'Compra guardada · Total: \$${formatearImporte(saved.totalCentavos)}',
      );
      if (!widget.stayAfterSave && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _items = widget.useShoppingList
              ? (_cart?.current.items ?? []).map((i) => i.copyWith()).toList()
              : [];
          _storeId = null;
        });
      }
    } catch (_) {
      if (mounted) {
        _message(
          'No se guardó la compra. Revisa los artículos y vuelve a intentarlo.',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _dateLabel(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final knownPrices = _items.every((i) => i.priceCents != null);
    final total = _items.fold<int>(0, (sum, i) => sum + i.subtotalCents);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Scaffold(
          bottomNavigationBar: const AppBottomNavigation(selectedIndex: 3),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                const SliverAppBar(
                  pinned: true,
                  toolbarHeight: 68,
                  title: AppSectionHeading(section: AppSection.purchase),
                ),
                if (widget.useShoppingList)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: OutlinedButton.icon(
                        onPressed: _saving
                            ? null
                            : () =>
                                  Navigator.of(context)
                                      .pushNamed('/purchase-history'),
                        icon: const Icon(Icons.history_rounded),
                        label: const Text('Historial de compras'),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  sliver: SliverList.list(
                    children: [
                      if (_loading) const LinearProgressIndicator(),
                      if (_error != null) ...[
                        Text(_error!),
                        TextButton(
                          onPressed: () {
                            setState(() => _loading = true);
                            _load();
                          },
                          child: const Text('Reintentar'),
                        ),
                      ],
                      const Text(
                        'Artículos de la compra',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Selecciona productos de tu alacena y toca un artículo para editar su cantidad, precio y caducidad.',
                        style: TextStyle(
                          color: PantryColors.muted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _loading || _saving || _error != null
                            ? null
                            : _selectProducts,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar productos'),
                      ),
                      const SizedBox(height: 12),
                      if (_items.isEmpty && !_loading && _error == null)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Column(
                            children: [
                              IconButton.filled(
                                onPressed: _saving ? null : _selectProducts,
                                tooltip: 'Agregar productos existentes',
                                icon: const Icon(Icons.add, size: 32),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Agrega productos a esta compra',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Selecciona los productos que ya registraste en Inicio.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: PantryColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      for (final item in _items)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PurchaseArticleCard(
                            key: ValueKey('purchase-item-${item.key}'),
                            item: item,
                            onTap: _saving ? null : () => _edit(item),
                            onRemove: _saving ? null : () => _remove(item),
                            onIncrease: _saving
                                ? null
                                : () => _changeCount(item, 1),
                            onDecrease:
                                _saving ||
                                    (item.packaging.esEnvase
                                        ? item.packageCount <= 1
                                        : item.quantity <= 1)
                                ? null
                                : () => _changeCount(item, -1),
                          ),
                        ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 20),
                      _panel(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tienda / Supermercado',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            if (_stores.isNotEmpty)
                              DropdownButtonFormField<int>(
                                key: ValueKey('purchase-store-$_storeId'),
                                initialValue: _storeId,
                                isExpanded: true,
                                hint: const Text('Selecciona una tienda'),
                                decoration: const InputDecoration(
                                  prefixIcon: Icon(Icons.storefront_outlined),
                                ),
                                items: _stores
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.nombre),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _saving
                                    ? null
                                    : (id) => setState(() => _storeId = id),
                              ),
                            if (_stores.isEmpty && !_loading)
                              const Text(
                                'Agrega una tienda para registrar la compra.',
                              ),
                            TextButton.icon(
                              onPressed: _saving ? null : _addStore,
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar tienda'),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                              title: const Text('Fecha de compra'),
                              subtitle: Text(_dateLabel(_purchaseDate)),
                              trailing: const Icon(Icons.edit_outlined),
                              onTap: _saving ? null : _changePurchaseDate,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _panel(
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Flexible(
                              child: Text(
                                knownPrices
                                    ? '\$${formatearImporte(total)}'
                                    : 'Por completar',
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w700,
                                  color: PantryColors.green,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed:
                            _loading ||
                                _saving ||
                                _items.isEmpty ||
                                _error != null
                            ? null
                            : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.shopping_bag_outlined),
                        label: Text(_saving ? 'Guardando…' : 'Guardar compra'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _panel(Widget child) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
