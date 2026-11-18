import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/input.dart';
import '../audio/playback.dart';
import '../audio/synth.dart';
import '../content/curriculum.dart';
import '../game/games.dart';
import '../game/song_session.dart';
import '../logic/progress.dart';
import '../models.dart';
import '../music/fingering.dart';
import '../music/notes.dart';
import '../state/app_state.dart';
import '../ui/common.dart';
import '../ui/kit.dart';
import '../ui/painters.dart';
import '../ui/piano.dart';
import '../ui/widgets.dart';

typedef Next = void Function([int? stars]);

class LessonScreen extends StatefulWidget {
  final String id;
  const LessonScreen({super.key, required this.id});
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int idx = 0;
  final scores = <int>[];
  final _sw = Stopwatch()..start();
  ({int stars, Outcome outcome})? done;

  @override
  void didUpdateWidget(LessonScreen old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      idx = 0;
      done = null;
      scores.clear();
      _sw.reset();
    }
  }

  void _next([int? stars]) {
    final lesson = lessonById(widget.id)!;
    if (stars != null) scores.add(stars);
    if (idx + 1 < lesson.steps.length) {
      setState(() => idx++);
      return;
    }
    final s3 = scores.isEmpty ? 3 : (scores.reduce((a, b) => a + b) / scores.length).round().clamp(1, 3);
    final out = context.read<AppState>().record(Activity(kind: 'lesson', ref: lesson.id, title: lesson.title, stars: s3, sec: _sw.elapsedMilliseconds / 1000, boss: lesson.boss, region: lesson.region));
    synth.sfx(out.regionUnlocked != null ? Sfx.levelup : Sfx.win);
    speech.speak(out.regionUnlocked != null ? 'Tuyệt vời! Bạn đã mở khóa ${regionById(out.regionUnlocked!).name}!' : 'Hoàn thành bài học! Giỏi quá!');
    setState(() => done = (stars: s3, outcome: out));
  }

  @override
  Widget build(BuildContext context) {
    final lesson = lessonById(widget.id);
    final child = context.watch<AppState>().child;
    if (lesson == null || child == null) return const Scaffold(body: Center(child: Text('Không tìm thấy bài học.')));
    final region = regionById(lesson.region);
    final bg = BoxDecoration(gradient: LinearGradient(colors: region.bg.map((c) => Color(c)).toList(), begin: Alignment.topLeft, end: Alignment.bottomRight));
    if (!isLessonUnlocked(child, lesson) && done == null) {
      return Scaffold(
        body: Container(
          decoration: bg,
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Guide('Bài học này chưa mở. Hãy hoàn thành bài trước đó nhé!'),
            Btn('🗺️ Về bản đồ', kind: BtnKind.primary, onTap: () => context.go(child.unlockedRegion >= lesson.region ? '/region/${lesson.region}' : '/map')),
          ])),
        ),
      );
    }
    final list = lessonsOf(lesson.region);
    final i = list.indexOf(lesson);
    final nextLesson = i + 1 < list.length ? list[i + 1] : null;
    final step = lesson.steps[idx];
    final body = switch (step) {
      TalkStep s => _TalkView(step: s, next: _next),
      DemoStep s => _DemoView(step: s, next: _next),
      FindStep s => _FindView(step: s, next: _next),
      EchoStep s => _EchoView(step: s, next: _next),
      DynStep s => _DynView(step: s, next: _next),
      GameStep s => GameRunner(kind: s.game, config: s.config, embedded: true, onDone: (st) => _next(st)),
      SongStep s => SongSession(songId: s.songId, level: s.level, forcedMode: s.mode, embedded: true, onDone: (r) => _next(r.stars)),
    };
    return Scaffold(
      body: Container(
        decoration: bg,
        child: SafeArea(
          child: Stack(children: [
            Column(children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(children: [
                  IconBtn('✕', onTap: () => context.go('/region/${lesson.region}')),
                  const SizedBox(width: 12),
                  Expanded(child: Text('${lesson.emoji} ${lesson.title}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800))),
                  for (var k = 0; k < lesson.steps.length; k++)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      width: k == idx ? 18 : 14,
                      height: k == idx ? 18 : 14,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: k < idx ? C.good : k == idx ? C.primary : Colors.black12),
                    ),
                ]),
              ),
              Expanded(child: KeyedSubtree(key: ValueKey('${widget.id}-$idx'), child: body)),
            ]),
            if (done != null)
              ResultOverlay(
                child: ResultPanel(
                  title: lesson.boss ? 'Bạn đã thắng ${region.bossName}!' : 'Hoàn thành bài học!',
                  stars: done!.stars,
                  outcome: done!.outcome,
                  actions: [
                    Btn('🗺️ Về bản đồ', kind: BtnKind.ghost, onTap: () => context.go('/region/${lesson.region}')),
                    if (nextLesson != null) Btn('Bài tiếp theo ➜', kind: BtnKind.primary, onTap: () => context.go('/lesson/${nextLesson.id}')),
                    if (done!.outcome.regionUnlocked != null) Btn('Khám phá vùng mới ➜', kind: BtnKind.primary, onTap: () => context.go('/region/${done!.outcome.regionUnlocked}')),
                  ],
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

String? _skin(BuildContext c) => c.watch<AppState>().child?.equipped.skin;
bool _lenient(BuildContext c) => c.read<AppState>().child?.input == InputKind.mic;

class _TalkView extends StatelessWidget {
  final TalkStep step;
  final Next next;
  const _TalkView({required this.step, required this.next});
  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Guide(step.text),
            if (step.pic != null) Padding(padding: const EdgeInsets.all(8), child: Illustration(step.pic!)),
            const SizedBox(height: 12),
            Btn('Tiếp ▶', kind: BtnKind.primary, huge: true, onTap: () => next()),
          ]),
        ),
      );
}

class _DemoView extends StatefulWidget {
  final DemoStep step;
  final Next next;
  const _DemoView({required this.step, required this.next});
  @override
  State<_DemoView> createState() => _DemoViewState();
}

class _DemoViewState extends State<_DemoView> {
  List<int> lit = [];
  bool heard = false;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _timers.add(Timer(const Duration(milliseconds: 1800), _play));
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _play() async {
    await synth.ensure();
    final notes = widget.step.notes;
    for (var i = 0; i < notes.length; i++) {
      synth.playChord(notes[i], dur: 0.7, vel: 0.7, delay: i * 0.8);
      _timers.add(Timer(Duration(milliseconds: i * 800), () => setState(() => lit = notes[i])));
    }
    _timers.add(Timer(Duration(milliseconds: notes.length * 800 + 200), () => setState(() {
          lit = [];
          heard = true;
        })));
  }

  @override
  Widget build(BuildContext context) {
    final all = widget.step.notes.expand((x) => x).toList();
    final r = rangeForNotes(all);
    final fmap = lit.length > 1 ? lessonFingers(lit, chord: true) : lessonFingers(widget.step.notes.where((c) => c.length == 1).expand((x) => x).toList());
    return Column(children: [
      Expanded(child: SingleChildScrollView(child: Column(children: [
        Guide(widget.step.text, compact: true),
        Wrap(spacing: 10, children: [Btn('🔁 Nghe lại', onTap: _play), Btn('Tiếp ▶', kind: BtnKind.primary, onTap: heard ? () => widget.next() : null)]),
      ]))),
      PianoKeyboard(lo: r.$1, hi: r.$2, hints: {for (final m in lit) m: null}, fingers: pickFingers(fmap, lit), skin: _skin(context)),
    ]);
  }
}

class _FindView extends StatefulWidget {
  final FindStep step;
  final Next next;
  const _FindView({required this.step, required this.next});
  @override
  State<_FindView> createState() => _FindViewState();
}

class _FindViewState extends State<_FindView> {
  int count = 0, wrong = 0;
  Map<int, bool> marks = {};
  StreamSubscription<NoteEvt>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = hub.events.listen(_onNote);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onNote(NoteEvt e) {
    final s = widget.step;
    if (!e.on || count >= s.count) return;
    final lenient = _lenient(context);
    bool ok;
    if (s.target.isEmpty) {
      ok = true;
    } else if (s.chord) {
      if (lenient) {
        ok = s.target.any((t) => pc(t) == pc(e.m));
      } else if (!s.target.contains(e.m)) {
        ok = false;
      } else if (s.target.every(hub.held.contains)) {
        ok = true;
      } else {
        return;
      }
    } else if (s.anyOctave || lenient) {
      ok = s.target.any((t) => pc(t) == pc(e.m));
    } else {
      ok = s.target.contains(e.m);
    }
    setState(() => marks = {e.m: ok});
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => marks = {});
    });
    if (!ok) {
      wrong++;
      return;
    }
    synth.sfx(Sfx.coin);
    setState(() => count++);
    if (count >= s.count) Future.delayed(const Duration(milliseconds: 700), () => widget.next(wrong == 0 ? 3 : wrong <= 2 ? 2 : 1));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.step;
    final r = s.target.isEmpty || s.anyOctave ? (48, 72) : rangeForNotes(s.target);
    final showHints = s.target.isNotEmpty && (count == 0 || wrong > 0);
    final hints = {if (showHints) for (final t in s.target) t: null as String?};
    return Column(children: [
      Expanded(child: SingleChildScrollView(child: Column(children: [
        Guide(s.text, compact: true),
        Wrap(spacing: 6, children: [for (var i = 0; i < s.count; i++) Opacity(opacity: i < count ? 1 : 0.3, child: Text('⭐', style: TextStyle(fontSize: i < count ? 40 : 34)))]),
      ]))),
      PianoKeyboard(lo: r.$1, hi: r.$2, hints: hints, marks: marks, fingers: pickFingers(lessonFingers(s.target, chord: s.chord), hints.keys), skin: _skin(context)),
    ]);
  }
}

class _EchoView extends StatefulWidget {
  final EchoStep step;
  final Next next;
  const _EchoView({required this.step, required this.next});
  @override
  State<_EchoView> createState() => _EchoViewState();
}

class _EchoViewState extends State<_EchoView> {
  int round = 0, pos = 0, mistakes = 0, roundMistakes = 0;
  bool listening = true;
  int? lit;
  Map<int, bool> marks = {};
  StreamSubscription<NoteEvt>? _sub;
  final _timers = <Timer>[];

  @override
  void initState() {
    super.initState();
    _sub = hub.events.listen(_onNote);
    _timers.add(Timer(const Duration(milliseconds: 1800), _play));
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _play() async {
    await synth.ensure();
    setState(() {
      listening = true;
      pos = 0;
    });
    final notes = widget.step.notes;
    for (var i = 0; i < notes.length; i++) {
      synth.play(notes[i], dur: 0.5, delay: i * 0.6);
      _timers.add(Timer(Duration(milliseconds: i * 600), () => setState(() => lit = notes[i])));
    }
    _timers.add(Timer(Duration(milliseconds: notes.length * 600 + 100), () => setState(() {
          lit = null;
          listening = false;
        })));
  }

  void _onNote(NoteEvt e) {
    if (!e.on || listening) return;
    final want = widget.step.notes[pos];
    final ok = e.m == want || (_lenient(context) && pc(e.m) == pc(want));
    setState(() => marks = {e.m: ok});
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => marks = {});
    });
    if (!ok) {
      mistakes++;
      setState(() => roundMistakes++);
      return;
    }
    if (pos + 1 < widget.step.notes.length) {
      setState(() => pos++);
      return;
    }
    synth.sfx(Sfx.ok);
    if (round + 1 >= widget.step.rounds) {
      Future.delayed(const Duration(milliseconds: 600), () => widget.next(mistakes == 0 ? 3 : mistakes <= 3 ? 2 : 1));
    } else {
      setState(() {
        roundMistakes = 0;
        round++;
      });
      _timers.add(Timer(const Duration(milliseconds: 600), _play));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.step;
    final r = rangeForNotes(s.notes);
    final hints = <int, String?>{};
    if (lit != null) {
      hints[lit!] = null;
    } else if (!listening && (round == 0 || roundMistakes > 0)) {
      hints[s.notes[pos]] = null;
    }
    return Column(children: [
      Expanded(child: SingleChildScrollView(child: Column(children: [
        Guide(listening ? 'Nghe nè...' : s.text, compact: true, auto: !listening),
        Wrap(spacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Pill('Lượt ${round + 1}/${s.rounds}'),
          for (var i = 0; i < s.notes.length; i++) CircleAvatar(radius: 17, backgroundColor: i < pos ? C.good : Colors.white, child: Text('♪', style: TextStyle(color: i < pos ? Colors.white : C.ink))),
          Btn('🔁 Nghe lại', small: true, onTap: listening ? null : _play),
        ]),
      ]))),
      PianoKeyboard(lo: r.$1, hi: r.$2, hints: hints, marks: marks, fingers: pickFingers(lessonFingers(s.notes), hints.keys), skin: _skin(context)),
    ]);
  }
}

class _DynView extends StatefulWidget {
  final DynStep step;
  final Next next;
  const _DynView({required this.step, required this.next});
  @override
  State<_DynView> createState() => _DynViewState();
}

class _DynViewState extends State<_DynView> {
  int i = 0, correct = 0, tries = 0;
  String feedback = '';
  StreamSubscription<NoteEvt>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = hub.events.listen(_onNote);
    _say();
  }

  void _say() {
    if (i < widget.step.prompts.length) speech.speak(widget.step.prompts[i] == 'f' ? 'Chơi mạnh!' : 'Chơi nhẹ thôi!');
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onNote(NoteEvt e) {
    final prompts = widget.step.prompts;
    if (!e.on || i >= prompts.length) return;
    final loud = e.src == Source.mic ? e.v >= 0.5 : e.v >= 0.62;
    final soft = e.src == Source.mic ? e.v < 0.5 : e.v <= 0.55;
    final ok = prompts[i] == 'f' ? loud : soft;
    tries++;
    if (ok || tries >= 3) {
      if (ok) {
        correct++;
        synth.sfx(Sfx.ok);
      }
      tries = 0;
      setState(() {
        feedback = ok ? 'Đúng rồi!' : 'Không sao, mình làm tiếp nhé!';
        i++;
      });
      if (i >= prompts.length) {
        final ratio = correct / prompts.length;
        Future.delayed(const Duration(milliseconds: 600), () => widget.next(ratio >= 0.9 ? 3 : ratio >= 0.6 ? 2 : 1));
      } else {
        _say();
      }
    } else {
      setState(() => feedback = prompts[i] == 'f' ? 'Mạnh hơn chút nữa!' : 'Nhẹ hơn chút nữa!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final prompt = i < widget.step.prompts.length ? widget.step.prompts[i] : null;
    return Column(children: [
      Expanded(child: SingleChildScrollView(child: Column(children: [
        Guide(widget.step.text, compact: true),
        if (prompt != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: C.shadow),
            child: Column(children: [
              Text(prompt, style: TextStyle(fontSize: 90, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, fontFamily: 'serif', color: prompt == 'f' ? const Color(0xffe03131) : const Color(0xff74c0fc))),
              Text(prompt == 'f' ? 'MẠNH' : 'nhẹ', style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ),
        Padding(padding: const EdgeInsets.all(8), child: Text(feedback, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
      ]))),
      PianoKeyboard(lo: 60, hi: 72, skin: _skin(context)),
    ]);
  }
}
