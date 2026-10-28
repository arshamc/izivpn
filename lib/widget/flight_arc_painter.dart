import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FlightArcOverlay extends StatefulWidget {
  final bool isConnecting;

  const FlightArcOverlay({super.key, required this.isConnecting});

  @override
  State<FlightArcOverlay> createState() => _FlightArcOverlayState();
}

class _FlightArcOverlayState extends State<FlightArcOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    if (widget.isConnecting) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FlightArcOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnecting && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isConnecting && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isConnecting) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size.infinite,
          painter: _FlightArcPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _FlightArcPainter extends CustomPainter {
  final double progress;

  _FlightArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Origin and destination over the globe area
    final p0 = Offset(w * 0.22, h * 0.38); // Origin (left globe pin)
    final p2 = Offset(w * 0.76, h * 0.36); // Target (right globe pin)
    final p1 = Offset(w * 0.49, h * 0.16); // Arc zenith (control point above globe)

    final glowPaint = Paint()
      ..color = AppColors.brandCoral.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final linePaint = Paint()
      ..color = AppColors.brandCoral
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fullPath = Path();
    fullPath.moveTo(p0.dx, p0.dy);
    fullPath.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

    // Draw full trajectory faint trace
    canvas.drawPath(fullPath, glowPaint);
    canvas.drawPath(fullPath, linePaint);

    // Compute airplane current position along quadratic curve
    final t = progress;
    final u = 1 - t;
    final currentX = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final currentY = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;

    // Tangent angle for plane orientation
    final dx = 2 * u * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx);
    final dy = 2 * u * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy);
    final angle = atan2(dy, dx);

    // Draw origin and target beacon pins
    final pinPaint = Paint()..color = AppColors.brandCoral;
    canvas.drawCircle(p0, 4.5, pinPaint);
    canvas.drawCircle(p2, 4.5, pinPaint);

    // Draw airplane at (currentX, currentY)
    canvas.save();
    canvas.translate(currentX, currentY);
    canvas.rotate(angle);

    final planePaint = Paint()..color = Colors.white;
    final planeGlow = Paint()
      ..color = AppColors.cyberCyan.withOpacity(0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Sleek paper plane shape
    final planePath = Path();
    planePath.moveTo(12, 0);
    planePath.lineTo(-8, -6);
    planePath.lineTo(-4, 0);
    planePath.lineTo(-8, 6);
    planePath.close();

    canvas.drawPath(planePath, planeGlow);
    canvas.drawPath(planePath, planePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FlightArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
