import 'package:inventopos/domain/repositories/remote_pdf_download_repository.dart';

class DownloadRemotePdfToDeviceUseCase {
  DownloadRemotePdfToDeviceUseCase(this._downloads);

  final RemotePdfDownloadRepository _downloads;

  Future<String?> call(String pdfUrl) => _downloads.downloadPdfToDevice(pdfUrl);
}
