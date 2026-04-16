import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

// ── Radar Dot Matrix Animation (Obstacle Avoiding) ────────────────────────────
class RadarDotAnimation extends StatefulWidget {
  final bool isActive;
  const RadarDotAnimation({super.key, required this.isActive});

  @override
  State<RadarDotAnimation> createState() => _RadarDotAnimationState();
}

class _RadarDotAnimationState extends State<RadarDotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isActive) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(RadarDotAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _ctrl.repeat();
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _RadarPainter(_ctrl.value, widget.isActive),
        size: const Size(140, 140),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweep;
  final bool active;
  _RadarPainter(this.sweep, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;

    for (int ring = 1; ring <= 4; ring++) {
      final radius = ring * 16.0;
      final dotsCount = ring * 10;
      for (int i = 0; i < dotsCount; i++) {
        final angle = (i * 2 * math.pi) / dotsCount;
        double a = active ? 0.3 : 0.6;

        if (active) {
          double radarAngle = sweep * 2 * math.pi;
          double diff = angle - radarAngle;
          while (diff < 0) {
            diff += 2 * math.pi;
          }
          if (diff < math.pi / 2) {
            a = 1.0 - (diff / (math.pi / 2));
          }
        }

        final pt = Paint()
          ..color = active
              ? AppTheme.accentRed.withValues(alpha: a)
              : Colors.white.withValues(alpha: 0.2);
        canvas.drawCircle(
          Offset(cx + radius * math.cos(angle), cy + radius * math.sin(angle)),
          1.8,
          pt,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.sweep != sweep || old.active != active;
}

// Tracker Dot Matrix Animation (Human Following)
class TrackerDotAnimation extends StatefulWidget {
  final bool isActive;
  const TrackerDotAnimation({super.key, required this.isActive});

  @override
  State<TrackerDotAnimation> createState() => _TrackerDotAnimationState();
}

class _TrackerDotAnimationState extends State<TrackerDotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.isActive) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(TrackerDotAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        painter: _TrackerPainter(_ctrl.value, widget.isActive),
        size: const Size(140, 140),
      ),
    );
  }
}

class _TrackerPainter extends CustomPainter {
  final double pulse;
  final bool active;
  _TrackerPainter(this.pulse, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final dotColor = active ? AppTheme.accentRed : Colors.white.withValues(alpha: 0.2);
    final paint = Paint()..color = dotColor;

    final List<Offset> human = [
      Offset(cx, cy - 20),
      Offset(cx, cy - 5),
      Offset(cx, cy + 5),
      Offset(cx - 10, cy),
      Offset(cx + 10, cy),
      Offset(cx - 8, cy + 18),
      Offset(cx + 8, cy + 18),
    ];
    for (var o in human) {
      canvas.drawCircle(o, 2.5, paint);
    }

    if (active) {
      final lockSize = 40.0 + (pulse * 10);
      final alpha = (1.0 - pulse) * 0.8 + 0.2;
      final lockPaint = Paint()..color = AppTheme.accentRed.withValues(alpha: alpha);

      canvas.drawCircle(Offset(cx - lockSize, cy - lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx - lockSize + 6, cy - lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx - lockSize, cy - lockSize + 6), 2, lockPaint);

      canvas.drawCircle(Offset(cx + lockSize, cy - lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx + lockSize - 6, cy - lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx + lockSize, cy - lockSize + 6), 2, lockPaint);

      canvas.drawCircle(Offset(cx - lockSize, cy + lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx - lockSize + 6, cy + lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx - lockSize, cy + lockSize - 6), 2, lockPaint);

      canvas.drawCircle(Offset(cx + lockSize, cy + lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx + lockSize - 6, cy + lockSize), 2, lockPaint);
      canvas.drawCircle(Offset(cx + lockSize, cy + lockSize - 6), 2, lockPaint);
    }
  }

  @override
  bool shouldRepaint(_TrackerPainter old) =>
      old.pulse != pulse || old.active != active;
}

// Nothing OS Controller Dot Matrix (Normal Mode)
class NormalDotAnimation extends StatelessWidget {
  const NormalDotAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _NormalCarPainter(),
      size: Size(140, 140),
    );
  }
}

class _NormalCarPainter extends CustomPainter {
  const _NormalCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    const double gridScale = 9.0;
    final double startX = cx - (5 * gridScale);
    final double startY = cy - (3.5 * gridScale);

    // Pure white dots — Nothing OS style controller
    final bodyPaint = Paint()..color = Colors.white;

    final List<List<int>> dots = [
      [2, 0], [3, 0], [7, 0], [8, 0],
      [1, 1], [2, 1], [3, 1], [4, 1], [5, 1], [6, 1], [7, 1], [8, 1], [9, 1],
      [0, 2], [1, 2], [3, 2], [4, 2], [5, 2], [6, 2], [7, 2], [9, 2], [10, 2],
      [0, 3], [4, 3], [5, 3], [6, 3], [8, 3], [10, 3],
      [0, 4], [1, 4], [3, 4], [4, 4], [5, 4], [6, 4], [7, 4], [9, 4], [10, 4],
      [0, 5], [1, 5], [2, 5], [3, 5], [7, 5], [8, 5], [9, 5], [10, 5],
      [0, 6], [1, 6], [2, 6], [8, 6], [9, 6], [10, 6],
      [1, 7], [2, 7], [8, 7], [9, 7],
    ];

    for (final dot in dots) {
      canvas.drawCircle(
        Offset(startX + (dot[0] * gridScale), startY + (dot[1] * gridScale)),
        3.5,
        bodyPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

//  Voice Wave Animation
class DotMatrixVoiceAnimation extends StatefulWidget {
  const DotMatrixVoiceAnimation({super.key});

  @override
  State<DotMatrixVoiceAnimation> createState() =>
      _DotMatrixVoiceAnimationState();
}

class _DotMatrixVoiceAnimationState extends State<DotMatrixVoiceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Smooth continuous cycle
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _NothingEqualizerPainter(_controller.value),
          size: const Size(140, 60),
        );
      },
    );
  }
}

class _NothingEqualizerPainter extends CustomPainter {
  final double animationValue;

  _NothingEqualizerPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    const dotSize = 3.0; // radius
    const cols = 15;
    const maxRows = 7; // max vertical dots
    const spacingX = 9.0;
    const spacingY = 9.0;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Start drawing from the left side so the 15 columns are perfectly centered
    final startX = cx - ((cols - 1) * spacingX) / 2;

    for (int col = 0; col < cols; col++) {
      // Combine 3 smooth intersecting sine waves to create a chaotic equalizer effect
      final wave1 = math.sin(animationValue * math.pi * 4 + (col * 0.5));
      final wave2 = math.sin(animationValue * math.pi * 6 - (col * 0.8));
      final wave3 = math.sin(animationValue * math.pi * 2 + (col * 0.2));

      final composite = ((wave1 + wave2 + wave3) / 3).abs(); // ranges from 0.0 to approx 1.0

      // Calculate vertical dot count (forcing it to be odd so it's perfectly symmetrical)
      int dotsCount = (1 + (maxRows - 1) * composite).round();
      if (dotsCount % 2 == 0) dotsCount++;

      // Create a gradient mask for alpha based on distance from center
      final distFromCenter = (col - (cols / 2)).abs() / (cols / 2);
      final columnAlpha = 1.0 - (distFromCenter * 0.5); // Fades out gently towards edges

      final paint = Paint()
        ..color = AppTheme.accentRed.withValues(alpha: columnAlpha.clamp(0.0, 1.0));

      for (int i = 0; i < dotsCount; i++) {
        // Find exact center vertical position for each dot in this column
        final double dy = cy + (i - (dotsCount - 1) / 2) * spacingY;
        canvas.drawCircle(Offset(startX + col * spacingX, dy), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_NothingEqualizerPainter old) =>
      old.animationValue != animationValue;
}

//  Background dot grid
class DotGrid extends StatelessWidget {
  const DotGrid({super.key});

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(painter: _DotGridPainter());
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    const spacing = 22.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

//  Radial dot halo (behind center animation)
class RadialDotHaloPainter extends CustomPainter {
  const RadialDotHaloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2;
    final radii = [size.width * 0.32, size.width * 0.45, size.width * 0.58];
    final counts = [16, 22, 28];
    final opacities = [0.12, 0.07, 0.04];

    for (int ring = 0; ring < radii.length; ring++) {
      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacities[ring]);
      final n = counts[ring];
      for (int i = 0; i < n; i++) {
        final angle = (2 * math.pi / n) * i;
        final dx = cx + radii[ring] * math.cos(angle);
        final dy = cy + radii[ring] * math.sin(angle);
        canvas.drawCircle(Offset(dx, dy), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
