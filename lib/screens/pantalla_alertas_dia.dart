import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import '../components/tema_alacena.dart';
import '../presentation/datos_calendario_demostracion.dart';
import '../widgets/miniatura_producto.dart';

/// Vista diaria reutilizable. Los filtros son visuales y no generan movimientos.
class DayAlertsScreen extends StatefulWidget {
  const DayAlertsScreen({super.key, required this.day, required this.alerts});
  final DateTime day;
  final List<CalendarAlertPreview> alerts;

  @override
  State<DayAlertsScreen> createState() => _DayAlertsScreenState();
}

class _DayAlertsScreenState extends State<DayAlertsScreen> {
  bool _clearView = false;
  CalendarPreviewStatus? _status;

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final alerts = widget.alerts;
    final visible = _clearView
        ? <CalendarAlertPreview>[]
        : alerts
              .where((alert) => _status == null || alert.status == _status)
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
                    actions: [
                      IconButton(
                        onPressed: () {},
                        tooltip: 'Buscar productos del día',
                        icon: const Icon(Icons.search_rounded, size: 20),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: IconButton.filled(
                          onPressed: () {},
                          tooltip: 'Perfil',
                          style: IconButton.styleFrom(
                            backgroundColor: PantryColors.green,
                          ),
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            size: 17,
                          ),
                        ),
                      ),
                    ],
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
                                  '${alerts.length} alertas activas',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: PantryColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            tooltip: 'Gestionar alertas del día',
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
                                label: 'Con alertas (${alerts.length})',
                                icon: Icons.notifications_active_outlined,
                                selected: !_clearView,
                                onTap: () => setState(() => _clearView = false),
                              ),
                            ),
                            Expanded(
                              child: _DayTab(
                                label: 'Día despejado (0)',
                                icon: Icons.event_available_outlined,
                                selected: _clearView,
                                onTap: () => setState(() => _clearView = true),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    sliver: SliverToBoxAdapter(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text(
                                'Todos (${_clearView ? 0 : alerts.length})',
                              ),
                              selected: _status == null,
                              showCheckmark: false,
                              onSelected: (_) => setState(() => _status = null),
                              selectedColor: PantryColors.green,
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                fontSize: 10,
                                color: _status == null
                                    ? Colors.white
                                    : PantryColors.ink,
                              ),
                              side: BorderSide.none,
                            ),
                            for (final status in CalendarPreviewStatus.values)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: ChoiceChip(
                                  label: Text(
                                    '${status.label} (${_clearView ? 0 : alerts.where((alert) => alert.status == status).length})',
                                  ),
                                  avatar: Icon(
                                    Icons.circle,
                                    size: 6,
                                    color: status.color,
                                  ),
                                  selected: _status == status,
                                  showCheckmark: false,
                                  onSelected: (_) =>
                                      setState(() => _status = status),
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
                              _clearView
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
                  if (alerts.isNotEmpty && !_clearView) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: PantryColors.greenLight,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.auto_awesome_outlined,
                                    size: 19,
                                    color: PantryColors.green,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Acción inteligente del día',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _DayBadge('1 TAP'),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Agrega los ${alerts.length} productos comprometidos a tu carrito de reposición para preparar tu próxima visita al súper.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: PantryColors.muted,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              FilledButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.add_shopping_cart_outlined,
                                  size: 17,
                                ),
                                label: Text(
                                  'Agregar los ${alerts.length} productos al carrito',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2EA),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Lotes del día',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${alerts.where((alert) => alert.status == CalendarPreviewStatus.expiring).length} por vencer / ${alerts.where((alert) => alert.status == CalendarPreviewStatus.expired).length} crítico',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 14,
                                ),
                                label: const Text(
                                  'Gestionar lote',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
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

class _DayProductCard extends StatelessWidget {
  const _DayProductCard({required this.alert, required this.day});
  final CalendarAlertPreview alert;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final action = switch (alert.status) {
      CalendarPreviewStatus.expired => 'Desechar',
      CalendarPreviewStatus.expiring => 'Consumir',
      CalendarPreviewStatus.lowStock => 'Anotar',
      CalendarPreviewStatus.empty => 'Reordenar',
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PantryColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProductThumbnail(kind: alert.thumbnail, size: 54),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.location,
                      style: const TextStyle(
                        fontSize: 10,
                        color: PantryColors.muted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: alert.status.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.status.label,
                        style: TextStyle(
                          fontSize: 9,
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.event_outlined, size: 12, color: alert.status.color),
              Text(
                calendarPreviewDateLabel(day),
                style: TextStyle(fontSize: 9, color: alert.status.color),
              ),
              Text(
                'Lote: #${alert.lotCode}',
                style: const TextStyle(fontSize: 9, color: PantryColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: PantryColors.greenLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: PantryColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          alert.quantity,
                          style: const TextStyle(
                            fontSize: 9,
                            color: PantryColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF1EB),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  minimumSize: const Size(0, 30),
                  foregroundColor: PantryColors.ink,
                ),
                child: Text(action, style: const TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 5),
              IconButton.filled(
                onPressed: () {},
                tooltip: 'Agregar ${alert.name} al carrito',
                style: IconButton.styleFrom(
                  backgroundColor: PantryColors.green,
                  minimumSize: const Size(32, 32),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.add_shopping_cart_outlined, size: 17),
              ),
            ],
          ),
        ],
      ),
    );
  }
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

class _DayBadge extends StatelessWidget {
  const _DayBadge(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: PantryColors.background,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 8,
        fontWeight: FontWeight.w700,
        color: PantryColors.green,
      ),
    ),
  );
}
