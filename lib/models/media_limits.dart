import 'attachment_model.dart';

/// Why an attachment can't be added to a draft — mapped to a localized
/// message by the composer (see mediaRejectionMessage in attachment_views).
enum MediaRejection {
  typeNotAllowed,
  tooManyAttachments,
  tooManyImages,
  oneVideoOnly,
  videoTooLong,
  fileTooLarge,
}

/// Per-surface attachment rules for composers (chat input, thread composer).
/// Mirrors the caps in firestore.rules / storage.rules for the same surface,
/// so a violation is reported up front instead of as a permission-denied at
/// upload time.
class MediaLimits {
  final int maxImages;
  final int maxAttachments;
  final bool allowVideo;
  final bool allowPdf;
  final bool allowAudio;
  // null = no limit enforced in the app.
  final Duration? maxVideoDuration;
  final int? maxPdfBytes;
  final int? maxAudioBytes;
  final int? maxVideoBytes;

  const MediaLimits({
    this.maxImages = 5,
    this.maxAttachments = 10,
    this.allowVideo = true,
    this.allowPdf = true,
    this.allowAudio = true,
    this.maxVideoDuration,
    this.maxPdfBytes,
    this.maxAudioBytes,
    this.maxVideoBytes,
  });

  static const int megabyte = 1024 * 1024;

  /// Community wall (threadPosts): up to 5 images + one video of at most
  /// 10 minutes — unchanged from before subcategory posting existed.
  static const wall = MediaLimits(
    maxAttachments: 6,
    allowPdf: false,
    allowAudio: false,
    maxVideoDuration: Duration(minutes: 10),
  );

  /// Private 1:1 chat: images, one video of any length, PDFs of any size
  /// and audio, max 10 per message.
  static const directMessage = MediaLimits();

  /// Subcategory feeds/chat and user groups: video ≤ 5 min, up to 5 images,
  /// PDFs and audio ≤ 50 MB each (also enforced in storage.rules).
  static const community = MediaLimits(
    maxVideoDuration: Duration(minutes: 5),
    maxPdfBytes: 50 * megabyte,
    maxAudioBytes: 50 * megabyte,
    maxVideoBytes: 1024 * megabyte,
  );

  bool allows(String type) => switch (type) {
        Attachment.image => true,
        Attachment.video => allowVideo,
        Attachment.pdf => allowPdf,
        Attachment.audio => allowAudio,
        _ => false,
      };

  int? maxBytesFor(String type) => switch (type) {
        Attachment.pdf => maxPdfBytes,
        Attachment.audio => maxAudioBytes,
        Attachment.video => maxVideoBytes,
        _ => null,
      };

  /// How many more images may be picked given what's already in [current].
  int imageRoom(List<PendingAttachment> current) {
    final images = current.where((a) => a.type == Attachment.image).length;
    final room = maxImages - images;
    final total = maxAttachments - current.length;
    return room < total ? room : total;
  }

  /// Checks whether a picked file may join the draft. Pure — the caller
  /// reads the file's size (and a video's duration) beforehand.
  MediaRejection? check({
    required String type,
    required int size,
    required List<PendingAttachment> current,
    Duration? videoDuration,
  }) {
    if (!allows(type)) return MediaRejection.typeNotAllowed;
    if (current.length >= maxAttachments) return MediaRejection.tooManyAttachments;
    if (type == Attachment.image && imageRoom(current) <= 0) {
      return MediaRejection.tooManyImages;
    }
    if (type == Attachment.video) {
      if (current.any((a) => a.type == Attachment.video)) {
        return MediaRejection.oneVideoOnly;
      }
      final maxDuration = maxVideoDuration;
      if (maxDuration != null &&
          (videoDuration == null || videoDuration > maxDuration)) {
        return MediaRejection.videoTooLong;
      }
    }
    final maxBytes = maxBytesFor(type);
    if (maxBytes != null && size > maxBytes) return MediaRejection.fileTooLarge;
    return null;
  }
}
