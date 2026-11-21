import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Camera-style viewfinder placeholder.
/// TODO: put a real camera preview (e.g. mobile_scanner) inside this box.
class ScannerFrame extends StatelessWidget {
  const ScannerFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 290,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1A2F),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(alignment: Alignment.center, children: [
        const Icon(Icons.qr_code_2_rounded,
            size: 120, color: Color(0x33FFFFFF)),
        SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(painter: _CornerPainter()),
        ),
        Container(width: 180, height: 2, color: TarumtColors.accent),
        const Positioned(
          bottom: 16,
          child: Text('Point the camera at the QR label',
              style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12)),
        ),
      ]),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const len = 30.0;
    final w = size.width;
    final h = size.height;
    canvas.drawPath(
        Path()..moveTo(0, len)..lineTo(0, 0)..lineTo(len, 0), p);
    canvas.drawPath(
        Path()..moveTo(w - len, 0)..lineTo(w, 0)..lineTo(w, len), p);
    canvas.drawPath(
        Path()..moveTo(0, h - len)..lineTo(0, h)..lineTo(len, h), p);
    canvas.drawPath(
        Path()..moveTo(w - len, h)..lineTo(w, h)..lineTo(w, h - len), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
