import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import 'package:badges/badges.dart' as badges;

import '../components/tema_alacena.dart';
import '../presentation/datos_alacena_demostracion.dart';
import '../widgets/tarjeta_producto.dart';
import '../widgets/acciones_deslizables_catalogo.dart';

/// Maqueta de Inicio. Los callbacks quedan disponibles para conectar las
/// pantallas y los servicios después; aquí solo se presentan datos de ejemplo.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onSearch,
    this.onProfile,
    this.onCart,
    this.onAddProduct,
    this.onDestinationSelected,
    this.onProductTap,
    this.onAddToCart,
    this.cartCount = 3,
    this.onEditProduct,
    this.onDeleteProduct,
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

  @override
  Widget build(BuildContext context) {
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
                  _HomeAppBar(onSearch: onSearch, onProfile: onProfile),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
                    sliver: SliverToBoxAdapter(
                      child: _PantryHeading(
                        onCart: onCart,
                        cartCount: cartCount,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _StatusFilters()),
                  for (final section in pantryPreviewSections) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                      sliver: SliverToBoxAdapter(
                        child: _SectionHeading(section: section),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final product = section.products[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: CatalogSwipeActions(
                              key: ValueKey('product-swipe-${product.name}'),
                              name: product.name,
                              onEdit: () => onEditProduct?.call(product),
                              onDelete: () => onDeleteProduct?.call(product),
                              child: ProductCard(
                                product: product,
                                onTap: onProductTap == null
                                    ? null
                                    : () => onProductTap!(product),
                                onAddToCart: onAddToCart == null
                                    ? null
                                    : () => onAddToCart!(product),
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
              onPressed: onAddProduct ?? () {},
              child: const Icon(Icons.add_rounded, size: 30),
            ),
            bottomNavigationBar: AppBottomNavigation(
              selectedIndex: 0,
              onDestinationSelected: onDestinationSelected,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeAppBar extends StatelessWidget {
  const _HomeAppBar({this.onSearch, this.onProfile});

  final VoidCallback? onSearch;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      leadingWidth: 40,
      pinned: true,
      toolbarHeight: 68,
      titleSpacing: 20,
      title: const AppSectionHeading(section: AppSection.home),
      actions: [
        IconButton(
          tooltip: 'Buscar',
          onPressed: onSearch ?? () {},
          icon: const Icon(Icons.search_rounded, size: 23),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2, right: 16),
          child: IconButton.filled(
            tooltip: 'Perfil',
            onPressed: onProfile ?? () {},
            style: IconButton.styleFrom(
              backgroundColor: PantryColors.green,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.person_outline_rounded, size: 20),
          ),
        ),
      ],
    );
  }
}

class _PantryHeading extends StatelessWidget {
  const _PantryHeading({this.onCart, required this.cartCount});

  final VoidCallback? onCart;
  final int cartCount;

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
            Icons.eco_outlined,
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
              const Text(
                '11 artículos registrados',
                style: TextStyle(fontSize: 11, color: PantryColors.muted),
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
  const _StatusFilters();

  @override
  Widget build(BuildContext context) {
    const filters = [
      (
        'Caducados',
        '2',
        Icons.error_outline_rounded,
        PantryColors.red,
        PantryColors.redLight,
      ),
      (
        'Por caducar',
        '4',
        Icons.hourglass_bottom_rounded,
        PantryColors.orange,
        PantryColors.orangeLight,
      ),
      (
        'Por agotarse',
        '1',
        Icons.warning_amber_rounded,
        PantryColors.amber,
        PantryColors.amberLight,
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: filter.$5,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(filter.$3, size: 15, color: filter.$4),
                    const SizedBox(width: 5),
                    Text(
                      filter.$1,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
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
