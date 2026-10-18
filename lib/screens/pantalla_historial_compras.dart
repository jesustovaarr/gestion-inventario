import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../database/daos/compra_dao.dart';
import '../models/compra_model.dart';
import '../models/historial_compra_model.dart';
import '../utils/importes.dart';
import '../utils/presentaciones.dart';
import '../widgets/acciones_deslizables_catalogo.dart';
import '../widgets/encabezado_seccion.dart';
import '../widgets/miniatura_producto.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final _dao = CompraDao();
  final _searchController = TextEditingController();
  final Set<String> _eliminando = {};
  List<CompraEnHistorial> _compras = [];
  bool _loading = true;
  String? _error;
  int _tiendaId = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final compras = await _dao.obtenerCompras();
      if (!mounted) return;
      setState(() {
        _compras = compras;
        _loading = false;
        if (!compras.any((c) => c.tiendaId == _tiendaId)) _tiendaId = 0;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo cargar el historial de compras.';
      });
    }
  }

  Future<void> _eliminar(CompraEnHistorial compra) async {
    if (!_eliminando.add(compra.clave)) return;
    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Eliminar compra'),
          content: Text(
            '¿Eliminar la compra de ${compra.tiendaNombre} del ${_fecha(compra.fechaCompra)}?\n\nSe quitará del historial. Los productos y sus existencias se conservarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: PantryColors.red),
              child: const Text('Eliminar'),
            ),
          ],
        ),
      );
      if (!mounted || confirm != true) return;
      await _dao.eliminarDelHistorial(compra);
      if (!mounted) return;
      setState(() {
        _compras.removeWhere((c) => c.clave == compra.clave);
        if (!_compras.any((c) => c.tiendaId == _tiendaId)) _tiendaId = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra eliminada del historial')),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar la compra. Inténtalo de nuevo.'),
          ),
        );
      }
    } finally {
      _eliminando.remove(compra.clave);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiendas = {
      for (final c in _compras) c.tiendaId: c.tiendaNombre,
    }.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    final query = _searchController.text.trim().toLowerCase();
    final visibles = _compras.where((c) {
      if (_tiendaId != 0 && c.tiendaId != _tiendaId) return false;
      return query.isEmpty ||
          c.tiendaNombre.toLowerCase().contains(query) ||
          c.articulos.any(
            (a) => (a.productoNombre ?? '').toLowerCase().contains(query),
          );
    }).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  const SliverAppBar(
                    pinned: true,
                    toolbarHeight: 68,
                    titleSpacing: 0,
                    title: AppSectionHeading(
                      section: AppSection.purchaseHistory,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consulta tus compras por tienda y producto. Desliza una compra hacia la izquierda para borrarla.',
                            style: TextStyle(color: PantryColors.muted),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            key: const ValueKey('purchase-history-search'),
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Buscar producto o tienda',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Limpiar búsqueda',
                                      icon: const Icon(Icons.close),
                                      onPressed: () =>
                                          setState(_searchController.clear),
                                    ),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (tiendas.isNotEmpty) ...[
                            const Text(
                              'Filtrar por tienda',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  for (final tienda in tiendas)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                        key: ValueKey(
                                          'purchase-history-store-${tienda.key}',
                                        ),
                                        label: Text(tienda.value),
                                        selected: _tiendaId == tienda.key,
                                        showCheckmark: false,
                                        onSelected: (selected) => setState(
                                          () => _tiendaId = selected
                                              ? tienda.key
                                              : 0,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          if (!_loading && _error == null) ...[
                            const SizedBox(height: 16),
                            Text(
                              '${visibles.length} ${visibles.length == 1 ? 'compra' : 'compras'} · Más recientes primero',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyHistory(
                        message: _error!,
                        action: TextButton(
                          onPressed: _load,
                          child: const Text('Reintentar'),
                        ),
                      ),
                    )
                  else if (visibles.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyHistory(
                        message: _compras.isEmpty
                            ? 'No hay compras registradas. Las compras que guardes desde Carrito aparecerán aquí.'
                            : 'No hay compras que coincidan con la búsqueda.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverList.builder(
                        itemCount: visibles.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CatalogSwipeActions(
                            key: ValueKey(
                              'purchase-swipe-${visibles[index].clave}',
                            ),
                            name:
                                'compra de ${visibles[index].tiendaNombre} del ${_fecha(visibles[index].fechaCompra)}',
                            onDelete: () => _eliminar(visibles[index]),
                            child: _PurchaseCard(
                              key: ValueKey(visibles[index].clave),
                              compra: visibles[index],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({super.key, required this.compra});
  final CompraEnHistorial compra;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    child: ExpansionTile(
      key: PageStorageKey(compra.clave),
      shape: const Border(),
      collapsedShape: const Border(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: const Icon(
        Icons.receipt_long_outlined,
        color: PantryColors.green,
      ),
      title: Text(
        compra.tiendaNombre,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _fecha(compra.fechaCompra),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            if (compra.articulos.isNotEmpty)
              Text(
                compra.articulos
                    .map((a) => a.productoNombre ?? 'Producto no disponible')
                    .join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 6),
            Text(
              compra.totalCentavos == null
                  ? 'Total no registrado'
                  : 'Total: \$${formatearImporte(compra.totalCentavos!)}',
              style: const TextStyle(
                color: PantryColors.green,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      children: [
        const Divider(height: 1),
        if (compra.articulos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Los artículos de esta compra ya no están disponibles.',
            ),
          ),
        for (final articulo in compra.articulos)
          _HistoryArticle(
            key: ValueKey('history-article-${articulo.id}'),
            articulo: articulo,
          ),
      ],
    ),
  );
}

class _HistoryArticle extends StatelessWidget {
  const _HistoryArticle({super.key, required this.articulo});
  final HistorialCompra articulo;

  @override
  Widget build(BuildContext context) {
    final precio = articulo.precioVisibleCentavos;
    final subtotal = articulo.subtotalCentavos;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductThumbnail(imagePath: articulo.imagen, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  articulo.productoNombre ?? 'Producto no disponible',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  articulo.descripcionCantidad,
                  style: const TextStyle(color: PantryColors.green),
                ),
                const SizedBox(height: 4),
                Text(
                  precio == null
                      ? 'Precio no registrado'
                      : '\$${formatearImporte(precio)} por ${articulo.presentacion.esEnvase ? articulo.presentacion.singular.toLowerCase() : unidadVisible(articulo.unidadMedida)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: PantryColors.muted,
                  ),
                ),
                if (articulo.fechaCaducidad != null)
                  Text(
                    'Cad: ${_fecha(articulo.fechaCaducidad!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: PantryColors.muted,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  subtotal == null
                      ? 'Subtotal no registrado'
                      : 'Subtotal: \$${formatearImporte(subtotal)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message, this.action});
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 40,
          color: PantryColors.muted,
        ),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        ?action,
      ],
    ),
  );
}

String _fecha(String value) {
  final date = DateTime.tryParse(value);
  return date == null
      ? value
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
