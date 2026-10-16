import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';

import '../widgets/barra_navegacion_inferior.dart';

import '../components/tema_alacena.dart';
import '../presentation/datos_alacena_demostracion.dart';
import '../widgets/miniatura_producto.dart';

/// Alta visual: los valores solo viven en la pantalla, sin persistencia.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});
  final PantryProductPreview? product;
  bool get isEditing => product != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  String _name = '';
  String _category = 'Lácteos';
  String _unit = 'pza';
  String _zone = 'Nevera';
  String _time = '09:00 AM';
  int _minimum = 0;
  int _quantity = 3;
  bool _reminder = true;

  @override
  void initState() {
    super.initState();
    _name = widget.product?.name ?? '';
    _category = widget.product?.category ?? 'Lácteos';
    _unit = widget.product?.unit ?? 'pza';
    _minimum = widget.product?.minimumStock ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: PantryColors.greenLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Scaffold(
            bottomNavigationBar: const AppBottomNavigation(selectedIndex: 0),
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
                          ? AppSection.editProduct
                          : AppSection.newProduct,
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: IconButton.filled(
                          onPressed: () {},
                          tooltip: 'Perfil',
                          style: IconButton.styleFrom(
                            backgroundColor: PantryColors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    sliver: SliverList.list(
                      children: [
                        _ArticlePanel(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.qr_code_scanner_rounded,
                                size: 26,
                                color: PantryColors.green,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¿Tienes el código de barras?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Rellena los datos en 1 segundo',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: PantryColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              FilledButton.icon(
                                onPressed: () {},
                                icon: const Icon(
                                  Icons.document_scanner_outlined,
                                  size: 13,
                                ),
                                label: const Text(
                                  'Escanear',
                                  style: TextStyle(fontSize: 10),
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 32),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        if (widget.product == null)
                          const _PhotoPlaceholder()
                        else
                          Center(
                            child: ProductThumbnail(
                              kind: widget.product!.thumbnail,
                              imagePath: widget.product!.imagePath,
                              size: 130,
                            ),
                          ),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: [
                            _PhotoButton(
                              label: 'Cámara',
                              icon: Icons.camera_alt_outlined,
                            ),
                            _PhotoButton(
                              label: 'Galería',
                              icon: Icons.photo_library_outlined,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const _ArticleLabel(
                          'Nombre del producto',
                          required: true,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: _name,
                          onChanged: (value) => setState(() => _name = value),
                          style: const TextStyle(fontSize: 12),
                          decoration: _articleInput().copyWith(
                            prefixIcon: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                              color: PantryColors.green,
                            ),
                            hintText: 'Ej. Leche deslactosada 1 L',
                            errorText: _name.trim().isEmpty
                                ? 'Este campo es obligatorio'
                                : null,
                            errorStyle: const TextStyle(fontSize: 10),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const _ArticleLabel('Categoría', required: true),
                        const SizedBox(height: 9),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final category in [
                                if (widget.product != null &&
                                    ![
                                      'Lácteos',
                                      'Granos',
                                      'Enlatados',
                                      'Otros',
                                    ].contains(widget.product!.category))
                                  (
                                    widget.product!.category,
                                    Icons.category_outlined,
                                  ),
                                ('Lácteos', Icons.kitchen_outlined),
                                ('Granos', Icons.grain_rounded),
                                ('Enlatados', Icons.inventory_2_outlined),
                                ('Otros', Icons.category_outlined),
                              ])
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: ChoiceChip(
                                    label: Text(category.$1),
                                    avatar: Icon(
                                      category.$2,
                                      size: 15,
                                      color: _category == category.$1
                                          ? Colors.white
                                          : PantryColors.ink,
                                    ),
                                    selected: _category == category.$1,
                                    showCheckmark: false,
                                    selectedColor: PantryColors.green,
                                    backgroundColor: PantryColors.greenLight,
                                    labelStyle: TextStyle(
                                      fontSize: 11,
                                      color: _category == category.$1
                                          ? Colors.white
                                          : PantryColors.ink,
                                    ),
                                    side: BorderSide.none,
                                    onSelected: (_) =>
                                        setState(() => _category = category.$1),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final units = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ArticleLabel(
                                  'Unidad de medida',
                                  required: true,
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    color: PantryColors.greenLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      for (final unit in [
                                        'pza',
                                        'kg',
                                        'L',
                                        'g',
                                      ])
                                        Expanded(
                                          child: InkWell(
                                            onTap: () =>
                                                setState(() => _unit = unit),
                                            borderRadius: BorderRadius.circular(
                                              9,
                                            ),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 11,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _unit == unit
                                                    ? PantryColors.green
                                                    : Colors.transparent,
                                                borderRadius:
                                                    BorderRadius.circular(9),
                                              ),
                                              child: Text(
                                                unit,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _unit == unit
                                                      ? Colors.white
                                                      : PantryColors.ink,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Presentación básica',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: PantryColors.muted,
                                  ),
                                ),
                              ],
                            );
                            final minimum = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _ArticleLabel(
                                  'Stock mínimo',
                                  required: true,
                                ),
                                const SizedBox(height: 10),
                                _QuantityControl(
                                  value: _minimum,
                                  onDecrease: () => setState(() {
                                    if (_minimum > 0) _minimum--;
                                  }),
                                  onIncrease: () => setState(() => _minimum++),
                                  label: 'stock mínimo',
                                ),
                                const SizedBox(height: 6),
                                if (_minimum == 0)
                                  const Text(
                                    'Ingresa un valor mayor a 0',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.red,
                                    ),
                                  ),
                              ],
                            );
                            if (constraints.maxWidth < 350) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  units,
                                  const SizedBox(height: 18),
                                  minimum,
                                ],
                              );
                            }
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: units),
                                const SizedBox(width: 16),
                                Expanded(child: minimum),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 22),
                        if (!widget.isEditing)
                          _ArticlePanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: PantryColors.green,
                                      child: Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: [
                                              Text(
                                                'Primer lote',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              _ArticleTag('Entrada inicial'),
                                            ],
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Registra la existencia actual y su fecha de vencimiento.',
                                            style: TextStyle(
                                              fontSize: 11,
                                              height: 1.4,
                                              color: PantryColors.muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const _ArticleLabel(
                                  'Cantidad inicial',
                                  required: true,
                                ),
                                const SizedBox(height: 9),
                                _QuantityControl(
                                  value: _quantity,
                                  unit: _unit,
                                  onDecrease: () => setState(() {
                                    if (_quantity > 0) _quantity--;
                                  }),
                                  onIncrease: () => setState(() => _quantity++),
                                  label: 'cantidad inicial',
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Existencias listas para almacenar',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: PantryColors.muted,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const _ArticleLabel(
                                  'Fecha de caducidad',
                                  required: true,
                                ),
                                const SizedBox(height: 9),
                                TextFormField(
                                  readOnly: true,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _articleInput().copyWith(
                                    hintText: 'dd/mm/aaaa',
                                    prefixIcon: const Icon(
                                      Icons.calendar_today_outlined,
                                      size: 18,
                                      color: PantryColors.green,
                                    ),
                                    suffixIcon: const Icon(
                                      Icons.event_outlined,
                                      size: 18,
                                      color: PantryColors.muted,
                                    ),
                                    helperText: 'Selecciona una fecha de vencimiento válida',
                                    helperStyle: const TextStyle(
                                      fontSize: 10,
                                      color: PantryColors.red,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const CircleAvatar(
                                            radius: 15,
                                            backgroundColor:
                                                PantryColors.greenLight,
                                            child: Icon(
                                              Icons
                                                  .notifications_active_outlined,
                                              size: 17,
                                              color: PantryColors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Recordarme el día que caduca',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Recibir notificación en tu dispositivo',
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
                                            value: _reminder,
                                            onChanged: (value) => setState(
                                              () => _reminder = value,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.access_time_rounded,
                                            size: 14,
                                            color: PantryColors.green,
                                          ),
                                          const SizedBox(width: 5),
                                          const Expanded(
                                            child: Text(
                                              'Hora del aviso:',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: PantryColors.muted,
                                              ),
                                            ),
                                          ),
                                          DropdownButton<String>(
                                            value: _time,
                                            underline: const SizedBox.shrink(),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: PantryColors.green,
                                            ),
                                            items:
                                                const [
                                                      '08:00 AM',
                                                      '09:00 AM',
                                                      '06:00 PM',
                                                    ]
                                                    .map(
                                                      (time) =>
                                                          DropdownMenuItem(
                                                            value: time,
                                                            child: Text(time),
                                                          ),
                                                    )
                                                    .toList(),
                                            onChanged: _reminder
                                                ? (value) => setState(
                                                    () => _time = value!,
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (widget.isEditing)
                          const _ArticlePanel(
                            child: Text(
                              'Las existencias y las fechas se administran desde los lotes del producto.',
                              style: TextStyle(
                                fontSize: 12,
                                color: PantryColors.muted,
                                height: 1.5,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Row(
                          children: [
                            Icon(
                              Icons.kitchen_outlined,
                              size: 15,
                              color: PantryColors.muted,
                            ),
                            SizedBox(width: 5),
                            Expanded(
                              child: _ArticleLabel('Zona de almacenamiento'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            for (final zone in [
                              ('Nevera', Icons.kitchen_outlined),
                              ('Alacena', Icons.inventory_2_outlined),
                              ('Congelador', Icons.ac_unit_rounded),
                            ])
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  child: Material(
                                    color: _zone == zone.$1
                                        ? PantryColors.greenLight
                                        : const Color(0xFFEAF3EB),
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _zone = zone.$1),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                          horizontal: 3,
                                        ),
                                        child: Column(
                                          children: [
                                            Icon(
                                              zone.$2,
                                              size: 20,
                                              color: _zone == zone.$1
                                                  ? PantryColors.green
                                                  : PantryColors.muted,
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              zone.$1,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: _zone == zone.$1
                                                    ? PantryColors.green
                                                    : PantryColors.muted,
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
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: () {},
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.isEditing
                                ? 'Guardar cambios'
                                : 'Guardar artículo',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 5),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 11,
                              color: PantryColors.ink,
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

InputDecoration _articleInput() => InputDecoration(
  filled: true,
  fillColor: const Color(0xFFEAF4EC),
  hintStyle: const TextStyle(fontSize: 11, color: PantryColors.muted),
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide.none,
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(11),
    borderSide: BorderSide.none,
  ),
);

class _ArticlePanel extends StatelessWidget {
  const _ArticlePanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF4EC),
      borderRadius: BorderRadius.circular(15),
    ),
    child: child,
  );
}

class _ArticleLabel extends StatelessWidget {
  const _ArticleLabel(this.text, {this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: text),
        if (required)
          const TextSpan(
            text: ' *',
            style: TextStyle(color: PantryColors.red),
          ),
      ],
    ),
    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
  );
}

class _ArticleTag extends StatelessWidget {
  const _ArticleTag(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(
      color: PantryColors.greenLight,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 9, color: PantryColors.green),
    ),
  );
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder();
  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFE1ECE4),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: PantryColors.background,
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 26,
                    color: PantryColors.green,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Foto opcional',
                  style: TextStyle(fontSize: 10, color: PantryColors.muted),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: IconButton.filled(
              onPressed: () {},
              tooltip: 'Editar foto',
              icon: const Icon(Icons.edit_outlined, size: 16),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PhotoButton extends StatelessWidget {
  const _PhotoButton({required this.label, required this.icon});
  final String label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => FilledButton.tonalIcon(
    onPressed: () {},
    icon: Icon(icon, size: 14),
    label: Text(label, style: const TextStyle(fontSize: 11)),
    style: FilledButton.styleFrom(
      backgroundColor: PantryColors.greenLight,
      foregroundColor: PantryColors.green,
      minimumSize: const Size(0, 34),
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
    required this.label,
    this.unit,
  });
  final int value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String label;
  final String? unit;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: PantryColors.background,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        IconButton(
          onPressed: onDecrease,
          tooltip: 'Disminuir $label',
          icon: const Icon(
            Icons.remove_rounded,
            size: 18,
            color: PantryColors.muted,
          ),
        ),
        Expanded(
          child: Text(
            '$value${unit == null ? '' : '  $unit'}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          onPressed: onIncrease,
          tooltip: 'Aumentar $label',
          icon: const Icon(
            Icons.add_rounded,
            size: 18,
            color: PantryColors.green,
          ),
        ),
      ],
    ),
  );
}
