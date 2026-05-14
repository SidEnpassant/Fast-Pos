/// Extracts plain text lines from an on-disk image (e.g. camera capture path).
abstract class TextRecognitionRepository {
  Future<List<String>> extractLinesFromImagePath(String imagePath);
}
