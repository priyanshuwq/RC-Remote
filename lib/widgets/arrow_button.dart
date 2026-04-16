import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/colors.dart';

class ArrowButton extends StatelessWidget {
  final String letter;
  final List<List<int>> pattern;
  final bool isActive;
  final bool isTopHalf;
  final bool isHorizontal;
  final VoidCallback onDown;
  final VoidCallback onUp;

  const ArrowButton({
    super.key,
    required this.letter,
    required this.pattern,
    required this.isActive,
    required this.isTopHalf,
    required this.onDown,
    required this.onUp,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        onDown();
      },
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: isActive
            ? BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: DotArrow(pattern: pattern, active: isActive),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                letter,
                style: TextStyle(
                  color: isActive ? AppTheme.accentRed : Colors.white38,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DotArrow extends StatelessWidget {
  final List<List<int>> pattern;
  final bool active;
  const DotArrow({super.key, required this.pattern, required this.active});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DotArrowPainter(pattern, active),
      size: const Size(44, 44),
    );
  }
}

class _DotArrowPainter extends CustomPainter {
  final List<List<int>> pattern;
  final bool active;
  _DotArrowPainter(this.pattern, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    const dotR = 2.8;
    const step = 8.0;
    final paint = Paint()
      ..color = active ? AppTheme.accentRed : Colors.white.withValues(alpha: 0.55);
    for (final pt in pattern) {
      canvas.drawCircle(
        Offset(pt[0] * step + dotR, pt[1] * step + dotR),
        dotR,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotArrowPainter old) => old.active != active;
}
