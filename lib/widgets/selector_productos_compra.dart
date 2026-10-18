import 'package:flutter/material.dart';

import '../presentation/modelos_vista_alacena.dart';
import 'miniatura_producto.dart';

class PurchaseProductSelector extends StatefulWidget {
  const PurchaseProductSelector({
    super.key,
    required this.products,
    required this.selectedKeys,
  });
  final List<PantryProductPreview> products;
  final Set<String> selectedKeys;
  @override
  State<PurchaseProductSelector> createState() =>
      _PurchaseProductSelectorState();
}

class _PurchaseProductSelectorState extends State<PurchaseProductSelector> {
  late final Set<String> _selected;
  String _search = '';
  @override
  void initState() {
    super.initState();
    _selected = Set.of(widget.selectedKeys);
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products
        .where(
          (p) =>
              p.name.toLowerCase().contains(_search) ||
              p.category.toLowerCase().contains(_search),
        )
        .toList();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Agregar productos',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar en tu alacena',
              ),
              onChanged: (v) =>
                  setState(() => _search = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        widget.products.isEmpty
                            ? 'No hay productos registrados. Agrega productos desde Inicio.'
                            : 'No hay productos que coincidan con la búsqueda.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (_, index) {
                        final p = products[index];
                        return CheckboxListTile(
                          key: ValueKey('purchase-option-${p.key}'),
                          value: _selected.contains(p.key),
                          onChanged: (selected) {
                            setState(() {
                              selected == true
                                  ? _selected.add(p.key)
                                  : _selected.remove(p.key);
                            });
                          },
                          secondary: ProductThumbnail(
                            kind: p.thumbnail,
                            imagePath: p.imagePath,
                            size: 44,
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            '${p.presentationLabel}\n${p.category}',
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(
                  context,
                  widget.products
                      .where((p) => _selected.contains(p.key))
                      .toList(),
                ),
                child: Text('Usar selección (${_selected.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
