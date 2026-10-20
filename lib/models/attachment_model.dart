/// A file attached to a chat message or community wall post, stored as an
/// element of the parent doc's `attachments` array.
class Attachment {
  static const image = 'image';
  static const video = 'video';
  static const pdf = 'pdf';
  static const audio = 'audio';

  final String type;
  final String url;
  // Storage path — lets Cloud Functions delete the file with its parent.
  final String path;
  final String? name;
  final int? size;

  const Attachment({
    required this.type,
    required this.url,
    required this.path,
    this.name,
    this.size,
  });

  factory Attachment.fromMap(Map<String, dynamic> data) => Attachment(
        type: data['type'] as String? ?? image,
        url: data['url'] as String? ?? '',
        path: data['path'] as String? ?? '',
        name: data['name'] as String?,
        size: (data['size'] as num?)?.toInt(),
      );

  Map<String, dynamic> toMap() => {
        'type': type,
        'url': url,
        'path': path,
        if (name != null) 'name': name,
        if (size != null) 'size': size,
      };

  static List<Attachment> listFrom(dynamic raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((m) => Attachment.fromMap(Map<String, dynamic>.from(m)))
          .toList()
      : const [];
}

/// A file picked on the device but not uploaded yet.
class PendingAttachment {
  final String type;
  final String localPath;
  final String name;
  final int size;

  const PendingAttachment({
    required this.type,
    required this.localPath,
    required this.name,
    required this.size,
  });
}
