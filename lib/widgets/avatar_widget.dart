import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/avatar_level.dart';

class AvatarWidget extends StatefulWidget {
  final AvatarLevel level;
  final bool isTimerRunning;
  final double size;

  const AvatarWidget({
    super.key,
    required this.level,
    required this.isTimerRunning,
    this.size = 120,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _swayController;
  late AnimationController _levelUpController;
  late Animation<double> _pulseAnim;
  late Animation<double> _swayAnim;
  late Animation<double> _levelUpAnim;
  AvatarLevel _displayedLevel = AvatarLevel.seed;

  @override
  void initState() {
    super.initState();
    _displayedLevel = widget.level;

    // Pulse glow during timer
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Gentle sway
    _swayController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _swayAnim = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );

    // Level-up pop animation
    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _levelUpAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _levelUpController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isTimerRunning && !oldWidget.isTimerRunning) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isTimerRunning) {
      _pulseController.stop();
      _pulseController.value = 0.7;
    }

    if (widget.level != oldWidget.level) {
      _levelUpController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _displayedLevel = widget.level);
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _swayController.dispose();
    _levelUpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(
          [_pulseController, _swayController, _levelUpController]),
      builder: (context, child) {
        final glowOpacity =
            widget.isTimerRunning ? _pulseAnim.value * 0.6 : 0.0;
        final levelColor = _getLevelColor(_displayedLevel);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow circle behind avatar
              if (widget.isTimerRunning)
                Container(
                  width: widget.size * 0.9,
                  height: widget.size * 0.9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: levelColor.withValues(alpha: glowOpacity),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                ),
              // Plant base circle
              Container(
                width: widget.size * 0.82,
                height: widget.size * 0.82,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      levelColor.withValues(alpha: 0.15),
                      levelColor.withValues(alpha: 0.04),
                    ],
                  ),
                  border: Border.all(
                    color: levelColor.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
              ),
              // Plant drawing
              ScaleTransition(
                scale: _levelUpAnim,
                child: Transform.rotate(
                  angle: _swayAnim.value,
                  child: CustomPaint(
                    size: Size(widget.size * 0.6, widget.size * 0.6),
                    painter: _PlantPainter(
                      level: _displayedLevel,
                      color: levelColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Color _getLevelColor(AvatarLevel level) {
    switch (level) {
      case AvatarLevel.seed:
        return const Color(0xFFB8860B); // dark gold
      case AvatarLevel.sprout:
        return const Color(0xFF5DBB63); // fresh green
      case AvatarLevel.plant:
        return const Color(0xFF2E8B57); // sea green
      case AvatarLevel.tree:
        return const Color(0xFF228B22); // forest green
      case AvatarLevel.bigTree:
        return const Color(0xFF1A6B1A); // deep forest
      case AvatarLevel.bloom:
        return const Color(0xFFFF69B4); // hot pink bloom
    }
  }
}

class _PlantPainter extends CustomPainter {
  final AvatarLevel level;
  final Color color;

  _PlantPainter({required this.level, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    switch (level) {
      case AvatarLevel.seed:
        _drawSeed(canvas, size, cx, cy);
        break;
      case AvatarLevel.sprout:
        _drawSprout(canvas, size, cx, cy);
        break;
      case AvatarLevel.plant:
        _drawPlant(canvas, size, cx, cy);
        break;
      case AvatarLevel.tree:
        _drawTree(canvas, size, cx, cy);
        break;
      case AvatarLevel.bigTree:
        _drawBigTree(canvas, size, cx, cy);
        break;
      case AvatarLevel.bloom:
        _drawBloom(canvas, size, cx, cy);
        break;
    }
  }

  Paint _fill(Color c) => Paint()
    ..color = c
    ..style = PaintingStyle.fill;

  Paint _stroke(Color c, double width) => Paint()
    ..color = c
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round;

  // 🌱 Level 0: Zaadje
  void _drawSeed(Canvas canvas, Size size, double cx, double cy) {
    final soil = _fill(const Color(0xFF6B4226));
    // Soil mound
    final soilPath = Path()
      ..moveTo(cx - size.width * 0.38, cy + size.height * 0.35)
      ..quadraticBezierTo(
          cx, cy + size.height * 0.15, cx + size.width * 0.38, cy + size.height * 0.35)
      ..close();
    canvas.drawPath(soilPath, soil);

    // Seed bump peeking out
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.1),
          width: size.width * 0.28,
          height: size.height * 0.2),
      _fill(color),
    );

    // Tiny sprout line
    final stemPaint = _stroke(const Color(0xFF5DBB63), size.width * 0.055);
    canvas.drawLine(
      Offset(cx, cy + size.height * 0.05),
      Offset(cx, cy - size.height * 0.12),
      stemPaint,
    );

    // Tiny leaf bud
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + size.width * 0.1, cy - size.height * 0.14),
          width: size.width * 0.15,
          height: size.height * 0.1),
      _fill(const Color(0xFF5DBB63)),
    );
  }

  // 🌿 Level 1: Spruit
  void _drawSprout(Canvas canvas, Size size, double cx, double cy) {
    final soilColor = const Color(0xFF6B4226);
    // Soil pot
    final potPath = Path()
      ..moveTo(cx - size.width * 0.3, cy + size.height * 0.15)
      ..lineTo(cx - size.width * 0.22, cy + size.height * 0.42)
      ..lineTo(cx + size.width * 0.22, cy + size.height * 0.42)
      ..lineTo(cx + size.width * 0.3, cy + size.height * 0.15)
      ..close();
    canvas.drawPath(potPath, _fill(const Color(0xFFE07B39)));
    // Pot rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - size.width * 0.32, cy + size.height * 0.1,
            size.width * 0.64, size.height * 0.08),
        const Radius.circular(4),
      ),
      _fill(const Color(0xFFC4652A)),
    );
    // Soil top
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.14),
          width: size.width * 0.54,
          height: size.height * 0.1),
      _fill(soilColor),
    );

    // Stem
    canvas.drawLine(
      Offset(cx, cy + size.height * 0.1),
      Offset(cx, cy - size.height * 0.22),
      _stroke(color, size.width * 0.06),
    );

    // Two leaves
    _drawLeaf(canvas, Offset(cx, cy - size.height * 0.08),
        size.width * 0.22, -math.pi / 4, color);
    _drawLeaf(canvas, Offset(cx, cy - size.height * 0.08),
        size.width * 0.22, math.pi + math.pi / 4, color);
  }

  // 🪴 Level 2: Plantje
  void _drawPlant(Canvas canvas, Size size, double cx, double cy) {
    _drawPot(canvas, size, cx, cy);

    // Taller stem
    canvas.drawLine(
      Offset(cx, cy + size.height * 0.1),
      Offset(cx, cy - size.height * 0.35),
      _stroke(color, size.width * 0.055),
    );
    // Branch left
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.1),
      Offset(cx - size.width * 0.2, cy - size.height * 0.25),
      _stroke(color, size.width * 0.045),
    );
    // Branch right
    canvas.drawLine(
      Offset(cx, cy - size.height * 0.18),
      Offset(cx + size.width * 0.2, cy - size.height * 0.3),
      _stroke(color, size.width * 0.045),
    );
    // Leaves
    _drawLeaf(canvas, Offset(cx - size.width * 0.2, cy - size.height * 0.25),
        size.width * 0.25, -math.pi / 3, color);
    _drawLeaf(canvas, Offset(cx + size.width * 0.2, cy - size.height * 0.3),
        size.width * 0.25, math.pi / 5, color);
    _drawLeaf(canvas, Offset(cx, cy - size.height * 0.35),
        size.width * 0.2, -math.pi / 2, color);
  }

  // 🌳 Level 3: Jonge Boom
  void _drawTree(Canvas canvas, Size size, double cx, double cy) {
    // Trunk
    final trunkPaint = _fill(const Color(0xFF8B5E3C));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - size.width * 0.07, cy,
            size.width * 0.14, size.height * 0.4),
        const Radius.circular(4),
      ),
      trunkPaint,
    );

    // Foliage circles - layered
    canvas.drawCircle(Offset(cx, cy - size.height * 0.05),
        size.width * 0.35, _fill(color.withValues(alpha: 0.7)));
    canvas.drawCircle(Offset(cx - size.width * 0.15, cy - size.height * 0.12),
        size.width * 0.26, _fill(color));
    canvas.drawCircle(Offset(cx + size.width * 0.15, cy - size.height * 0.15),
        size.width * 0.26, _fill(color));
    canvas.drawCircle(Offset(cx, cy - size.height * 0.3),
        size.width * 0.28, _fill(color.withValues(alpha: 0.9)));
  }

  // 🌲 Level 4: Grote Boom
  void _drawBigTree(Canvas canvas, Size size, double cx, double cy) {
    // Trunk
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - size.width * 0.085, cy,
            size.width * 0.17, size.height * 0.45),
        const Radius.circular(5),
      ),
      _fill(const Color(0xFF6B4226)),
    );
    // Roots
    canvas.drawLine(
      Offset(cx - size.width * 0.085, cy + size.height * 0.38),
      Offset(cx - size.width * 0.3, cy + size.height * 0.45),
      _stroke(const Color(0xFF6B4226), size.width * 0.05),
    );
    canvas.drawLine(
      Offset(cx + size.width * 0.085, cy + size.height * 0.38),
      Offset(cx + size.width * 0.3, cy + size.height * 0.45),
      _stroke(const Color(0xFF6B4226), size.width * 0.05),
    );

    // Big layered canopy - pine tree style
    final darkColor = color.withValues(alpha: 0.8);
    _drawTriangle(canvas, Offset(cx, cy - size.height * 0.42),
        size.width * 0.72, size.height * 0.3, color);
    _drawTriangle(canvas, Offset(cx, cy - size.height * 0.25),
        size.width * 0.82, size.height * 0.32, darkColor);
    _drawTriangle(canvas, Offset(cx, cy - size.height * 0.05),
        size.width * 0.9, size.height * 0.3, color);
  }

  // ✨ Level 5: Bloem
  void _drawBloom(Canvas canvas, Size size, double cx, double cy) {
    // Stem
    canvas.drawLine(
      Offset(cx, cy + size.height * 0.42),
      Offset(cx, cy - size.height * 0.05),
      _stroke(const Color(0xFF2E8B57), size.width * 0.06),
    );
    // Two leaves on stem
    _drawLeaf(canvas, Offset(cx, cy + size.height * 0.15),
        size.width * 0.22, -math.pi / 4, const Color(0xFF2E8B57));
    _drawLeaf(canvas, Offset(cx, cy + size.height * 0.05),
        size.width * 0.22, math.pi + math.pi / 4, const Color(0xFF2E8B57));

    // Flower petals
    final petalColor = const Color(0xFFFF69B4);
    const petalCount = 8;
    for (int i = 0; i < petalCount; i++) {
      final angle = (i / petalCount) * 2 * math.pi;
      final px = cx + math.cos(angle) * size.width * 0.22;
      final py = cy - size.height * 0.2 + math.sin(angle) * size.height * 0.22;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, py),
          width: size.width * 0.22,
          height: size.height * 0.14,
        ),
        _fill(i.isEven
            ? petalColor
            : const Color(0xFFFF85C2)),
      );
    }
    // Center of flower
    canvas.drawCircle(
      Offset(cx, cy - size.height * 0.2),
      size.width * 0.12,
      _fill(const Color(0xFFFFD700)),
    );
    // Sparkles
    _drawSparkle(canvas, Offset(cx - size.width * 0.38, cy - size.height * 0.38),
        size.width * 0.07, const Color(0xFFFFD700));
    _drawSparkle(canvas, Offset(cx + size.width * 0.35, cy - size.height * 0.42),
        size.width * 0.055, const Color(0xFFFF69B4));
    _drawSparkle(canvas, Offset(cx + size.width * 0.42, cy - size.height * 0.08),
        size.width * 0.06, const Color(0xFFFFD700));
  }

  void _drawPot(Canvas canvas, Size size, double cx, double cy) {
    final potPath = Path()
      ..moveTo(cx - size.width * 0.28, cy + size.height * 0.12)
      ..lineTo(cx - size.width * 0.2, cy + size.height * 0.42)
      ..lineTo(cx + size.width * 0.2, cy + size.height * 0.42)
      ..lineTo(cx + size.width * 0.28, cy + size.height * 0.12)
      ..close();
    canvas.drawPath(potPath, _fill(const Color(0xFFE07B39)));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - size.width * 0.3, cy + size.height * 0.08,
            size.width * 0.6, size.height * 0.08),
        const Radius.circular(4),
      ),
      _fill(const Color(0xFFC4652A)),
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy + size.height * 0.12),
          width: size.width * 0.5,
          height: size.height * 0.09),
      _fill(const Color(0xFF6B4226)),
    );
  }

  void _drawLeaf(Canvas canvas, Offset base, double leafSize,
      double angle, Color leafColor) {
    final path = Path();
    final tip = Offset(
      base.dx + math.cos(angle) * leafSize,
      base.dy + math.sin(angle) * leafSize,
    );
    final control = Offset(
      (base.dx + tip.dx) / 2 + math.cos(angle + math.pi / 2) * leafSize * 0.35,
      (base.dy + tip.dy) / 2 + math.sin(angle + math.pi / 2) * leafSize * 0.35,
    );
    path.moveTo(base.dx, base.dy);
    path.quadraticBezierTo(control.dx, control.dy, tip.dx, tip.dy);
    path.quadraticBezierTo(base.dx, base.dy, base.dx, base.dy);
    canvas.drawPath(path, _fill(leafColor));
  }

  void _drawTriangle(
      Canvas canvas, Offset tip, double width, double height, Color c) {
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - width / 2, tip.dy + height)
      ..lineTo(tip.dx + width / 2, tip.dy + height)
      ..close();
    canvas.drawPath(path, _fill(c));
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color c) {
    final paint = _stroke(c, size * 0.3);
    canvas.drawLine(
        Offset(center.dx - size, center.dy),
        Offset(center.dx + size, center.dy),
        paint);
    canvas.drawLine(
        Offset(center.dx, center.dy - size),
        Offset(center.dx, center.dy + size),
        paint);
    final diagSize = size * 0.65;
    canvas.drawLine(
        Offset(center.dx - diagSize, center.dy - diagSize),
        Offset(center.dx + diagSize, center.dy + diagSize),
        paint);
    canvas.drawLine(
        Offset(center.dx + diagSize, center.dy - diagSize),
        Offset(center.dx - diagSize, center.dy + diagSize),
        paint);
  }

  @override
  bool shouldRepaint(_PlantPainter oldDelegate) =>
      oldDelegate.level != level || oldDelegate.color != color;
}
