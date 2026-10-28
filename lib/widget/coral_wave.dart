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

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;

        return SizedBox(
          width: w,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(w, height),
                painter: _CoralWavePainter(
                  fillColor: fillColor,
                  strokeColor: AppColors.brandCoral,
                ),
              ),
              Container(
                height: height,
                width: w,
                padding: const EdgeInsets.only(top: 36),
                child: child,
              ),
            ],
          ),
        );
      },
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
    final w = (size.width.isFinite && size.width > 0) ? size.width : 390.0;
    final h = (size.height.isFinite && size.height > 0) ? size.height : 400.0;

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
    path.lineTo(w, h + 100);
    path.lineTo(0, h + 100);
    path.close();

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _CoralWavePainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeColor != strokeColor;
  }
}
