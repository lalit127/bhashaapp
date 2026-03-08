import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/storage_service.dart';

class PackService extends GetxService {
  final Dio _dio = Dio();
  final _downloadProgress = 0.0.obs;
  final _isDownloading = false.obs;

  double get downloadProgress => _downloadProgress.value;
  bool get isDownloading => _isDownloading.value;

  Future<String> _getPackDir(String langCode) async {
    final dir = await getApplicationDocumentsDirectory();
    final packDir = Directory('${dir.path}/packs/$langCode');
    if (!packDir.existsSync()) packDir.createSync(recursive: true);
    return packDir.path;
  }

  Future<void> downloadPack({
    required String langCode,
    required String cdnUrl,
    required String expectedChecksum,
    void Function(double)? onProgress,
  }) async {
    _isDownloading.value = true;
    _downloadProgress.value = 0;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final zipPath = '${dir.path}/packs/$langCode.zip';
      final existingFile = File(zipPath);
      final existingBytes = existingFile.existsSync() ? existingFile.lengthSync() : 0;

      await _dio.download(
        cdnUrl, zipPath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            _downloadProgress.value = (existingBytes + received) / (existingBytes + total);
            onProgress?.call(_downloadProgress.value);
          }
        },
        options: Options(
          headers: existingBytes > 0 ? {'Range': 'bytes=$existingBytes-'} : null,
          responseType: ResponseType.bytes,
        ),
      );

      final bytes = await existingFile.readAsBytes();
      final checksum = sha256.convert(bytes).toString();
      if (checksum != expectedChecksum) throw Exception('Integrity check failed');

      await _extractPack(zipPath, langCode);
      await Get.find<StorageService>().setPackDownloaded(langCode);
      _downloadProgress.value = 1.0;
    } finally {
      _isDownloading.value = false;
    }
  }

  Future<void> _extractPack(String zipPath, String langCode) async {
    final packDir = await _getPackDir(langCode);
    final inputStream = InputFileStream(zipPath);
    final archive = ZipDecoder().decodeStream(inputStream);
    for (final file in archive.files) {
      if (file.isFile) {
        final outFile = File('$packDir/${file.name}');
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
      }
    }
  }

  Future<String?> readPackFile(String langCode, String relativePath) async {
    final packDir = await _getPackDir(langCode);
    final file = File('$packDir/$relativePath');
    if (!file.existsSync()) return null;
    return file.readAsStringSync();
  }

  Future<bool> isPackReady(String langCode) async {
    final packDir = await _getPackDir(langCode);
    return File('$packDir/manifest.json').existsSync();
  }
}
