// Desenha a mangueira da splash sem dependências ou lógica de navegação.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';

class SplashHoseAnimation extends StatelessWidget {
  const SplashHoseAnimation({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    height: 170,
    child: Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: SplashHosePainter(progress)),
        ),
        Positioned(
          left: 78,
          top: 8,
          child: Transform.scale(
            scale: _pumpScale(progress),
            child: SvgPicture.asset(
              'assets/images/loading_mark.svg',
              width: 64,
              height: 64,
              semanticsLabel: 'Bomba de combustível carregando',
            ),
          ),
        ),
      ],
    ),
  );

  double _pumpScale(double value) =>
      0.96 + (0.04 * (1 - (2 * value - 1).abs()));
}

class SplashHosePainter extends CustomPainter {
  const SplashHosePainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(139, 58)
      ..cubicTo(198, 65, 205, 130, 155, 143)
      ..cubicTo(112, 154, 62, 132, 58, 96);
    final metric = path.computeMetrics().first;
    final reveal = ((progress - .12) / .42).clamp(0.0, 1.0);
    final visiblePath = metric.extractPath(0, metric.length * reveal);

    canvas.drawPath(
      visiblePath,
      Paint()
        ..color = AppColors.onPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    if (reveal > .92 && progress < .9) {
      final tip = metric.getTangentForOffset(metric.length);
      if (tip != null) _drawNozzle(canvas, tip);
    }

    if (progress >= .56 && progress <= .84) {
      final fuelProgress = ((progress - .56) / .28).clamp(0.0, 1.0);
      final fuel = metric.getTangentForOffset(metric.length * fuelProgress);
      if (fuel != null) {
        canvas.drawCircle(fuel.position, 4, Paint()..color = AppColors.accent);
      }
    }
  }

  void _drawNozzle(Canvas canvas, ui.Tangent tip) {
    canvas.save();
    canvas.translate(tip.position.dx, tip.position.dy);
    canvas.rotate(tip.angle + 1.25);
    final nozzle = Path()
      ..moveTo(0, 0)
      ..lineTo(-12, -19)
      ..lineTo(-4, -25)
      ..lineTo(10, -6)
      ..close();
    canvas.drawPath(nozzle, Paint()..color = AppColors.onPrimary);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -29, 10, 18),
        const Radius.circular(3),
      ),
      Paint()..color = AppColors.accent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SplashHosePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
