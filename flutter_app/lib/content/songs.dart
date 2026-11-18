import '../models.dart';
import '../music/fingering.dart';
import '../music/notes.dart';

List<int>? _nums(String? s) => s?.trim().split(RegExp(r'\s+')).map(int.parse).toList();

Song _make({
  required String id, required String title, required String subtitle, required String origin, required String credit,
  required String emoji, required int color, required int region, required int bpm, required int bpb, required String rh,
  String? easy, String? lh, double lhStart = 0,
}) {
  final r = seq(rh);
  final levels = <Arrangement>[
    Arrangement(level: 1, label: 'Dễ', bpm: (bpm * 0.75).round(), beatsPerBar: bpb, hands: Hand.r, defaultMode: PlayMode.wait, steps: easy != null ? seq(easy) : seq(rh)),
    Arrangement(level: 2, label: 'Vừa', bpm: bpm, beatsPerBar: bpb, hands: Hand.r, defaultMode: PlayMode.wait, steps: r),
  ];
  if (lh != null) {
    levels.add(Arrangement(level: 3, label: 'Hai tay', bpm: (bpm * 0.85).round(), beatsPerBar: bpb, hands: Hand.b, defaultMode: PlayMode.wait, steps: merge([r, seq(lh, lhStart, true)])));
    levels.add(Arrangement(level: 4, label: 'Biểu diễn', bpm: (bpm * 1.05).round(), beatsPerBar: bpb, hands: Hand.b, defaultMode: PlayMode.timed, steps: merge([r, seq(lh, lhStart, true)])));
  } else {
    levels.add(Arrangement(level: 3, label: 'Biểu diễn', bpm: (bpm * 1.1).round(), beatsPerBar: bpb, hands: Hand.r, defaultMode: PlayMode.timed, steps: seq(rh)));
  }
  for (final l in levels) {
    applyFingering(l.steps);
  }
  return Song(id: id, title: title, subtitle: subtitle, origin: origin, credit: credit, emoji: emoji, color: color, region: region, levels: levels);
}

Song _exercise({
  required String id, required String title, required String subtitle, required String credit, required String emoji, required int color,
  required int region, required int bpm, required int bpb, String? rh, String? lh, String? rf, String? lf,
}) {
  final levels = <Arrangement>[];
  if (rh != null) levels.add(Arrangement(level: levels.length + 1, label: 'Tay phải', bpm: bpm, beatsPerBar: bpb, hands: Hand.r, defaultMode: PlayMode.wait, steps: seq(rh)));
  if (lh != null) levels.add(Arrangement(level: levels.length + 1, label: 'Tay trái', bpm: bpm, beatsPerBar: bpb, hands: Hand.l, defaultMode: PlayMode.wait, steps: seq(lh, 0, true)));
  if (rh != null && lh != null) {
    levels.add(Arrangement(level: levels.length + 1, label: 'Hai tay', bpm: bpm, beatsPerBar: bpb, hands: Hand.b, defaultMode: PlayMode.wait, steps: merge([seq(rh), seq(lh, 0, true)])));
  }
  for (final l in levels) {
    applyFingering(l.steps, rf: _nums(rf), lf: _nums(lf));
  }
  return Song(id: id, title: title, subtitle: subtitle, origin: 'exercise', credit: credit, emoji: emoji, color: color, region: region, levels: levels);
}

final List<Song> songs = [
  _make(
    id: 'hot-cross-buns', title: 'Bánh Nóng', subtitle: 'Hot Cross Buns', origin: 'intl', credit: 'Đồng dao Anh', emoji: '🥐', color: 0xffffa94d, region: 1, bpm: 90, bpb: 4,
    rh: 'E4 D4 C4:2 | E4 D4 C4:2 | C4:0.5 C4:0.5 C4:0.5 C4:0.5 D4:0.5 D4:0.5 D4:0.5 D4:0.5 | E4 D4 C4:2',
    lh: 'C3:4 C3:4 C3:2 G2:2 C3:4',
  ),
  _make(
    id: 'au-clair', title: 'Ánh Trăng', subtitle: 'Au Clair de la Lune', origin: 'intl', credit: 'Dân ca Pháp', emoji: '🌙', color: 0xff748ffc, region: 1, bpm: 90, bpb: 4,
    rh: 'C4 C4 C4 D4 | E4:2 D4:2 | C4 E4 D4 D4 | C4:4 | C4 C4 C4 D4 | E4:2 D4:2 | C4 E4 D4 D4 | C4:4',
    lh: 'C3:4 C3:2 G2:2 C3:2 G2:2 C3:4 C3:4 C3:2 G2:2 C3:2 G2:2 C3:4',
  ),
  _make(
    id: 'mary', title: 'Chú Cừu Nhỏ', subtitle: 'Mary Had a Little Lamb', origin: 'intl', credit: 'Nhạc thiếu nhi Mỹ (thế kỷ 19)', emoji: '🐑', color: 0xfff783ac, region: 1, bpm: 100, bpb: 4,
    rh: 'E4 D4 C4 D4 | E4 E4 E4:2 | D4 D4 D4:2 | E4 G4 G4:2 | E4 D4 C4 D4 | E4 E4 E4 E4 | D4 D4 E4 D4 | C4:4',
    lh: 'C3:4 C3:4 G2:4 C3:4 C3:4 C3:4 G2:4 C3:4',
  ),
  _make(
    id: 'twinkle', title: 'Ngôi Sao Lấp Lánh', subtitle: 'Twinkle, Twinkle, Little Star', origin: 'intl', credit: 'Giai điệu dân gian Pháp', emoji: '⭐', color: 0xffffd43b, region: 1, bpm: 100, bpb: 4,
    easy: 'C4 C4 G4 G4 | A4 A4 G4:2 | F4 F4 E4 E4 | D4 D4 C4:2',
    rh: 'C4 C4 G4 G4 | A4 A4 G4:2 | F4 F4 E4 E4 | D4 D4 C4:2 | G4 G4 F4 F4 | E4 E4 D4:2 | G4 G4 F4 F4 | E4 E4 D4:2 | C4 C4 G4 G4 | A4 A4 G4:2 | F4 F4 E4 E4 | D4 D4 C4:2',
    lh: 'C3:4 F3:2 C3:2 F3:2 C3:2 G2:2 C3:2 C3:2 G2:2 C3:2 G2:2 C3:2 G2:2 C3:2 G2:2 C3:4 F3:2 C3:2 F3:2 C3:2 G2:2 C3:2',
  ),
  _make(
    id: 'frere', title: 'Kìa Con Bướm Vàng', subtitle: 'Frère Jacques', origin: 'vn', credit: 'Giai điệu dân ca Pháp, lời Việt quen thuộc', emoji: '🦋', color: 0xfffcc419, region: 2, bpm: 100, bpb: 4,
    rh: 'C4 D4 E4 C4 | C4 D4 E4 C4 | E4 F4 G4:2 | E4 F4 G4:2 | G4:0.5 A4:0.5 G4:0.5 F4:0.5 E4 C4 | G4:0.5 A4:0.5 G4:0.5 F4:0.5 E4 C4 | C4 G3 C4:2 | C4 G3 C4:2',
    lh: 'C3:4 C3:4 C3:4 C3:4 C3:4 C3:4 C3:4 C3:4',
  ),
  _make(
    id: 'london', title: 'Cầu London', subtitle: 'London Bridge', origin: 'intl', credit: 'Đồng dao Anh', emoji: '🌉', color: 0xff4dabf7, region: 2, bpm: 100, bpb: 4,
    rh: 'G4:1.5 A4:0.5 G4 F4 | E4 F4 G4:2 | D4 E4 F4:2 | E4 F4 G4:2 | G4:1.5 A4:0.5 G4 F4 | E4 F4 G4:2 | D4:2 G4:2 | E4 C4:3',
    lh: 'C3:4 C3:4 G2:4 C3:4 C3:4 C3:4 G2:4 C3:4',
  ),
  _make(
    id: 'ode', title: 'Niềm Vui', subtitle: 'Ode to Joy', origin: 'classical', credit: 'L. v. Beethoven (1824)', emoji: '🎻', color: 0xff69db7c, region: 2, bpm: 100, bpb: 4,
    rh: 'E4 E4 F4 G4 | G4 F4 E4 D4 | C4 C4 D4 E4 | E4:1.5 D4:0.5 D4:2 | E4 E4 F4 G4 | G4 F4 E4 D4 | C4 C4 D4 E4 | D4:1.5 C4:0.5 C4:2',
    lh: 'C3:4 G2:4 C3:4 G2:4 C3:4 G2:4 C3:4 G2:2 C3:2',
  ),
  _make(
    id: 'birthday', title: 'Chúc Mừng Sinh Nhật', subtitle: 'Happy Birthday', origin: 'intl', credit: 'M. & P. Hill (1893)', emoji: '🎂', color: 0xffff8787, region: 4, bpm: 100, bpb: 3,
    rh: 'G4:0.75 G4:0.25 | A4 G4 C5 | B4:2 G4:0.75 G4:0.25 | A4 G4 D5 | C5:2 G4:0.75 G4:0.25 | G5 E5 C5 | B4 A4:2 | F5:0.75 F5:0.25 E5 C5 | D5 C5:3',
    lh: 'C3:3 G2:3 G2:3 C3:3 C3:3 F3:3 C3:3 G2:1 C3:3', lhStart: 1,
  ),
  _make(
    id: 'jingle', title: 'Chuông Ngân Vang', subtitle: 'Jingle Bells', origin: 'intl', credit: 'J. Pierpont (1857)', emoji: '🔔', color: 0xffe64980, region: 4, bpm: 110, bpb: 4,
    rh: 'E4 E4 E4:2 | E4 E4 E4:2 | E4 G4 C4:1.5 D4:0.5 | E4:4 | F4 F4 F4:1.5 F4:0.5 | F4 E4 E4 E4:0.5 E4:0.5 | E4 D4 D4 E4 | D4:2 G4:2 | E4 E4 E4:2 | E4 E4 E4:2 | E4 G4 C4:1.5 D4:0.5 | E4:4 | F4 F4 F4:1.5 F4:0.5 | F4 E4 E4 E4:0.5 E4:0.5 | G4 G4 F4 D4 | C4:4',
    lh: 'C3:4 C3:4 C3:4 C3:4 F3:4 C3:4 G2:4 G2:4 C3:4 C3:4 C3:4 C3:4 F3:4 C3:4 G2:4 C3:4',
  ),
  _make(
    id: 'minuet', title: 'Minuet Sol Trưởng', subtitle: 'Minuet in G', origin: 'classical', credit: 'C. Petzold (khoảng 1725)', emoji: '💃', color: 0xff9775fa, region: 5, bpm: 100, bpb: 3,
    rh: 'D5 G4:0.5 A4:0.5 B4:0.5 C5:0.5 | D5 G4 G4 | E5 C5:0.5 D5:0.5 E5:0.5 F#5:0.5 | G5 G4 G4 | C5 D5:0.5 C5:0.5 B4:0.5 A4:0.5 | B4 C5:0.5 B4:0.5 A4:0.5 G4:0.5 | A4 B4:0.5 A4:0.5 G4:0.5 F#4:0.5 | G4:3',
    lh: 'G3:3 B3:3 C4:3 B3:3 A3:3 G3:3 D3:3 G2:3',
  ),
  _make(
    id: 'fur-elise', title: 'Gửi Elise', subtitle: 'Für Elise', origin: 'classical', credit: 'L. v. Beethoven (1810)', emoji: '🌹', color: 0xffe599f7, region: 5, bpm: 132, bpb: 3,
    easy: 'E5:0.5 D#5:0.5 | E5:0.5 D#5:0.5 E5:0.5 B4:0.5 D5:0.5 C5:0.5 | A4:3',
    rh: 'E5:0.5 D#5:0.5 | E5:0.5 D#5:0.5 E5:0.5 B4:0.5 D5:0.5 C5:0.5 | A4 r:0.5 C4:0.5 E4:0.5 A4:0.5 | B4 r:0.5 E4:0.5 G#4:0.5 B4:0.5 | C5 r:0.5 E4:0.5 E5:0.5 D#5:0.5 | E5:0.5 D#5:0.5 E5:0.5 B4:0.5 D5:0.5 C5:0.5 | A4 r:0.5 C4:0.5 E4:0.5 A4:0.5 | B4 r:0.5 E4:0.5 C5:0.5 B4:0.5 | A4:2',
    lh: 'A2:0.5 E3:0.5 A3:0.5 r:1.5 E2:0.5 E3:0.5 G#3:0.5 r:1.5 A2:0.5 E3:0.5 A3:0.5 r:1.5 r:3 A2:0.5 E3:0.5 A3:0.5 r:1.5 E2:0.5 E3:0.5 G#3:0.5 r:1.5 A2:0.5 E3:0.5 A3:1',
    lhStart: 4,
  ),
  _make(
    id: 'canon', title: 'Canon Rê Trưởng', subtitle: 'Canon in D', origin: 'classical', credit: 'J. Pachelbel (khoảng 1680)', emoji: '🕊️', color: 0xff38d9a9, region: 6, bpm: 72, bpb: 4,
    rh: 'F#5:2 E5:2 | D5:2 C#5:2 | B4:2 A4:2 | B4:2 C#5:2 | D5:2 C#5:2 | B4:2 A4:2 | G4:2 F#4:2 | G4:2 E4:2',
    lh: 'D3:2 A2:2 B2:2 F#2:2 G2:2 D2:2 G2:2 A2:2 D3:2 A2:2 B2:2 F#2:2 G2:2 D2:2 G2:2 A2:2',
  ),
  _exercise(
    id: 'lh-walk', title: 'Tay Trái Đi Dạo', subtitle: 'Bài tập tay trái', credit: 'Bài tập Piano Quest', emoji: '🚶', color: 0xff20c997, region: 3, bpm: 80, bpb: 4,
    lh: 'C3 D3 E3 F3 | G3:2 G3:2 | G3 F3 E3 D3 | C3:4 | C3 E3 G3 E3 | C3:2 G2:2 | C3 D3 E3 D3 | C3:4',
  ),
  Song(
    id: 'hoi-dap', title: 'Hỏi – Đáp', subtitle: 'Hai tay thay phiên', origin: 'exercise', credit: 'Bài tập Piano Quest', emoji: '💬', color: 0xff66d9e8, region: 3,
    levels: [
      Arrangement(
        level: 1, label: 'Hai tay', bpm: 80, beatsPerBar: 4, hands: Hand.b, defaultMode: PlayMode.wait,
        steps: applyFingering(merge([
          seq('C4 D4 E4:2 r:4 E4 D4 C4:2 r:4 C4 E4 G4:2 r:4 G4 E4 C4:2'),
          seq('C3 D3 E3:2 r:4 E3 D3 C3:2 r:4 C3 E3 G3:2 r:2 C3:2', 4, true),
        ])),
      ),
    ],
  ),
  _exercise(
    id: 'scale-c', title: 'Gam Đô Trưởng', subtitle: 'C major scale', credit: 'Bài tập kỹ thuật', emoji: '🪜', color: 0xffced4da, region: 6, bpm: 80, bpb: 4,
    rh: 'C4 D4 E4 F4 G4 A4 B4 C5 | B4 A4 G4 F4 E4 D4 C4:2', lh: 'C3 D3 E3 F3 G3 A3 B3 C4 | B3 A3 G3 F3 E3 D3 C3:2',
    rf: '1 2 3 1 2 3 4 5 4 3 2 1 3 2 1', lf: '5 4 3 2 1 3 2 1 2 3 1 2 3 4 5',
  ),
  _exercise(
    id: 'scale-g', title: 'Gam Sol Trưởng', subtitle: 'G major scale', credit: 'Bài tập kỹ thuật', emoji: '🧗', color: 0xffadb5bd, region: 5, bpm: 80, bpb: 4,
    rh: 'G4 A4 B4 C5 D5 E5 F#5 G5 | F#5 E5 D5 C5 B4 A4 G4:2', lh: 'G2 A2 B2 C3 D3 E3 F#3 G3 | F#3 E3 D3 C3 B2 A2 G2:2',
    rf: '1 2 3 1 2 3 4 5 4 3 2 1 3 2 1', lf: '5 4 3 2 1 3 2 1 2 3 1 2 3 4 5',
  ),
  _exercise(
    id: 'arpeggio', title: 'Hợp Âm Rải', subtitle: 'Arpeggios C – F – G', credit: 'Bài tập kỹ thuật', emoji: '🌊', color: 0xff74c0fc, region: 4, bpm: 80, bpb: 4,
    rh: 'C4 E4 G4 C5 G4 E4 C4:2 | F4 A4 C5 F5 C5 A4 F4:2 | G4 B4 D5 G5 D5 B4 G4:2 | C4 E4 G4 C5:4', lh: 'C3+E3+G3:8 F3+A3+C4:8 G2+B2+D3:8 C3+E3+G3:7',
    rf: '1 2 3 5 3 2 1 1 2 3 5 3 2 1 1 2 3 5 3 2 1 1 2 3 5', lf: '5 3 1 5 3 1 5 3 1 5 3 1',
  ),
];

Song? songById(String id) => songs.where((s) => s.id == id).firstOrNull;

Arrangement? arrangement(String songId, int level) => songById(songId)?.levels.where((l) => l.level == level).firstOrNull;

String songKey(String songId, int level) => '$songId@$level';
