import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class FlightArcOverlay extends StatefulWidget {
  final bool isConnecting;
  final String? targetCountry;

  const FlightArcOverlay({
    super.key,
    required this.isConnecting,
    this.targetCountry,
  });

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
      duration: const Duration(milliseconds: 2400),
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
      _controller.reset();
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
          painter: _FlightArcPainter(
            progress: _controller.value,
          ),
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

    // Origin (Your Location) and Target (VPN Server) in upper atmosphere
    final p0 = Offset(w * 0.16, h * 0.32);
    final p2 = Offset(w * 0.84, h * 0.28);
    final p1 = Offset(w * 0.50, h * 0.10); // Apex of arc above horizon

    // 1. Draw glowing pulsed beacon rings around origin & destination
    _drawBeacon(canvas, p0, AppColors.statusGreen, progress, 'HOME');
    _drawBeacon(canvas, p2, AppColors.brandCoral, (progress + 0.5) % 1.0, 'SERVER');

    // 2. Trajectory Arc Path
    final arcPath = Path();
    arcPath.moveTo(p0.dx, p0.dy);
    arcPath.quadraticBezierTo(p1.dx, p1.dy, p2.dx, p2.dy);

    // Faint full flight corridor
    final corridorPaint = Paint()
      ..color = Colors.white.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(arcPath, corridorPaint);

    // Glowing Neon Trajectory
    final glowPaint = Paint()
      ..color = AppColors.brandCoral.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(arcPath, glowPaint);

    // 3. Compute current airplane position along the quadratic Bézier curve
    final t = progress;
    final u = 1 - t;
    final currentX = u * u * p0.dx + 2 * u * t * p1.dx + t * t * p2.dx;
    final currentY = u * u * p0.dy + 2 * u * t * p1.dy + t * t * p2.dy;

    // Tangent angle for plane heading
    final dx = 2 * u * (p1.dx - p0.dx) + 2 * t * (p2.dx - p1.dx);
    final dy = 2 * u * (p1.dy - p0.dy) + 2 * t * (p2.dy - p1.dy);
    final angle = atan2(dy, dx);

    // 4. Draw Jet Trail (Glowing Comet Tail behind plane)
    final tailLength = 0.22;
    if (t > 0.02) {
      final tailStartT = max(0.0, t - tailLength);
      final tailSteps = 12;
      for (int i = 0; i < tailSteps; i++) {
        final stepT = tailStartT + (t - tailStartT) * (i / tailSteps);
        final stepU = 1 - stepT;
        final sx = stepU * stepU * p0.dx + 2 * stepU * stepT * p1.dx + stepT * stepT * p2.dx;
        final sy = stepU * stepU * p0.dy + 2 * stepU * stepT * p1.dy + stepT * stepT * p2.dy;
        final alpha = (i / tailSteps) * 0.75;

        final particlePaint = Paint()
          ..color = AppColors.brandCoral.withOpacity(alpha)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(Offset(sx, sy), 2.0 + (i / tailSteps) * 2.5, particlePaint);
      }
    }

    // 5. Draw Modern Supersonic Jet Airplane at (currentX, currentY)
    canvas.save();
    canvas.translate(currentX, currentY);
    canvas.rotate(angle);

    // Jet Aura Glow
    final auraPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset.zero, 12, auraPaint);

    // Airplane Body Shape (Scale ~2.5x larger for high visibility)
    final planeBody = Path();
    planeBody.moveTo(22, 0);          // Nose tip
    planeBody.lineTo(-14, -14);       // Left wingtip
    planeBody.lineTo(-8, -4);         // Left wing inner
    planeBody.lineTo(-18, -4);        // Left tail fin
    planeBody.lineTo(-14, 0);         // Engine nozzle
    planeBody.lineTo(-18, 4);         // Right tail fin
    planeBody.lineTo(-8, 4);          // Right wing inner
    planeBody.lineTo(-14, 14);        // Right wingtip
    planeBody.close();

    // Jet Thruster Fire / Afterburner
    final thrusterPaint = Paint()
      ..color = AppColors.cyberCyan
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final thrusterPath = Path();
    thrusterPath.moveTo(-14, -3);
    thrusterPath.lineTo(-26 - (sin(progress * 24) * 4), 0);
    thrusterPath.lineTo(-14, 3);
    thrusterPath.close();
    canvas.drawPath(thrusterPath, thrusterPaint);

    // Jet Fuselage Fill (Crisp White with Cyber Cyan Wing Accent)
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(planeBody, bodyPaint);

    // Center Cockpit Stripe
    final cockpitPaint = Paint()
      ..color = AppColors.brandCoral
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(-4, 0), const Offset(16, 0), cockpitPaint);

    canvas.restore();
  }

  void _drawBeacon(Canvas canvas, Offset center, Color color, double phase, String label) {
    // Pulsing outer ripple
    final rippleRadius = 6.0 + phase * 18.0;
    final rippleOpacity = max(0.0, (1.0 - phase) * 0.7);
    final ripplePaint = Paint()
      ..color = color.withOpacity(rippleOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, rippleRadius, ripplePaint);

    // Solid Beacon Core
    final corePaint = Paint()..color = color;
    canvas.drawCircle(center, 5.5, corePaint);

    final whiteCenter = Paint()..color = Colors.white;
    canvas.drawCircle(center, 2.5, whiteCenter);
  }

  @override
  bool shouldRepaint(covariant _FlightArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
