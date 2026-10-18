import 'package:flutter/material.dart';

import '../components/tema_alacena.dart';
import '../database/daos/producto_dao.dart';
import '../models/datos_escaneo_producto.dart';
import '../services/servicio_open_food_facts.dart';
import '../services/servicio_precios_referencia.dart';
import 'escaner_codigo_barras.dart';
import 'visualizador_codigo_barras.dart';

class CampoCodigoBarras extends StatefulWidget {
  final TextEditingController controller;
  final bool isEditing;
  final int? currentProductId;
  final ValueChanged<DatosEscaneoProducto> onProductResolved;
  final ProductoDao? productoDao;
  final ServicioOpenFoodFacts? openFoodFactsService;
  final ServicioPreciosReferencia? preciosReferenciaService;
  final bool autoStartCamera;

  const CampoCodigoBarras({
    super.key,
    required this.controller,
    required this.onProductResolved,
    this.isEditing = false,
    this.currentProductId,
    this.productoDao,
    this.openFoodFactsService,
    this.preciosReferenciaService,
    this.autoStartCamera = true,
  });

  @override
  State<CampoCodigoBarras> createState() => _CampoCodigoBarrasState();
}

class _CampoCodigoBarrasState extends State<CampoCodigoBarras> {
  late final ProductoDao _productoDao;
  late final ServicioOpenFoodFacts _offService;
  late final ServicioPreciosReferencia _preciosService;

  bool _buscando = false;

  @override
  void initState() {
    super.initState();
    _productoDao = widget.productoDao ?? ProductoDao();
    _offService = widget.openFoodFactsService ?? ServicioOpenFoodFacts();
    _preciosService =
        widget.preciosReferenciaService ?? ServicioPreciosReferencia();
    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  Future<void> _abrirEscaner() async {
    final scanned = await EscanerCodigoBarrasSheet.abrir(
      context,
      autoStartCamera: widget.autoStartCamera,
    );
    if (scanned != null && scanned.isNotEmpty) {
      widget.controller.text = scanned;
      await resolverCodigo(scanned);
    }
  }

  Future<void> resolverCodigo(String rawCode) async {
    final codigo = rawCode.trim();
    if (codigo.isEmpty) return;

    setState(() => _buscando = true);

    try {
      // Verificar si ya existe en la base de datos local
      dynamic existente;
      try {
        existente = await _productoDao
            .obtenerPorCodigo(codigo)
            .timeout(const Duration(milliseconds: 300));
      } catch (_) {
        existente = null;
      }
      if (existente != null && existente.id != widget.currentProductId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Aviso: Este código ya está asignado a "${existente.nombre}".',
              ),
              backgroundColor: PantryColors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        widget.onProductResolved(
          DatosEscaneoProducto(
            codigo: codigo,
            nombre: existente.nombre,
            yaExisteEnInventario: true,
            productoExistenteId: existente.id,
            nombreExistente: existente.nombre,
          ),
        );
        return;
      }

      // Buscar en catálogo de referencia precargado (offline)
      final datosRef = await _preciosService.obtenerDatosPorCodigo(codigo);

      // Buscar en Open Food Facts (online)
      DatosEscaneoProducto? datosOff;
      try {
        datosOff = await _offService.consultarCodigo(codigo);
      } catch (_) {
        datosOff = null;
      }

      // Consolidar la mejor información encontrada
      final nombre = datosRef?.nombre ?? datosOff?.nombre;
      final categoria = datosRef?.categoria ?? datosOff?.categoria;
      final presentacion = datosRef?.presentacion ?? datosOff?.presentacion;
      final contenido = datosRef?.contenidoEnvase ?? datosOff?.contenidoEnvase;
      final unidad = datosRef?.unidad ?? datosOff?.unidad;
      final imagenUrl = datosOff?.imagenUrl;

      // Estimar precio de referencia inteligente
      double? precio = datosRef?.precioSugerido;
      if (precio == null || precio <= 0) {
        precio = await _preciosService.obtenerPrecio(
          codigo: codigo,
          categoria: categoria,
          contenido: contenido,
          unidad: unidad,
        );
      }

      final consolidado = DatosEscaneoProducto(
        codigo: codigo,
        nombre: nombre,
        marca: datosOff?.marca,
        categoria: categoria,
        presentacion: presentacion,
        contenidoEnvase: contenido,
        unidad: unidad,
        precioSugerido: precio,
        imagenUrl: imagenUrl,
      );

      if (mounted) {
        if (nombre != null && nombre.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Producto identificado: $nombre'),
              backgroundColor: PantryColors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Código listo. No se encontraron datos en línea, completa los campos manualmente.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      widget.onProductResolved(consolidado);
    } finally {
      if (mounted) {
        setState(() => _buscando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Código de barras',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: PantryColors.ink,
              ),
            ),
            if (_buscando)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: PantryColors.green,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('input_codigo_barras'),
          controller: widget.controller,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Escanea o escribe el código (opcional)',
            prefixIcon: const Icon(
              Icons.qr_code_rounded,
              size: 20,
              color: PantryColors.green,
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.controller.text.isNotEmpty) ...[
                  IconButton(
                    key: const Key('btn_ver_codigo_generado'),
                    icon: const Icon(
                      Icons.remove_red_eye_outlined,
                      size: 20,
                      color: PantryColors.green,
                    ),
                    tooltip: 'Ver código de barras generado',
                    onPressed: () {
                      VisualizadorCodigoBarrasModal.mostrar(
                        context,
                        codigo: widget.controller.text,
                        nombreProducto: widget.isEditing ? 'Producto' : null,
                      );
                    },
                  ),
                  IconButton(
                    key: const Key('btn_buscar_codigo'),
                    icon: const Icon(
                      Icons.search,
                      size: 20,
                      color: PantryColors.green,
                    ),
                    tooltip: 'Buscar producto',
                    onPressed: _buscando
                        ? null
                        : () => resolverCodigo(widget.controller.text),
                  ),
                  IconButton(
                    key: const Key('btn_limpiar_codigo'),
                    icon: const Icon(
                      Icons.clear,
                      size: 18,
                      color: PantryColors.muted,
                    ),
                    tooltip: 'Borrar código',
                    onPressed: () {
                      widget.controller.clear();
                      setState(() {});
                    },
                  ),
                ],
                IconButton(
                  key: const Key('btn_escanear_codigo'),
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: PantryColors.green,
                    size: 22,
                  ),
                  tooltip: 'Escanear código de barras',
                  onPressed: _buscando ? null : _abrirEscaner,
                ),
              ],
            ),
            filled: true,
            fillColor: PantryColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PantryColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PantryColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: PantryColors.green, width: 1.5),
            ),
          ),
          onSubmitted: (val) => resolverCodigo(val),
        ),
      ],
    );
  }
}
