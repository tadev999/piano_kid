import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../audio/input.dart';
import '../audio/synth.dart';
import '../content/songs.dart';
import '../logic/progress.dart';
import '../models.dart';
import '../music/notes.dart';
import '../state/app_state.dart';
import '../ui/common.dart';
import '../ui/kit.dart';
import '../ui/piano.dart';
import '../ui/widgets.dart';

class GameResult {
  final int stars, score, total;
  final bool perfect;
  final double? acc;
  const GameResult(this.stars, this.score, this.total, {this.perfect = false, this.acc});
}

typedef OnGameFinish = void Function(GameResult);

const gameInfo = <GameKind, ({String name, String emoji, String desc})>{
  GameKind.catchNotes: (name: 'Bắt nốt rơi', emoji: '🫧', desc: 'Bấm đúng phím trước khi bong bóng chạm đất'),
  GameKind.ear: (name: 'Đoán tiếng', emoji: '👂', desc: 'Nghe nốt nhạc rồi chơi lại'),
  GameKind.rhythm: (name: 'Nhảy theo nhịp', emoji: '🦘', desc: 'Nhảy qua chướng ngại đúng nhịp'),
  GameKind.detective: (name: 'Thám tử bản nhạc', emoji: '🕵️', desc: 'Tìm nốt bị chơi sai trong bài hát'),
};

bool _lenient(BuildContext c) => c.read<AppState>().child?.input == InputKind.mic;
String? _skin(BuildContext c) => c.watch<AppState>().child?.equipped.skin;

class _Bubble {
  final int id, m;
  double y;
  final double speed;
  int? popped;
  _Bubble(this.id, this.m, this.y, this.speed);
}

class CatchGame extends StatefulWidget {
  final GameConfig config;
  final OnGameFinish onFinish;
  const CatchGame({super.key, required this.config, required this.onFinish});
  @override
  State<CatchGame> createState() => _CatchGameState();
}

class _CatchGameState extends State<CatchGame> with SingleTickerProviderStateMixin {
  late final notes = widget.config.notes ?? n('C4 D4 E4');
  late final duration = widget.config.duration ?? 40;
  late final range = rangeForNotes(notes);
  late final layout = {for (final k in keyLayout(range.$1, range.$2)) k.m: k};
  final _bubbles = <_Bubble>[];
  int caught = 0, missed = 0, _id = 0;
  bool running = false, _done = false;
  late final Ticker _ticker = createTicker(_tick);
  final _sw = Stopwatch();
  double _nextSpawn = 0.4, _last = 0;
  StreamSubscription<NoteEvt>? _sub;
  final _rnd = math.Random();

  @override
  void initState() {
    super.initState();
    _sub = hub.events.listen((e) {
      if (!e.on || !running) return;
      final lenient = _lenient(context);
      final cands = _bubbles.where((b) => b.popped == null && (b.m == e.m || (lenient && pc(b.m) == pc(e.m)))).toList()..sort((a, b) => b.y.compareTo(a.y));
      if (cands.isNotEmpty) {
        cands.first.popped = _sw.elapsedMilliseconds;
        caught++;
        synth.sfx(Sfx.pop);
      }
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    super.dispose();
  }

  void _tick(Duration _) {
    final t = _sw.elapsedMilliseconds / 1000;
    final dt = t - _last;
    _last = t;
    final progress = (t / duration).clamp(0.0, 1.0);
    if (t >= _nextSpawn && t < duration - 2) {
      _bubbles.add(_Bubble(_id++, notes[_rnd.nextInt(notes.length)], -0.1, 0.17 + progress * 0.15));
      _nextSpawn = t + (1.7 - progress * 0.8);
    }
    for (final b in _bubbles) {
      if (b.popped == null) b.y += b.speed * dt;
    }
    _bubbles.removeWhere((b) {
      if (b.popped != null) return _sw.elapsedMilliseconds - b.popped! > 350;
      if (b.y > 1.02) {
        missed++;
        return true;
      }
      return false;
    });
    setState(() {});
    if (t >= duration && _bubbles.every((b) => b.popped != null) && !_done) {
      _done = true;
      _ticker.stop();
      final ratio = caught / math.max(1, caught + missed);
      widget.onFinish(GameResult(ratio >= 0.9 ? 3 : ratio >= 0.7 ? 2 : 1, caught, caught + missed, acc: ratio, perfect: missed == 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = math.max(0, (duration - _sw.elapsedMilliseconds / 1000).ceil());
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xffe7f5ff), Color(0xffd0ebff)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Pill('🫧 $caught'), const SizedBox(width: 8), Pill('⏳ ${running ? left : duration}s')])),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final sz = (box.maxWidth * 0.07).clamp(44.0, 70.0);
            return Stack(children: [
              for (final b in _bubbles)
                if (layout[b.m] != null)
                  Positioned(
                    left: (layout[b.m]!.left + layout[b.m]!.width / 2) * box.maxWidth - sz / 2,
                    top: b.y * box.maxHeight - sz / 2,
                    child: AnimatedScale(
                      scale: b.popped != null ? 1.8 : 1,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedOpacity(
                        opacity: b.popped != null ? 0 : 1,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          width: sz,
                          height: sz,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: noteColor(b.m), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0x22000000), offset: Offset(-4, -4), spreadRadius: -2)]),
                          child: Text(solfege(b.m), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: sz * 0.28)),
                        ),
                      ),
                    ),
                  ),
              if (!running)
                Positioned.fill(
                  child: Container(
                    color: Colors.white38,
                    alignment: Alignment.center,
                    child: Btn('▶ Bắt đầu', kind: BtnKind.primary, huge: true, pulse: true, onTap: () async {
                      await synth.ensure();
                      setState(() => running = true);
                      _sw.start();
                      _ticker.start();
                    }),
                  ),
                ),
            ]);
          }),
        ),
        PianoKeyboard(lo: range.$1, hi: range.$2, skin: _skin(context)),
      ]),
    );
  }
}

class EarGame extends StatefulWidget {
  final GameConfig config;
  final OnGameFinish onFinish;
  const EarGame({super.key, required this.config, required this.onFinish});
  @override
  State<EarGame> createState() => _EarGameState();
}

class _EarGameState extends State<EarGame> {
  late final pool = widget.config.notes ?? n('C4 D4 E4');
  late final rounds = widget.config.rounds ?? 6;
  late final len = widget.config.melodyLen ?? 1;
  late final range = rangeForNotes(pool);
  int round = 0, pos = 0, mistakes = 0, firstTry = 0;
  List<int> target = [];
  String phase = 'intro'; // intro | listen | answer | ok
  Map<int, bool> marks = {};
  StreamSubscription<NoteEvt>? _sub;
  final _rnd = math.Random();

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

  List<int> _newTarget() {
    final t = <int>[];
    for (var i = 0; i < len; i++) {
      var m = pool[_rnd.nextInt(pool.length)];
      if (len > 1 && t.isNotEmpty && m == t.last && pool.length > 1) m = pool[(pool.indexOf(m) + 1) % pool.length];
      t.add(m);
    }
    return t;
  }

  void _play(List<int> t) {
    setState(() => phase = 'listen');
    for (var i = 0; i < t.length; i++) {
      synth.play(t[i], dur: 0.5, delay: i * 0.65);
    }
    Future.delayed(Duration(milliseconds: t.length * 650 + 150), () {
      if (mounted) setState(() => phase = 'answer');
    });
  }

  void _begin() async {
    await synth.ensure();
    target = _newTarget();
    pos = 0;
    mistakes = 0;
    _play(target);
  }

  void _onNote(NoteEvt e) {
    if (!e.on || phase != 'answer') return;
    final want = target[pos];
    final ok = e.m == want || (_lenient(context) && pc(e.m) == pc(want));
    setState(() => marks = {e.m: ok});
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => marks = {});
    });
    if (!ok) {
      mistakes++;
      pos = 0;
      Future.delayed(const Duration(milliseconds: 500), () => _play(target));
      return;
    }
    if (pos + 1 < target.length) {
      setState(() => pos++);
      return;
    }
    synth.sfx(Sfx.ok);
    if (mistakes == 0) firstTry++;
    setState(() => phase = 'ok');
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (round + 1 >= rounds) {
        widget.onFinish(GameResult(firstTry >= rounds * 0.9 ? 3 : firstTry >= rounds * 0.6 ? 2 : 1, firstTry, rounds, perfect: firstTry == rounds, acc: firstTry / rounds));
        return;
      }
      round++;
      target = _newTarget();
      pos = 0;
      mistakes = 0;
      _play(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hints = <int, String?>{};
    if (phase == 'answer' && mistakes >= 2 && pos < target.length) hints[target[pos]] = null;
    final text = switch (phase) {
      'intro' => 'Nghe ${len > 1 ? '$len nốt' : 'một nốt'} rồi chơi lại giống hệt nhé!',
      'listen' => 'Nghe kỹ nè...',
      'ok' => 'Đúng rồi! Giỏi quá!',
      _ => mistakes >= 2 ? 'Mình gợi ý phím sáng nhé!' : mistakes > 0 ? 'Gần đúng rồi! Nghe lại nhé.' : 'Đến lượt bạn!',
    };
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(8),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Pill('🎯 ${round + (phase == 'ok' ? 1 : 0)}/$rounds'),
          const SizedBox(width: 8),
          if (phase != 'intro') Btn('🔁 Nghe lại', small: true, onTap: phase == 'listen' ? null : () => _play(target)),
        ]),
      ),
      Expanded(
        child: SingleChildScrollView(
          child: Column(children: [
            Guide(text, size: 90, auto: phase != 'listen', mood: phase == 'ok' ? Mood.cheer : Mood.happy, compact: true),
            Wrap(spacing: 6, children: [
              for (var i = 0; i < target.length; i++)
                CircleAvatar(radius: 19, backgroundColor: i < pos || phase == 'ok' ? C.good : Colors.white, child: Text('♪', style: TextStyle(color: i < pos || phase == 'ok' ? Colors.white : C.ink))),
            ]),
            if (phase == 'intro') Padding(padding: const EdgeInsets.all(12), child: Btn('▶ Bắt đầu', kind: BtnKind.primary, huge: true, pulse: true, onTap: _begin)),
          ]),
        ),
      ),
      PianoKeyboard(lo: range.$1, hi: range.$2, hints: hints, marks: marks, labels: 'c', skin: _skin(context)),
    ]);
  }
}

class _Obstacle {
  final double beat, len;
  String? judged;
  _Obstacle(this.beat, this.len);
}

class RhythmGame extends StatefulWidget {
  final GameConfig config;
  final OnGameFinish onFinish;
  const RhythmGame({super.key, required this.config, required this.onFinish});
  @override
  State<RhythmGame> createState() => _RhythmGameState();
}

class _RhythmGameState extends State<RhythmGame> with SingleTickerProviderStateMixin {
  late final pattern = widget.config.pattern ?? const [1.0, 1.0, 1.0, 1.0];
  late final bpm = widget.config.bpm ?? 80;
  late final spb = 60 / bpm;
  List<_Obstacle> obs = [];
  late final double endBeat;
  int _startMs = 0, _lastClick = -99, _jumpAt = 0;
  double beat = -4;
  bool running = false;
  String? feedback;
  int _fbId = 0;
  late final Ticker _ticker = createTicker(_tick);
  StreamSubscription<NoteEvt>? _sub;

  @override
  void initState() {
    super.initState();
    var t = 0.0;
    final list = <_Obstacle>[];
    for (var rep = 0; rep < 2; rep++) {
      for (final d in pattern) {
        list.add(_Obstacle(t, d));
        t += d;
      }
    }
    obs = list;
    endBeat = t + 1;
    _sub = hub.events.listen((e) {
      if (e.on) _tap(e.at);
    });
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  bool _onKey(KeyEvent e) {
    if (e is KeyDownEvent && e.logicalKey == LogicalKeyboardKey.space) {
      _tap(nowMs());
      return true;
    }
    return false;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  void _start() async {
    await synth.ensure();
    for (final o in obs) {
      o.judged = null;
    }
    _startMs = nowMs() + (4 * spb * 1000).round();
    _lastClick = -99;
    setState(() => running = true);
    _ticker.start();
  }

  void _tick(Duration _) {
    final b = (nowMs() - _startMs) / 1000 / spb;
    final whole = b.floor();
    if (whole > _lastClick && b < endBeat) {
      _lastClick = whole;
      synth.click(accent: whole % 4 == 0);
    }
    for (final o in obs) {
      if (o.judged == null && b - o.beat > 0.5) o.judged = 'miss';
    }
    setState(() => beat = b);
    if (b > endBeat) {
      _ticker.stop();
      final credit = obs.fold<double>(0, (s, o) => s + (o.judged == 'perfect' ? 1 : o.judged == 'good' ? 0.6 : 0));
      final acc = credit / obs.length;
      setState(() => running = false);
      widget.onFinish(GameResult(acc >= 0.85 ? 3 : acc >= 0.6 ? 2 : 1, credit.round(), obs.length, acc: acc));
    }
  }

  void _tap(int at) {
    if (!running) return;
    setState(() => _jumpAt = nowMs());
    final b = (at - _startMs) / 1000 / spb;
    final open = obs.where((o) => o.judged == null).toList()..sort((x, y) => (x.beat - b).abs().compareTo((y.beat - b).abs()));
    if (open.isEmpty || (open.first.beat - b).abs() > 0.5) return;
    final err = (open.first.beat - b).abs() * spb * 1000;
    open.first.judged = err <= 150 ? 'perfect' : err <= 300 ? 'good' : 'miss';
    synth.sfx(open.first.judged == 'miss' ? Sfx.tap : Sfx.ok);
    setState(() {
      feedback = open.first.judged == 'perfect' ? 'Chuẩn!' : open.first.judged == 'good' ? 'Gần đúng!' : 'Ối!';
      _fbId++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child;
    final jumping = nowMs() - _jumpAt < 350;
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xffebfbee), Color(0xffb2f2bb)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Pill('🥁 $bpm nhịp/phút'), if (running && beat < 0) ...[const SizedBox(width: 8), Pill('Đếm: ${(-beat).ceil()}', fontSize: 22)]])),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth;
            const pxPerBeat = 0.22;
            return Stack(children: [
              Positioned(left: 0, right: 0, bottom: 0, height: 18, child: Container(color: const Color(0xff8ce99a))),
              Positioned(left: w * 0.2, top: 0, bottom: 0, width: 6, child: Container(decoration: const BoxDecoration(color: C.gold, boxShadow: [BoxShadow(color: C.gold, blurRadius: 16)]))),
              if (running)
                for (final o in obs)
                  if (0.2 + (o.beat - beat) * pxPerBeat > -0.1 && 0.2 + (o.beat - beat) * pxPerBeat < 1.1)
                    Positioned(
                      left: w * (0.2 + (o.beat - beat) * pxPerBeat),
                      bottom: 24,
                      width: math.max(w * 0.06, w * (o.len * pxPerBeat) - 4),
                      height: 54,
                      child: Opacity(
                        opacity: o.judged == 'miss' ? 0.4 : 1,
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: o.judged == 'perfect' ? const Color(0xffb2f2bb) : o.judged == 'good' ? const Color(0xffffec99) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x1a000000), offset: Offset(0, 4))]),
                          child: Text(o.len >= 2 ? '🪨 Ta-a' : '🍄 Ta', overflow: TextOverflow.clip, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                left: w * 0.2 - 30,
                bottom: jumping ? 110 : 24,
                child: child == null ? const SizedBox() : AvatarView(child.avatar, hat: child.equipped.hat, size: 64),
              ),
              if (feedback != null) Align(alignment: const Alignment(0, -0.8), child: PopIn(key: ValueKey(_fbId), child: Text(feedback!, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800, color: Color(0xffe67700))))),
              if (!running)
                Positioned.fill(
                  child: Container(
                    color: Colors.white54,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(12),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Bấm phím đàn bất kỳ, nút Nhảy hoặc phím cách khi chướng ngại vật chạm vạch!', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Btn('▶ Bắt đầu', kind: BtnKind.primary, huge: true, pulse: true, onTap: _start),
                    ]),
                  ),
                ),
            ]);
          }),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Listener(onPointerDown: (_) => _tap(nowMs()), child: const Btn('🦘 Nhảy!', kind: BtnKind.gold, huge: true, onTap: _noop)),
        ),
      ]),
    );
  }
}

void _noop() {}

class DetectiveGame extends StatefulWidget {
  final GameConfig config;
  final OnGameFinish onFinish;
  const DetectiveGame({super.key, required this.config, required this.onFinish});
  @override
  State<DetectiveGame> createState() => _DetectiveGameState();
}

class _DetectiveGameState extends State<DetectiveGame> {
  late final rounds = widget.config.rounds ?? 4;
  late final len = widget.config.melodyLen ?? 6;
  late final List<int> melody = () {
    final a = arrangement(widget.config.songId ?? 'twinkle', 2) ?? arrangement(widget.config.songId ?? 'twinkle', 1)!;
    return a.steps.map((s) => s.notes.where((m) => !s.lh.contains(m)).reduce(math.max)).toList();
  }();
  final _rnd = math.Random();
  int round = 0, mistakes = 0, score = 0, playing = -1;
  int? picked;
  late ({List<int> correct, List<int> wrong, int wrongIdx}) data = _make();
  final _timers = <Timer>[];

  ({List<int> correct, List<int> wrong, int wrongIdx}) _make() {
    final start = _rnd.nextInt(math.max(1, melody.length - len));
    final correct = melody.sublist(start, math.min(melody.length, start + len));
    final wrongIdx = 1 + _rnd.nextInt(correct.length - 1);
    final orig = correct[wrongIdx];
    final options = [orig - 2, orig - 1, orig + 1, orig + 2].where((m) => !isBlack(m) && m != orig).toList();
    final wrong = [...correct]..[wrongIdx] = options[_rnd.nextInt(options.length)];
    return (correct: correct, wrong: wrong, wrongIdx: wrongIdx);
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    super.dispose();
  }

  void _play(List<int> notes) async {
    await synth.ensure();
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    for (var i = 0; i < notes.length; i++) {
      synth.play(notes[i], dur: 0.45, delay: i * 0.55);
      _timers.add(Timer(Duration(milliseconds: i * 550), () => setState(() => playing = i)));
    }
    _timers.add(Timer(Duration(milliseconds: notes.length * 550), () => setState(() => playing = -1)));
  }

  void _choose(int i) {
    if (picked != null) return;
    if (i != data.wrongIdx) {
      setState(() => mistakes++);
      synth.sfx(Sfx.tap);
      return;
    }
    setState(() => picked = i);
    synth.sfx(Sfx.ok);
    if (mistakes == 0) score++;
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      if (round + 1 >= rounds) {
        widget.onFinish(GameResult(score >= rounds ? 3 : score >= rounds * 0.5 ? 2 : 1, score, rounds, perfect: score == rounds));
        return;
      }
      setState(() {
        round++;
        data = _make();
        picked = null;
        mistakes = 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = picked != null ? 'Thám tử giỏi quá! Tìm ra rồi!' : mistakes > 0 ? 'Chưa phải nốt đó. Nghe lại thật kỹ nhé!' : 'Nghe bản nhạc, rồi chạm vào nốt bị sai.';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(children: [
        Pill('🕵️ ${round + 1}/$rounds'),
        Guide(text, size: 90, compact: true),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          for (var i = 0; i < data.wrong.length; i++)
            GestureDetector(
              onTap: () => _choose(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 76,
                height: 76,
                transform: Matrix4.diagonal3Values(playing == i ? 1.15 : 1, playing == i ? 1.15 : 1, 1),
                decoration: BoxDecoration(color: picked == i ? C.good : playing == i ? const Color(0xffffe066) : Colors.white, shape: BoxShape.circle, boxShadow: C.shadow),
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('♪', style: TextStyle(fontSize: 30)), Text('${i + 1}', style: const TextStyle(color: C.muted))]),
              ),
            ),
        ]),
        const SizedBox(height: 20),
        Wrap(spacing: 10, children: [Btn('▶ Nghe bản bị sai', kind: BtnKind.primary, onTap: () => _play(data.wrong)), Btn('✓ Nghe bản đúng', kind: BtnKind.ghost, onTap: () => _play(data.correct))]),
      ]),
    );
  }
}

class GameRunner extends StatefulWidget {
  final GameKind kind;
  final GameConfig config;
  final bool embedded;
  final void Function(int stars)? onDone;
  final VoidCallback? onExit;
  const GameRunner({super.key, required this.kind, required this.config, this.embedded = false, this.onDone, this.onExit});
  @override
  State<GameRunner> createState() => _GameRunnerState();
}

class _GameRunnerState extends State<GameRunner> {
  GameResult? result;
  Outcome? outcome;
  int attempt = 0;
  final _sw = Stopwatch()..start();

  void _finish(GameResult r) {
    synth.sfx(r.stars >= 2 ? Sfx.win : Sfx.ok);
    final out = context.read<AppState>().record(Activity(
          kind: 'game', ref: widget.kind.name, title: gameInfo[widget.kind]!.name, stars: r.stars, sec: _sw.elapsedMilliseconds / 1000,
          gameKind: widget.kind, perfect: r.perfect, rhythmAcc: widget.kind == GameKind.rhythm ? r.acc : null, noteAcc: r.acc,
        ));
    setState(() {
      result = r;
      outcome = out;
    });
  }

  @override
  Widget build(BuildContext context) {
    final info = gameInfo[widget.kind]!;
    final r = result;
    final game = switch (widget.kind) {
      GameKind.catchNotes => CatchGame(key: ValueKey(attempt), config: widget.config, onFinish: _finish),
      GameKind.ear => EarGame(key: ValueKey(attempt), config: widget.config, onFinish: _finish),
      GameKind.rhythm => RhythmGame(key: ValueKey(attempt), config: widget.config, onFinish: _finish),
      GameKind.detective => DetectiveGame(key: ValueKey(attempt), config: widget.config, onFinish: _finish),
    };
    return Stack(children: [
      Column(children: [
        if (!widget.embedded)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: SafeArea(
              bottom: false,
              child: Row(children: [
                if (widget.onExit != null) IconBtn('⬅', onTap: widget.onExit),
                const SizedBox(width: 8),
                Text(info.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(info.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)), Text(info.desc, style: const TextStyle(color: C.muted))])),
              ]),
            ),
          ),
        Expanded(child: game),
      ]),
      if (r != null)
        ResultOverlay(
          child: ResultPanel(
            title: r.stars >= 3 ? 'Xuất sắc!' : r.stars >= 2 ? 'Giỏi lắm!' : 'Hoàn thành!',
            stars: r.stars,
            outcome: widget.embedded ? null : outcome,
            lines: ['Điểm: ${r.score}/${r.total}'],
            actions: [
              Btn('🔁 Chơi lại', kind: BtnKind.ghost, onTap: () => setState(() {
                    result = null;
                    outcome = null;
                    attempt++;
                    _sw.reset();
                  })),
              if (widget.embedded) Btn('Tiếp tục ➜', kind: BtnKind.primary, onTap: () => widget.onDone?.call(r.stars)),
              if (!widget.embedded && widget.onExit != null) Btn('Xong ✓', kind: BtnKind.primary, onTap: widget.onExit),
            ],
          ),
        ),
    ]);
  }
}
