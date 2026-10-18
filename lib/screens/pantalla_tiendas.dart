import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../components/tema_alacena.dart';
import '../models/tienda_model.dart';
import '../database/daos/tienda_dao.dart';
import 'formulario_tienda.dart';
import 'pantalla_editar_tienda.dart';
import '../widgets/acciones_deslizables_catalogo.dart';

/// Catálogo de tiendas
class StoresScreen extends StatefulWidget {
  const StoresScreen({super.key});

  @override
  State<StoresScreen> createState() => _StoresScreenState();
}

class _StoresScreenState extends State<StoresScreen> {
  final TiendaDao _tiendaDao = TiendaDao();
  final TextEditingController _searchController = TextEditingController();

  List<Tienda> _todasLasTiendas = [];
  bool _cargando = true;
  bool _mostrarBuscador = false;
  String _filtroTexto = '';
  String? _filtroActivo;

  @override
  void initState() {
    super.initState();
    _cargarTiendas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarTiendas() async {
    setState(() => _cargando = true);
    final tiendas = await _tiendaDao.obtenerTodas();
    if (mounted) {
      setState(() {
        _todasLasTiendas = tiendas;
        _cargando = false;
      });
    }
  }

  List<Tienda> get _tiendasFiltradas {
    return _todasLasTiendas.where((tienda) {
      final matchesSearch =
          _filtroTexto.isEmpty ||
          tienda.nombre.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
          (tienda.ubicacion ?? '').toLowerCase().contains(
            _filtroTexto.toLowerCase(),
          );

      if (!matchesSearch) return false;

      switch (_filtroActivo) {
        case 'Con compras':
          return tienda.totalCompras > 0;
        case 'Frecuentes':
          return tienda.totalCompras >= 3;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _abrirNuevaTienda() async {
    final creado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const StoreFormScreen()),
    );
    if (creado == true) {
      _cargarTiendas();
    }
  }

  Future<void> _abrirEditarTienda(Tienda tienda) async {
    final editado = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => EditStoreScreen(
          storeId: tienda.id,
          storeName: tienda.nombre,
          address: tienda.ubicacion ?? '',
          purchases: tienda.totalCompras,
          tipoTiendaId: tienda.tipoTiendaId,
        ),
      ),
    );
    if (editado == true) {
      _cargarTiendas();
    }
  }

  Future<void> _intentarEliminarTienda(Tienda tienda) async {
    final tieneCompras = tienda.totalCompras > 0;
    final String mensaje = tieneCompras
        ? 'Esta tienda tiene ${tienda.totalCompras} compras registradas en el historial. Si la eliminas, se eliminarán también dichos registros.\n\n¿Deseas eliminar definitivamente "${tienda.nombre}"?'
        : '¿Deseas eliminar definitivamente "${tienda.nombre}"?';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tienda'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PantryColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true && tienda.id != null) {
      await _tiendaDao.eliminar(tienda.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tienda "${tienda.nombre}" eliminada'),
            backgroundColor: PantryColors.green,
          ),
        );
        _cargarTiendas();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiendasAMostrar = _tiendasFiltradas;

    return ColoredBox(
      color: PantryColors.greenLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Scaffold(
            bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
            body: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 68,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    titleSpacing: 20,
                    title: const AppSectionHeading(section: AppSection.stores),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton(
                          tooltip: _mostrarBuscador
                              ? 'Cerrar búsqueda'
                              : 'Buscar tiendas',
                          onPressed: () {
                            setState(() {
                              _mostrarBuscador = !_mostrarBuscador;
                              if (!_mostrarBuscador) {
                                _searchController.clear();
                                _filtroTexto = '';
                              }
                            });
                          },
                          icon: Icon(
                            _mostrarBuscador
                                ? Icons.close_rounded
                                : Icons.search_rounded,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_mostrarBuscador)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          onChanged: (val) =>
                              setState(() => _filtroTexto = val),
                          decoration: InputDecoration(
                            hintText: 'Buscar tienda o sucursal…',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: PantryColors.muted,
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              size: 20,
                              color: PantryColors.green,
                            ),
                            suffixIcon: _filtroTexto.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _filtroTexto = '');
                                    },
                                    tooltip: 'Limpiar búsqueda',
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 17,
                                      color: PantryColors.muted,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: PantryColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: PantryColors.border,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => setState(
                              () =>
                                  _filtroActivo = _filtroActivo == 'Con compras'
                                  ? null
                                  : 'Con compras',
                            ),
                            icon: Icon(
                              Icons.receipt_long_outlined,
                              size: 14,
                              color: _filtroActivo == 'Con compras'
                                  ? PantryColors.green
                                  : PantryColors.muted,
                            ),
                            label: const Text(
                              'Con compras registradas',
                              style: TextStyle(
                                fontSize: 11,
                                color: PantryColors.ink,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _filtroActivo == 'Con compras'
                                  ? PantryColors.greenLight
                                  : Colors.white,
                              side: BorderSide(
                                color: _filtroActivo == 'Con compras'
                                    ? PantryColors.green
                                    : PantryColors.border,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                          ),
                          const SizedBox(width: 7),
                          OutlinedButton.icon(
                            onPressed: () => setState(
                              () =>
                                  _filtroActivo = _filtroActivo == 'Frecuentes'
                                  ? null
                                  : 'Frecuentes',
                            ),
                            icon: Icon(
                              Icons.star_border_rounded,
                              size: 14,
                              color: _filtroActivo == 'Frecuentes'
                                  ? PantryColors.green
                                  : PantryColors.muted,
                            ),
                            label: const Text(
                              'Frecuentes',
                              style: TextStyle(
                                fontSize: 11,
                                color: PantryColors.ink,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: _filtroActivo == 'Frecuentes'
                                  ? PantryColors.greenLight
                                  : Colors.white,
                              side: BorderSide(
                                color: _filtroActivo == 'Frecuentes'
                                    ? PantryColors.green
                                    : PantryColors.border,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'CATÁLOGO DE TIENDAS',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: .6,
                              ),
                            ),
                          ),
                          Text(
                            '${tiendasAMostrar.length} registradas',
                            style: const TextStyle(
                              fontSize: 10,
                              color: PantryColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_cargando)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else if (tiendasAMostrar.isEmpty)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            _filtroTexto.isNotEmpty
                                ? 'No se encontraron tiendas que coincidan con "$_filtroTexto"'
                                : 'No hay tiendas registradas.',
                            style: const TextStyle(
                              color: PantryColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: tiendasAMostrar.length,
                        itemBuilder: (context, index) {
                          final tienda = tiendasAMostrar[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: CatalogSwipeActions(
                              key: ValueKey(
                                'store-swipe-${tienda.id ?? tienda.nombre}',
                              ),
                              name: tienda.nombre,
                              onDelete: () => _intentarEliminarTienda(tienda),
                              child: _StoreCard(
                                tienda: tienda,
                                onEdit: () => _abrirEditarTienda(tienda),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 90)),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: _abrirNuevaTienda,
              heroTag: null,
              icon: const Icon(Icons.add_rounded, size: 23),
              label: const Text(
                'Nueva tienda',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.tienda, required this.onEdit});
  final Tienda tienda;
  final VoidCallback onEdit;

  IconData _iconForType(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'supermercado':
        return Icons.storefront_outlined;
      case 'mayorista':
      case 'club de precios':
        return Icons.apartment_rounded;
      case 'tienda local':
      case 'tiendita de la esquina':
        return Icons.shopping_basket_outlined;
      case 'mercado / tianguis':
      case 'mercado local':
        return Icons.store_mall_directory_outlined;
      default:
        return Icons.storefront_outlined;
    }
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(17),
      side: const BorderSide(color: PantryColors.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: PantryColors.greenLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconForType(tienda.tipoTiendaNombre),
                    size: 23,
                    color: PantryColors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tienda.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (tienda.totalCompras >= 3) ...[
                            const SizedBox(width: 5),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: PantryColors.greenLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Frecuente',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: PantryColors.green,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: PantryColors.muted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              tienda.ubicacion?.isNotEmpty == true
                                  ? tienda.ubicacion!
                                  : 'Sin dirección registrada',
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.4,
                                color: PantryColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: PantryColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    size: 13,
                    color: PantryColors.green,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${tienda.totalCompras} ${tienda.totalCompras == 1 ? 'compra registrada' : 'compras registradas'}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: PantryColors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      tienda.tipoTiendaNombre ?? 'Supermercado',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: 10,
                        color: PantryColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
