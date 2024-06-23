import 'package:flutter/material.dart';

class TextOverlayPainter extends CustomPainter {
  final String recognizedText;

  TextOverlayPainter({required this.recognizedText});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    const textPadding = 8.0; // Spațiul de padding în jurul textului
    final textWidth = size.width - (2 * textPadding); // Lățimea textului
    final textHeight = size.height * 0.2; // Înălțimea textului

    final textRect = Rect.fromLTWH(textPadding, size.height * 0.7 - (textHeight / 2), textWidth, textHeight);
    canvas.drawRect(textRect, paint);

    // Afiseaza textul detectat
    const textTextStyle = TextStyle(color: Colors.white, fontSize: 20);
    final textSpan = TextSpan(text: recognizedText, style: textTextStyle);
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
