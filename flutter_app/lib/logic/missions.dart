import '../content/songs.dart';
import '../models.dart';
import 'dates.dart';

/// Deterministic pseudo-random generator so a child's missions are stable for the day.
double Function() seededRandom(String seed) {
  var h = 2166136261;
  for (final c in seed.codeUnits) {
    h = ((h ^ c) * 16777619) & 0xffffffff;
  }
  return () {
    h = ((h ^ (h >> 15)) * 2246822507) & 0xffffffff;
    h = ((h ^ (h >> 13)) * 3266489909) & 0xffffffff;
    h = (h ^ (h >> 16)) & 0xffffffff;
    return h / 4294967296;
  };
}

({String key, String title})? _reviewCandidate(ChildProfile child) {
  final now = DateTime.now().millisecondsSinceEpoch;
  final entries = child.songs.entries.where((e) => e.value.stars < 3 || now - e.value.last > 3 * 86400000).toList()
    ..sort((a, b) => a.value.last.compareTo(b.value.last));
  if (entries.isEmpty) return null;
  final song = songById(entries.first.key.split('@').first);
  return song == null ? null : (key: entries.first.key, title: song.title);
}

DailyState generateMissions(ChildProfile child, String date) {
  final rand = seededRandom('${child.id}:$date');
  final review = _reviewCandidate(child);
  final templates = <String, (String text, int target, int reward, String? ref)?>{
    'lesson': ('Hoàn thành 1 bài học trên bản đồ', 1, 20, null),
    'song': ('Chơi trọn 2 bài hát', 2, 20, null),
    'game': ('Chơi 1 trò chơi luyện tai hoặc nhịp', 1, 15, null),
    'stars': ('Thu thập 5 ngôi sao', 5, 25, null),
    'free': ('Chơi tự do hoặc sáng tác 1 giai điệu', 1, 15, null),
    'minutes': ('Luyện đàn 10 phút', 10, 25, null),
    'review': review == null ? null : ('Ôn lại bài "${review.title}"', 1, 25, review.key),
  };
  final first = rand() < 0.5 ? 'lesson' : 'song';
  final rest = ['game', 'stars', 'free', 'minutes', 'review'].where((k) => templates[k] != null).toList();
  final picks = [first];
  while (picks.length < 3 && rest.isNotEmpty) {
    picks.add(rest.removeAt((rand() * rest.length).floor()));
  }
  return DailyState(
    date: date,
    missions: [
      for (var i = 0; i < picks.length; i++)
        Mission(id: '$date-$i', kind: picks[i], text: templates[picks[i]]!.$1, target: templates[picks[i]]!.$2, reward: templates[picks[i]]!.$3, ref: templates[picks[i]]!.$4),
    ],
  );
}

ChildProfile ensureDaily(ChildProfile child) {
  final today = dayKey();
  if (child.daily?.date == today) return child;
  return child.clone()..daily = generateMissions(child, today);
}
