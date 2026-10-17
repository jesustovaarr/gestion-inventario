import 'package:flutter/material.dart';

import '../widgets/encabezado_seccion.dart';
import '../widgets/barra_navegacion_inferior.dart';
import '../components/tema_alacena.dart';
import '../models/tienda_model.dart';
import '../models/tipo_tienda_model.dart';
import '../database/daos/tienda_dao.dart';
import '../database/daos/tipo_tienda_dao.dart';

/// Formulario para crear y editar tiendas
class StoreFormScreen extends StatefulWidget {
  const StoreFormScreen({
    super.key,
    this.storeId,
    this.storeName,
    this.address,
    this.tipoTiendaId,
    this.purchases = 0,
    this.tienda,
  });

  final int? storeId;
  final String? storeName;
  final String? address;
  final int? tipoTiendaId;
  final int purchases;
  final Tienda? tienda;

  bool get isEditing => (storeId != null) || (tienda != null) || (storeName != null);

  @override
  State<StoreFormScreen> createState() => _StoreFormScreenState();
}

class _StoreFormScreenState extends State<StoreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  final TiendaDao _tiendaDao = TiendaDao();
  final TipoTiendaDao _tipoTiendaDao = TipoTiendaDao();

  List<TipoTienda> _tiposTienda = [];
  int _selectedTipoId = 1;
  bool _usual = false;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    final initialName = widget.tienda?.nombre ?? widget.storeName ?? '';
    final initialAddress = widget.tienda?.ubicacion ?? widget.address ?? '';
    _nameController = TextEditingController(text: initialName);
    _addressController = TextEditingController(text: initialAddress);
    _notesController = TextEditingController(
      text: widget.isEditing ? 'Suele tener mejores ofertas de lácteos los martes' : '',
    );

    _selectedTipoId = widget.tienda?.tipoTiendaId ?? widget.tipoTiendaId ?? 1;
    _usual = widget.isEditing;
    _cargarTiposTienda();
  }

  Future<void> _cargarTiposTienda() async {
    final tipos = await _tipoTiendaDao.obtenerTodos();
    if (mounted && tipos.isNotEmpty) {
      setState(() {
        _tiposTienda = tipos;
        final actual = tipos.firstWhere(
          (t) => t.id == _selectedTipoId,
          orElse: () => tipos.first,
        );
        _selectedTipoId = actual.id ?? 1;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _guardarTienda() async {
    final nombre = _nameController.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de la tienda es obligatorio'),
          backgroundColor: PantryColors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final ubicacion = _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim();

      final int? id = widget.tienda?.id ?? widget.storeId;

      if (id != null) {
        // Actualizar existente
        final tiendaActualizada = Tienda(
          id: id,
          nombre: nombre,
          ubicacion: ubicacion,
          tipoTiendaId: _selectedTipoId,
        );
        await _tiendaDao.actualizar(tiendaActualizada);
      } else {
        // Insertar nueva
        final nuevaTienda = Tienda(
          nombre: nombre,
          ubicacion: ubicacion,
          tipoTiendaId: _selectedTipoId,
        );
        await _tiendaDao.insertar(nuevaTienda);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(id != null ? 'Tienda actualizada' : 'Tienda creada con éxito'),
            backgroundColor: PantryColors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar tienda: $e'),
            backgroundColor: PantryColors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _eliminarTienda() async {
    final id = widget.tienda?.id ?? widget.storeId;
    if (id == null) return;

    final tieneCompras = await _tiendaDao.tieneCompras(id);
    if (!mounted) return;
    final String mensaje = tieneCompras
        ? 'Esta tienda tiene compras vinculadas en tu historial. Si la eliminas, también se eliminarán sus registros de compra asociados.\n\n¿Deseas eliminar definitivamente "${_nameController.text.trim()}"?'
        : '¿Deseas eliminar definitivamente "${_nameController.text.trim()}" del catálogo?';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar tienda'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: PantryColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _tiendaDao.eliminar(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tienda eliminada del catálogo'),
              backgroundColor: PantryColors.orange,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar tienda: $e'),
              backgroundColor: PantryColors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectivePurchases = widget.tienda?.totalCompras ?? widget.purchases;

    return ColoredBox(
      color: PantryColors.greenLight,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Scaffold(
            bottomNavigationBar: const AppBottomNavigation(selectedIndex: 2),
            body: SafeArea(
              child: Form(
                key: _formKey,
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
                            onPressed: _guardando ? null : _guardarTienda,
                            icon: _guardando
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_rounded, size: 16),
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
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _nameController.text.isNotEmpty
                                                ? _nameController.text
                                                : (widget.storeName ?? 'Nueva tienda'),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                                  text: '$effectivePurchases compras registradas.',
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
                                  controller: _nameController,
                                  onChanged: (_) => setState(() {}),
                                  style: const TextStyle(fontSize: 12),
                                  decoration: _decoration(Icons.storefront_outlined),
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
                                const _EditLabel('Tipo de establecimiento / Cadena'),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final tiposAMostrar = _tiposTienda.isNotEmpty
                                        ? _tiposTienda
                                        : const [
                                            TipoTienda(id: 1, nombre: 'Supermercado'),
                                            TipoTienda(id: 2, nombre: 'Mercado local'),
                                            TipoTienda(id: 3, nombre: 'Tiendita de la esquina'),
                                            TipoTienda(id: 4, nombre: 'Club de precios'),
                                          ];

                                    return Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        for (final tipo in tiposAMostrar)
                                          SizedBox(
                                            width: (constraints.maxWidth - 8) / 2,
                                            child: Semantics(
                                              selected: _selectedTipoId == tipo.id,
                                              button: true,
                                              child: Material(
                                                color: _selectedTipoId == tipo.id
                                                    ? const Color(0xFFE9F8ED)
                                                    : PantryColors.background,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(9),
                                                  side: BorderSide(
                                                    color: _selectedTipoId == tipo.id
                                                        ? PantryColors.green
                                                        : PantryColors.border,
                                                  ),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      _selectedTipoId = tipo.id ?? 1;
                                                    });
                                                  },
                                                  borderRadius: BorderRadius.circular(9),
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 9,
                                                      vertical: 13,
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          _selectedTipoId == tipo.id
                                                              ? Icons.radio_button_checked_rounded
                                                              : Icons.radio_button_unchecked_rounded,
                                                          size: 16,
                                                          color: _selectedTipoId == tipo.id
                                                              ? PantryColors.green
                                                              : PantryColors.muted,
                                                        ),
                                                        const SizedBox(width: 5),
                                                        Flexible(
                                                          child: Text(
                                                            tipo.nombre,
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: _selectedTipoId == tipo.id
                                                                  ? PantryColors.green
                                                                  : PantryColors.muted,
                                                              fontWeight: _selectedTipoId == tipo.id
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
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _EditPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _EditLabel('Dirección / Ubicación'),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _addressController,
                                  maxLines: 2,
                                  minLines: 1,
                                  style: const TextStyle(fontSize: 11),
                                  decoration: _decoration(Icons.location_on_outlined),
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
                                          Expanded(child: _EditLabel('Tienda habitual')),
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
                                  onChanged: (value) => setState(() => _usual = value),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          _EditPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const _EditLabel('Notas o recordatorios de compra'),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _notesController,
                                  minLines: 3,
                                  maxLines: 5,
                                  style: const TextStyle(fontSize: 12, height: 1.5),
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
                                    onPressed: _eliminarTienda,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFFECDAD5)),
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
                                          color: PantryColors.red,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Eliminar tienda definitivamente',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: PantryColors.red,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 16,
                                          color: PantryColors.red,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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
      ),
    );
  }

  InputDecoration _decoration([IconData? icon]) => InputDecoration(
        prefixIcon: icon != null
            ? Icon(icon, size: 16, color: PantryColors.muted)
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: PantryColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: PantryColors.border),
        ),
      );
}

class _EditPanel extends StatelessWidget {
  const _EditPanel({required this.child, this.color});
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(16),
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: PantryColors.ink,
        ),
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
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 9,
            color: PantryColors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}
