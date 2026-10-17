import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../database/daos/lote_dao.dart';
import '../database/daos/producto_dao.dart';
import '../models/lote_model.dart';
import '../presentation/modelos_vista_alacena.dart';
import '../presentation/modelos_vista_calendario.dart';
import '../presentation/controlador_carrito.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../widgets/encabezado_seccion.dart';
import '../widgets/miniatura_producto.dart';
import 'pantalla_detalle_producto.dart';

// Vista diaria que muestra los lotes que vencen en una fecha específica,
// permitiendo consumir, desechar, agregar al carrito o gestionar el producto.
class DayAlertsScreen extends StatefulWidget {
  const DayAlertsScreen({super.key, required this.day, required this.alerts});
  final DateTime day;
  final List<CalendarAlertPreview> alerts;

  @override
  State<DayAlertsScreen> createState() => _DayAlertsScreenState();
}

class _DayAlertsScreenState extends State<DayAlertsScreen> {
  final LoteDao _loteDao = LoteDao();
  final ProductoDao _productoDao = ProductoDao();

  late List<CalendarAlertPreview> _alertas;
  bool _clearView = false;
  CalendarPreviewStatus? _status;

  @override
  void initState() {
    super.initState();
    _alertas = List.of(widget.alerts);
  }

  void _close() => Navigator.of(context).pop();

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

  Future<void> _recargarAlertas() async {
    try {
      final iso =
          '${widget.day.year.toString().padLeft(4, '0')}-${widget.day.month.toString().padLeft(2, '0')}-${widget.day.day.toString().padLeft(2, '0')}';
      final lotes = await _loteDao.obtenerLotesPorFecha(iso);
      if (mounted) {
        setState(() {
          _alertas = lotes.map(_loteToAlert).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _agregarAlCarrito(CalendarAlertPreview alert) async {
    if (alert.productoId == null) return;
    try {
      final productPreview = PantryProductPreview(
        id: alert.productoId,
        name: alert.name,
        category: 'Inventario',
        status: PantryPreviewStatus.healthy,
        note: 'Stock: ${alert.quantity}',
        quantity: alert.quantity,
        thumbnail: alert.thumbnail,
        unit: alert.unidad,
      );

      try {
        ShoppingListsPreviewScope.of(context).addProduct(productPreview);
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${alert.name} agregado a la lista de compras'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${alert.name} agregado a la lista de compras'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _gestionarLote(CalendarAlertPreview alert) async {
    if (alert.productoId == null) return;
    try {
      final producto = await _productoDao.obtenerPorId(alert.productoId!);
      if (producto == null || !mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: producto.toPreview()),
        ),
      );

      await _recargarAlertas();
    } catch (_) {}
  }

  void _abrirSelectorGestionarLote(List<CalendarAlertPreview> lista) {
    if (lista.isEmpty) return;
    if (lista.length == 1) {
      _gestionarLote(lista.first);
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
                'Selecciona un artículo a gestionar',
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
                      _gestionarLote(a);
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

  Future<void> _consumirLote(CalendarAlertPreview alert) async {
    if (alert.status == CalendarPreviewStatus.expired) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Desechar lote'),
          content: Text(
            '¿Deseas desechar este lote caducado de "${alert.name}"?\n'
            'Cantidad: ${alert.quantity}\n\n'
            'Esta acción dará de baja el lote y lo descontará del inventario.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PantryColors.red,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Desechar'),
            ),
          ],
        ),
      );

      if (confirmar == true) {
        try {
          if (alert.loteId != null) {
            await _loteDao.descartarLote(alert.loteId!);
          } else if (alert.productoId != null) {
            await _loteDao.descontarStockFEFO(alert.productoId!, alert.cantidad);
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lote de ${alert.name} desechado'),
                backgroundColor: PantryColors.orange,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
            await _recargarAlertas();
          }
        } catch (_) {}
      }
      return;
    }

    // Caso Consumir / Anotar / Reordenar
    double cantConsumir = alert.cantidad > 0 ? alert.cantidad : 1.0;
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Consumir producto'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Deseas registrar el consumo de "${alert.name}"?',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: PantryColors.greenLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        alert.lotCode,
                        style: const TextStyle(
                          fontSize: 12,
                          color: PantryColors.muted,
                        ),
                      ),
                      Text(
                        'Disponible: ${alert.quantity}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (alert.cantidad > 1) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Cantidad a consumir:',
                    style: TextStyle(
                      fontSize: 12,
                      color: PantryColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        onPressed: cantConsumir > 1
                            ? () => setDialogState(() => cantConsumir--)
                            : null,
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${cantConsumir.truncateToDouble() == cantConsumir ? cantConsumir.toInt() : cantConsumir.toStringAsFixed(1)} ${alert.unidad}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton.filledTonal(
                        onPressed: cantConsumir < alert.cantidad
                            ? () => setDialogState(() => cantConsumir++)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Consumir'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmar == true) {
      try {
        if (alert.loteId != null) {
          if (cantConsumir >= alert.cantidad) {
            await _loteDao.descartarLote(alert.loteId!);
          } else {
            await _loteDao.actualizarCantidad(
              alert.loteId!,
              alert.cantidad - cantConsumir,
            );
          }
        } else if (alert.productoId != null) {
          await _loteDao.descontarStockFEFO(alert.productoId!, cantConsumir);
        }

        if (mounted) {
          final cantStr = cantConsumir.truncateToDouble() == cantConsumir
              ? '${cantConsumir.toInt()}'
              : cantConsumir.toStringAsFixed(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Se consumieron $cantStr ${alert.unidad} de ${alert.name}',
              ),
              backgroundColor: PantryColors.green,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          await _recargarAlertas();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _alertas;
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
                            onPressed: () => _abrirSelectorGestionarLote(
                              visible.isNotEmpty ? visible : _alertas,
                            ),
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
                          onConsume: _consumirLote,
                          onAddToCart: _agregarAlCarrito,
                          onManageLot: _gestionarLote,
                        ),
                      ),
                    ),
                  if (alerts.isNotEmpty && !_clearView) ...[
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                                onPressed: () => _abrirSelectorGestionarLote(
                                  visible.isNotEmpty ? visible : alerts,
                                ),
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
            bottomNavigationBar: const AppBottomNavigation(selectedIndex: 1),
          ),
        ),
      ),
    );
  }
}

class _DayProductCard extends StatelessWidget {
  const _DayProductCard({
    required this.alert,
    required this.day,
    required this.onConsume,
    required this.onAddToCart,
    required this.onManageLot,
  });

  final CalendarAlertPreview alert;
  final DateTime day;
  final ValueChanged<CalendarAlertPreview> onConsume;
  final ValueChanged<CalendarAlertPreview> onAddToCart;
  final ValueChanged<CalendarAlertPreview> onManageLot;

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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PantryColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onManageLot(alert),
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                    IconButton(
                      onPressed: () => onManageLot(alert),
                      tooltip: 'Gestionar lote',
                      icon: const Icon(
                        Icons.chevron_right,
                        color: PantryColors.muted,
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
                    Icon(
                      Icons.event_outlined,
                      size: 12,
                      color: alert.status.color,
                    ),
                    Text(
                      calendarPreviewDateLabel(day),
                      style: TextStyle(fontSize: 9, color: alert.status.color),
                    ),
                    Text(
                      alert.lotCode,
                      style: const TextStyle(
                        fontSize: 9,
                        color: PantryColors.muted,
                      ),
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
                      onPressed: () => onConsume(alert),
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
                      onPressed: () => onAddToCart(alert),
                      tooltip: 'Agregar ${alert.name} al carrito',
                      style: IconButton.styleFrom(
                        backgroundColor: PantryColors.green,
                        minimumSize: const Size(32, 32),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(
                        Icons.add_shopping_cart_outlined,
                        size: 17,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
