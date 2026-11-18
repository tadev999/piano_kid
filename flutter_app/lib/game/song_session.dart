import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../audio/input.dart';
import '../audio/playback.dart';
import '../audio/synth.dart';
import '../content/songs.dart';
import '../data/api.dart';
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
import 'song_engine.dart';

class SongDone {
  final int stars;
  final double noteAcc, rhythmAcc;
  const SongDone(this.stars, this.noteAcc, this.rhythmAcc);
}

const _praise = ['Tuyệt vời!', 'Giỏi quá!', 'Siêu đỉnh!', 'Hay lắm!', 'Cứ thế nhé!'];

class SongSession extends StatefulWidget {
  final String songId;
  final int level;
  final PlayMode? forcedMode;
  final bool embedded;
  final void Function(SongDone)? onDone;
  final void Function(int level)? onNavigateLevel;
  final VoidCallback? onExit;
  const SongSession({super.key, required this.songId, required this.level, this.forcedMode, this.embedded = false, this.onDone, this.onNavigateLevel, this.onExit});
  @override
  State<SongSession> createState() => _SongSessionState();
}

class _SongSessionState extends State<SongSession> with SingleTickerProviderStateMixin {
  late final Song song = songById(widget.songId)!;
  late final Arrangement arr = arrangement(widget.songId, widget.level)!;
  late PlayMode mode = widget.forcedMode ?? arr.defaultMode;
  late Hand hand = arr.hands;
  double speed = 1;
  bool metronome = false, showFingers = true, staffView = false;
  (double, double)? range;
  SongEngine? engine;
  EngineResult? result;
  Outcome? outcome;
  String? praise;
  int _praiseId = 0;
  late final Ticker _ticker;
  final _frame = ValueNotifier(0);
  int _lastRender = 0;
  StreamSubscription<NoteEvt>? _sub;
  final _startedAt = Stopwatch()..start();
  late final (int, int) _range = rangeOf(arr.steps);
  late final Set<int> _lhNotes = {for (final s in arr.steps) ...s.lh};

  bool get _lenient => context.read<AppState>().child?.input == InputKind.mic;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    _sub = hub.events.listen((e) => engine?.input(e));
    WidgetsBinding.instance.addPostFrameCallback((_) => _rebuildEngine());
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    engine?.stop();
    synth.allOff();
    _frame.dispose();
    super.dispose();
  }

  void _rebuildEngine() {
    engine?.stop();
    final e = SongEngine(arr: arr, mode: mode, hand: hand, speed: speed, metronome: metronome, lenient: _lenient, range: range);
    e.onChange = () {
      if (mounted) setState(() {});
    };
    e.onHit = (good) {
      if (good && e.streak > 0 && e.streak % 8 == 0) {
        setState(() {
          praise = _praise[math.Random().nextInt(_praise.length)];
          _praiseId++;
        });
        final id = _praiseId;
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted && id == _praiseId) setState(() => praise = null);
        });
      }
    };
    e.onFinish = (r) => _finish(r, e);
    setState(() {
      engine = e;
      result = null;
    });
  }

  void _set(VoidCallback fn) {
    fn();
    _rebuildEngine();
  }

  void _onTick(Duration _) {
    final e = engine;
    if (e == null) return;
    final now = nowMs();
    e.tick(now);
    _frame.value++;
    if ((e.status == EngineStatus.demo || (e.status == EngineStatus.playing && e.mode == PlayMode.timed)) && now - _lastRender > 90) {
      _lastRender = now;
      setState(() {});
    }
  }

  void _finish(EngineResult r, SongEngine e) {
    final partial = e.hand != arr.hands || e.range != null;
    final stars = partial ? math.min(1, r.stars) : r.stars;
    final res = r.withStars(stars);
    final sec = _startedAt.elapsedMilliseconds / 1000;
    _startedAt.reset();
    synth.sfx(stars >= 2 ? Sfx.win : Sfx.ok);
    speech.speak(stars >= 3 ? 'Xuất sắc! Ba ngôi sao!' : stars >= 2 ? 'Giỏi lắm! Bạn được hai ngôi sao!' : stars >= 1 ? 'Bạn đã hoàn thành bài hát!' : 'Cố lên! Mình thử chậm hơn nhé!');
    final app = context.read<AppState>();
    final child = app.child;
    Outcome? out;
    if (child != null) {
      final key = songKey(widget.songId, widget.level);
      out = app.record(Activity(kind: 'song', ref: key, title: song.title, stars: stars, sec: sec, noteAcc: r.noteAcc, rhythmAcc: r.rhythmAcc, weak: r.weak));
      final u = app.user;
      if (u != null && app.settings.allowRecording && !partial && r.hits > 0 && r.events.isNotEmpty) {
        final rec = Recording(
          id: newId(), childId: child.id, songId: widget.songId, level: widget.level, title: '${song.title} (${arr.label})',
          events: r.events.take(3800).toList(), createdAt: DateTime.now().millisecondsSinceEpoch, stars: stars, noteAcc: r.noteAcc, rhythmAcc: r.rhythmAcc, durationMs: r.durationMs,
        );
        api.saveRecording(u.uid, rec).catchError((_) {});
        final improved = out.bestImproved;
        app.updateChild((c) {
          final sp = c.songs[key];
          if (sp == null) return c;
          final n = c.clone();
          final p = n.songs[key]!;
          p.firstRec ??= rec.id;
          if (improved || p.bestRec == null) p.bestRec = rec.id;
          return n;
        });
      }
    }
    setState(() {
      result = res;
      outcome = out;
    });
  }

  void _start() async {
    await synth.ensure();
    setState(() {
      result = null;
      outcome = null;
    });
    _startedAt
      ..reset()
      ..start();
    engine?.start();
  }

  @override
  Widget build(BuildContext context) {
    final e = engine;
    final status = e?.status ?? EngineStatus.idle;
    final busy = status == EngineStatus.countin || status == EngineStatus.playing || status == EngineStatus.demo;
    final child = context.watch<AppState>().child;

    final hints = <int, String?>{};
    if (e != null && (status == EngineStatus.playing || status == EngineStatus.countin)) {
      for (final m in e.expected()) {
        hints[m] = null;
      }
    }
    if (e != null && status == EngineStatus.demo) {
      for (final s in e.steps) {
        if (s.t <= e.beat && e.beat < s.t + s.d) {
          for (final m in s.notes) {
            hints[m] = null;
          }
        }
      }
    }
    final marks = <int, bool>{};
    e?.wrongFlash.forEach((m, t) {
      if (nowMs() - t < 400) marks[m] = false;
    });
    final fingerHints = <int, FingerHint>{};
    if (e != null && showFingers) {
      final active = status == EngineStatus.demo
          ? e.steps.where((s) => s.t <= e.beat && e.beat < s.t + s.d)
          : e.mode == PlayMode.wait
              ? (e.cur < e.steps.length ? [e.steps[e.cur]] : <Step>[])
              : e.steps.where((s) => s.t >= e.beat - 0.2 && s.t <= e.beat + 1);
      for (final s in active) {
        for (final m in s.notes) {
          final f = s.fingers[m];
          if (f != null && (status == EngineStatus.demo || hints.containsKey(m))) fingerHints[m] = (f: f, left: s.lh.contains(m));
        }
      }
    }
    List<int> fingersOf(bool left) => (fingerHints.values.where((x) => x.left == left).map((x) => x.f).toSet().toList()..sort());
    final usesLeft = _lhNotes.isNotEmpty && hand != Hand.r;
    final usesRight = arr.steps.any((s) => s.notes.length > s.lh.length) && hand != Hand.l;
    final next = song.levels.where((l) => l.level == widget.level + 1).firstOrNull;
    final r = result;

    return Container(
      color: const Color(0xff1b1840),
      child: Stack(children: [
        Column(children: [
          Container(
            color: Colors.white.withValues(alpha: 0.94),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
              if (!widget.embedded && widget.onExit != null) IconBtn('⬅', onTap: widget.onExit),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(song.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(width: 6),
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(song.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  Text('${song.subtitle} · ${arr.label}${range != null ? ' · luyện đoạn' : ''}', style: const TextStyle(color: C.muted, fontSize: 12)),
                ]),
              ]),
              if (!widget.embedded) Seg<int>(options: [for (final l in song.levels) (l.level, l.label)], value: widget.level, onChanged: busy ? null : (l) => widget.onNavigateLevel?.call(l)),
              Seg<PlayMode>(
                options: const [(PlayMode.wait, '🐢 Chờ bé'), (PlayMode.timed, '⏱️ Theo nhịp')],
                value: mode,
                onChanged: busy || widget.forcedMode != null ? null : (m) => _set(() {
                      mode = m;
                      if (m == PlayMode.timed) metronome = true;
                    }),
              ),
              if (arr.hands == Hand.b)
                Seg<Hand>(options: const [(Hand.r, '✋ Phải'), (Hand.l, '🤚 Trái'), (Hand.b, '🙌 Hai tay')], value: hand, onChanged: busy ? null : (h) => _set(() => hand = h)),
              Seg<double>(options: const [(0.5, '0.5×'), (0.75, '0.75×'), (1.0, '1×')], value: speed, onChanged: busy ? null : (s) => _set(() => speed = s)),
              IconBtn('🥁', on: metronome, tooltip: 'Máy đếm nhịp', onTap: busy ? null : () => _set(() => metronome = !metronome)),
              IconBtn('🖐️', on: showFingers, tooltip: 'Hiện ngón tay', onTap: () => setState(() => showFingers = !showFingers)),
              IconBtn(staffView ? '🌧️' : '🎼', tooltip: 'Đổi cách xem', onTap: () => setState(() => staffView = !staffView)),
            ]),
          ),
          SizedBox(height: 6, child: LinearProgressIndicator(value: e?.progress() ?? 0, backgroundColor: Colors.white12, color: const Color(0xffffa94d))),
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: e == null
                    ? const SizedBox()
                    : staffView
                        ? Container(color: Colors.white, child: CustomPaint(painter: StaffPainter(steps: e.steps, current: e.cur, isPlayer: (s, m) => e.playerNotes(s).contains(m), fingers: showFingers)))
                        : CustomPaint(
                            painter: FallingPainter(
                              steps: e.steps, lo: _range.$1, hi: _range.$2, bpb: e.bpb, beat: () => e.beat, hits: e.hits,
                              isPlayer: (s, m) => e.status == EngineStatus.demo || e.playerNotes(s).contains(m),
                              current: () => e.mode == PlayMode.wait ? e.cur : null, showFingers: showFingers, repaint: _frame,
                            ),
                          ),
              ),
              if (status == EngineStatus.countin && e != null)
                Center(child: Text('${math.max(1, (-e.beat).ceil())}', style: const TextStyle(fontSize: 140, fontWeight: FontWeight.w800, color: Colors.white, shadows: [Shadow(color: Colors.black38, offset: Offset(0, 6))]))),
              if (praise != null)
                Align(alignment: const Alignment(0, -0.4), child: PopIn(key: ValueKey(_praiseId), child: Text(praise!, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Color(0xffffe066), shadows: [Shadow(color: Color(0xffe67700), offset: Offset(0, 4))])))),
              if ((status == EngineStatus.idle || status == EngineStatus.done) && r == null)
                Positioned.fill(
                  child: Container(
                    color: const Color(0x8c1b1840),
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Mascot(size: 90, mood: Mood.cheer),
                        Btn('▶ Bắt đầu', kind: BtnKind.primary, huge: true, pulse: true, onTap: _start),
                        const SizedBox(height: 10),
                        Btn('👂 Nghe mẫu', kind: BtnKind.ghost, onTap: () async {
                          await synth.ensure();
                          engine?.demo();
                        }),
                        const SizedBox(height: 8),
                        Text(
                          mode == PlayMode.wait ? 'Chế độ Chờ bé: nốt chỉ đi tiếp khi bạn bấm đúng.' : 'Theo nhịp: bấm khi nốt chạm vạch vàng. Đúng nhịp mới có sao thứ 3!',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xffdee2e6)),
                        ),
                        if (child?.input == InputKind.mic) const Text('🎤 Đang nghe qua micro – đặt máy gần đàn nhé.', style: TextStyle(color: Color(0xffdee2e6))),
                      ]),
                    ),
                  ),
                ),
              if (busy && status != EngineStatus.countin)
                Positioned(top: 10, right: 10, child: Btn('⏹ Dừng', small: true, onTap: () => engine?.stop())),
            ]),
          ),
          if (showFingers) HandGuide(right: fingersOf(false), left: fingersOf(true), showLeft: usesLeft, showRight: usesRight),
          PianoKeyboard(lo: _range.$1, hi: _range.$2, hints: hints, marks: marks, fingers: fingerHints, skin: child?.equipped.skin, leftHand: _lhNotes),
        ]),
        if (r != null)
          ResultOverlay(
            child: ResultPanel(
              title: r.stars >= 3 ? 'Xuất sắc!' : r.stars >= 2 ? 'Giỏi lắm!' : r.stars >= 1 ? 'Hoàn thành!' : 'Cố lên nhé!',
              stars: r.stars,
              outcome: widget.embedded ? null : outcome,
              lines: [
                '🎯 Đúng nốt: ${(r.noteAcc * 100).round()}%',
                mode == PlayMode.timed ? '⏱️ Đúng nhịp: ${(r.rhythmAcc * 100).round()}%' : '💡 Chơi chế độ Theo nhịp để lấy sao thứ 3!',
              ],
              actions: widget.embedded
                  ? [
                      Btn('🔁 Chơi lại', kind: BtnKind.ghost, onTap: _start),
                      Btn('Tiếp tục ➜', kind: BtnKind.primary, onTap: () => widget.onDone?.call(SongDone(math.max(1, r.stars), r.noteAcc, r.rhythmAcc))),
                    ]
                  : [
                      Btn('🔁 Chơi lại', kind: BtnKind.ghost, onTap: _start),
                      if (outcome?.suggestion == 'slower' && speed > 0.5)
                        Btn('🐢 Chơi chậm hơn', onTap: () => _set(() {
                              speed = speed == 1 ? 0.75 : 0.5;
                              mode = PlayMode.wait;
                            })),
                      if (r.worstBar >= 0 && r.wrong + (r.total - r.hits) > 2 && range == null)
                        Btn('🎯 Luyện đoạn khó', onTap: () => _set(() {
                              range = ((r.worstBar * arr.beatsPerBar).toDouble(), ((r.worstBar + 2) * arr.beatsPerBar).toDouble());
                              mode = PlayMode.wait;
                            })),
                      if (range != null) Btn('📜 Chơi cả bài', onTap: () => _set(() => range = null)),
                      if (mode == PlayMode.wait && r.stars >= 2)
                        Btn('⏱️ Thử theo nhịp', onTap: () => _set(() {
                              mode = PlayMode.timed;
                              metronome = true;
                            })),
                      if (next != null && (outcome?.suggestion == 'harder' || r.stars >= 2)) Btn('⬆ Cấp ${next.label}', kind: BtnKind.primary, onTap: () => widget.onNavigateLevel?.call(next.level)),
                      if (widget.onExit != null) Btn('Xong ✓', kind: BtnKind.primary, onTap: widget.onExit),
                    ],
            ),
          ),
      ]),
    );
  }
}
