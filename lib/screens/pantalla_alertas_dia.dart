import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../database/daos/lote_dao.dart';
import '../presentation/modelos_vista_calendario.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../widgets/encabezado_seccion.dart';
import '../widgets/miniatura_producto.dart';
import '../widgets/editor_fecha_caducidad.dart';

// Consulta de los productos que caducan en la fecha seleccionada.
class DayAlertsScreen extends StatefulWidget {
  const DayAlertsScreen({super.key, required this.day, required this.alerts});
  final DateTime day;
  final List<CalendarAlertPreview> alerts;

  @override
  State<DayAlertsScreen> createState() => _DayAlertsScreenState();
}

class _DayAlertsScreenState extends State<DayAlertsScreen> {
  final LoteDao _loteDao = LoteDao();
  final Set<int> _fechasEnEdicion = {};

  late List<CalendarAlertPreview> _alertas;
  bool? _clearView;
  CalendarPreviewStatus? _status;

  @override
  void initState() {
    super.initState();
    _alertas = List.of(widget.alerts);
  }

  void _close() => Navigator.of(context).pop();

  Future<void> _recargarAlertas() async {
    try {
      final iso =
          '${widget.day.year.toString().padLeft(4, '0')}-${widget.day.month.toString().padLeft(2, '0')}-${widget.day.day.toString().padLeft(2, '0')}';
      final lotes = await _loteDao.obtenerLotesPorFecha(iso);
      if (mounted) {
        setState(() {
          _alertas = lotes.map(calendarAlertFromLot).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _editarFecha(CalendarAlertPreview alert) async {
    final id = alert.loteId;
    if (id == null || !_fechasEnEdicion.add(id)) return;
    try {
      final fecha = await showDialog<DateTime>(
        context: context,
        builder: (_) => ExpiryDateEditorDialog(initialDate: widget.day),
      );
      if (fecha == null || !mounted) return;
      final iso = fecha.toIso8601String().substring(0, 10);
      final cambios = await _loteDao.actualizarFechaCaducidad(id, iso);
      if (cambios != 1) throw StateError('El lote ya no tiene existencias.');
      await _recargarAlertas();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fecha de caducidad actualizada')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo actualizar la fecha del lote.'),
          ),
        );
      }
    } finally {
      _fechasEnEdicion.remove(id);
    }
  }

  void _seleccionarLoteParaEditarFecha(List<CalendarAlertPreview> lista) {
    if (lista.isEmpty) return;
    if (lista.length == 1) {
      _editarFecha(lista.first);
      return;
    }
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Selecciona el lote para cambiar su fecha',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: lista.length,
                itemBuilder: (ctx, idx) {
                  final a = lista[idx];
                  return ListTile(
                    leading: const Icon(
                      Icons.inventory_2_outlined,
                      color: PantryColors.green,
                    ),
                    title: Text(
                      a.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${a.lotCode} · ${a.quantity} · ${a.status.label}',
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _editarFecha(a);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _alertas;
    final withAlerts = alerts
        .where((a) => a.status != CalendarPreviewStatus.healthy)
        .toList();
    final withoutAlerts = alerts
        .where((a) => a.status == CalendarPreviewStatus.healthy)
        .toList();
    final visible =
        (_clearView == true
                ? withoutAlerts
                : _clearView == false
                ? withAlerts
                : alerts)
            .where((a) => _status == null || a.status == _status)
            .toList();
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
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
                  SliverAppBar(
                    toolbarHeight: 68,
                    leadingWidth: 40,
                    pinned: true,
                    automaticallyImplyLeading: false,
                    titleSpacing: 20,
                    title: const AppSectionHeading(
                      section: AppSection.dayAlerts,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _close,
                            tooltip: 'Cerrar productos del día',
                            style: IconButton.styleFrom(
                              backgroundColor: PantryColors.greenLight,
                            ),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${weekdays[widget.day.weekday - 1]} ${widget.day.day} de ${calendarPreviewMonths[widget.day.month - 1].toLowerCase()}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${alerts.length} ${alerts.length == 1 ? "producto" : "productos"} para esta fecha',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: PantryColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _seleccionarLoteParaEditarFecha(
                              visible.isNotEmpty ? visible : _alertas,
                            ),
                            tooltip: 'Editar fecha de caducidad',
                            style: IconButton.styleFrom(
                              backgroundColor: PantryColors.greenLight,
                              foregroundColor: PantryColors.green,
                            ),
                            icon: const Icon(
                              Icons.edit_calendar_outlined,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: PantryColors.greenLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _DayTab(
                                label: 'Con alertas (${withAlerts.length})',
                                icon: Icons.notifications_active_outlined,
                                selected: _clearView == false,
                                onTap: () => setState(() {
                                  _clearView = _clearView == false
                                      ? null
                                      : false;
                                  _status = null;
                                }),
                              ),
                            ),
                            Expanded(
                              child: _DayTab(
                                label: 'Sin alerta (${withoutAlerts.length})',
                                icon: Icons.event_available_outlined,
                                selected: _clearView == true,
                                onTap: () => setState(() {
                                  _clearView = _clearView == true ? null : true;
                                  _status = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (_clearView != true)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      sliver: SliverToBoxAdapter(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              for (final status
                                  in CalendarPreviewStatus.values.where(
                                    (s) => s != CalendarPreviewStatus.healthy,
                                  ))
                                Padding(
                                  padding: const EdgeInsets.only(left: 6),
                                  child: ChoiceChip(
                                    label: Text(
                                      '${status.label} (${withAlerts.where((alert) => alert.status == status).length})',
                                    ),
                                    avatar: Icon(
                                      Icons.circle,
                                      size: 6,
                                      color: status.color,
                                    ),
                                    selected: _status == status,
                                    showCheckmark: false,
                                    onSelected: (_) => setState(() {
                                      _status = _status == status
                                          ? null
                                          : status;
                                      _clearView = null;
                                    }),
                                    labelStyle: TextStyle(
                                      fontSize: 10,
                                      color: status.color,
                                    ),
                                    backgroundColor: Colors.white,
                                    selectedColor: status.background,
                                    side: BorderSide.none,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (visible.isEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 36),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.event_available_outlined,
                              size: 38,
                              color: PantryColors.green,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _clearView == true
                                  ? 'No hay productos sin alertas para este día'
                                  : alerts.isEmpty
                                  ? 'Sin alertas para este día'
                                  : 'Sin productos con este estado',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: PantryColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: visible.length,
                        itemBuilder: (_, index) => _DayProductCard(
                          alert: visible[index],
                          day: widget.day,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
          ),
        ),
      ),
    );
  }
}

class _DayProductCard extends StatelessWidget {
  const _DayProductCard({required this.alert, required this.day});
  final CalendarAlertPreview alert;
  final DateTime day;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: PantryColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumbnail(
              kind: alert.thumbnail,
              imagePath: alert.imagePath,
              size: 54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.location,
                    style: const TextStyle(
                      fontSize: 12,
                      color: PantryColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: alert.status.background,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          alert.status.icon,
                          size: 13,
                          color: alert.status.color,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            alert.status.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: alert.status.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 16,
              color: PantryColors.green,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                alert.quantity,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.event_outlined,
              size: 16,
              color: PantryColors.muted,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Caducidad: ${calendarPreviewDateLabel(day)}',
                style: const TextStyle(fontSize: 12, color: PantryColors.muted),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DayTab extends StatelessWidget {
  const _DayTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: selected ? Colors.white : Colors.transparent,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? PantryColors.green : PantryColors.muted,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected ? PantryColors.green : PantryColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
