import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/attachment_model.dart';
import '../models/media_limits.dart';
import '../services/attachment_service.dart';

/// Localized message for a [MediaRejection] under [limits].
String mediaRejectionMessage(
  AppLocalizations l10n,
  MediaRejection rejection,
  MediaLimits limits, {
  String? type,
}) {
  switch (rejection) {
    case MediaRejection.typeNotAllowed:
      return l10n.attachmentTypeNotAllowed;
    case MediaRejection.tooManyAttachments:
      return l10n.attachmentsMax(limits.maxAttachments);
    case MediaRejection.tooManyImages:
      return l10n.imagesMax(limits.maxImages);
    case MediaRejection.oneVideoOnly:
      return l10n.oneVideoOnly;
    case MediaRejection.videoTooLong:
      return l10n.videoMaxMinutes(limits.maxVideoDuration?.inMinutes ?? 0);
    case MediaRejection.fileTooLarge:
      final maxBytes = (type == null ? null : limits.maxBytesFor(type)) ??
          limits.maxPdfBytes ??
          0;
      return l10n.fileTooLarge(maxBytes ~/ MediaLimits.megabyte);
  }
}

/// Bottom sheet listing the attachment types [limits] allows. Returns the
/// chosen Attachment.* type, or null if dismissed.
Future<String?> showAttachmentTypeMenu(BuildContext context, MediaLimits limits) {
  final l10n = context.l10n;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF0077C2)),
            title: Text(l10n.attachImages(limits.maxImages)),
            onTap: () => Navigator.pop(ctx, Attachment.image),
          ),
          if (limits.allowVideo)
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: Color(0xFF0077C2)),
              title: Text(limits.maxVideoDuration == null
                  ? l10n.attachVideo
                  : l10n.attachVideoMax(limits.maxVideoDuration!.inMinutes)),
              onTap: () => Navigator.pop(ctx, Attachment.video),
            ),
          if (limits.allowAudio)
            ListTile(
              leading: const Icon(Icons.audiotrack_rounded, color: Color(0xFF8B2942)),
              title: Text(limits.maxAudioBytes == null
                  ? l10n.attachAudio
                  : l10n.attachAudioMax(limits.maxAudioBytes! ~/ MediaLimits.megabyte)),
              onTap: () => Navigator.pop(ctx, Attachment.audio),
            ),
          if (limits.allowPdf)
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined, color: Colors.redAccent),
              title: Text(limits.maxPdfBytes == null
                  ? l10n.attachPdf
                  : l10n.attachPdfMax(limits.maxPdfBytes! ~/ MediaLimits.megabyte)),
              onTap: () => Navigator.pop(ctx, Attachment.pdf),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Picks files of [type] and validates each against [limits] given the
/// draft's [current] items. Rejections are shown as a snackbar; accepted
/// files are returned (possibly empty). [onCheckingVideo] toggles a
/// spinner while a picked video's duration is read.
Future<List<PendingAttachment>> pickValidatedAttachments(
  BuildContext context, {
  required String type,
  required MediaLimits limits,
  required List<PendingAttachment> current,
  AttachmentService? service,
  void Function(bool checking)? onCheckingVideo,
}) async {
  final attachments = service ?? AttachmentService();
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  void reject(MediaRejection r) => messenger.showSnackBar(SnackBar(
      content: Text(mediaRejectionMessage(l10n, r, limits, type: type))));

  // Up-front check (without a file yet) so the picker isn't opened for
  // something that can't be added anyway.
  final early = limits.check(type: type, size: 0, current: current,
      videoDuration: Duration.zero);
  if (early != null && early != MediaRejection.videoTooLong) {
    reject(early);
    return const [];
  }

  final List<PendingAttachment> picked;
  switch (type) {
    case Attachment.image:
      picked = await attachments.pickImages(limits.imageRoom(current));
    case Attachment.video:
      final video = await attachments.pickVideo();
      picked = video == null ? const [] : [video];
    case Attachment.audio:
      final audio = await attachments.pickAudio();
      picked = audio == null ? const [] : [audio];
    case Attachment.pdf:
      final pdf = await attachments.pickPdf();
      picked = pdf == null ? const [] : [pdf];
    default:
      picked = const [];
  }

  final accepted = <PendingAttachment>[];
  for (final item in picked) {
    Duration? duration;
    if (item.type == Attachment.video && limits.maxVideoDuration != null) {
      onCheckingVideo?.call(true);
      duration = await attachments.videoDuration(item.localPath);
      onCheckingVideo?.call(false);
      if (duration == null) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.videoReadFailed)));
        continue;
      }
    }
    final rejection = limits.check(
      type: item.type,
      size: item.size,
      current: [...current, ...accepted],
      videoDuration: duration,
    );
    if (rejection != null) {
      reject(rejection);
      continue;
    }
    accepted.add(item);
  }
  return accepted;
}
