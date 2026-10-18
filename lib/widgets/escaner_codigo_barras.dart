import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../components/tema_alacena.dart';

class EscanerCodigoBarrasSheet extends StatefulWidget {
  final bool autoStartCamera;
  const EscanerCodigoBarrasSheet({super.key, this.autoStartCamera = true});

  // Abre el modal de escaneo y devuelve el código de barras detectado o ingresado
  static Future<String?> abrir(
    BuildContext context, {
    bool autoStartCamera = true,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EscanerCodigoBarrasSheet(
        autoStartCamera: autoStartCamera,
      ),
    );
  }

  @override
  State<EscanerCodigoBarrasSheet> createState() =>
      _EscanerCodigoBarrasSheetState();
}

class _EscanerCodigoBarrasSheetState extends State<EscanerCodigoBarrasSheet> {
  late final MobileScannerController _controller;
  final TextEditingController _manualController = TextEditingController();
  bool _procesado = false;
  bool _torchEncendido = false;
  bool _mostrarEntradaManual = false;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      autoStart: widget.autoStartCamera,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.qrCode,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
    super.dispose();
  }

  void _finalizarConCodigo(String rawCode) {
    final clean = rawCode.trim();
    if (_procesado || clean.isEmpty) return;
    _procesado = true;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(clean);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final alturaSheet = media.size.height * 0.75;

    return Container(
      height: alturaSheet,
      decoration: const BoxDecoration(
        color: PantryColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Barra superior de arrastre
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: PantryColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Encabezado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: PantryColors.green,
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Escanear código de barras',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PantryColors.ink,
                    ),
                  ),
                ),
                // Botón linterna
                IconButton(
                  key: const Key('btn_toggle_torch'),
                  icon: Icon(
                    _torchEncendido
                        ? Icons.flash_on_rounded
                        : Icons.flash_off_rounded,
                    color: _torchEncendido
                        ? PantryColors.amber
                        : PantryColors.muted,
                  ),
                  tooltip: 'Linterna',
                  onPressed: () async {
                    await _controller.toggleTorch();
                    setState(() => _torchEncendido = !_torchEncendido);
                  },
                ),
                // Botón cambiar cámara
                IconButton(
                  key: const Key('btn_switch_camera'),
                  icon: const Icon(
                    Icons.cameraswitch_outlined,
                    color: PantryColors.muted,
                  ),
                  tooltip: 'Cambiar cámara',
                  onPressed: () => _controller.switchCamera(),
                ),
                // Botón cerrar
                IconButton(
                  key: const Key('btn_cerrar_escaner'),
                  icon: const Icon(Icons.close_rounded, color: PantryColors.ink),
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 16, color: PantryColors.border),

          // Área de escaneo o entrada manual
          Expanded(
            child: _mostrarEntradaManual
                ? _buildEntradaManual()
                : _buildVisorCamara(),
          ),

          // Pie con opción de entrada manual
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              12 + media.viewInsets.bottom,
            ),
            child: TextButton.icon(
              key: const Key('btn_toggle_modo_manual'),
              onPressed: () {
                setState(() => _mostrarEntradaManual = !_mostrarEntradaManual);
              },
              icon: Icon(
                _mostrarEntradaManual
                    ? Icons.camera_alt_outlined
                    : Icons.keyboard_outlined,
                size: 18,
                color: PantryColors.green,
              ),
              label: Text(
                _mostrarEntradaManual
                    ? 'Regresar a la cámara'
                    : 'Ingresar código manualmente',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: PantryColors.green,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisorCamara() {
    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: widget.autoStartCamera
                    ? MobileScanner(
                        controller: _controller,
                        onDetect: (capture) {
                          for (final barcode in capture.barcodes) {
                            final val = barcode.rawValue;
                            if (val != null && val.isNotEmpty) {
                              _finalizarConCodigo(val);
                              break;
                            }
                          }
                        },
                        errorBuilder: (context, error) {
                          return Container(
                            color: PantryColors.border,
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.videocam_off_outlined,
                                    size: 40,
                                    color: PantryColors.muted,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No se pudo acceder a la cámara:\n${error.errorDetails?.message ?? error.errorCode.name}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: PantryColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.black87,
                        child: const Center(
                          child: Icon(
                            Icons.qr_code_scanner,
                            color: PantryColors.green,
                            size: 50,
                          ),
                        ),
                      ),
              ),
            ),
          ),
        ),

        // Marco y guía visual
        IgnorePointer(
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: PantryColors.green, width: 2.5),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        // Texto de ayuda
        Positioned(
          bottom: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Apunta al código de barras del empaque',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEntradaManual() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pin_outlined,
            size: 44,
            color: PantryColors.green,
          ),
          const SizedBox(height: 12),
          const Text(
            'Ingresa el número del código de barras',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: PantryColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Lo encuentras impreso debajo de las barras en el empaque.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: PantryColors.muted,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('input_codigo_manual'),
            controller: _manualController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ej. 7501020512100',
              prefixIcon: const Icon(
                Icons.barcode_reader,
                color: PantryColors.green,
              ),
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
                borderSide: const BorderSide(color: PantryColors.green, width: 1.5),
              ),
            ),
            onSubmitted: _finalizarConCodigo,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            key: const Key('btn_confirmar_codigo_manual'),
            onPressed: () => _finalizarConCodigo(_manualController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: PantryColors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Aceptar código',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
