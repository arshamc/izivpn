import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class CircularFlagWidget extends StatelessWidget {
  final String flagCode;
  final double size;
  final bool isSelected;
  final bool showOuterRing;

  const CircularFlagWidget({
    super.key,
    required this.flagCode,
    this.size = 36,
    this.isSelected = false,
    this.showOuterRing = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget flagWidget = ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _FlagPainter(code: flagCode.toLowerCase()),
        ),
      ),
    );

    if (!showOuterRing) return flagWidget;

    // Outer tactile frosted ring
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size + 10,
      height: size + 10,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: isSelected ? AppColors.brandCoral : const Color(0xFFEEF2F6),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.brandCoral.withOpacity(0.35)
                : Colors.black.withOpacity(0.06),
            blurRadius: isSelected ? 12 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(child: flagWidget),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final String code;

  _FlagPainter({required this.code});

  @override
  void paint(Canvas canvas, Size size) {
    switch (code) {
      case 'us':
        _paintUS(canvas, size);
        break;
      case 'fr':
        _paintFR(canvas, size);
        break;
      case 'gb':
      case 'uk':
        _paintGB(canvas, size);
        break;
      case 'de':
        _paintDE(canvas, size);
        break;
      case 'nl':
        _paintNL(canvas, size);
        break;
      case 'tr':
        _paintTR(canvas, size);
        break;
      default:
        _paintGlobal(canvas, size);
        break;
    }
  }

  void _paintUS(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Stripes
    final redPaint = Paint()..color = const Color(0xFFB22234);
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), whitePaint);

    final stripeHeight = h / 7;
    for (int i = 0; i < 7; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, i * stripeHeight, w, stripeHeight), redPaint);
    }

    // Blue Canton
    final bluePaint = Paint()..color = const Color(0xFF3C3B6E);
    canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.48, h * 0.58), bluePaint);

    // Mini stars dot
    final starPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.24, h * 0.29), 2.2, starPaint);
    canvas.drawCircle(Offset(w * 0.14, h * 0.18), 1.6, starPaint);
    canvas.drawCircle(Offset(w * 0.34, h * 0.18), 1.6, starPaint);
    canvas.drawCircle(Offset(w * 0.14, h * 0.40), 1.6, starPaint);
    canvas.drawCircle(Offset(w * 0.34, h * 0.40), 1.6, starPaint);
  }

  void _paintFR(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final third = w / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, third, h), Paint()..color = const Color(0xFF002654));
    canvas.drawRect(Rect.fromLTWH(third, 0, third, h), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(third * 2, 0, third, h), Paint()..color = const Color(0xFFCE1126));
  }

  void _paintGB(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Blue background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF012169));

    // White diagonals
    final whiteDiag = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.22;
    canvas.drawLine(const Offset(0, 0), Offset(w, h), whiteDiag);
    canvas.drawLine(Offset(0, h), Offset(w, 0), whiteDiag);

    // Red diagonals
    final redDiag = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = w * 0.10;
    canvas.drawLine(const Offset(0, 0), Offset(w, h), redDiag);
    canvas.drawLine(Offset(0, h), Offset(w, 0), redDiag);

    // White cross
    canvas.drawRect(Rect.fromLTWH(w * 0.38, 0, w * 0.24, h), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.38, w, h * 0.24), Paint()..color = Colors.white);

    // Red cross
    canvas.drawRect(Rect.fromLTWH(w * 0.43, 0, w * 0.14, h), Paint()..color = const Color(0xFFC8102E));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.43, w, h * 0.14), Paint()..color = const Color(0xFFC8102E));
  }

  void _paintDE(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final third = h / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, third), Paint()..color = const Color(0xFF000000));
    canvas.drawRect(Rect.fromLTWH(0, third, w, third), Paint()..color = const Color(0xFFDD0000));
    canvas.drawRect(Rect.fromLTWH(0, third * 2, w, third), Paint()..color = const Color(0xFFFFCC00));
  }

  void _paintNL(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final third = h / 3;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, third), Paint()..color = const Color(0xFFAE1C28));
    canvas.drawRect(Rect.fromLTWH(0, third, w, third), Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(0, third * 2, w, third), Paint()..color = const Color(0xFF21468B));
  }

  void _paintTR(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Red field
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFE30A17));

    // White outer crescent circle
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.42, h * 0.5), w * 0.26, whitePaint);

    // Inner red cutout
    final redCut = Paint()..color = const Color(0xFFE30A17);
    canvas.drawCircle(Offset(w * 0.48, h * 0.5), w * 0.20, redCut);

    // Star
    canvas.drawCircle(Offset(w * 0.70, h * 0.5), w * 0.08, whitePaint);
  }

  void _paintGlobal(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF1E293B));
    final cyanPaint = Paint()
      ..color = AppColors.cyberCyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.35, cyanPaint);
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), cyanPaint);
    canvas.drawLine(Offset(w * 0.5, 0), Offset(w * 0.5, h), cyanPaint);
  }

  @override
  bool shouldRepaint(covariant _FlagPainter oldDelegate) => oldDelegate.code != code;
}
