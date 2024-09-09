import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class GaugeMeter extends StatelessWidget {
  final int value;
  final Size size;
  const GaugeMeter({super.key, required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 100,
      child: Stack(
        children: [
          // Main gauge meter
          CustomPaint(
            size: size,
            painter: GaugePainter(
                value: value.toDouble() * 10,
                gaugeRadius: size.width / 1.8,
                healthStatus: value < 54
                    ? "Low"
                    : value < 75
                        ? "Healthy"
                        : "High"),
          ),
          // Mirror effect
          Positioned(
            child: ClipRect(
              child: Opacity(
                opacity: 0.3,
                child: Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.rotationX(0),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: CustomPaint(
                      size: size,
                      painter: GaugePainter(
                          value: value.toDouble() * 10,
                          isMirror: true,
                          healthStatus: value < 54
                              ? "Low"
                              : value < 75
                                  ? "Healthy"
                                  : "High",
                          gaugeRadius: (size.width - 30) / 1.8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GaugePainter extends CustomPainter {
  final double value;
  final bool isMirror;
  final double gaugeRadius;
  final String healthStatus;

  GaugePainter(
      {required this.value,
      this.isMirror = false,
      required this.gaugeRadius,
      required this.healthStatus});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = gaugeRadius;
    const startAngle = pi;
    const sweepAngle = pi;

    // Draw background arc
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade900
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Draw colored ranges with simulated blur effect if not mirror
    final ranges = [
      _GaugeRange(0, 333, Colors.red),
      _GaugeRange(333, 666, Colors.amber),
      _GaugeRange(666, 1000, Colors.green),
    ];

    for (var range in ranges) {
      if (!isMirror) {
        // Draw blur effect
        final blurPaint = Paint()
          ..color = range.color.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30 // Slightly larger to simulate blur
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 10); // Apply blur effect

        final startSweep = (range.start / 1000) * pi;
        final endSweep = (range.end / 1000) * pi;

        canvas.drawArc(
          Rect.fromCircle(
              center: center, radius: radius + 5), // Slightly larger radius
          startAngle + startSweep,
          endSweep - startSweep,
          false,
          blurPaint,
        );
      }

      // Draw the actual range
      final rangePaint = Paint()
        ..color = range.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20;

      final startSweep = (range.start / 1000) * pi;
      final endSweep = (range.end / 1000) * pi;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + startSweep,
        endSweep - startSweep,
        false,
        rangePaint,
      );
    }

    // Draw the needle pointer
    if (!isMirror) {
      final pointerAngle = startAngle + (value / 1000) * pi;
      final needleBaseLength = radius - 30; // Adjusted length inside the curve
      final needleTipLength = radius - 20; // Adjusted length outside the curve

      // Adjusted base length for the triangle
      const basePointLength = 20; // Base length of the triangle

      final basePoint1 = Offset(
        center.dx +
            (needleBaseLength - basePointLength / 2) *
                cos(pointerAngle - pi / 20),
        center.dy +
            (needleBaseLength - basePointLength / 2) *
                sin(pointerAngle - pi / 20),
      );

      final basePoint2 = Offset(
        center.dx +
            (needleBaseLength - basePointLength / 2) *
                cos(pointerAngle + pi / 20),
        center.dy +
            (needleBaseLength - basePointLength / 2) *
                sin(pointerAngle + pi / 20),
      );

      final tipPoint = Offset(
        center.dx + needleTipLength * cos(pointerAngle),
        center.dy + needleTipLength * sin(pointerAngle),
      );

      final path = Path()
        ..moveTo(tipPoint.dx, tipPoint.dy)
        ..lineTo(basePoint1.dx, basePoint1.dy)
        ..lineTo(basePoint2.dx, basePoint2.dy)
        ..close();

      final needlePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, needlePaint);

      // Draw the value and label
      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '${value.toInt() ~/ 10}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(center.dx - textPainter.width / 2, center.dy - 50),
      );

      TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: healthStatus,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(center.dx - labelPainter.width / 2, center.dy - 25),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _GaugeRange {
  final double start;
  final double end;
  final Color color;

  _GaugeRange(this.start, this.end, this.color);
}
