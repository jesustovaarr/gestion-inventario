import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../database/daos/lote_dao.dart';
import '../services/servicio_notificaciones.dart';

// Diálogo interactivo para configurar o modificar la alerta y recordatorio de un producto/lote
class DialogoConfiguracionAlerta extends StatefulWidget {
  final int loteId;
  final String productoNombre;
  final String lotCode;
  final int alarmaActiva;
  final String horaAviso;
  final DateTime fechaCaducidad;
  final LoteDao? loteDao;
  final VoidCallback? onActualizado;

  const DialogoConfiguracionAlerta({
    super.key,
    required this.loteId,
    required this.productoNombre,
    required this.lotCode,
    required this.alarmaActiva,
    required this.horaAviso,
    required this.fechaCaducidad,
    this.loteDao,
    this.onActualizado,
  });

  static Future<void> mostrar(
    BuildContext context, {
    required int loteId,
    required String productoNombre,
    required String lotCode,
    required int alarmaActiva,
    required String horaAviso,
    required DateTime fechaCaducidad,
    LoteDao? loteDao,
    VoidCallback? onActualizado,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => DialogoConfiguracionAlerta(
        loteId: loteId,
        productoNombre: productoNombre,
        lotCode: lotCode,
        alarmaActiva: alarmaActiva,
        horaAviso: horaAviso,
        fechaCaducidad: fechaCaducidad,
        loteDao: loteDao,
        onActualizado: onActualizado,
      ),
    );
  }

  @override
  State<DialogoConfiguracionAlerta> createState() =>
      _DialogoConfiguracionAlertaState();
}

class _DialogoConfiguracionAlertaState
    extends State<DialogoConfiguracionAlerta> {
  late bool _alarmaActiva;
  late String _horaAviso;
  late DateTime _fechaCaducidad;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _alarmaActiva = widget.alarmaActiva == 1;
    _horaAviso = widget.horaAviso.isEmpty ? '09:00 AM' : widget.horaAviso;
    _fechaCaducidad = widget.fechaCaducidad;
    if (_alarmaActiva) {
      final error = ServicioNotificaciones.validarMomentoAlarma(
        fechaCaducidad: _fechaCaducidad,
        horaAviso: _horaAviso,
      );
      if (error != null) {
        _alarmaActiva = false;
      }
    }
  }

  TimeOfDay _parseHora(String str) {
    try {
      final parts = str.trim().split(' ');
      final hm = parts[0].split(':');
      var h = int.parse(hm[0]);
      final m = int.parse(hm[1]);
      if (parts.length > 1) {
        final period = parts[1].toUpperCase();
        if (period == 'PM' && h < 12) h += 12;
        if (period == 'AM' && h == 12) h = 0;
      }
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hourOfPeriod == 0 ? 12 : tod.hourOfPeriod;
    final minute = tod.minute.toString().padLeft(2, '0');
    final period = tod.period == DayPeriod.am ? 'AM' : 'PM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _formatIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _seleccionarHora() async {
    final actual = _parseHora(_horaAviso);
    final seleccionada = await showTimePicker(
      context: context,
      initialTime: actual,
      helpText: 'HORA DEL RECORDATORIO',
      confirmText: 'SELECCIONAR',
      cancelText: 'CANCELAR',
    );
    if (seleccionada != null && mounted) {
      final nuevaHora = _formatTimeOfDay(seleccionada);
      if (_alarmaActiva) {
        final error = ServicioNotificaciones.validarMomentoAlarma(
          fechaCaducidad: _fechaCaducidad,
          horaAviso: nuevaHora,
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
      setState(() {
        _horaAviso = nuevaHora;
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final seleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaCaducidad,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'FECHA DE CADUCIDAD',
      confirmText: 'SELECCIONAR',
      cancelText: 'CANCELAR',
    );
    if (seleccionada != null && mounted) {
      final errorAlarma = ServicioNotificaciones.validarMomentoAlarma(
        fechaCaducidad: seleccionada,
        horaAviso: _horaAviso,
      );
      final alarmaEstabaActiva = _alarmaActiva;
      setState(() {
        _fechaCaducidad = seleccionada;
        if (errorAlarma != null && _alarmaActiva) {
          _alarmaActiva = false;
        }
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
    }
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    final dao = widget.loteDao ?? LoteDao();
    final iso = _formatIso(_fechaCaducidad);

    try {
      await dao.actualizarConfiguracionAlarma(
        widget.loteId,
        alarmaActiva: _alarmaActiva ? 1 : 0,
        horaAviso: _horaAviso,
        fechaCaducidad: iso,
      );

      // Reprogramar o cancelar notificación según la configuración
      final notifService = ServicioNotificaciones();
      if (_alarmaActiva) {
        final error = ServicioNotificaciones.validarMomentoAlarma(
          fechaCaducidad: _fechaCaducidad,
          horaAviso: _horaAviso,
        );
        if (error == null) {
          await notifService.programarAlertaLote(
            loteId: widget.loteId,
            nombreProducto: widget.productoNombre,
            fechaCaducidad: iso,
            horaAviso: _horaAviso,
          );
        } else {
          _alarmaActiva = false;
          await dao.actualizarConfiguracionAlarma(
            widget.loteId,
            alarmaActiva: 0,
            horaAviso: _horaAviso,
            fechaCaducidad: iso,
          );
          await notifService.cancelarAlerta(widget.loteId);
        }
      } else {
        await notifService.cancelarAlerta(widget.loteId);
      }

      if (mounted) {
        widget.onActualizado?.call();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _alarmaActiva
                  ? 'Alerta configurada para las $_horaAviso'
                  : 'Alarma desactivada para este lote',
            ),
            backgroundColor: PantryColors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo guardar la configuración de la alerta.'),
            backgroundColor: PantryColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: PantryColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabecera
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _alarmaActiva
                          ? PantryColors.orangeLight
                          : PantryColors.greenLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _alarmaActiva
                          ? Icons.notifications_active_rounded
                          : Icons.alarm_rounded,
                      color: _alarmaActiva
                          ? PantryColors.orange
                          : PantryColors.green,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Configurar Alerta',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: PantryColors.ink,
                          ),
                        ),
                        Text(
                          '${widget.productoNombre} · ${widget.lotCode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: PantryColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Switch Alarma activa / inactiva
              Material(
                color: PantryColors.background,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PantryColors.border),
                ),
                child: SwitchListTile(
                  key: const Key('switch_alarma_activa'),
                  title: const Text(
                    'Recordatorio de caducidad',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _alarmaActiva
                        ? 'Notificación activa para el día de vencimiento'
                        : 'Sin alarma local programada',
                    style: const TextStyle(
                      fontSize: 11,
                      color: PantryColors.muted,
                    ),
                  ),
                  value: _alarmaActiva,
                  activeThumbColor: PantryColors.green,
                  onChanged: (val) {
                    if (val) {
                      final error = ServicioNotificaciones.validarMomentoAlarma(
                        fechaCaducidad: _fechaCaducidad,
                        horaAviso: _horaAviso,
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
                    setState(() => _alarmaActiva = val);
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Selector de Hora
              Material(
                color: _alarmaActiva ? Colors.white : const Color(0xFFF7F9F8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PantryColors.border),
                ),
                child: ListTile(
                  enabled: _alarmaActiva,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: Icon(
                    Icons.access_time_rounded,
                    color: _alarmaActiva
                        ? PantryColors.green
                        : PantryColors.muted,
                    size: 20,
                  ),
                  title: const Text(
                    'Hora del aviso',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _horaAviso,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _alarmaActiva
                          ? PantryColors.ink
                          : PantryColors.muted,
                    ),
                  ),
                  trailing: TextButton(
                    key: const Key('btn_cambiar_hora_aviso'),
                    onPressed: _alarmaActiva ? _seleccionarHora : null,
                    child: const Text('Cambiar'),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Selector de Fecha de Caducidad
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: PantryColors.border),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  leading: const Icon(
                    Icons.calendar_today_rounded,
                    color: PantryColors.green,
                    size: 20,
                  ),
                  title: const Text(
                    'Fecha de caducidad',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _formatDate(_fechaCaducidad),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: PantryColors.ink,
                    ),
                  ),
                  trailing: TextButton(
                    key: const Key('btn_cambiar_fecha_caducidad'),
                    onPressed: _seleccionarFecha,
                    child: const Text('Cambiar'),
                  ),
                ),
              ),
              const SizedBox(height: 20),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    key: const Key('btn_cancelar_config_alerta'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: PantryColors.ink,
                      side: const BorderSide(color: PantryColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    key: const Key('btn_guardar_config_alerta'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PantryColors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
