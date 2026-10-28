import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../models/attachment_model.dart';

/// Picking and uploading of chat / wall attachments.
class AttachmentService {
  final _picker = ImagePicker();

  /// Up to [limit] images from the gallery (may return fewer, or none).
  Future<List<PendingAttachment>> pickImages(int limit) async {
    if (limit <= 0) return [];
    final files = limit == 1
        ? [await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 2000)]
            .whereType<XFile>()
            .toList()
        : await _picker.pickMultiImage(imageQuality: 85, maxWidth: 2000, limit: limit);
    return Future.wait(files.take(limit).map((f) => _pending(Attachment.image, f.path, f.name)));
  }

  /// One photo from the camera (e.g. an ID document), or null.
  Future<PendingAttachment?> takePhoto() async {
    final file = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 85, maxWidth: 2000);
    if (file == null) return null;
    return _pending(Attachment.image, file.path, file.name);
  }

  Future<PendingAttachment?> pickVideo() async {
    final file = await _picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return null;
    return _pending(Attachment.video, file.path, file.name);
  }

  Future<PendingAttachment?> pickAudio() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    final file = result?.files.single;
    if (file?.path == null) return null;
    return PendingAttachment(
      type: Attachment.audio,
      localPath: file!.path!,
      name: file.name,
      size: file.size,
    );
  }

  Future<PendingAttachment?> pickPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final file = result?.files.single;
    if (file?.path == null) return null;
    return PendingAttachment(
      type: Attachment.pdf,
      localPath: file!.path!,
      name: file.name,
      size: file.size,
    );
  }

  /// Length of a local video file, or null if it can't be read.
  Future<Duration?> videoDuration(String localPath) async {
    final controller = VideoPlayerController.file(File(localPath));
    try {
      await controller.initialize();
      return controller.value.duration;
    } catch (_) {
      return null;
    } finally {
      await controller.dispose();
    }
  }

  /// Uploads every item under [folder] and returns the stored attachments,
  /// in the same order. [onProgress] receives 0.0–1.0 across all files.
  /// Files are streamed from disk (putFile), so large videos and PDFs
  /// aren't loaded into memory.
  Future<List<Attachment>> uploadAll(
    String folder,
    List<PendingAttachment> items, {
    void Function(double progress)? onProgress,
  }) async {
    final totalBytes = items.fold<int>(0, (sum, i) => sum + i.size);
    final sent = List<int>.filled(items.length, 0);
    final storage = FirebaseStorage.instance;

    final results = <Attachment>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final path = '$folder/${i}_${_safeName(item.name)}';
      final ref = storage.ref(path);
      final task = ref.putFile(
        File(item.localPath),
        SettableMetadata(contentType: contentTypeFor(item)),
      );
      final sub = task.snapshotEvents.listen((s) {
        sent[i] = s.bytesTransferred;
        if (totalBytes > 0) {
          onProgress?.call(sent.reduce((a, b) => a + b) / totalBytes);
        }
      });
      try {
        await task;
      } finally {
        await sub.cancel();
      }
      results.add(Attachment(
        type: item.type,
        url: await ref.getDownloadURL(),
        path: path,
        name: item.name,
        size: item.size,
      ));
    }
    return results;
  }

  Future<PendingAttachment> _pending(String type, String path, String name) async =>
      PendingAttachment(
        type: type,
        localPath: path,
        name: name,
        size: await File(path).length(),
      );

  static String _safeName(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');

  /// MIME type sent with an upload — storage.rules checks it.
  static String contentTypeFor(PendingAttachment item) {
    final ext = item.name.split('.').last.toLowerCase();
    switch (item.type) {
      case Attachment.pdf:
        return 'application/pdf';
      case Attachment.audio:
        return switch (ext) {
          'm4a' || 'mp4' => 'audio/mp4',
          'aac' => 'audio/aac',
          'wav' => 'audio/wav',
          'ogg' || 'opus' => 'audio/ogg',
          'amr' => 'audio/amr',
          'flac' => 'audio/flac',
          _ => 'audio/mpeg',
        };
      case Attachment.video:
        return switch (ext) {
          'mov' => 'video/quicktime',
          '3gp' => 'video/3gpp',
          'webm' => 'video/webm',
          'mkv' => 'video/x-matroska',
          _ => 'video/mp4',
        };
      default:
        return switch (ext) {
          'png' => 'image/png',
          'gif' => 'image/gif',
          'webp' => 'image/webp',
          'heic' => 'image/heic',
          _ => 'image/jpeg',
        };
    }
  }
}
