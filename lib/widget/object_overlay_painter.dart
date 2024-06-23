



import 'package:flutter/material.dart';

class ObjectOverlayPainter extends CustomPainter {
  final String objectLabel;

  ObjectOverlayPainter({required this.objectLabel});

  @override
  void paint(Canvas canvas, Size size) {

    final paint = Paint()..color = Colors.black.withOpacity(0.5);
    final backgroundRect = Rect.fromLTWH(0, size.height * 0.4, size.width, size.height * 0.2);
    canvas.drawRect(backgroundRect, paint);

    // Afiseaza label-ul obiectului
    const objectTextStyle = TextStyle(color: Colors.white, fontSize: 20);
    final objectTextSpan = TextSpan(text: objectLabel, style: objectTextStyle);
    final objectTextPainter = TextPainter(
      text: objectTextSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    objectTextPainter.layout();
    final textWidth = objectTextPainter.width;
    final textHeight = objectTextPainter.height;
    final textOffset = Offset((size.width - textWidth) / 2, size.height * 0.5 - (textHeight / 2));
    objectTextPainter.paint(canvas, textOffset);

    // Restul codului rămâne la fel
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
