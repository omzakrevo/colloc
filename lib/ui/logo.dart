import 'package:flutter/material.dart';

/// Logo Colloc (même géométrie que brand/logo.svg, viewBox 512) : une maison, deux colocataires.
/// Animé à l'apparition : la maison se pose, puis les deux personnes apparaissent.
class ColocLogo extends StatefulWidget {
  const ColocLogo({super.key, this.size = 48, this.animated = true});
  final double size;
  final bool animated;

  @override
  State<ColocLogo> createState() => _ColocLogoState();
}

class _ColocLogoState extends State<ColocLogo>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.animated ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, _) => CustomPaint(
      size: Size.square(widget.size),
      painter: _LogoPainter(_c.value),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter(this.t);
  final double t;

  double _seg(double a, double b, Curve c) =>
      c.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 512;
    canvas.save();
    canvas.scale(s);

    final bg = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 512, 512),
      const Radius.circular(112),
    );
    canvas.drawRRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B5E57), Color(0xFF14B8A6), Color(0xFF5EEAD4)],
          stops: [0, .55, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 512, 512)),
    );

    // maison : arrive du haut avec un petit rebond
    final h = _seg(0, .55, Curves.easeOutBack);
    canvas.save();
    canvas.translate(0, (1 - h) * -60);
    final house = Path()
      ..moveTo(256, 108)
      ..lineTo(408, 236)
      ..lineTo(408, 388)
      ..arcToPoint(const Offset(380, 416), radius: const Radius.circular(28))
      ..lineTo(132, 416)
      ..arcToPoint(const Offset(104, 388), radius: const Radius.circular(28))
      ..lineTo(104, 236)
      ..close();
    final white = Paint()
      ..color = Colors.white.withValues(alpha: h.clamp(0.0, 1.0));
    canvas.drawPath(house, white);
    canvas.drawPath(
      house,
      white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    void person(double cx, Color color, double k) {
      if (k <= 0) return;
      canvas.save();
      canvas.translate(cx, 378);
      canvas.scale(k);
      canvas.translate(-cx, -378);
      final p = Paint()..color = color;
      canvas.drawCircle(Offset(cx, 290), 30, p);
      canvas.drawPath(
        Path()
          ..moveTo(cx - 46, 378)
          ..arcToPoint(Offset(cx + 46, 378), radius: const Radius.circular(46))
          ..close(),
        p,
      );
      canvas.restore();
    }

    person(214, const Color(0xFF0F766E), _seg(.35, .75, Curves.elasticOut));
    person(298, const Color(0xFFF97316), _seg(.5, .95, Curves.elasticOut));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.t != t;
}
