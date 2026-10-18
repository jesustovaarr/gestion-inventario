import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';

import '../models/lote_model.dart';
import '../services/servicio_notificaciones.dart';
import '../utils/cantidades.dart';
import '../utils/presentaciones.dart';

class ProductLotsEditor extends StatefulWidget {
  const ProductLotsEditor({
    super.key,
    required this.productoId,
    required this.lotes,
    required this.unit,
    required this.onChanged,
    this.defaultPackaging = PresentacionCompra.granel,
    this.defaultContent = 1,
  });
  final int productoId;
  final List<Lote> lotes;
  final String unit;
  final ValueChanged<List<Lote>?> onChanged;
  final PresentacionCompra defaultPackaging;
  final double defaultContent;
  @override
  State<ProductLotsEditor> createState() => _ProductLotsEditorState();
}

class _LotDraft {
  _LotDraft(this.lote)
    : cantidad = TextEditingController(text: formatearCantidad(lote.cantidad));
  Lote lote;
  final TextEditingController cantidad;
}

class _ProductLotsEditorState extends State<ProductLotsEditor> {
  bool _pickingDate = false;
  late final List<_LotDraft> _drafts;
  final List<Lote> _removed = [];
  @override
  void initState() {
    super.initState();
    _drafts = widget.lotes
        .where((l) => l.cantidad > 0)
        .map((l) {
          var lote = l;
          if (lote.alarmaActiva == 1) {
            final f = DateTime.tryParse(lote.fechaCaducidad);
            if (f != null &&
                ServicioNotificaciones.validarMomentoAlarma(
                  fechaCaducidad: f,
                  horaAviso: lote.horaAviso,
                ) !=
                    null) {
              lote = lote.copyWith(alarmaActiva: 0);
            }
          }
          return _LotDraft(lote);
        })
        .toList();
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.cantidad.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final values = <Lote>[..._removed];
    for (final draft in _drafts) {
      final qty = leerCantidad(draft.cantidad.text, permiteCero: true);
      if (qty == null) {
        widget.onChanged(null);
        return;
      }
      draft.lote = draft.lote.copyWith(cantidad: qty);
      values.add(draft.lote);
    }
    widget.onChanged(values);
  }

  Future<void> _eliminar(_LotDraft draft) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar lote'),
        content: const Text(
          'Se quitarán sus existencias al guardar los cambios. El historial de compras y consumos se conserva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: PantryColors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (!mounted || confirm != true) return;
    setState(() {
      _drafts.remove(draft);
      // Un lote retirado queda sin existencias, conservando sus referencias históricas.
      if (draft.lote.id != null) {
        _removed.add(draft.lote.copyWith(cantidad: 0, alarmaActiva: 0));
      }
    });
    // Esperar a que se retire el campo antes de liberar su controlador.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => draft.cantidad.dispose(),
    );
    _emit();
  }

  Future<void> _fecha(_LotDraft draft) async {
    if (_pickingDate) return;
    _pickingDate = true;
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(draft.lote.fechaCaducidad),
      firstDate: DateTime(1900),
      lastDate: DateTime(3100),
    );
    _pickingDate = false;
    if (fecha == null || !mounted) return;
    final errorAlarma = ServicioNotificaciones.validarMomentoAlarma(
      fechaCaducidad: fecha,
      horaAviso: draft.lote.horaAviso,
    );
    final alarmaEstabaActiva = draft.lote.alarmaActiva == 1;
    setState(() {
      draft.lote = draft.lote.copyWith(
        fechaCaducidad: fecha.toIso8601String().substring(0, 10),
        alarmaActiva: errorAlarma != null ? 0 : draft.lote.alarmaActiva,
      );
    });
    if (errorAlarma != null && alarmaEstabaActiva && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La fecha seleccionada ya pasó. La alarma se ha desactivado.',
          ),
          backgroundColor: PantryColors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
    _emit();
  }

  Future<void> _hora(_LotDraft draft) async {
    final partes = RegExp(r'^(\d{1,2}):(\d{2})(?: (AM|PM))?$')
        .firstMatch(draft.lote.horaAviso);
    var hour = int.tryParse(partes?.group(1) ?? '') ?? 9;
    if (partes?.group(3) != null) {
      hour = hour % 12 + (partes!.group(3) == 'PM' ? 12 : 0);
    }
    final inicial = TimeOfDay(
      hour: hour,
      minute: int.tryParse(partes?.group(2) ?? '') ?? 0,
    );
    final hora = await showTimePicker(context: context, initialTime: inicial);
    if (hora == null || !mounted) return;
    final nuevaHora =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';
    final f = DateTime.tryParse(draft.lote.fechaCaducidad);
    if (f != null && draft.lote.alarmaActiva == 1) {
      final error = ServicioNotificaciones.validarMomentoAlarma(
        fechaCaducidad: f,
        horaAviso: nuevaHora,
      );
      if (error != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: PantryColors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    }
    setState(() {
      draft.lote = draft.lote.copyWith(
        horaAviso: nuevaHora,
      );
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Lotes y existencias',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      const Text(
        'Cada entrada conserva su caducidad. Aquí aparecen solo las que todavía tienen existencias.',
        style: TextStyle(fontSize: 12),
      ),
      if (_drafts.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'No hay lotes con existencias.',
            style: TextStyle(color: PantryColors.red),
          ),
        ),
      for (final draft in _drafts)
        Padding(
          key: ObjectKey(draft),
          padding: const EdgeInsets.only(top: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          draft.lote.id == null
                              ? 'Nuevo lote'
                              : 'Lote #${draft.lote.id}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        tooltip: draft.lote.id == null
                            ? 'Eliminar lote nuevo'
                            : 'Eliminar lote #${draft.lote.id}',
                        onPressed: () => _eliminar(draft),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    describirExistencia(
                      cantidad:
                          leerCantidad(
                            draft.cantidad.text,
                            permiteCero: true,
                          ) ??
                          draft.lote.cantidad,
                      unidad: widget.unit,
                      presentacion: widget.defaultPackaging,
                      contenidoEnvase: widget.defaultContent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: draft.cantidad,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Cantidad disponible',
                      suffixText: unidadVisible(widget.unit),
                      helperText: 'Hasta tres decimales',
                      errorText:
                          leerCantidad(
                                draft.cantidad.text,
                                permiteCero: true,
                              ) ==
                              null
                          ? 'Cantidad inválida'
                          : null,
                    ),
                    onChanged: (_) {
                      setState(() {});
                      _emit();
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: const Text('Fecha de caducidad'),
                    subtitle: Text(draft.lote.fechaCaducidad),
                    trailing: const Icon(Icons.edit_outlined),
                    onTap: () => _fecha(draft),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aviso de caducidad'),
                    value: draft.lote.alarmaActiva == 1,
                    onChanged: (v) {
                      if (v) {
                        final f = DateTime.tryParse(draft.lote.fechaCaducidad);
                        if (f != null) {
                          final error =
                              ServicioNotificaciones.validarMomentoAlarma(
                                fechaCaducidad: f,
                                horaAviso: draft.lote.horaAviso,
                              );
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: PantryColors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                        }
                      }
                      setState(() {
                        draft.lote = draft.lote.copyWith(
                          alarmaActiva: v ? 1 : 0,
                        );
                      });
                      _emit();
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hora del aviso'),
                    subtitle: Text(draft.lote.horaAviso),
                    leading: const Icon(Icons.access_time_rounded),
                    onTap: () => _hora(draft),
                  ),
                ],
              ),
            ),
          ),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: () {
          setState(() {
            _drafts.add(
              _LotDraft(
                Lote(
                  productoId: widget.productoId,
                  cantidad: widget.defaultPackaging.esEnvase
                      ? widget.defaultContent
                      : 1,
                  presentacion: widget.defaultPackaging,
                  contenidoEnvase: widget.defaultContent,
                  fechaCaducidad: DateTime.now()
                      .add(const Duration(days: 7))
                      .toIso8601String()
                      .substring(0, 10),
                ),
              ),
            );
          });
          _emit();
        },
        icon: const Icon(Icons.add),
        label: const Text('Agregar lote'),
      ),
    ],
  );
}
