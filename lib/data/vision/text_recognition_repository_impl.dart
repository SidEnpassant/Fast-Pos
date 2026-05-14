import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:inventopos/domain/repositories/text_recognition_repository.dart';

class TextRecognitionRepositoryImpl implements TextRecognitionRepository {
  @override
  Future<List<String>> extractLinesFromImagePath(String imagePath) async {
    final recognizer = TextRecognizer();
    try {
      final input = InputImage.fromFilePath(imagePath);
      final recognized = await recognizer.processImage(input);
      return recognized.blocks
          .expand((b) => b.lines)
          .map((l) => l.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    } finally {
      await recognizer.close();
    }
  }
}
