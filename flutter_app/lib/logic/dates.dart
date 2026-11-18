import '../content/rewards.dart';

String _p(int x) => x.toString().padLeft(2, '0');

String dayKey([DateTime? d]) {
  final x = d ?? DateTime.now();
  return '${x.year}-${_p(x.month)}-${_p(x.day)}';
}

String monthKey([DateTime? d]) {
  final x = d ?? DateTime.now();
  return '${x.year}-${_p(x.month)}';
}

DateTime weekStart([DateTime? d]) {
  final x = d ?? DateTime.now();
  final day = DateTime(x.year, x.month, x.day);
  return day.subtract(Duration(days: day.weekday - 1));
}

String weekKey([DateTime? d]) => dayKey(weekStart(d));

List<String> weekDays([DateTime? d]) {
  final s = weekStart(d);
  return List.generate(7, (i) => dayKey(DateTime(s.year, s.month, s.day + i)));
}

List<String> lastNDays(int count) {
  final now = DateTime.now();
  return List.generate(count, (i) => dayKey(DateTime(now.year, now.month, now.day - (count - 1 - i))));
}

const weekdayShort = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

class ActiveEvent {
  final SeasonEvent event;
  final String key;
  final DateTime endsAt;
  const ActiveEvent(this.event, this.key, this.endsAt);
}

ActiveEvent activeEvent([DateTime? now]) {
  final d = now ?? DateTime.now();
  final md = '${_p(d.month)}-${_p(d.day)}';
  for (final e in seasonEvents) {
    if (md.compareTo(e.from) >= 0 && md.compareTo(e.to) <= 0) {
      final parts = e.to.split('-').map(int.parse).toList();
      return ActiveEvent(e, '${e.id}-${d.year}', DateTime(d.year, parts[0], parts[1], 23, 59));
    }
  }
  return ActiveEvent(monthlyEvent, '${monthlyEvent.id}-${monthKey(d)}', DateTime(d.year, d.month + 1, 0, 23, 59));
}

int daysLeft(DateTime end) {
  final ms = end.difference(DateTime.now()).inMilliseconds;
  return ms <= 0 ? 0 : (ms / 86400000).ceil();
}

String formatDuration(int sec) {
  final m = (sec / 60).round();
  if (m < 60) return '$m phút';
  return '${m ~/ 60} giờ ${m % 60} phút';
}
