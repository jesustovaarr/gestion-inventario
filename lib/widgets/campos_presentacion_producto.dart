import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../utils/presentaciones.dart';

/// Primero se elige el envase; después, la unidad y su contenido.
class ProductPresentationFields extends StatelessWidget {
  const ProductPresentationFields({
    super.key,
    required this.packaging,
    required this.unit,
    required this.contentController,
    required this.onPackagingChanged,
    required this.onUnitChanged,
    required this.onContentChanged,
  });

  final PresentacionCompra packaging;
  final String unit;
  final TextEditingController contentController;
  final ValueChanged<PresentacionCompra> onPackagingChanged;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<String> onContentChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      DropdownButtonFormField<PresentacionCompra>(
        key: ValueKey('catalog-packaging-${packaging.name}'),
        initialValue: packaging,
        decoration: const InputDecoration(labelText: 'Presentación'),
        items: PresentacionCompra.values
            .map((p) => DropdownMenuItem(value: p, child: Text(p.singular)))
            .toList(),
        onChanged: (p) {
          if (p != null) onPackagingChanged(p);
        },
      ),
      const SizedBox(height: 18),
      const Text(
        'Unidad de medida',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: PantryColors.greenLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (final value in ['pza', 'kg', 'L', 'g', 'ml'])
              Expanded(
                child: InkWell(
                  onTap: () => onUnitChanged(value),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: unit == value
                          ? PantryColors.green
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(
                      value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: unit == value ? Colors.white : PantryColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Text(
        packaging.esEnvase
            ? 'Unidad del contenido de cada ${packaging.singular.toLowerCase()}.'
            : 'Unidad en la que se pesa o mide el producto.',
        style: const TextStyle(fontSize: 11, color: PantryColors.muted),
      ),
      if (packaging.esEnvase) ...[
        const SizedBox(height: 12),
        TextFormField(
          key: const ValueKey('catalog-package-content'),
          controller: contentController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Contenido por ${packaging.singular.toLowerCase()}',
            suffixText: unidadVisible(unit),
            helperText: 'Para otro tamaño, registra otro producto.',
          ),
          onChanged: onContentChanged,
        ),
      ],
    ],
  );
}
