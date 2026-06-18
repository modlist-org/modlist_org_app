import 'dart:io' hide BytesBuilder;
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'api_service.dart';

class CloudSaveService {
  /// Scans eligible configuration/save files under [gamePath].
  /// Excludes executable binaries (.dll, .exe, .pdb), archives, and files > 10MB.
  /// Also excludes any files that were explicitly installed by a mod.
  static List<File> scanEligibleFiles(String gamePath, {List<String> installedModFiles = const []}) {
    final List<File> files = [];
    final List<String> targetSubDirs = ['UserData', 'UMMMods', 'Mods'];
    final normalizedInstalledFiles = installedModFiles.map((f) => f.replaceAll('\\', '/').toLowerCase()).toSet();

    for (final subDirName in targetSubDirs) {
      final dir = Directory(p.join(gamePath, subDirName));
      if (!dir.existsSync()) continue;

      try {
        final List<FileSystemEntity> entities = dir.listSync(recursive: true, followLinks: false);
        for (final entity in entities) {
          if (entity is File) {
            final file = entity;
            
            // Check if this file is tracked as an installed mod file
            final relativePath = p.relative(file.path, from: gamePath);
            final normalizedRelPath = relativePath.replaceAll('\\', '/').toLowerCase();
            if (normalizedInstalledFiles.contains(normalizedRelPath)) {
              continue;
            }

            final stat = file.statSync();

            // Exclude files larger than 10MB (configs and saves are normally smaller,
            // but we allow up to 10MB to avoid skipping larger valid save databases/files)
            if (stat.size > 10 * 1024 * 1024) continue;

            // Exclude executables, libraries, pdb, and compressed archives
            final ext = p.extension(file.path).toLowerCase();
            if (const {
              '.dll', '.exe', '.pdb', '.so', '.dylib',
              '.zip', '.rar', '.7z', '.tar', '.gz',
              '.unity3d', '.assets', '.bundle', '.ress', '.cab', '.resource'
            }.contains(ext)) {
              continue;
            }

            files.add(file);
          }
        }
      } catch (_) {
        // Ignore folder read errors
      }
    }

    return files;
  }

  /// Bundles scanned files into in-memory zip bytes.
  static List<int> createBackupZip(String gamePath, List<File> files) {
    final archive = Archive();

    for (final file in files) {
      final relativePath = p.relative(file.path, from: gamePath);
      final bytes = file.readAsBytesSync();
      
      // Use forward slashes for zip cross-platform compatibility
      final archivePath = relativePath.replaceAll('\\', '/');

      final archiveFile = ArchiveFile(archivePath, bytes.length, bytes);
      archive.addFile(archiveFile);
    }

    final zipEncoder = ZipEncoder();
    final zipBytes = zipEncoder.encode(archive);
    if (zipBytes == null) {
      throw Exception('Failed to compress backup files.');
    }
    return zipBytes;
  }

  /// Extracts ZIP bytes back into the [gamePath] directory.
  static void extractBackupZip(String gamePath, List<int> zipBytes) {
    final zipDecoder = ZipDecoder();
    final archive = zipDecoder.decodeBytes(zipBytes);

    for (final file in archive) {
      if (file.isFile) {
        final data = file.content as List<int>;
        
        // Prevent path traversal attacks (Zip Slip)
        final safePath = p.normalize(file.name);
        if (safePath.startsWith('..') || safePath.startsWith('/')) {
          continue;
        }

        final outFile = File(p.join(gamePath, safePath));
        outFile.createSync(recursive: true);
        outFile.writeAsBytesSync(data);
      }
    }
  }

  /// Runs the backup process: scans, zips, gets presigned upload URL, uploads to R2, and confirms.
  static Future<Map<String, dynamic>> backup({
    required String gameId,
    required String gamePath,
    required ApiService apiService,
    required Function(double) onProgress,
    List<String> installedModFiles = const [],
  }) async {
    onProgress(0.1);
    final files = scanEligibleFiles(gamePath, installedModFiles: installedModFiles);
    if (files.isEmpty) {
      throw Exception('No configuration or save files found to back up.');
    }

    onProgress(0.3);
    final zipBytes = createBackupZip(gamePath, files);
    final fileSize = zipBytes.length;
    final fileName = '${gameId}_save.zip';

    onProgress(0.5);
    // Request upload URL
    final presignRes = await apiService.getUploadPresignedUrl(
      game: gameId,
      fileName: fileName,
      fileSize: fileSize,
    );

    final String uploadUrl = presignRes['uploadUrl'] as String;
    final String fileKey = presignRes['fileKey'] as String;

    onProgress(0.7);
    // Upload bytes to storage directly
    await apiService.uploadFileToR2(uploadUrl, zipBytes);

    onProgress(0.9);
    // Confirm upload with Modlist server
    final confirmRes = await apiService.confirmUpload(
      game: gameId,
      fileName: fileName,
      fileKey: fileKey,
      fileSize: fileSize,
    );

    onProgress(1.0);
    return confirmRes;
  }

  /// Runs the restore process: gets presigned download URL, downloads, and extracts.
  static Future<void> restore({
    required String gamePath,
    required String fileKey,
    required ApiService apiService,
    required Function(double) onProgress,
  }) async {
    onProgress(0.2);
    // Get presigned download URL
    final downloadUrl = await apiService.getDownloadPresignedUrl(fileKey);

    onProgress(0.5);
    // Download ZIP bytes
    final response = await httpGet(downloadUrl);

    onProgress(0.8);
    // Extract to game folder
    extractBackupZip(gamePath, response);
    onProgress(1.0);
  }

  /// Simple HTTP GET helper for downloading binary content
  static Future<List<int>> httpGet(String url) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }
      
      final builder = BytesBuilder();
      await for (final chunk in response) {
        builder.add(chunk);
      }
      return builder.takeBytes();
    } finally {
      client.close();
    }
  }
}
