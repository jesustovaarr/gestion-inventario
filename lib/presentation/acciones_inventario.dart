import 'package:flutter/material.dart';

import '../database/daos/lote_dao.dart';
import '../database/daos/producto_dao.dart';
import '../utils/cantidades.dart';
import '../utils/presentaciones.dart';

/// Consulta el lote actual antes de actuar para no usar datos antiguos de la tarjeta.
Future<void> actuarSobrePrimerLote(
  BuildContext context,
  int productoId, {
  double cantidad = 1,
}) async {
  final dao = LoteDao();
  try {
    final producto = await ProductoDao().obtenerPorId(productoId);
    final lotes = producto?.lotesActivos ?? [];
    if (!context.mounted || lotes.isEmpty) return;
    final primero = lotes.first;
    final desechar = primero.estaCaducado;
    final seleccion = await showDialog<double>(
      context: context,
      builder: (_) => _CantidadDialog(
        cantidadInicial: primero.presentacion.esEnvase
            ? (primero.contenidoEnvase < primero.cantidad
                  ? primero.contenidoEnvase
                  : primero.cantidad)
            : cantidad,
        disponible: desechar
            ? primero.cantidad
            : normalizarCantidad(
                lotes.fold<double>(0, (s, l) => s + l.cantidad),
              ),
        desechar: desechar,
        loteId: primero.id!,
        unidad: producto!.unidadMedida,
        descripcionLote: describirExistencia(
          cantidad: primero.cantidad,
          unidad: producto.unidadMedida,
          presentacion: primero.presentacion,
          contenidoEnvase: primero.contenidoEnvase,
        ),
      ),
    );
    if (seleccion == null || !context.mounted) return;
    final ok = desechar
        ? await dao.descartarLote(primero.id!) > 0
        : await dao.descontarStockFEFO(productoId, seleccion);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (desechar
                    ? 'Lote desechado. Inventario actualizado.'
                    : 'Consumo registrado. Inventario actualizado.')
              : 'No se pudo actualizar. Revisa las cantidades y los lotes caducados.',
        ),
      ),
    );
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo guardar el movimiento. Inténtalo de nuevo.'),
      ),
    );
  }
}

class _CantidadDialog extends StatefulWidget {
  const _CantidadDialog({
    required this.cantidadInicial,
    required this.disponible,
    required this.desechar,
    required this.loteId,
    required this.unidad,
    required this.descripcionLote,
  });
  final double cantidadInicial;
  final double disponible;
  final bool desechar;
  final int loteId;
  final String unidad;
  final String descripcionLote;
  @override
  State<_CantidadDialog> createState() => _CantidadDialogState();
}

class _CantidadDialogState extends State<_CantidadDialog> {
  late final TextEditingController controller;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: formatearCantidad(
        widget.cantidadInicial > widget.disponible
            ? widget.disponible
            : widget.cantidadInicial,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valor = leerCantidad(controller.text);
    final valido = valor != null && valor <= widget.disponible;
    return AlertDialog(
      title: Text(
        widget.desechar ? 'Desechar producto completo' : 'Registrar consumo',
      ),
      content: widget.desechar
          ? Text(
              'Se desechará todo el contenido del lote #${widget.loteId}: ${widget.descripcionLote}. El siguiente lote quedará disponible.',
            )
          : TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Cantidad a consumir',
                suffixText: unidadVisible(widget.unidad),
                helperText:
                    'Disponible en total: ${formatearContenido(widget.disponible, widget.unidad)}. Primero se consumirá el lote #${widget.loteId}: ${widget.descripcionLote}.',
                helperMaxLines: 4,
                errorText: valido
                    ? null
                    : 'Usa hasta tres decimales; máximo ${formatearCantidad(widget.disponible)}',
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: widget.desechar || valido
              ? () => Navigator.pop(
                  context,
                  widget.desechar ? widget.disponible : valor,
                )
              : null,
          child: Text(widget.desechar ? 'Desechar' : 'Registrar consumo'),
        ),
      ],
    );
  }
}
