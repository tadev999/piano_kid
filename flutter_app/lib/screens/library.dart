import 'package:flutter/material.dart' hide Step;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../content/curriculum.dart';
import '../content/songs.dart';
import '../game/games.dart';
import '../game/song_session.dart';
import '../models.dart';
import '../music/notes.dart';
import '../state/app_state.dart';
import '../ui/common.dart';
import '../ui/kit.dart';
import '../ui/widgets.dart';

LinearGradient _grad(Region r) => LinearGradient(colors: r.bg.map((c) => Color(c)).toList(), begin: Alignment.topLeft, end: Alignment.bottomRight);

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    return Scaffold(
      appBar: const TopBar(back: '/', title: '🗺️ Bản đồ âm nhạc'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: ListView(padding: const EdgeInsets.all(14), children: [
            for (final r in regions)
              Align(
                alignment: r.id.isOdd ? Alignment.centerLeft : Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.9,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Opacity(
                      opacity: r.id > child.unlockedRegion ? 0.55 : 1,
                      child: GestureDetector(
                        onTap: r.id > child.unlockedRegion ? null : () => context.go('/region/${r.id}'),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(gradient: _grad(r), border: Border.all(color: Color(r.color), width: 4), borderRadius: BorderRadius.circular(28), boxShadow: C.shadow),
                          child: Row(children: [
                            Text(r.id > child.unlockedRegion ? '🔒' : r.emoji, style: const TextStyle(fontSize: 54)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Builder(builder: (context) {
                                final st = regionStars(child, r.id);
                                final locked = r.id > child.unlockedRegion;
                                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text('${r.id}. ${r.name}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
                                  Text('${r.rank} · ${r.desc}', style: const TextStyle(color: C.muted)),
                                  const SizedBox(height: 6),
                                  if (!locked) ProgressBar(st.done.toDouble(), st.total.toDouble(), color: Color(r.color)),
                                  if (!locked) Text('⭐ ${st.got}/${st.max} · Trùm: ${r.bossEmoji} ${r.bossName}'),
                                  if (locked) const Text('Thắng trùm vùng trước để mở khóa'),
                                ]);
                              }),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class RegionScreen extends StatelessWidget {
  final int id;
  const RegionScreen({super.key, required this.id});
  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    final region = regionById(id);
    final locked = id > child.unlockedRegion;
    final list = lessonsOf(id);
    return Scaffold(
      appBar: TopBar(back: '/map', title: '${region.emoji} ${region.name}'),
      body: Container(
        decoration: BoxDecoration(gradient: _grad(region)),
        child: locked
            ? const Center(child: Guide('Vùng đất này còn bị khóa. Hãy thắng trùm của vùng trước nhé!'))
            : ListView(padding: const EdgeInsets.fromLTRB(14, 8, 14, 40), children: [
                Guide('Chào mừng đến ${region.name}! Ở đây bạn sẽ học: ${region.desc}.', compact: true, size: 80),
                for (var i = 0; i < list.length; i++)
                  Align(
                    alignment: i.isEven ? const Alignment(-0.6, 0) : const Alignment(0.6, 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Builder(builder: (context) {
                        final l = list[i];
                        final unlocked = isLessonUnlocked(child, l);
                        final done = child.lessons[l.id];
                        final node = Container(
                          width: l.boss ? 200 : 170,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: l.boss ? const LinearGradient(colors: [Colors.white, Color(0xfffff3bf)], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
                            color: unlocked ? Colors.white : const Color(0xfff8f9fa),
                            border: Border.all(color: unlocked ? Color(region.color) : const Color(0xffced4da), width: 4),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: C.shadow,
                          ),
                          child: Column(children: [
                            Text(unlocked ? l.emoji : '🔒', style: const TextStyle(fontSize: 40)),
                            Text(l.title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                            if (done != null) StarsRow(done.stars, size: 18) else if (unlocked) const Text('Bắt đầu ▶', style: TextStyle(color: C.primary, fontWeight: FontWeight.w700)),
                          ]),
                        );
                        if (!unlocked) return Opacity(opacity: 0.55, child: node);
                        final tap = GestureDetector(onTap: () => context.go('/lesson/${l.id}'), child: MouseRegion(cursor: SystemMouseCursors.click, child: node));
                        return done == null ? Pulse(scale: 1.04, child: tap) : tap;
                      }),
                    ),
                  ),
              ]),
      ),
    );
  }
}

const _originLabel = {'vn': '🇻🇳 Việt Nam', 'intl': '🌍 Quốc tế', 'classical': '🎻 Cổ điển', 'exercise': '🏋️ Bài tập'};

class SongbookScreen extends StatefulWidget {
  const SongbookScreen({super.key});
  @override
  State<SongbookScreen> createState() => _SongbookScreenState();
}

class _SongbookScreenState extends State<SongbookScreen> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    final list = songs.where((s) => filter == 'all' || s.origin == filter).toList();
    return Scaffold(
      appBar: const TopBar(back: '/', title: '🎵 Thư viện bài hát'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Center(child: Seg<String>(options: [('all', 'Tất cả'), for (final e in _originLabel.entries) (e.key, e.value)], value: filter, onChanged: (v) => setState(() => filter = v))),
        const SizedBox(height: 12),
        Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
          for (final s in list)
            SizedBox(
              width: 230,
              child: Opacity(
                opacity: s.region > child.unlockedRegion ? 0.55 : 1,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Color(s.color), width: 3), borderRadius: BorderRadius.circular(24), boxShadow: C.shadow),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Color(s.color), borderRadius: BorderRadius.circular(16)),
                      child: Text(s.region > child.unlockedRegion ? '🔒' : s.emoji, textAlign: TextAlign.center, style: const TextStyle(fontSize: 40)),
                    ),
                    const SizedBox(height: 6),
                    Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                    Text('${s.subtitle} · ${s.credit}', style: const TextStyle(color: C.muted, fontSize: 12)),
                    const SizedBox(height: 6),
                    if (s.region > child.unlockedRegion)
                      Text('Mở ở vùng ${s.region}', style: const TextStyle(color: C.muted))
                    else
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final l in s.levels)
                          GestureDetector(
                            onTap: () => context.go('/song/${s.id}/${l.level}'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xfff3f0ff), borderRadius: BorderRadius.circular(12)),
                              child: Column(children: [Text(l.label, style: const TextStyle(fontWeight: FontWeight.w700)), StarsRow(child.songs[songKey(s.id, l.level)]?.stars ?? 0, size: 12)]),
                            ),
                          ),
                      ]),
                  ]),
                ),
              ),
            ),
        ]),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Mỗi bài có nhiều cấp: Dễ → Vừa → Hai tay → Biểu diễn. Chơi lại bài cũ ở cấp khó hơn để thấy mình tiến bộ!', textAlign: TextAlign.center, style: TextStyle(color: C.muted)),
        ),
      ]),
    );
  }
}

class SongScreen extends StatelessWidget {
  final String id;
  final int level;
  const SongScreen({super.key, required this.id, required this.level});
  @override
  Widget build(BuildContext context) {
    if (arrangement(id, level) == null) return const Scaffold(body: Center(child: Text('Không tìm thấy bài hát.')));
    return Scaffold(
      body: SafeArea(
        child: SongSession(
          key: ValueKey('$id-$level'),
          songId: id,
          level: level,
          onExit: () => context.canPop() ? context.pop() : context.go('/songs'),
          onNavigateLevel: (l) => context.replace('/song/$id/$l'),
        ),
      ),
    );
  }
}

GameConfig freeGameConfig(GameKind kind, int region) {
  final pools = [n('C4 D4 E4'), n('C4 D4 E4 F4 G4'), n('C4 D4 E4 F4 G4 A4 B4 C5'), n('C3 E3 G3 C4 E4 G4'), n('C4 D4 E4 F4 G4 A4 B4 C5'), n('C4 D4 E4 F4 F#4 G4 A4 B4 C5')];
  final pool = pools[region.clamp(1, pools.length) - 1];
  return switch (kind) {
    GameKind.catchNotes => GameConfig(notes: pool, duration: 45),
    GameKind.ear => GameConfig(notes: pool, rounds: 8, melodyLen: region >= 4 ? 2 : 1),
    GameKind.rhythm => GameConfig(pattern: region >= 3 ? const [1, 1, 2, 0.5, 0.5, 1, 2] : const [1, 1, 2, 1, 1, 2], bpm: 72 + region * 6),
    GameKind.detective => GameConfig(songId: const ['twinkle', 'ode', 'frere', 'jingle'][(region - 1).clamp(0, 3)], melodyLen: 6, rounds: 4),
  };
}

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    return Scaffold(
      appBar: const TopBar(back: '/', title: '🎮 Trò chơi âm nhạc'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
          for (final k in GameKind.values)
            Builder(builder: (context) {
              final locked = k == GameKind.detective && child.unlockedRegion < 2;
              final info = gameInfo[k]!;
              return SizedBox(
                width: 240,
                child: Opacity(
                  opacity: locked ? 0.55 : 1,
                  child: CardBox(
                    padding: const EdgeInsets.all(22),
                    onTap: locked ? null : () => context.go('/game/${k.name}'),
                    child: Column(children: [
                      Text(locked ? '🔒' : info.emoji, style: const TextStyle(fontSize: 56)),
                      Text(info.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                      Text(locked ? 'Mở ở Rừng Nhịp Điệu' : info.desc, textAlign: TextAlign.center, style: const TextStyle(color: C.muted)),
                    ]),
                  ),
                ),
              );
            }),
        ]),
      ]),
    );
  }
}

class GameScreen extends StatelessWidget {
  final String kind;
  const GameScreen({super.key, required this.kind});
  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    final k = GameKind.values.where((g) => g.name == kind).firstOrNull ?? GameKind.catchNotes;
    return Scaffold(body: GameRunner(kind: k, config: freeGameConfig(k, child.unlockedRegion), onExit: () => context.go('/games')));
  }
}
