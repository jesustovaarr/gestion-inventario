import 'package:flutter/material.dart';

/// Illustrations used while a product does not have a local photograph.
enum ProductThumbnailKind { milk, yogurt, tuna, rice, oil }

/// A local product photograph with a self-contained illustrated fallback.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    super.key,
    required this.kind,
    this.imagePath,
    this.size = 68,
  });

  final ProductThumbnailKind kind;
  final String? imagePath;
  final double size;

  String get _label => switch (kind) {
    ProductThumbnailKind.milk => 'Envase de leche',
    ProductThumbnailKind.yogurt => 'Tarro de yogurt',
    ProductThumbnailKind.tuna => 'Lata de atún',
    ProductThumbnailKind.rice => 'Frasco de arroz',
    ProductThumbnailKind.oil => 'Botella de aceite de oliva',
  };

  Widget get _illustration => CustomPaint(
    painter: _ProductIllustrationPainter(kind),
    size: Size.square(size),
  );

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: _label,
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox.square(
            dimension: size,
            child: imagePath == null
                ? _illustration
                : Image.asset(
                    imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _illustration,
                  ),
          ),
        ),
      ),
    );
  }
}

class _ProductIllustrationPainter extends CustomPainter {
  const _ProductIllustrationPainter(this.kind);

  final ProductThumbnailKind kind;

  static const _cream = Color(0xFFF5EEDB);
  static const _forest = Color(0xFF284C38);
  static const _ink = Color(0xFF344338);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    _paintBackdrop(canvas);
    switch (kind) {
      case ProductThumbnailKind.milk:
        _paintMilk(canvas);
      case ProductThumbnailKind.yogurt:
        _paintYogurt(canvas);
      case ProductThumbnailKind.tuna:
        _paintTuna(canvas);
      case ProductThumbnailKind.rice:
        _paintRice(canvas);
      case ProductThumbnailKind.oil:
        _paintOil(canvas);
    }
    canvas.restore();
  }

  void _paintBackdrop(Canvas canvas) {
    const rect = Rect.fromLTWH(0, 0, 100, 100);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB3B9A2), Color(0xFFE5DDC8), Color(0xFFF5EBD8)],
        ).createShader(rect),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 75, 100, 25),
      Paint()..color = const Color(0xFFD9C5A2),
    );
    canvas.drawRect(
      const Rect.fromLTWH(0, 74, 100, 1),
      Paint()..color = const Color(0xFFAFA587),
    );
    // Soft cabinet shapes suggest a pantry without relying on remote images.
    _roundRect(
      canvas,
      const Rect.fromLTWH(5, 9, 12, 57),
      3,
      const Color(0x306A765F),
    );
    _roundRect(
      canvas,
      const Rect.fromLTWH(82, 4, 14, 63),
      3,
      const Color(0x20FFFFFF),
    );
    canvas.drawOval(
      const Rect.fromLTWH(15, 81, 73, 12),
      Paint()
        ..color = const Color(0x450F2417)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  void _paintMilk(Canvas canvas) {
    final front = Path()
      ..moveTo(29, 32)
      ..lineTo(41, 19)
      ..lineTo(65, 22)
      ..lineTo(68, 84)
      ..lineTo(30, 87)
      ..close();
    _gradientPath(canvas, front, const Rect.fromLTWH(29, 19, 39, 68), [
      const Color(0xFFFFFEF0),
      const Color(0xFFD6D6BC),
    ]);
    _path(canvas, [
      const Offset(65, 22),
      const Offset(76, 31),
      const Offset(78, 81),
      const Offset(68, 84),
    ], const Color(0xFFA4B39D));
    _path(canvas, [
      const Offset(29, 32),
      const Offset(41, 19),
      const Offset(54, 31),
    ], const Color(0xFFCED4BE));
    _path(canvas, [
      const Offset(41, 19),
      const Offset(65, 22),
      const Offset(54, 31),
    ], const Color(0xFFE9EBD8));
    _roundRect(canvas, const Rect.fromLTWH(32, 41, 33, 37), 2, _forest);
    _text(
      canvas,
      'LECHE',
      const Offset(36, 47),
      8,
      _cream,
      weight: FontWeight.w800,
    );
    _text(
      canvas,
      'ENTERA',
      const Offset(37, 57),
      5,
      _cream,
      weight: FontWeight.w600,
    );
    _text(canvas, '1 L', const Offset(43, 70), 6, _cream);
    canvas.drawCircle(
      const Offset(59, 28),
      5,
      Paint()..color = const Color(0xFFF8F7EA),
    );
    canvas.drawCircle(
      const Offset(59, 28),
      3.5,
      Paint()..color = const Color(0xFFD6DDC8),
    );
    _line(
      canvas,
      const Offset(34, 37),
      const Offset(63, 36),
      const Color(0xFFBAC5AF),
      1,
    );
  }

  void _paintYogurt(Canvas canvas) {
    // A spoon behind the pot makes the silhouette easy to distinguish.
    _line(
      canvas,
      const Offset(70, 24),
      const Offset(58, 61),
      const Color(0xFFA29680),
      3,
    );
    canvas.save();
    canvas.translate(72, 21);
    canvas.rotate(.35);
    canvas.drawOval(
      const Rect.fromLTWH(-4, -8, 8, 16),
      Paint()..color = const Color(0xFFD9D4C7),
    );
    canvas.restore();
    final pot = Path()
      ..moveTo(24, 41)
      ..lineTo(77, 41)
      ..lineTo(70, 84)
      ..quadraticBezierTo(50, 94, 31, 84)
      ..close();
    _gradientPath(canvas, pot, const Rect.fromLTWH(24, 41, 53, 47), [
      const Color(0xFFFDF6DF),
      const Color(0xFFD8CFB8),
    ]);
    _roundRect(
      canvas,
      const Rect.fromLTWH(30, 53, 41, 24),
      4,
      const Color(0xFFECE2C8),
    );
    _text(
      canvas,
      'YOGURT',
      const Offset(34, 57),
      7,
      const Color(0xFF72533B),
      weight: FontWeight.w800,
    );
    _text(canvas, 'natural', const Offset(38, 67), 6, const Color(0xFF72533B));
    canvas.drawOval(
      const Rect.fromLTWH(23, 33, 55, 16),
      Paint()..color = const Color(0xFFA58760),
    );
    canvas.drawOval(
      const Rect.fromLTWH(23, 31, 55, 14),
      Paint()..color = const Color(0xFFD8C4A2),
    );
    canvas.drawOval(
      const Rect.fromLTWH(30, 34, 41, 7),
      Paint()..color = const Color(0xFFF1E3C7),
    );
    _line(
      canvas,
      const Offset(34, 47),
      const Offset(32, 67),
      const Color(0x88FFFFFF),
      2,
    );
  }

  void _paintTuna(Canvas canvas) {
    const body = Rect.fromLTWH(19, 37, 64, 42);
    canvas.drawRect(body, Paint()..color = const Color(0xFF7F8960));
    _gradientPath(canvas, Path()..addRect(body), body, [
      const Color(0xFF516241),
      const Color(0xFF9B9B66),
      const Color(0xFF3F5035),
    ]);
    canvas.drawOval(
      const Rect.fromLTWH(19, 70, 64, 17),
      Paint()..color = const Color(0xFFBCA25D),
    );
    canvas.drawOval(
      const Rect.fromLTWH(19, 66, 64, 17),
      Paint()..color = const Color(0xFF5F6E44),
    );
    _roundRect(
      canvas,
      const Rect.fromLTWH(24, 46, 54, 26),
      3,
      const Color(0xFFEADCAE),
    );
    _text(
      canvas,
      'ATÚN',
      const Offset(35, 49),
      10,
      _forest,
      weight: FontWeight.w800,
    );
    _text(canvas, 'en aceite', const Offset(35, 62), 5, _ink);
    canvas.drawOval(
      const Rect.fromLTWH(19, 29, 64, 18),
      Paint()..color = const Color(0xFFAA985E),
    );
    canvas.drawOval(
      const Rect.fromLTWH(21, 29, 60, 14),
      Paint()..color = const Color(0xFFE4D7A1),
    );
    canvas.drawOval(
      const Rect.fromLTWH(27, 32, 48, 8),
      Paint()
        ..color = const Color(0xFFB6A772)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawOval(
      const Rect.fromLTWH(44, 33, 17, 6),
      Paint()
        ..color = const Color(0xFF8D875F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintRice(Canvas canvas) {
    const jar = Rect.fromLTWH(28, 25, 48, 63);
    _roundRect(canvas, jar, 9, const Color(0xBBDDD9BE));
    _roundRect(
      canvas,
      const Rect.fromLTWH(31, 34, 42, 51),
      7,
      const Color(0xFFD4C393),
    );
    for (var i = 0; i < 58; i++) {
      final x = 34 + ((i * 17) % 35).toDouble();
      final y = 36 + ((i * 13) % 45).toDouble();
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate((i % 7) * .4);
      canvas.drawOval(
        const Rect.fromLTWH(-1, -3, 2.2, 6),
        Paint()..color = i.isEven ? _cream : const Color(0xFFE5D8B8),
      );
      canvas.restore();
    }
    _roundRect(
      canvas,
      const Rect.fromLTWH(26, 19, 52, 12),
      3,
      const Color(0xFF66513A),
    );
    _line(
      canvas,
      const Offset(29, 22),
      const Offset(75, 22),
      const Color(0xFF8A7554),
      1,
    );
    _roundRect(
      canvas,
      const Rect.fromLTWH(31, 49, 42, 24),
      2,
      const Color(0xFFF1E9D4),
    );
    _text(
      canvas,
      'ARROZ',
      const Offset(36, 53),
      8,
      _forest,
      weight: FontWeight.w800,
    );
    _text(canvas, 'grano largo', const Offset(36, 64), 4.5, _ink);
    _line(
      canvas,
      const Offset(32, 33),
      const Offset(32, 47),
      const Color(0xAAFFFFFF),
      2,
    );
  }

  void _paintOil(Canvas canvas) {
    final bottle = Path()
      ..moveTo(43, 24)
      ..lineTo(60, 24)
      ..lineTo(60, 37)
      ..quadraticBezierTo(73, 43, 73, 50)
      ..lineTo(73, 83)
      ..quadraticBezierTo(73, 89, 68, 89)
      ..lineTo(35, 89)
      ..quadraticBezierTo(30, 89, 30, 83)
      ..lineTo(30, 50)
      ..quadraticBezierTo(30, 43, 43, 37)
      ..close();
    _gradientPath(canvas, bottle, const Rect.fromLTWH(30, 24, 43, 65), [
      const Color(0xFF606632),
      const Color(0xFF9D9B45),
      const Color(0xFF3D4E2C),
    ]);
    _roundRect(
      canvas,
      const Rect.fromLTWH(41, 13, 21, 15),
      3,
      const Color(0xFF253A29),
    );
    _line(
      canvas,
      const Offset(44, 17),
      const Offset(59, 17),
      const Color(0xFF596A45),
      1,
    );
    _roundRect(canvas, const Rect.fromLTWH(33, 51, 37, 29), 2, _cream);
    _text(
      canvas,
      'OLIVA',
      const Offset(38, 55),
      8,
      _forest,
      weight: FontWeight.w800,
    );
    _text(canvas, 'extra virgen', const Offset(37, 67), 4.5, _ink);
    _line(
      canvas,
      const Offset(37, 45),
      const Offset(35, 76),
      const Color(0x55FFFFFF),
      2,
    );
    // A small olive branch on the label.
    _line(canvas, const Offset(47, 75), const Offset(56, 72), _forest, .8);
    canvas.drawOval(
      const Rect.fromLTWH(48, 72, 4, 2),
      Paint()..color = const Color(0xFF6B7C47),
    );
    canvas.drawOval(
      const Rect.fromLTWH(53, 74, 4, 2),
      Paint()..color = const Color(0xFF6B7C47),
    );
  }

  void _gradientPath(Canvas canvas, Path path, Rect rect, List<Color> colors) {
    canvas.drawPath(
      path,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  void _path(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  void _roundRect(Canvas canvas, Rect rect, double radius, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(radius)),
      Paint()..color = color,
    );
  }

  void _line(Canvas canvas, Offset from, Offset to, Color color, double width) {
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color
        ..strokeWidth = width,
    );
  }

  void _text(
    Canvas canvas,
    String text,
    Offset offset,
    double size,
    Color color, {
    FontWeight weight = FontWeight.w500,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          color: color,
          fontWeight: weight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    painter.paint(canvas, offset);
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant _ProductIllustrationPainter oldDelegate) {
    return kind != oldDelegate.kind;
  }
}
