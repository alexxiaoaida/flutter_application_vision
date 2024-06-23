import 'package:flutter/material.dart';

class MoneyOverlayPainter extends CustomPainter {
  final String detectedMoney;

  MoneyOverlayPainter({required this.detectedMoney});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    const textPadding = 8.0; // Padding around the text
    final textWidth = size.width - (2 * textPadding); // Text width
    final textHeight = size.height * 0.2; // Text height

    final textRect = Rect.fromLTWH(textPadding, size.height * 0.7 - (textHeight / 2), textWidth, textHeight);
    canvas.drawRect(textRect, paint);

    // Display the detected money
    const textStyle = TextStyle(color: Colors.white, fontSize: 20);
    final textSpan = TextSpan(text: detectedMoney, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout();
    final textOffset = Offset((size.width - textPainter.width) / 2, size.height * 0.7 - (textPainter.height / 2));
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}