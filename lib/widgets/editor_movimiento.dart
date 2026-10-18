import 'package:flutter/material.dart';

import '../utils/cantidades.dart';

class MovementEdit {
  const MovementEdit(this.tipo, this.cantidad, this.fecha);
  final String tipo;
  final double? cantidad;
  final DateTime fecha;
}

class MovementEditorDialog extends StatefulWidget {
  const MovementEditorDialog({
    super.key,
    required this.movimiento,
    required this.unit,
  });
  final Map<String, Object?> movimiento;
  final String unit;
  @override
  State<MovementEditorDialog> createState() => _MovementEditorDialogState();
}

class _MovementEditorDialogState extends State<MovementEditorDialog> {
  late final TextEditingController _cantidad;
  late String _tipo;
  late DateTime _fecha;
  @override
  void initState() {
    super.initState();
    _cantidad = TextEditingController(
      text: formatearCantidad(
        (widget.movimiento['cantidad'] ??
                widget.movimiento['cantidad_descartada'] ??
                1)
            as num,
      ),
    );
    _tipo = widget.movimiento['tipo'] as String;
    _fecha = DateTime.parse(widget.movimiento['fecha'] as String);
  }

  @override
  void dispose() {
    _cantidad.dispose();
    super.dispose();
  }

  Future<void> _cambiarFecha() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(1900),
      lastDate: DateTime(3100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_fecha),
    );
    if (time == null || !mounted) return;
    setState(() {
      _fecha = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final qty = leerCantidad(_cantidad.text);
    return AlertDialog(
      title: const Text('Editar movimiento'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _tipo,
              decoration: const InputDecoration(labelText: 'Tipo'),
              items: const [
                DropdownMenuItem(value: 'consumo', child: Text('Consumo')),
                DropdownMenuItem(value: 'desecho', child: Text('Desecho')),
              ],
              onChanged: (v) => setState(() {
                _tipo = v!;
              }),
            ),
            if (_tipo == 'consumo')
              TextField(
                controller: _cantidad,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  suffixText: widget.unit,
                  errorText: qty == null
                      ? 'Usa una cantidad mayor que 0, con hasta tres decimales'
                      : null,
                ),
                onChanged: (_) => setState(() {}),
              )
            else
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.inventory_2_outlined),
                title: const Text('Producto completo'),
                subtitle: Text(
                  'Se registra el desecho del lote #${widget.movimiento['lote_id']} completo.',
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha y hora'),
              subtitle: Text(_fecha.toString().substring(0, 16)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _cambiarFecha,
            ),
            const Text(
              'Solo se modifica este registro. El inventario conserva su cantidad actual.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _tipo == 'consumo' && qty == null
              ? null
              : () => Navigator.pop(
                  context,
                  MovementEdit(_tipo, _tipo == 'consumo' ? qty : null, _fecha),
                ),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
