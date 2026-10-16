import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../components/tema_alacena.dart';
import '../presentation/datos_alacena_demostracion.dart';
import '../presentation/lista_compras_demostracion.dart';
import '../widgets/miniatura_producto.dart';
import 'pantalla_registrar_compra.dart';

/// Lista de demostración, sin persistencia ni reposición de inventario.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  PantryProductPreview? _purchaseProduct;

  Future<void> _selectPurchaseProduct(
    ShoppingListsPreviewController controller,
  ) async {
    final product = await showModalBottomSheet<PantryProductPreview>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) =>
          _CatalogPicker(controller: controller, selectForPurchase: true),
    );
    if (mounted && product != null) {
      setState(() => _purchaseProduct = product);
    }
  }

  void _openCatalog(ShoppingListsPreviewController controller) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CatalogPicker(controller: controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ShoppingListsPreviewScope.of(context);
    final current = controller.current;
    final purchaseProduct =
        _purchaseProduct ??
        (current.items.isEmpty ? null : current.items.first.product);
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
                  const SliverAppBar(
                    toolbarHeight: 68,
                    leadingWidth: 40,
                    pinned: true,
                    titleSpacing: 0,
                    title: AppSectionHeading(section: AppSection.shoppingLists),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Nombre de la lista',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PantryColors.muted,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            key: ValueKey(current.id),
                            initialValue: current.name,
                            onChanged: controller.renameCurrent,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Escribe el nombre de tu lista',
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Agrega productos de tu catálogo y ajusta lo que necesitas comprar.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: PantryColors.muted,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openCatalog(controller),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: PantryColors.green,
                                    side: const BorderSide(
                                      color: PantryColors.green,
                                    ),
                                    minimumSize: const Size(0, 44),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text(
                                    'Agregar del catálogo',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              IconButton(
                                onPressed: current.items.isEmpty
                                    ? null
                                    : controller.clearCurrent,
                                tooltip: 'Vaciar lista actual',
                                icon: const Icon(
                                  Icons.delete_sweep_outlined,
                                  color: PantryColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  if (current.items.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyCart())
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: current.items.length,
                        itemBuilder: (_, index) {
                          final item = current.items[index];
                          return _CartItem(
                            product: item.product,
                            quantity: '${item.quantity}',
                            alert: item.product.note,
                            onRemove: () =>
                                controller.removeProduct(item.product),
                            onDecrease: () =>
                                controller.changeQuantity(item.product, -1),
                            onIncrease: () =>
                                controller.changeQuantity(item.product, 1),
                          );
                        },
                      ),
                    ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        key: const ValueKey('cart-purchase-section'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: PantryColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 19,
                                  color: PantryColors.green,
                                ),
                                SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    'Registrar compra',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Captura la tienda, la cantidad y el precio que pagaste en esta compra.',
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: PantryColors.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: PantryColors.greenLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 18,
                                    color: PantryColors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      key: ValueKey(
                                        'purchase-product-${purchaseProduct?.name}',
                                      ),
                                      initialValue: purchaseProduct?.name,
                                      readOnly: true,
                                      onTap: () =>
                                          _selectPurchaseProduct(controller),
                                      style: const TextStyle(fontSize: 11),
                                      decoration: const InputDecoration(
                                        hintText: 'Selecciona un artículo',
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        suffixIcon: Icon(
                                          Icons.expand_more_rounded,
                                          size: 18,
                                          color: PantryColors.green,
                                        ),
                                        suffixIconConstraints: BoxConstraints(
                                          minWidth: 24,
                                          minHeight: 24,
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  FilledButton(
                                    key: const ValueKey(
                                      'cart-register-purchase',
                                    ),
                                    onPressed: purchaseProduct == null
                                        ? null
                                        : () => Navigator.of(context).push(
                                            MaterialPageRoute<void>(
                                              builder: (_) =>
                                                  RegisterPurchaseScreen(
                                                    product: purchaseProduct,
                                                  ),
                                            ),
                                          ),
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      minimumSize: const Size(0, 34),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                    ),
                                    child: const Text(
                                      'Agregar',
                                      style: TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'El precio puede variar según la tienda y la fecha.',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.4,
                                color: PantryColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: PantryColors.greenLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.shopping_cart_outlined,
                              size: 23,
                              color: PantryColors.green,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Total: ${current.items.length} ${current.items.length == 1 ? 'producto' : 'productos'}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${current.units} ${current.units == 1 ? 'unidad' : 'unidades'} en la lista',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: PantryColors.muted,
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
                ],
              ),
            ),
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1, color: PantryColors.border),
                SafeArea(
                  bottom: false,
                  minimum: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: current.items.isEmpty
                          ? null
                          : controller.clearCurrent,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Completar lista',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const AppBottomNavigation(selectedIndex: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  const _CartItem({
    required this.product,
    required this.quantity,
    required this.alert,
    required this.onRemove,
    required this.onDecrease,
    required this.onIncrease,
  });
  final PantryProductPreview product;
  final String quantity;
  final String alert;
  final VoidCallback onRemove;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PantryColors.border),
    ),
    child: Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumbnail(
              kind: product.thumbnail,
              imagePath: product.imagePath,
              size: 58,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    product.category,
                    style: const TextStyle(
                      fontSize: 10,
                      color: PantryColors.muted,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    alert,
                    style: TextStyle(fontSize: 10, color: product.status.color),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Eliminar ${product.name} de la lista',
              icon: const Icon(
                Icons.delete_outline_rounded,
                size: 19,
                color: PantryColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Cantidad a comprar:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: PantryColors.background,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onDecrease,
                    tooltip: 'Disminuir ${product.name}',
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(Icons.remove_rounded, size: 16),
                  ),
                  Text(
                    quantity,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    onPressed: onIncrease,
                    tooltip: 'Aumentar ${product.name}',
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: PantryColors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(32),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          radius: 42,
          backgroundColor: PantryColors.greenLight,
          child: Icon(
            Icons.shopping_bag_outlined,
            size: 42,
            color: PantryColors.green,
          ),
        ),
        SizedBox(height: 20),
        Text(
          'Tu lista está vacía',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 10),
        Text(
          'Agrega productos desde tu alacena para preparar tu próxima compra.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: PantryColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _CatalogPicker extends StatelessWidget {
  const _CatalogPicker({
    required this.controller,
    this.selectForPurchase = false,
  });
  final ShoppingListsPreviewController controller;
  final bool selectForPurchase;

  @override
  Widget build(BuildContext context) {
    final products = pantryPreviewSections
        .expand((section) => section.products)
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Productos del catálogo',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Cerrar catálogo',
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.builder(
                    itemCount: products.length,
                    itemBuilder: (_, index) {
                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            ProductThumbnail(kind: product.thumbnail, size: 48),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.category,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                if (selectForPurchase) {
                                  Navigator.of(context).pop(product);
                                } else {
                                  controller.addProduct(product);
                                  Navigator.of(context).pop();
                                }
                              },
                              tooltip: selectForPurchase
                                  ? 'Seleccionar ${product.name} para compra'
                                  : 'Añadir ${product.name} a la lista',
                              icon: const Icon(
                                Icons.add_circle_outline_rounded,
                                color: PantryColors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
