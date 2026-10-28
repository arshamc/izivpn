import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CoralWaveWidget extends StatelessWidget {
  final double height;
  final Widget? child;

  const CoralWaveWidget({
    super.key,
    required this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? AppColors.obsidianFogBottom : AppColors.pureFogBottom;

    return CustomPaint(
      size: Size(double.infinity, height),
      painter: _CoralWavePainter(
        fillColor: fillColor,
        strokeColor: AppColors.brandCoral,
      ),
      child: Container(
        height: height,
        width: double.infinity,
        padding: const EdgeInsets.only(top: 36),
        child: child,
      ),
    );
  }
}

class _CoralWavePainter extends CustomPainter {
  final Color fillColor;
  final Color strokeColor;

  _CoralWavePainter({
    required this.fillColor,
    required this.strokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // Start at left wave crest/dip
    path.moveTo(0, 35);

    // Dynamic elegant bezier curve across screen
    path.cubicTo(
      w * 0.18, 55, // first dip
      w * 0.32, -15, // first crest
      w * 0.52, 28, // middle inflection
    );
    path.cubicTo(
      w * 0.70, 65, // second dip
      w * 0.88, -8, // second rise
      w, 20, // right edge
    );

    // Draw the coral wave stroke
    canvas.drawPath(path, strokePaint);

    // Complete the path down to the bottom edges for solid fog fill
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _CoralWavePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
