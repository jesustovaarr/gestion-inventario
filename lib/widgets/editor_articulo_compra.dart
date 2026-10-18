import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../database/daos/producto_dao.dart';
import '../presentation/modelos_vista_alacena.dart';
import '../presentation/modelos_vista_compra.dart';
import '../screens/formulario_producto.dart';
import '../utils/cantidades.dart';
import '../utils/importes.dart';
import '../utils/presentaciones.dart';
import 'miniatura_producto.dart';

class PurchaseArticleEditor extends StatefulWidget {
  const PurchaseArticleEditor({
    super.key,
    required this.item,
    required this.purchaseDate,
    this.onChanged,
  });
  final PurchaseArticleDraft item;
  final DateTime purchaseDate;
  final ValueChanged<PurchaseArticleDraft>? onChanged;
  @override
  State<PurchaseArticleEditor> createState() => _PurchaseArticleEditorState();
}

class _PurchaseArticleEditorState extends State<PurchaseArticleEditor> {
  final _form = GlobalKey<FormState>();
  final _expiryField = GlobalKey<FormFieldState<DateTime>>();
  late final TextEditingController _qty, _content, _price;
  late PantryProductPreview _product;
  late PresentacionCompra _packaging;
  DateTime? _expiry;
  bool _pickingDate = false;
  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _product = item.product;
    _expiry = item.expiryDate;
    _packaging = item.packaging;
    _qty = TextEditingController(
      text: item.packaging.esEnvase
          ? '${item.packageCount}'
          : formatearCantidad(item.quantity),
    );
    _content = TextEditingController(
      text: formatearCantidad(item.packageContent),
    );
    _price = TextEditingController(
      text: item.priceCents == null ? '' : formatearImporte(item.priceCents!),
    );
  }

  @override
  void dispose() {
    _qty.dispose();
    _content.dispose();
    _price.dispose();
    super.dispose();
  }

  PurchaseArticleDraft? _value() {
    final qty = leerCantidad(_qty.text);
    final content = _packaging.esEnvase ? leerCantidad(_content.text) : 1.0;
    final count = _packaging.esEnvase ? int.tryParse(_qty.text.trim()) : 1;
    if (qty == null ||
        content == null ||
        count == null ||
        count < 1 ||
        count > 999999) {
      return null;
    }
    final total = _packaging.esEnvase
        ? normalizarCantidad(count * content)
        : qty;
    if (!cantidadValida(total)) return null;
    final price = leerPrecioCentavos(_price.text);
    if (_price.text.trim().isNotEmpty && price == null) return null;
    return PurchaseArticleDraft(
      product: _product,
      quantity: total,
      packaging: _packaging,
      packageCount: count,
      packageContent: content,
      priceCents: price,
      expiryDate: _expiry,
    );
  }

  void _changed() {
    setState(() {});
    final value = _value();
    if (value != null) widget.onChanged?.call(value);
  }

  Future<void> _date() async {
    if (_pickingDate) return;
    _pickingDate = true;
    try {
      final initial = _expiry != null && !_expiry!.isBefore(widget.purchaseDate)
          ? _expiry!
          : widget.purchaseDate.add(const Duration(days: 7));
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: widget.purchaseDate,
        lastDate: DateTime(3100),
      );
      if (!mounted || date == null) return;
      _expiry = date;
      _expiryField.currentState?.didChange(date);
      _changed();
    } finally {
      _pickingDate = false;
    }
  }

  Future<void> _catalog() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductFormScreen(product: _product, catalogOnly: true),
      ),
    );
    if (!mounted) return;
    try {
      final product = await ProductoDao().obtenerPorId(_product.id!);
      if (mounted && product != null) {
        _product = product.toPreview();
        final updated = PurchaseArticleDraft.fromProduct(_product);
        _packaging = updated.packaging;
        _content.text = formatearCantidad(updated.packageContent);
        _changed();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el producto.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _value();
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProductThumbnail(
                    kind: _product.thumbnail,
                    imagePath: _product.imagePath,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Cerrar artículo',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                etiquetaPresentacion(
                  _packaging,
                  leerCantidad(_content.text) ?? 1,
                  _product.unit,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: PantryColors.green,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Para otro tamaño, registra otro producto desde Inicio.',
                style: TextStyle(fontSize: 12, color: PantryColors.muted),
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('purchase-quantity'),
                controller: _qty,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: !_packaging.esEnvase,
                ),
                decoration: InputDecoration(
                  labelText: _packaging.esEnvase
                      ? 'Cuántas unidades'
                      : 'Cantidad a comprar',
                  suffixText: _packaging.esEnvase
                      ? _packaging.plural
                      : unidadVisible(_product.unit),
                ),
                validator: (v) =>
                    leerCantidad(v ?? '') == null ||
                        (_packaging.esEnvase && int.tryParse(v!.trim()) == null)
                    ? 'Indica una cantidad válida'
                    : null,
                onChanged: (_) => _changed(),
              ),
              if (_packaging.esEnvase && preview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${preview.quantityLabel} · Total: ${formatearCantidad(preview.quantity)} ${unidadVisible(_product.unit)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: PantryColors.muted,
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              TextFormField(
                key: const ValueKey('purchase-unit-price'),
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText:
                      'Precio por ${_packaging.esEnvase ? _packaging.singular.toLowerCase() : unidadVisible(_product.unit)}',
                  prefixText: '\$ ',
                ),
                validator: (v) => leerPrecioCentavos(v ?? '') == null
                    ? 'Indica un precio con hasta dos decimales'
                    : null,
                onChanged: (_) {
                  _changed();
                },
              ),
              FormField<DateTime>(
                key: _expiryField,
                initialValue: _expiry,
                validator: (_) =>
                    _expiry == null || _expiry!.isBefore(widget.purchaseDate)
                    ? 'Indica la caducidad'
                    : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Fecha de caducidad'),
                      subtitle: Text(
                        _expiry == null
                            ? 'Seleccionar una vez para este artículo'
                            : '${_expiry!.day}/${_expiry!.month}/${_expiry!.year}',
                      ),
                      trailing: const Icon(Icons.edit_outlined),
                      onTap: _date,
                    ),
                    if (field.hasError)
                      Text(
                        field.errorText!,
                        style: const TextStyle(
                          color: PantryColors.red,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      preview?.priceCents == null
                          ? 'Subtotal pendiente'
                          : 'Subtotal: \$${formatearImporte(preview!.subtotalCents)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _catalog,
                    child: const Text('Editar producto'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (!_form.currentState!.validate()) return;
                    final value = _value();
                    if (value == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'La cantidad total debe ser menor o igual a 999999.',
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.pop(context, value);
                  },
                  child: const Text('Listo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
