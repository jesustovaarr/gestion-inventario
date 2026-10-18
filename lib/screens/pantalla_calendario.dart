import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import 'package:table_calendar/table_calendar.dart';

import '../components/tema_alacena.dart';
import '../presentation/modelos_vista_calendario.dart';
import '../database/daos/lote_dao.dart';
import '../widgets/dialogo_configuracion_alerta.dart';
import '../widgets/miniatura_producto.dart';
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
        final alert = calendarAlertFromLot(lote);
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

  Future<void> _abrirSelectorParaConfigurarAlerta() async {
    final lotes = await _loteDao.obtenerTodosLotesActivos();
    if (!mounted) return;
    if (lotes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay productos con lotes activos registrados.'),
          backgroundColor: PantryColors.orange,
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.alarm_rounded, color: PantryColors.green),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Configurar recordatorio de producto',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: lotes.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, idx) {
                  final lote = lotes[idx];
                  final caducidad =
                      DateTime.tryParse(lote.fechaCaducidad) ?? DateTime.now();
                  return ListTile(
                    leading: ProductThumbnail(
                      kind: ProductThumbnailKind.placeholder,
                      imagePath: lote.productoImagen,
                      size: 40,
                    ),
                    title: Text(
                      lote.productoNombre ?? 'Producto',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      'Caduca: ${caducidad.day.toString().padLeft(2, '0')}/${caducidad.month.toString().padLeft(2, '0')}/${caducidad.year} · ${lote.alarmaActiva == 1 ? "Aviso: ${lote.horaAviso}" : "Sin alarma"}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: PantryColors.muted,
                      ),
                    ),
                    trailing: Icon(
                      lote.alarmaActiva == 1
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      color: lote.alarmaActiva == 1
                          ? PantryColors.orange
                          : PantryColors.muted,
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      DialogoConfiguracionAlerta.mostrar(
                        context,
                        loteId: lote.id!,
                        productoNombre: lote.productoNombre ?? 'Producto',
                        lotCode: lote.id == null ? 'Lote' : 'Lote #${lote.id}',
                        alarmaActiva: lote.alarmaActiva,
                        horaAviso: lote.horaAviso,
                        fechaCaducidad: caducidad,
                        loteDao: _loteDao,
                        onActualizado: _cargarAlertasDesdeBD,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                              final total = events.length;
                              const maxDots = 5;
                              final mostrarBadge = total > maxDots;
                              final dotsCount = mostrarBadge ? maxDots : total;
                              final restantes = total - maxDots;

                              return Positioned(
                                left: 0,
                                right: 0,
                                bottom: 2,
                                child: Semantics(
                                  label: '$total alertas',
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      for (var i = 0; i < dotsCount; i++)
                                        Container(
                                          key: ValueKey(
                                            'calendar-marker-${day.year}-${day.month}-${day.day}-$i',
                                          ),
                                          width: 3.5,
                                          height: 3.5,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 0.8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: events[i].status.color,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      if (mostrarBadge) ...[
                                        const SizedBox(width: 1.5),
                                        Text(
                                          '+$restantes',
                                          key: ValueKey(
                                            'calendar-more-${day.year}-${day.month}-${day.day}',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: FontWeight.w700,
                                            color: PantryColors.green,
                                            height: 1,
                                          ),
                                        ),
                                      ],
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
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: TextButton.icon(
                              onPressed: () => _openDay(_selectedDay, _focusedDay),
                              icon: const Icon(Icons.inventory_2_outlined, size: 16),
                              label: const Text(
                                'Gestionar inventario de esta fecha',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: TextButton.styleFrom(
                                backgroundColor: PantryColors.greenLight,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const Key('btn_configurar_alertas_calendario'),
                              onPressed: _abrirSelectorParaConfigurarAlerta,
                              icon: const Icon(Icons.alarm_rounded, size: 16),
                              label: const Text(
                                'Configurar recordatorio de caducidad',
                                style: TextStyle(fontSize: 11),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: PantryColors.ink,
                                side: const BorderSide(color: PantryColors.border),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                              ),
                            ),
                          ),
                        ],
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
