/// Downloads a remote PDF to device-accessible storage; returns saved path or null.
abstract class RemotePdfDownloadRepository {
  Future<String?> downloadPdfToDevice(String pdfUrl);
}
