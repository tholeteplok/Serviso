import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Perforated ticket divider with circular notch cutouts at both ends,
/// simulating a tear-off ticket strip on receipts, invoices, and queue slips.
class PerforatedTicketDivider extends StatelessWidget {
  const PerforatedTicketDivider({
    super.key,
    this.notchRadius = 9.0,
    this.lineColor = AppColors.borderInk,
    this.notchBgColor = AppColors.bgBase,
    this.notchBorderColor = AppColors.borderInk,
    this.borderWidth = 1.2,
    this.dashWidth = 5.0,
    this.dashGap = 4.0,
    this.margin,
  });

  final double notchRadius;
  final Color lineColor;
  final Color notchBgColor;
  final Color notchBorderColor;
  final double borderWidth;
  final double dashWidth;
  final double dashGap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    Widget divider = SizedBox(
      height: notchRadius * 2,
      width: double.infinity,
      child: CustomPaint(
        painter: _PerforatedDividerPainter(
          notchRadius: notchRadius,
          lineColor: lineColor,
          notchBgColor: notchBgColor,
          notchBorderColor: notchBorderColor,
          borderWidth: borderWidth,
          dashWidth: dashWidth,
          dashGap: dashGap,
        ),
      ),
    );

    if (margin != null) {
      divider = Padding(padding: margin!, child: divider);
    }

    return divider;
  }
}

class _PerforatedDividerPainter extends CustomPainter {
  const _PerforatedDividerPainter({
    required this.notchRadius,
    required this.lineColor,
    required this.notchBgColor,
    required this.notchBorderColor,
    required this.borderWidth,
    required this.dashWidth,
    required this.dashGap,
  });

  final double notchRadius;
  final Color lineColor;
  final Color notchBgColor;
  final Color notchBorderColor;
  final double borderWidth;
  final double dashWidth;
  final double dashGap;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;

    // 1. Paint left notch (inward arc from card edge)
    final leftPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(0, centerY), radius: notchRadius),
        -math.pi / 2,
        math.pi,
      );

    // 2. Paint right notch (inward arc from card right edge)
    final rightPath = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(size.width, centerY), radius: notchRadius),
        math.pi / 2,
        math.pi,
      );

    final fillPaint = Paint()
      ..color = notchBgColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = notchBorderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Draw notch fills
    canvas.drawPath(leftPath, fillPaint);
    canvas.drawPath(rightPath, fillPaint);

    // Draw notch borders
    canvas.drawPath(leftPath, borderPaint);
    canvas.drawPath(rightPath, borderPaint);

    // 3. Draw dashed line in the middle
    final dashPaint = Paint()
      ..color = lineColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    double startX = notchRadius + 2.0;
    final endX = size.width - notchRadius - 2.0;

    while (startX < endX) {
      final nextX = math.min(startX + dashWidth, endX);
      canvas.drawLine(
        Offset(startX, centerY),
        Offset(nextX, centerY),
        dashPaint,
      );
      startX += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _PerforatedDividerPainter oldDelegate) {
    return oldDelegate.notchRadius != notchRadius ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.notchBgColor != notchBgColor ||
        oldDelegate.notchBorderColor != notchBorderColor ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashGap != dashGap;
  }
}
