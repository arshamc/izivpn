import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CyberArcSpeedometer extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final double speedMbps;
  final double size;

  const CyberArcSpeedometer({
    super.key,
    required this.progress,
    required this.speedMbps,
    this.size = 280,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CyberArcPainter(progress: progress),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                speedMbps.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  color: AppColors.headingText(context),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Mbps',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.headingText(context).withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CyberArcPainter extends CustomPainter {
  final double progress;

  _CyberArcPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    const startAngle = 140 * pi / 180;
    const sweepTotalAngle = 260 * pi / 180;
    final currentSweep = sweepTotalAngle * progress.clamp(0.02, 1.0);

    final rect = Rect.fromCircle(center: center, radius: radius);

    // 1. Background Track Arc
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepTotalAngle, false, trackPaint);

    // 2. Gradient Arc (Coral-Red -> Cyber-Cyan)
    final gradient = const SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepTotalAngle,
      colors: [
        AppColors.brandCoral,
        Color(0xFFFF8E72),
        AppColors.cyberCyan,
      ],
      stops: [0.0, 0.45, 1.0],
    );

    // Glow filter
    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawArc(rect, startAngle, currentSweep, false, glowPaint);

    // Sharp foreground stroke
    final activePaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, currentSweep, false, activePaint);
  }

  @override
  bool shouldRepaint(covariant _CyberArcPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
