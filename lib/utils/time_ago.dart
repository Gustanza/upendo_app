String timeAgo(DateTime? dateTime) {
  if (dateTime == null) return '';
  final diff = DateTime.now().difference(dateTime);
  if (diff.inSeconds < 60) return 'Sasa hivi';
  if (diff.inMinutes < 60) return '${diff.inMinutes} dak';
  if (diff.inHours < 24) return '${diff.inHours} saa';
  if (diff.inDays < 7) return '${diff.inDays} siku';
  return '${(diff.inDays / 7).floor()} wiki';
}
