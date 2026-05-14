import 'package:inventopos/domain/repositories/text_recognition_repository.dart';

class ExtractTextLinesFromImagePathUseCase {
  ExtractTextLinesFromImagePathUseCase(this._recognition);

  final TextRecognitionRepository _recognition;

  Future<List<String>> call(String imagePath) =>
      _recognition.extractLinesFromImagePath(imagePath);
}
