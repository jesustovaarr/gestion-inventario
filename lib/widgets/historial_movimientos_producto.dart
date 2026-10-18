import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';

import '../database/daos/lote_dao.dart';
import 'editor_movimiento.dart';
import 'tarjeta_movimiento.dart';

class ProductMovementHistory extends StatefulWidget {
  const ProductMovementHistory({
    super.key,
    required this.productoId,
    required this.unit,
  });
  final int productoId;
  final String unit;
  @override
  State<ProductMovementHistory> createState() => _ProductMovementHistoryState();
}

class _ProductMovementHistoryState extends State<ProductMovementHistory> {
  final _dao = LoteDao();
  List<Map<String, Object?>> _movimientos = [];
  final Set<int> _ocupados = {};
  bool _cargando = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final rows = await _dao.obtenerMovimientos(widget.productoId);
      if (mounted) {
        setState(() {
          _movimientos = rows;
          _cargando = false;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _error = 'No se pudo cargar el historial.';
        });
      }
    }
  }

  Future<void> _editar(Map<String, Object?> movimiento) async {
    final id = movimiento['id'] as int;
    if (_ocupados.contains(id)) return;
    final edit = await showDialog<MovementEdit>(
      context: context,
      builder: (_) =>
          MovementEditorDialog(movimiento: movimiento, unit: widget.unit),
    );
    if (edit == null || !mounted) return;
    await _guardar(
      id,
      () => _dao.editarMovimiento(
        id,
        tipo: edit.tipo,
        cantidad: edit.cantidad,
        fecha: edit.fecha,
      ),
      'Registro actualizado',
    );
  }

  Future<void> _guardar(
    int id,
    Future<void> Function() operation,
    String mensaje,
  ) async {
    if (_ocupados.contains(id)) return;
    setState(() => _ocupados.add(id));
    try {
      await operation();
      await _cargar();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(mensaje)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No se pudo modificar el registro. Inténtalo de nuevo.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _ocupados.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Consumos y desechos',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 6),
      const Text(
        'Toca un registro para editarlo o desliza para borrarlo.',
        style: TextStyle(fontSize: 12),
      ),
      const SizedBox(height: 12),
      if (_cargando) const LinearProgressIndicator(),
      if (_error != null)
        TextButton(onPressed: _cargar, child: Text('$_error Reintentar')),
      if (!_cargando && _error == null && _movimientos.isEmpty)
        const Text(
          'Sin movimientos registrados',
          style: TextStyle(color: PantryColors.red),
        ),
      for (final row in _movimientos)
        MovementHistoryCard(
          movimiento: row,
          unit: widget.unit,
          enabled: !_ocupados.contains(row['id']),
          onTap: () => _editar(row),
          onDelete: () => _guardar(
            row['id'] as int,
            () => _dao.eliminarMovimiento(row['id'] as int),
            'Registro eliminado',
          ),
        ),
    ],
  );
}
