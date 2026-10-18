import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../components/tema_alacena.dart';

/// Widget desacoplado para seleccionar, visualizar, cambiar y eliminar
/// la fotografía de un producto mediante cámara o galería del dispositivo.
class ProductPhotoSelector extends StatelessWidget {
  const ProductPhotoSelector({
    super.key,
    this.imagePath,
    required this.onImageChanged,
    this.onBeforeCamera,
    this.onClearDraft,
  });

  final String? imagePath;
  final ValueChanged<String?> onImageChanged;
  final Future<void> Function()? onBeforeCamera;
  final Future<void> Function()? onClearDraft;

  bool get _hasValidImage =>
      imagePath != null &&
      imagePath!.trim().isNotEmpty &&
      imagePath != 'assets/images/default_product.png';

  Future<void> _seleccionarImagen(BuildContext context, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (source == ImageSource.camera && onBeforeCamera != null) {
        await onBeforeCamera!();
      }

      final picker = ImagePicker();
      final XFile? imagen = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (imagen == null) {
        await onClearDraft?.call();
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(appDir.path, 'product_images'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }

      final ext = p.extension(imagen.path).isEmpty ? '.jpg' : p.extension(imagen.path);
      final nombreArchivo = 'prod_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destinoPath = p.join(photosDir.path, nombreArchivo);

      await File(imagen.path).copy(destinoPath);
      onImageChanged(destinoPath);
      await onClearDraft?.call();

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Foto seleccionada correctamente'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      await onClearDraft?.call();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: PantryColors.red,
        ),
      );
    }
  }

  void _mostrarOpciones(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: PantryColors.green),
                title: const Text('Tomar fotografía'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarImagen(context, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: PantryColors.green),
                title: const Text('Elegir de la galería'),
                onTap: () {
                  Navigator.pop(ctx);
                  _seleccionarImagen(context, ImageSource.gallery);
                },
              ),
              if (_hasValidImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: PantryColors.red),
                  title: const Text('Quitar foto', style: TextStyle(color: PantryColors.red)),
                  onTap: () {
                    Navigator.pop(ctx);
                    onImageChanged('');
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 140,
        height: 140,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => _mostrarOpciones(context),
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1ECE4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: PantryColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _hasValidImage
                    ? (imagePath!.startsWith('assets/')
                        ? Image.asset(
                            imagePath!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _DefaultPhotoAvatar(),
                          )
                        : Image.file(
                            File(imagePath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const _DefaultPhotoAvatar(),
                          ))
                    : const _DefaultPhotoAvatar(),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton.filled(
                onPressed: () => _mostrarOpciones(context),
                tooltip: _hasValidImage ? 'Cambiar foto' : 'Tomar o elegir foto',
                icon: Icon(
                  _hasValidImage
                      ? Icons.edit_outlined
                      : Icons.add_a_photo_outlined,
                  size: 16,
                ),
              ),
            ),
            if (_hasValidImage)
              Positioned(
                right: 0,
                top: 0,
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: PantryColors.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(28, 28),
                    padding: EdgeInsets.zero,
                  ),
                  onPressed: () => onImageChanged(''),
                  tooltip: 'Quitar foto',
                  icon: const Icon(Icons.close_rounded, size: 14),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DefaultPhotoAvatar extends StatelessWidget {
  const _DefaultPhotoAvatar();

  @override
  Widget build(BuildContext context) {
    return const Column(
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
    );
  }
}
