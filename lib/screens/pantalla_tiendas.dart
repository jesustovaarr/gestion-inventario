import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import '../components/tema_alacena.dart';
import 'pantalla_editar_tienda.dart';
import 'formulario_tienda.dart';
import '../widgets/acciones_deslizables_catalogo.dart';

/// Catálogo visual de tiendas con datos fijos, sin consultas ni modificaciones.
class StoresScreen extends StatelessWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                    leadingWidth: 40,
                    pinned: true,
                    titleSpacing: 0,
                    title: const AppSectionHeading(
                      section: AppSection.stores,
                      count: '4',
                    ),
                    actions: [
                      IconButton(
                        onPressed: () {},
                        tooltip: 'Buscar tienda',
                        icon: const Icon(Icons.search_rounded, size: 21),
                      ),
                      IconButton(
                        onPressed: () {},
                        tooltip: 'Más opciones',
                        icon: const Icon(Icons.more_vert_rounded, size: 20),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton.filled(
                          onPressed: () {},
                          tooltip: 'Perfil',
                          style: IconButton.styleFrom(
                            backgroundColor: PantryColors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                hintText: 'Buscar tienda o sucursal…',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: PantryColors.muted,
                                ),
                                prefixIcon: const Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: PantryColors.muted,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () {},
                                  tooltip: 'Limpiar búsqueda',
                                  icon: const Icon(
                                    Icons.close_rounded,
                                    size: 17,
                                    color: PantryColors.muted,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14,
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
                          const SizedBox(width: 8),
                          IconButton.filledTonal(
                            onPressed: () {},
                            tooltip: 'Filtrar tiendas',
                            style: IconButton.styleFrom(
                              backgroundColor: PantryColors.greenLight,
                              foregroundColor: PantryColors.green,
                              minimumSize: const Size(48, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _StoreFilters()),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 20, 20, 14),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          Expanded(
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
                            '4 registradas',
                            style: TextStyle(
                              fontSize: 10,
                              color: PantryColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList.builder(
                      itemCount: _stores.length,
                      itemBuilder: (context, index) {
                        final store = _stores[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: CatalogSwipeActions(
                            key: ValueKey('store-swipe-${store.name}'),
                            name: store.name,
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => StoreFormScreen(
                                  storeName: store.name,
                                  address: store.address,
                                  purchases: store.purchases,
                                ),
                              ),
                            ),
                            onDelete: () => showCatalogRemovalPreview(
                              context,
                              name: store.name,
                              blockedByPurchases: store.purchases > 0,
                            ),
                            child: _StoreCard(store: store),
                          ),
                        );
                      },
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 110),
                    sliver: SliverToBoxAdapter(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFEAF4EB),
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          border: Border.fromBorderSide(
                            BorderSide(color: PantryColors.border),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.tips_and_updates_outlined,
                                size: 20,
                                color: PantryColors.green,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Asocia cada ticket o compra a una tienda para obtener comparativas automáticas de precios y saber dónde consigues tu despensa más barata.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.5,
                                    color: PantryColors.muted,
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
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const StoreFormScreen(),
                ),
              ),
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

class _StoreFilters extends StatelessWidget {
  const _StoreFilters();
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: [
        FilledButton(
          onPressed: () {},
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 13),
            minimumSize: const Size(0, 36),
          ),
          child: const Text('Todas   4', style: TextStyle(fontSize: 11)),
        ),
        const SizedBox(width: 7),
        _FilterPill(
          icon: Icons.receipt_long_outlined,
          label: 'Con compras registradas',
        ),
        const SizedBox(width: 7),
        _FilterPill(icon: Icons.star_border_rounded, label: 'Frecuentes'),
      ],
    ),
  );
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () {},
    icon: Icon(icon, size: 14, color: PantryColors.green),
    label: Text(
      label,
      style: const TextStyle(fontSize: 11, color: PantryColors.ink),
    ),
    style: OutlinedButton.styleFrom(
      backgroundColor: Colors.white,
      side: const BorderSide(color: PantryColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 11),
      minimumSize: const Size(0, 36),
    ),
  );
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({required this.store});
  final _StorePreview store;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 10, 13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: PantryColors.border),
    ),
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
              child: Icon(store.icon, size: 23, color: PantryColors.green),
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
                          store.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (store.frequent) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 3,
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
                          store.address,
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
            PopupMenuButton<String>(
              tooltip: 'Opciones de ${store.name}',
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => EditStoreScreen(
                        storeName: store.name,
                        address: store.address,
                        purchases: store.purchases,
                      ),
                    ),
                  );
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 150),
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: PantryColors.muted,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar tienda')),
                PopupMenuItem(
                  value: 'history',
                  child: Text('Historial de compras'),
                ),
                PopupMenuItem(
                  value: 'deactivate',
                  child: Text('Desactivar tienda'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 11),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(
            color: PantryColors.background,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Wrap(
            spacing: 7,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 13,
                color: PantryColors.green,
              ),
              Text(
                '${store.purchases} ${store.purchases == 1 ? 'compra registrada' : 'compras registradas'}',
                style: const TextStyle(
                  fontSize: 10,
                  color: PantryColors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Última compra: ${store.lastPurchase}',
                style: const TextStyle(fontSize: 10, color: PantryColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StorePreview {
  const _StorePreview(
    this.name,
    this.address,
    this.purchases,
    this.lastPurchase,
    this.icon, {
    this.frequent = false,
  });
  final String name;
  final String address;
  final int purchases;
  final String lastPurchase;
  final IconData icon;
  final bool frequent;
}

const _stores = [
  _StorePreview(
    'Walmart Supercenter',
    'Av. Universidad #1205, Col. del Valle',
    5,
    'Hace 3 días',
    Icons.storefront_outlined,
    frequent: true,
  ),
  _StorePreview(
    'Soriana Híper',
    'Blvd. Insurgentes #450, Jardines del Prado',
    8,
    'Ayer',
    Icons.storefront_outlined,
    frequent: true,
  ),
  _StorePreview(
    'Bodega Aurrerá Express',
    'Calle 5 de Mayo #32, Centro',
    3,
    'Hace 1 sem',
    Icons.shopping_basket_outlined,
  ),
  _StorePreview(
    'Costco Wholesale',
    'Calzada del Hueso #500, Coapa',
    1,
    'Hace 2 sem',
    Icons.apartment_rounded,
  ),
];
