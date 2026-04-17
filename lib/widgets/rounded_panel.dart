import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class RoundedPanel extends StatelessWidget {
  final Widget child;
  const RoundedPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: CustomPaint(
              foregroundPainter: const _NoisePainter(),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.03),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: Offset.zero,
                      blurStyle: BlurStyle.inner,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NoisePainter extends CustomPainter {
  const _NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(1337);
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.015)
      ..strokeWidth = 1.0;
    final points = <Offset>[];
    for (int i = 0; i < 2000; i++) {
      points.add(
        Offset(rand.nextDouble() * size.width, rand.nextDouble() * size.height),
      );
    }
    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
