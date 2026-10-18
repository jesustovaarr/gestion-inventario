import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../components/tema_alacena.dart';
import '../utils/cantidades.dart';

class MovementHistoryCard extends StatelessWidget {
  const MovementHistoryCard({
    super.key,
    required this.movimiento,
    required this.unit,
    required this.onTap,
    required this.onDelete,
    this.enabled = true,
  });
  final Map<String, Object?> movimiento;
  final String unit;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final consumo = movimiento['tipo'] == 'consumo';
    final fecha = DateTime.tryParse(movimiento['fecha'] as String? ?? '');
    final fechaTexto = fecha == null
        ? 'Sin fecha'
        : fecha.toString().substring(0, 16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey('movement-${movimiento['id']}'),
        enabled: enabled,
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.27,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              icon: Icons.delete_outline,
              label: 'Borrar',
              backgroundColor: PantryColors.red,
              foregroundColor: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    consumo ? Icons.restaurant_outlined : Icons.delete_outline,
                    size: 20,
                    color: consumo ? PantryColors.green : PantryColors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          consumo ? 'Consumo registrado' : 'Desecho registrado',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$fechaTexto · Lote #${movimiento['lote_id']}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: PantryColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    consumo
                        ? '${formatearCantidad(movimiento['cantidad'] as num)} $unit'
                        : 'Producto completo',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: PantryColors.green,
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
