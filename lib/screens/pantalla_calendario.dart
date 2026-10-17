import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import 'package:table_calendar/table_calendar.dart';

import '../components/tema_alacena.dart';
import '../presentation/datos_calendario_demostracion.dart';
import '../widgets/miniatura_producto.dart';
import '../models/lote_model.dart';
import '../database/daos/lote_dao.dart';
import 'pantalla_alertas_dia.dart';

// Calendario con alertas reales de caducidad por lote
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final _loteDao = LoteDao();
  late DateTime _selectedDay;
  late DateTime _focusedDay;
  Map<String, List<CalendarAlertPreview>> _alertasPorFecha = {};

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    _selectedDay = hoy;
    _focusedDay = hoy;
    _cargarAlertasDesdeBD();
  }

  String _formatoIso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _cargarAlertasDesdeBD() async {
    try {
      final lotes = await _loteDao.obtenerTodosLotesActivos();
      final Map<String, List<CalendarAlertPreview>> mapa = {};

      for (final lote in lotes) {
        final alert = _loteToAlert(lote);
        final fecha = lote.fechaCaducidad;
        mapa.putIfAbsent(fecha, () => []).add(alert);
      }

      if (mounted) {
        setState(() {
          _alertasPorFecha = mapa;
        });
      }
    } catch (_) {}
  }

  CalendarAlertPreview _loteToAlert(Lote lote) {
    CalendarPreviewStatus st;
    if (lote.estaCaducado) {
      st = CalendarPreviewStatus.expired;
    } else if (lote.porCaducar) {
      st = CalendarPreviewStatus.expiring;
    } else {
      st = CalendarPreviewStatus.lowStock;
    }

    final cantStr = lote.cantidad.truncateToDouble() == lote.cantidad
        ? '${lote.cantidad.toInt()}'
        : lote.cantidad.toStringAsFixed(1);

    return CalendarAlertPreview(
      lote.productoNombre ?? 'Producto',
      'Alacena · Inventario',
      '$cantStr ${lote.unidad ?? "pza"}',
      st,
      ProductThumbnailKind.placeholder,
      lotCode: lote.id != null ? 'Lote #${lote.id}' : 'Lote',
      loteId: lote.id,
      productoId: lote.productoId,
      cantidad: lote.cantidad,
      unidad: lote.unidad ?? 'pza',
    );
  }

  List<CalendarAlertPreview> _alertasParaDia(DateTime day) {
    final iso = _formatoIso(day);
    if (_alertasPorFecha.containsKey(iso)) {
      return _alertasPorFecha[iso]!;
    }
    return const [];
  }

  Future<void> _openDay(DateTime selected, DateTime focused) async {
    setState(() {
      _selectedDay = selected;
      _focusedDay = focused;
    });
    final alertasDelDia = _alertasParaDia(selected);
    await showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (_) => Dialog.fullscreen(
        child: DayAlertsScreen(day: selected, alerts: alertasDelDia),
      ),
    );
    _cargarAlertasDesdeBD();
  }

  void _moveMonth(int offset) {
    final day = DateTime(_focusedDay.year, _focusedDay.month + offset);
    if (day.year >= 2000 && day.year <= 2100) {
      setState(() => _focusedDay = day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _alertasParaDia(_selectedDay);
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
                    pinned: true,
                    automaticallyImplyLeading: false,
                    titleSpacing: 20,
                    title: const AppSectionHeading(
                      section: AppSection.calendar,
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 18,
                              backgroundColor: PantryColors.greenLight,
                              child: Icon(
                                Icons.calendar_month_outlined,
                                size: 21,
                                color: PantryColors.green,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'VISTA MENSUAL',
                                    style: TextStyle(
                                      fontSize: 8,
                                      letterSpacing: .5,
                                      color: PantryColors.muted,
                                    ),
                                  ),
                                  Text(
                                    '${calendarPreviewMonths[_focusedDay.month - 1]} ${_focusedDay.year}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => setState(() {
                                _selectedDay = DateTime.now();
                                _focusedDay = _selectedDay;
                              }),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 32),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                              child: const Text(
                                'Hoy',
                                style: TextStyle(fontSize: 11),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _moveMonth(-1),
                              tooltip: 'Mes anterior',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.chevron_left_rounded,
                                size: 20,
                              ),
                            ),
                            IconButton(
                              onPressed: () => _moveMonth(1),
                              tooltip: 'Mes siguiente',
                              visualDensity: VisualDensity.compact,
                              icon: const Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 13, 8, 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: TableCalendar<CalendarAlertPreview>(
                          locale: 'en_US',
                          firstDay: DateTime(2000),
                          lastDay: DateTime(2100, 12, 31),
                          focusedDay: _focusedDay,
                          startingDayOfWeek: StartingDayOfWeek.monday,
                          headerVisible: false,
                          rowHeight: 45,
                          daysOfWeekHeight: 26,
                          availableGestures: AvailableGestures.horizontalSwipe,
                          selectedDayPredicate: (day) =>
                              isSameDay(day, _selectedDay),
                          eventLoader: _alertasParaDia,
                          onDaySelected: _openDay,
                          onPageChanged: (day) =>
                              setState(() => _focusedDay = day),
                          calendarBuilders: CalendarBuilders(
                            dowBuilder: (_, day) => Center(
                              child: Text(
                                const [
                                  'Lun',
                                  'Mar',
                                  'Mié',
                                  'Jue',
                                  'Vie',
                                  'Sáb',
                                  'Dom',
                                ][day.weekday - 1],
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: PantryColors.muted,
                                ),
                              ),
                            ),
                            prioritizedBuilder: (_, day, focused) => Center(
                              child: Container(
                                key: ValueKey(
                                  'calendar-day-${day.year}-${day.month}-${day.day}',
                                ),
                                width: 29,
                                height: 29,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSameDay(day, _selectedDay)
                                      ? PantryColors.green
                                      : null,
                                  shape: BoxShape.circle,
                                  border: isSameDay(day, DateTime.now())
                                      ? Border.all(color: PantryColors.green)
                                      : null,
                                ),
                                child: Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSameDay(day, _selectedDay)
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isSameDay(day, _selectedDay)
                                        ? Colors.white
                                        : day.month == focused.month
                                        ? PantryColors.ink
                                        : const Color(0xFFBCC5BE),
                                  ),
                                ),
                              ),
                            ),
                            markerBuilder: (_, day, events) {
                              if (events.isEmpty) return null;
                              return Positioned(
                                left: 0,
                                right: 0,
                                bottom: 2,
                                child: Semantics(
                                  label: '${events.length} alertas',
                                  child: Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 2,
                                    runSpacing: 2,
                                    children: [
                                      for (var i = 0; i < events.length; i++)
                                        Container(
                                          key: ValueKey(
                                            'calendar-marker-${day.year}-${day.month}-${day.day}-$i',
                                          ),
                                          width: 4,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: events[i].status.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
                    sliver: SliverToBoxAdapter(child: _CalendarLegend()),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: PantryColors.greenLight,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(13),
                          child: Row(
                            children: [
                              Icon(
                                Icons.touch_app_outlined,
                                size: 24,
                                color: PantryColors.green,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Toca cualquier día con puntos para revisar los productos con alertas programadas.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    height: 1.4,
                                    color: PantryColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PantryColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                Text(
                                  '● ${calendarPreviewDateLabel(_selectedDay)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                _AlertCount(count: alerts.length),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (alerts.isEmpty)
                              const _NoDayAlerts()
                            else
                              for (final alert in alerts)
                                _AlertRow(alert: alert),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () =>
                                  _openDay(_selectedDay, _focusedDay),
                              icon: const Icon(
                                Icons.inventory_2_outlined,
                                size: 16,
                              ),
                              label: const Text(
                                'Gestionar inventario de esta fecha',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: PantryColors.background,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
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
            bottomNavigationBar: AppBottomNavigation(selectedIndex: 1),
          ),
        ),
      ),
    );
  }
}

class _CalendarLegend extends StatelessWidget {
  const _CalendarLegend();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        for (final status in CalendarPreviewStatus.values)
          Container(
            width: (constraints.maxWidth - 8) / 2,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: status.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 9,
                      color: status.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

class _AlertCount extends StatelessWidget {
  const _AlertCount({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
    decoration: BoxDecoration(
      color: PantryColors.greenLight,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text(
      '$count ${count == 1 ? 'alerta activa' : 'alertas activas'}',
      style: const TextStyle(
        fontSize: 9,
        color: PantryColors.green,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});
  final CalendarAlertPreview alert;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: PantryColors.background,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: alert.status.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(alert.status.icon, size: 18, color: alert.status.color),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${alert.location.split(' · ').first} · ${alert.quantity}',
                style: const TextStyle(
                  fontSize: 10,
                  color: PantryColors.muted,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                alert.status.label,
                style: TextStyle(
                  fontSize: 9,
                  color: alert.status.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NoDayAlerts extends StatelessWidget {
  const _NoDayAlerts();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Column(
      children: [
        Icon(
          Icons.event_available_outlined,
          size: 34,
          color: PantryColors.green,
        ),
        SizedBox(height: 10),
        Text(
          'Sin alertas para este día',
          style: TextStyle(fontSize: 13, color: PantryColors.muted),
        ),
      ],
    ),
  );
}