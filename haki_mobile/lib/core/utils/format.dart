import 'package:intl/intl.dart';

/// "9:41", "Yesterday", "Tue", "12 Mar".
String chatTime(DateTime t) {
  final local = t.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return DateFormat.jm().format(local);
  if (diff == 1) return 'Yesterday';
  if (diff < 7) return DateFormat.E().format(local);
  return DateFormat.MMMd().format(local);
}

/// "Today", "Yesterday", "Monday, 12 March".
String dayLabel(DateTime t) {
  final local = t.toLocal();
  final now = DateTime.now();
  final diff = DateTime(now.year, now.month, now.day)
      .difference(DateTime(local.year, local.month, local.day))
      .inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return DateFormat.MMMMEEEEd().format(local);
}

String mmss(Duration d) =>
    '${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}';

/// "just now", "5 min ago", "3 h ago", "2 days ago".
String relativeTime(DateTime t) {
  final s = DateTime.now().difference(t).inSeconds;
  if (s < 60) return 'just now';
  if (s < 3600) return '${s ~/ 60} min ago';
  if (s < 86400) return '${s ~/ 3600} h ago';
  final d = s ~/ 86400;
  return d == 1 ? 'yesterday' : '$d days ago';
}
