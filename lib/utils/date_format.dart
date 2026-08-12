import 'package:intl/intl.dart';

const _seoul = Duration(hours: 9);

DateTime toKst(DateTime utcOrLocal) {
  final utc = utcOrLocal.isUtc ? utcOrLocal : utcOrLocal.toUtc();
  return utc.add(_seoul);
}

String formatKstDateTime(DateTime? value) {
  if (value == null) return '—';
  final kst = toKst(value);
  return DateFormat('yyyy.MM.dd (E) HH:mm', 'ko').format(kst);
}

String formatKstDate(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('yyyy.MM.dd (E)', 'ko').format(toKst(value));
}

String formatKstTime(DateTime? value) {
  if (value == null) return '—';
  return DateFormat('HH:mm').format(toKst(value));
}

String formatKstRange(DateTime? start, DateTime? end) {
  if (start == null && end == null) return '—';
  if (start != null && end != null) {
    final s = toKst(start);
    final e = toKst(end);
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    if (sameDay) {
      final date = DateFormat('yyyy.MM.dd (E)', 'ko').format(s);
      final from = DateFormat('HH:mm').format(s);
      final to = DateFormat('HH:mm').format(e);
      return '$date  $from-$to';
    }
    return '${formatKstDateTime(start)} – ${formatKstDateTime(end)}';
  }
  return formatKstDateTime(start ?? end);
}

String ymdKst(DateTime value) {
  final kst = toKst(value);
  return DateFormat('yyyy-MM-dd').format(kst);
}

String formatRelativeKst(DateTime value) {
  final now = DateTime.now().toUtc();
  final utc = value.isUtc ? value : value.toUtc();
  final diff = now.difference(utc);
  if (diff.inMinutes < 1) return '방금';
  if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
  if (diff.inHours < 24) return '${diff.inHours}시간 전';
  if (diff.inDays < 7) return '${diff.inDays}일 전';
  return formatKstDateTime(value);
}

String payLabel(int? amount) {
  if (amount == null) return '급여 미정';
  return '${NumberFormat('#,###', 'ko').format(amount)}원';
}
