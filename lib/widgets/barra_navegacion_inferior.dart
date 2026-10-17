import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';

/// Navegación compartida por listas, detalles y formularios
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
  });
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    height: 72,
    backgroundColor: PantryColors.background,
    surfaceTintColor: Colors.transparent,
    indicatorColor: PantryColors.greenLight,
    labelTextStyle: const WidgetStatePropertyAll(
      TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
    ),
    onDestinationSelected: (index) {
      if (onDestinationSelected != null) {
        onDestinationSelected!(index);
        return;
      }
      if (index == selectedIndex) return;
      switch (index) {
        case 0:
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          break;
        case 1:
          Navigator.of(context).pushNamedAndRemoveUntil('/calendar', (route) => false);
          break;
        case 2:
          Navigator.of(context).pushNamedAndRemoveUntil('/stores', (route) => false);
          break;
        case 3:
          Navigator.of(context).pushNamedAndRemoveUntil('/cart', (route) => false);
          break;
      }
    },
    destinations: const [
      NavigationDestination(
        icon: Icon(Icons.home_outlined, size: 22),
        selectedIcon: Icon(
          Icons.home_rounded,
          size: 22,
          color: PantryColors.green,
        ),
        label: 'Inicio',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined, size: 22),
        selectedIcon: Icon(
          Icons.calendar_month_rounded,
          size: 22,
          color: PantryColors.green,
        ),
        label: 'Calendario',
      ),
      NavigationDestination(
        icon: Icon(Icons.storefront_outlined, size: 22),
        selectedIcon: Icon(
          Icons.storefront_rounded,
          size: 22,
          color: PantryColors.green,
        ),
        label: 'Tiendas',
      ),
      NavigationDestination(
        icon: Icon(Icons.shopping_cart_outlined, size: 22),
        selectedIcon: Icon(
          Icons.shopping_cart_rounded,
          size: 22,
          color: PantryColors.green,
        ),
        label: 'Carrito',
      ),
    ],
  );
}
