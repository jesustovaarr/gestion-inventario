import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

/// Acciones comunes para las tarjetas de productos y tiendas.
class CatalogSwipeActions extends StatelessWidget {
  const CatalogSwipeActions({
    super.key,
    required this.name,
    required this.child,
    required this.onEdit,
    required this.onDelete,
  });
  final String name;
  final Widget child;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: Slidable(
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: .48,
        children: [
          _action('Editar', Icons.edit_outlined, Colors.white, onEdit),
          _action(
            'Borrar',
            Icons.delete_outline_rounded,
            const Color(0xFFFFB8AE),
            onDelete,
          ),
        ],
      ),
      child: child,
    ),
  );

  Widget _action(
    String label,
    IconData icon,
    Color foreground,
    VoidCallback callback,
  ) => CustomSlidableAction(
    onPressed: (_) => callback(),
    backgroundColor: const Color(0xFF18344D),
    foregroundColor: foreground,
    padding: EdgeInsets.zero,
    child: Tooltip(
      message: '$label $name',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22, color: foreground),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 10, color: foreground)),
        ],
      ),
    ),
  );
}

Future<void> showCatalogRemovalPreview(
  BuildContext context, {
  required String name,
  bool blockedByPurchases = false,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(
      blockedByPurchases
          ? 'No se puede eliminar la tienda'
          : 'Desactivar del catálogo',
    ),
    content: Text(
      blockedByPurchases
          ? '$name tiene compras registradas. Conserva la tienda para mantener la trazabilidad de esas compras.'
          : '$name se dará de baja de forma lógica. Sus lotes y su historial se conservarán.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(dialogContext).pop(),
        child: Text(blockedByPurchases ? 'Entendido' : 'Cancelar'),
      ),
      if (!blockedByPurchases)
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Desactivar'),
        ),
    ],
  ),
);
