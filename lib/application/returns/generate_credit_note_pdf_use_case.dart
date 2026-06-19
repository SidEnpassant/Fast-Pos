import '../../data/returns/credit_note_pdf_generator.dart';
import '../../domain/entities/credit_note.dart';
import '../../domain/repositories/profile_repository.dart';

class GenerateCreditNotePdfUseCase {
  GenerateCreditNotePdfUseCase(this._profile, this._pdfGenerator);

  final ProfileRepository _profile;
  final CreditNotePdfGenerator _pdfGenerator;

  Future<String> call(CreditNote creditNote) async {
    final merchant = await _profile.fetchCurrentUserProfileSnapshot();
    if (merchant == null) {
      throw StateError('Merchant profile not found');
    }

    return await _pdfGenerator.generate(
      creditNote: creditNote,
      merchant: merchant,
    );
  }
}
