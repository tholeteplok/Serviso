import 'dart:io';
import 'package:image/image.dart';

void main() {
  const size = 1024;
  final img = Image(width: size, height: size, numChannels: 4);

  // Background #512D6D (R:81, G:45, B:109)
  fill(img, color: ColorRgb8(81, 45, 109));

  // Draw white rounded inner container motif & monogram geometry
  final white = ColorRgb8(255, 255, 255);
  final whiteTransparent = ColorRgba8(255, 255, 255, 180);

  // Inner subtle ring circle
  drawCircle(img, x: 512, y: 512, radius: 420, color: whiteTransparent);

  // Draw Stylized "S" + Wrench Motif using thick filled shapes and circles
  // Central Wrench ring
  drawCircle(img, x: 512, y: 360, radius: 120, color: white);
  drawCircle(img, x: 512, y: 360, radius: 110, color: white);
  drawCircle(img, x: 512, y: 360, radius: 100, color: white);

  // Wrench head cutout (center circle fill with bg color)
  fillCircle(img, x: 512, y: 360, radius: 55, color: ColorRgb8(81, 45, 109));

  // Wrench Handle (diagonal stroke)
  for (int i = -35; i <= 35; i++) {
    drawLine(img, x1: 512 + i, y1: 360 + i, x2: 720 + i, y2: 720 + i, color: white);
  }

  // Handle bottom end knob
  fillCircle(img, x: 720, y: 720, radius: 45, color: white);

  // Draw Monogram 'S' Curves on top left
  // Top curve arc of S
  for (int r = 130; r <= 170; r++) {
    drawCircle(img, x: 380, y: 440, radius: r, color: white);
  }
  // Bottom curve arc of S
  for (int r = 130; r <= 170; r++) {
    drawCircle(img, x: 440, y: 640, radius: r, color: white);
  }

  // Ensure assets directory exists
  final assetsDir = Directory('assets');
  if (!assetsDir.existsSync()) {
    assetsDir.createSync(recursive: true);
  }

  final pngBytes = encodePng(img);
  File('assets/icon.png').writeAsBytesSync(pngBytes);

  stderr.writeln('✅ Successfully generated assets/icon.png (${pngBytes.length} bytes)');
}
