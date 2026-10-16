import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import '../components/tema_alacena.dart';

/// Edición visual de una tienda. Guardar y desactivar no ejecutan operaciones.
class StoreFormScreen extends StatefulWidget {
  const StoreFormScreen({
    super.key,
    this.storeName,
    this.address,
    this.purchases = 0,
  });

  final String? storeName;
  final String? address;
  final int purchases;
  bool get isEditing => storeName != null;

  @override
  State<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends State<StoreFormScreen> {
  String _type = 'Supermercado';
  bool _usual = false;

  @override
  void initState() {
    super.initState();
    _usual = widget.isEditing;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PantryColors.greenLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Scaffold(
            bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
            body: SafeArea(
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    toolbarHeight: 68,
                    leadingWidth: 40,
                    pinned: true,
                    titleSpacing: 0,
                    title: AppSectionHeading(
                      section: widget.isEditing
                          ? AppSection.editStore
                          : AppSection.newStore,
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.check_rounded, size: 16),
                          label: const Text(
                            'Guardar',
                            style: TextStyle(fontSize: 11),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 34),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    sliver: SliverList.list(
                      children: [
                        _EditPanel(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: PantryColors.greenLight,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.storefront_outlined,
                                      color: PantryColors.green,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.storeName ?? 'Nueva tienda',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'TIENDA · CATÁLOGO LOCAL',
                                          style: TextStyle(
                                            fontSize: 9,
                                            letterSpacing: .4,
                                            color: PantryColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const _CatalogTag('Catálogo'),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (widget.isEditing)
                                Container(
                                  padding: const EdgeInsets.all(11),
                                  decoration: BoxDecoration(
                                    color: PantryColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_outlined,
                                        size: 18,
                                        color: PantryColors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text.rich(
                                          TextSpan(
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: PantryColors.muted,
                                              height: 1.5,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'Esta tienda cuenta con ',
                                              ),
                                              TextSpan(
                                                text:
                                                    '${widget.purchases} compras registradas.',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  color: PantryColors.green,
                                                ),
                                              ),
                                              const TextSpan(
                                                text: '\nLos cambios se sincronizarán automáticamente en el historial de despensa.',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EditPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Expanded(
                                    child: _EditLabel(
                                      'Nombre de la tienda / Sucursal',
                                    ),
                                  ),
                                  Text(
                                    '*',
                                    style: TextStyle(
                                      color: PantryColors.red,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: widget.storeName,
                                style: const TextStyle(fontSize: 12),
                                decoration: _decoration(
                                  Icons.storefront_outlined,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Se mostrará en la selección rápida al agregar compras.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: PantryColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EditPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _EditLabel(
                                'Tipo de establecimiento / Cadena',
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (context, constraints) => Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final type in [
                                      'Supermercado',
                                      'Mayorista',
                                      'Tienda local',
                                      'Mercado / Tianguis',
                                    ])
                                      SizedBox(
                                        width: (constraints.maxWidth - 8) / 2,
                                        child: Semantics(
                                          selected: _type == type,
                                          button: true,
                                          child: Material(
                                            color: _type == type
                                                ? const Color(0xFFE9F8ED)
                                                : PantryColors.background,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              side: BorderSide(
                                                color: _type == type
                                                    ? PantryColors.green
                                                    : PantryColors.border,
                                              ),
                                            ),
                                            child: InkWell(
                                              onTap: () =>
                                                  setState(() => _type = type),
                                              borderRadius:
                                                  BorderRadius.circular(9),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 9,
                                                      vertical: 13,
                                                    ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      _type == type
                                                          ? Icons
                                                                .radio_button_checked_rounded
                                                          : Icons
                                                                .radio_button_unchecked_rounded,
                                                      size: 16,
                                                      color: _type == type
                                                          ? PantryColors.green
                                                          : PantryColors.muted,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Flexible(
                                                      child: Text(
                                                        type,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color: _type == type
                                                              ? PantryColors
                                                                    .green
                                                              : PantryColors
                                                                    .muted,
                                                          fontWeight:
                                                              _type == type
                                                              ? FontWeight.w600
                                                              : FontWeight.w400,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EditPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: _EditLabel('Dirección / Ubicación'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () {},
                                    icon: const Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                    ),
                                    label: const Text(
                                      'Ubicar en mapa',
                                      style: TextStyle(fontSize: 10),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TextFormField(
                                initialValue: widget.address,
                                maxLines: 2,
                                minLines: 1,
                                style: const TextStyle(fontSize: 11),
                                decoration:
                                    _decoration(Icons.location_on_outlined)
                                        .copyWith(
                                          suffixIcon: const Icon(
                                            Icons.map_outlined,
                                            size: 18,
                                            color: PantryColors.muted,
                                          ),
                                        ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Permite sugerir esta tienda automáticamente al estar cerca.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: PantryColors.muted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EditPanel(
                          child: Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star_border_rounded,
                                          size: 15,
                                          color: PantryColors.green,
                                        ),
                                        SizedBox(width: 5),
                                        _EditLabel('Tienda habitual'),
                                      ],
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      'Marcar como supermercado habitual para comprar tus productos.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: PantryColors.muted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _usual,
                                onChanged: (value) =>
                                    setState(() => _usual = value),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _EditPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _EditLabel(
                                'Notas o recordatorios de compra',
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                initialValue: widget.isEditing
                                    ? 'Suele tener mejores ofertas de lácteos los martes'
                                    : '',
                                minLines: 3,
                                maxLines: 5,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 1.5,
                                ),
                                decoration: _decoration(),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Notas privadas para planificar tu despensa.',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: PantryColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (widget.isEditing)
                          _EditPanel(
                            color: const Color(0xFFEEF5EF),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GESTIÓN DE CATÁLOGO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    letterSpacing: .7,
                                    fontWeight: FontWeight.w600,
                                    color: PantryColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(
                                      color: PantryColors.border,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.visibility_off_outlined,
                                        size: 15,
                                        color: PantryColors.ink,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Desactivar tienda temporalmente',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: PantryColors.ink,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: PantryColors.muted,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: null,
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFECDAD5),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        size: 15,
                                        color: Color(0xFFDFA49A),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Eliminar tienda',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFFDFA49A),
                                          ),
                                        ),
                                      ),
                                      _CatalogTag('Bloqueado'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.info_outline_rounded,
                                      size: 12,
                                      color: PantryColors.red,
                                    ),
                                    SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        'No disponible: existen compras vinculadas.',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: PantryColors.muted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: Text(
                            widget.isEditing
                                ? 'Guardar cambios'
                                : 'Guardar tienda',
                            style: TextStyle(fontSize: 13),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 11,
                              color: PantryColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _decoration([IconData? icon]) => InputDecoration(
  filled: true,
  fillColor: PantryColors.background,
  prefixIcon: icon == null
      ? null
      : Icon(icon, size: 18, color: PantryColors.muted),
  contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
);

class _EditPanel extends StatelessWidget {
  const _EditPanel({required this.child, this.color = Colors.white});
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: PantryColors.border),
    ),
    child: child,
  );
}

class _EditLabel extends StatelessWidget {
  const _EditLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
  );
}

class _CatalogTag extends StatelessWidget {
  const _CatalogTag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: PantryColors.greenLight,
      borderRadius: BorderRadius.circular(7),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 8, color: PantryColors.green),
    ),
  );
}
