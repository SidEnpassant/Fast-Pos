import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final inputPath = 'assets/icon/app_main_icon.png';
  final outputPath = 'assets/icon/app_main_icon_padded.png';

  print('Reading image from $inputPath...');
  final imageBytes = File(inputPath).readAsBytesSync();
  final originalImage = img.decodeImage(imageBytes);

  if (originalImage == null) {
    print('Failed to decode image.');
    return;
  }

  int width = originalImage.width;
  int height = originalImage.height;
  
  print('Original dimensions: ${width}x${height}');

  int maxDim = width > height ? width : height;
  int targetCanvasSize = (maxDim * 1.8).round(); 
  
  print('Target canvas size: ${targetCanvasSize}x${targetCanvasSize}');

  // Create new solid color canvas using the app's brand color #0441e7 (R:4, G:65, B:231)
  final paddedImage = img.Image(width: targetCanvasSize, height: targetCanvasSize);
  img.fill(paddedImage, color: img.ColorRgba8(4, 65, 231, 255)); 

  // Calculate center position
  int dstX = (targetCanvasSize - width) ~/ 2;
  int dstY = (targetCanvasSize - height) ~/ 2;

  // Composite the original image onto the center of the solid canvas
  img.compositeImage(paddedImage, originalImage, dstX: dstX, dstY: dstY);

  // Save the result
  print('Saving padded image to $outputPath...');
  File(outputPath).writeAsBytesSync(img.encodePng(paddedImage));
  print('Done!');
}
