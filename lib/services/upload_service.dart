import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';

class UploadResult {
  UploadResult({required this.downloadUrl});
  final String downloadUrl;
}

class AudioUploadResult extends UploadResult {
  AudioUploadResult({required super.downloadUrl, required this.durationSeconds});
  final int? durationSeconds;
}

class UploadService {
  UploadService({FirebaseStorage? storage}) : _storage = storage ?? FirebaseStorage.instance;
  final FirebaseStorage _storage;

  Future<UploadResult> uploadImage({
    required Uint8List bytes,
    required String meditationId,
    required String fileExtension,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'images/$meditationId.$fileExtension';
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: _imageContentType(fileExtension));
    final task = ref.putData(bytes, metadata);
    if (onProgress != null) {
      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) {
          onProgress(s.bytesTransferred / s.totalBytes);
        }
      });
    }
    await task;
    final url = await ref.getDownloadURL();
    return UploadResult(downloadUrl: url);
  }

  Future<AudioUploadResult> uploadAudio({
    required Uint8List bytes,
    required String meditationId,
    required String fileExtension,
    void Function(double progress)? onProgress,
  }) async {
    final path = 'audio/$meditationId.$fileExtension';
    final ref = _storage.ref().child(path);
    final metadata = SettableMetadata(contentType: _audioContentType(fileExtension));
    final task = ref.putData(bytes, metadata);
    if (onProgress != null) {
      task.snapshotEvents.listen((s) {
        if (s.totalBytes > 0) {
          onProgress(s.bytesTransferred / s.totalBytes);
        }
      });
    }
    await task;
    final url = await ref.getDownloadURL();

    // Determine duration cross-platform. Prefer local file path APIs, but since we have bytes,
    // use the uploaded URL to avoid per-platform file handling.
    int? durationSec;
    try {
      final player = AudioPlayer();
      print('🎵 Setting audio URL: $url');
      await player.setUrl(url);
      print('🎵 URL set, waiting for duration metadata...');
      // Wait for duration to be available (web needs this - duration loads separately from ready state)
      final d = await player.durationStream
          .firstWhere((duration) => duration != null)
          .timeout(const Duration(seconds: 15));
      durationSec = d?.inSeconds;
      await player.dispose();
      print('🎵 Duration detected: $durationSec seconds');
    } catch (e) {
      print('❌ Duration detection failed: $e');
      durationSec = null;
    }

    return AudioUploadResult(downloadUrl: url, durationSeconds: durationSec);
  }

  String _imageContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  String _audioContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'mp3':
        return 'audio/mpeg';
      case 'm4a':
      case 'aac':
        return 'audio/aac';
      case 'wav':
        return 'audio/wav';
      default:
        return 'application/octet-stream';
    }
  }
}


