import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import 'package:badges/badges.dart' as badges;

import '../components/tema_alacena.dart';
import '../presentation/modelos_vista_alacena.dart';
import '../widgets/tarjeta_producto.dart';
import '../widgets/acciones_deslizables_catalogo.dart';

/// Maqueta de Inicio
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onSearch,
    this.onProfile,
    this.onCart,
    this.onAddProduct,
    this.onDestinationSelected,
    this.onProductTap,
    this.onAddToCart,
    this.cartCount = 0,
    this.onEditProduct,
    this.onDeleteProduct,
    this.sections = const [],
  });

  final VoidCallback? onSearch;
  final VoidCallback? onProfile;
  final VoidCallback? onCart;
  final VoidCallback? onAddProduct;
  final ValueChanged<int>? onDestinationSelected;
  final ValueChanged<PantryProductPreview>? onProductTap;
  final ValueChanged<PantryProductPreview>? onAddToCart;
  final int cartCount;
  final ValueChanged<PantryProductPreview>? onEditProduct;
  final ValueChanged<PantryProductPreview>? onDeleteProduct;
  final List<PantrySectionPreview>? sections;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _mostrarBuscador = false;
  String _filtroTexto = '';
  PantryPreviewStatus? _filtroEstado;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allSections = widget.sections ?? const [];

    int caducadosCount = 0;
    int porCaducarCount = 0;
    int porAgotarseCount = 0;

    for (final section in allSections) {
      for (final p in section.products) {
        final matchSearch = _filtroTexto.isEmpty ||
            p.name.toLowerCase().contains(_filtroTexto.toLowerCase()) ||
            p.category.toLowerCase().contains(_filtroTexto.toLowerCase());
        if (!matchSearch) continue;

        if (p.status == PantryPreviewStatus.expired) {
          caducadosCount++;
        } else if (p.status == PantryPreviewStatus.expiring) {
          porCaducarCount++;
        } else if (p.status == PantryPreviewStatus.lowStock) {
          porAgotarseCount++;
        }
      }
    }

    final totalArticulos = allSections.fold<int>(
      0,
      (sum, s) => sum + s.products.length,
    );

    final List<PantrySectionPreview> seccionesMostradas = allSections
        .map((s) {
          if (_filtroEstado != null && s.status != _filtroEstado) {
            return null;
          }

          final productosFiltrados = s.products.where((p) {
            if (_filtroEstado != null && p.status != _filtroEstado) {
              return false;
            }
            if (_filtroTexto.isEmpty) return true;
            final query = _filtroTexto.toLowerCase();
            return p.name.toLowerCase().contains(query) ||
                p.category.toLowerCase().contains(query);
          }).toList();

          if (productosFiltrados.isEmpty) return null;

          return PantrySectionPreview(
            title: s.title,
            caption: s.caption,
            status: s.status,
            products: productosFiltrados,
          );
        })
        .whereType<PantrySectionPreview>()
        .toList();

    return ColoredBox(
      color: PantryColors.greenLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Scaffold(
            body: SafeArea(
              bottom: false,
              child: CustomScrollView(
                slivers: [
                  _HomeAppBar(
                    isSearching: _mostrarBuscador,
                    onToggleSearch: () {
                      widget.onSearch?.call();
                      setState(() {
                        _mostrarBuscador = !_mostrarBuscador;
                        if (!_mostrarBuscador) {
                          _searchController.clear();
                          _filtroTexto = '';
                        }
                      });
                    },
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
                            hintText: 'Buscar artículo o categoría…',
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
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(13),
                              borderSide: const BorderSide(
                                color: PantryColors.green,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    sliver: SliverToBoxAdapter(
                      child: _PantryHeading(
                        onCart: widget.onCart,
                        cartCount: widget.cartCount,
                        itemCount: totalArticulos,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _StatusFilters(
                      expiredCount: caducadosCount,
                      expiringCount: porCaducarCount,
                      lowStockCount: porAgotarseCount,
                      selectedStatus: _filtroEstado,
                      onStatusSelected: (status) {
                        setState(() {
                          _filtroEstado = status;
                        });
                      },
                    ),
                  ),
                  if (seccionesMostradas.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 36, 20, 36),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                _filtroTexto.isNotEmpty
                                    ? Icons.search_off_rounded
                                    : Icons.filter_alt_off_outlined,
                                size: 36,
                                color: PantryColors.muted,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _filtroTexto.isNotEmpty
                                    ? 'No se encontraron artículos para "$_filtroTexto"'
                                    : _filtroEstado != null
                                        ? 'Sin artículos en "${_filtroEstado!.label}"'
                                        : 'No hay artículos registrados',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: PantryColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    for (final section in seccionesMostradas) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                        sliver: SliverToBoxAdapter(
                          child: _SectionHeading(section: section),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final product = section.products[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: CatalogSwipeActions(
                                key: ValueKey('product-swipe-${product.name}'),
                                name: product.name,
                                onEdit: () =>
                                    widget.onEditProduct?.call(product),
                                onDelete: () =>
                                    widget.onDeleteProduct?.call(product),
                                child: ProductCard(
                                  product: product,
                                  onTap: widget.onProductTap == null
                                      ? null
                                      : () => widget.onProductTap!(product),
                                  onAddToCart: widget.onAddToCart == null
                                      ? null
                                      : () => widget.onAddToCart!(product),
                                ),
                              ),
                            );
                          }, childCount: section.products.length),
                        ),
                      ),
                    ],
                  // Reserva espacio para que el botón flotante no tape tarjetas.
                  const SliverToBoxAdapter(child: SizedBox(height: 88)),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: null,
              tooltip: 'Agregar artículo',
              onPressed: widget.onAddProduct ?? () {},
              child: const Icon(Icons.add_rounded, size: 30),
            ),
            bottomNavigationBar: AppBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: widget.onDestinationSelected,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({
    this.isSearching = false,
    this.onToggleSearch,
  });

  final bool isSearching;
  final VoidCallback? onToggleSearch;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      toolbarHeight: 68,
      titleSpacing: 20,
      title: const AppSectionHeading(section: AppSection.home),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: IconButton(
            tooltip: isSearching ? 'Cerrar búsqueda' : 'Buscar artículos',
            onPressed: onToggleSearch,
            icon: Icon(
              isSearching ? Icons.close_rounded : Icons.search_rounded,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _PantryHeading extends StatelessWidget {
  const _PantryHeading({
    this.onCart,
    required this.cartCount,
    this.itemCount = 11,
  });

  final VoidCallback? onCart;
  final int cartCount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: PantryColors.greenLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: PantryColors.green,
            size: 25,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Alacena', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                '$itemCount ${itemCount == 1 ? 'artículo registrado' : 'artículos registrados'}',
                style: const TextStyle(fontSize: 11, color: PantryColors.muted),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Ver carrito, $cartCount artículos',
          onPressed: onCart ?? () {},
          icon: badges.Badge(
            key: const ValueKey('home-cart-badge'),
            position: badges.BadgePosition.topEnd(top: -5, end: -5),
            ignorePointer: true,
            showBadge: cartCount > 0,
            badgeContent: Text(
              '$cartCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            badgeStyle: const badges.BadgeStyle(
              badgeColor: PantryColors.red,
              padding: EdgeInsets.all(3),
            ),
            child: const Icon(Icons.shopping_cart_outlined, size: 25),
          ),
        ),
      ],
    );
  }
}

class _StatusFilters extends StatelessWidget {
  const _StatusFilters({
    this.expiredCount = 0,
    this.expiringCount = 0,
    this.lowStockCount = 0,
    this.selectedStatus,
    this.onStatusSelected,
  });

  final int expiredCount;
  final int expiringCount;
  final int lowStockCount;
  final PantryPreviewStatus? selectedStatus;
  final ValueChanged<PantryPreviewStatus?>? onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final filters = [
      (
        'Caducados',
        '$expiredCount',
        Icons.error_outline_rounded,
        PantryColors.red,
        PantryColors.redLight,
        PantryPreviewStatus.expired,
      ),
      (
        'Por caducar',
        '$expiringCount',
        Icons.hourglass_bottom_rounded,
        PantryColors.orange,
        PantryColors.orangeLight,
        PantryPreviewStatus.expiring,
      ),
      (
        'Por agotarse',
        '$lowStockCount',
        Icons.warning_amber_rounded,
        PantryColors.amber,
        PantryColors.amberLight,
        PantryPreviewStatus.lowStock,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final filter in filters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () {
                    final nuevo =
                        selectedStatus == filter.$6 ? null : filter.$6;
                    onStatusSelected?.call(nuevo);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selectedStatus == filter.$6
                          ? filter.$4.withAlpha(46)
                          : filter.$5,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: selectedStatus == filter.$6
                            ? filter.$4
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(filter.$3, size: 15, color: filter.$4),
                        const SizedBox(width: 5),
                        Text(
                          filter.$1,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: selectedStatus == filter.$6
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: selectedStatus == filter.$6
                                ? filter.$4
                                : PantryColors.ink,
                          ),
                        ),
                        const SizedBox(width: 6),
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: filter.$4,
                          child: Text(
                            filter.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.section});

  final PantrySectionPreview section;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: section.status.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            section.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          constraints: const BoxConstraints(maxWidth: 150),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: section.status.background,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            section.caption,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: section.status.color,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
