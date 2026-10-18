import 'package:flutter/material.dart';

/// Cambia únicamente la fecha de caducidad, sin abrir el formulario del producto.
class ExpiryDateEditorDialog extends StatefulWidget {
  const ExpiryDateEditorDialog({super.key, required this.initialDate});
  final DateTime initialDate;

  @override
  State<ExpiryDateEditorDialog> createState() => _ExpiryDateEditorDialogState();
}

class _ExpiryDateEditorDialogState extends State<ExpiryDateEditorDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _date;

  @override
  void initState() {
    super.initState();
    final d = widget.initialDate;
    _date = TextEditingController(
      text:
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}',
    );
  }

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  DateTime? _value() {
    final match = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$')
        .firstMatch(_date.text.trim());
    if (match == null) return null;
    final day = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final year = int.parse(match[3]!);
    if (year < 1900 || year > 3100) return null;
    final value = DateTime(year, month, day);
    return value.day == day && value.month == month && value.year == year
        ? value
        : null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Nueva fecha de caducidad'),
    content: Form(
      key: _form,
      child: TextFormField(
        controller: _date,
        autofocus: true,
        keyboardType: TextInputType.datetime,
        decoration: const InputDecoration(
          labelText: 'Nueva fecha',
          hintText: 'dd/mm/aaaa',
        ),
        validator: (_) =>
            _value() == null ? 'Escribe una fecha válida: dd/mm/aaaa' : null,
        onFieldSubmitted: (_) => _guardar(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
      FilledButton(onPressed: _guardar, child: const Text('Guardar')),
    ],
  );

  void _guardar() {
    if (_form.currentState!.validate()) Navigator.pop(context, _value());
  }
}
