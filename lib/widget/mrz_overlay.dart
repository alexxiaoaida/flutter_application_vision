import 'package:flutter/material.dart';

class MrzOverlay extends CustomPainter {
  final String recognizedText;

  MrzOverlay({required this.recognizedText});

  @override
  void paint(Canvas canvas, Size size) {
    // Display the recognized text
    const textTextStyle = TextStyle(color: Colors.white, fontSize: 20);
    final lines = recognizedText.split('\n');

    // Adjust the canvas for horizontal text to the left
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(90 * 3.1415927 / 180); // Rotate 90 degrees clockwise
    canvas.translate(-size.height / 2, -size.width / 2);

    // Calculate the total height of the text block
    double totalTextHeight = lines.length * (textTextStyle.fontSize! + 4.0);

    // Starting Y position for the text
    double startY = (size.width - totalTextHeight) / 2;

    // Paint each line of text
    for (var i = 0; i < lines.length; i++) {
      final textSpan = TextSpan(text: lines[i], style: textTextStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      final textOffset = Offset((size.height - textPainter.width) / 2, startY + i * (textTextStyle.fontSize! + 4.0));
      textPainter.paint(canvas, textOffset);
    }

    // Restore the canvas to its original orientation
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
