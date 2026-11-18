import 'dart:math' as math;

import '../audio/input.dart';
import '../audio/synth.dart';
import '../models.dart';
import '../music/notes.dart';

enum EngineStatus { idle, countin, playing, demo, done }

class EngineResult {
  final int stars, hits, total, wrong, durationMs, worstBar;
  final double noteAcc, rhythmAcc;
  final List<PerfEvent> events;
  final Map<String, int> weak;
  const EngineResult({required this.stars, required this.noteAcc, required this.rhythmAcc, required this.hits, required this.total, required this.wrong, required this.events, required this.durationMs, required this.weak, required this.worstBar});
  EngineResult withStars(int s) =>
      EngineResult(stars: s, noteAcc: noteAcc, rhythmAcc: rhythmAcc, hits: hits, total: total, wrong: wrong, events: events, durationMs: durationMs, weak: weak, worstBar: worstBar);
}

const _timedWindowMs = 260;
const _onTimeMs = 170;

class SongEngine {
  final Arrangement arr;
  final PlayMode mode;
  final Hand hand;
  final double speed;
  final bool metronome;

  /// Microphone input is monophonic, so any note of a chord counts.
  final bool lenient;
  final (double, double)? range;
  late final List<Step> steps;

  EngineStatus status = EngineStatus.idle;
  double beat = 0;
  int cur = 0;
  final Set<String> hits = {};
  final Map<int, int> wrongFlash = {};
  int wrong = 0, onTime = 0, streak = 0;
  int _startMs = 0, _lastClickBeat = -99, _lastFrame = 0;
  final Set<int> _autoPlayed = {};
  final Set<String> _missed = {};
  final List<PerfEvent> _events = [];
  final Map<String, int> _weak = {};
  final Map<int, int> _barErrors = {};
  double _targetBeat = 0;
  void Function()? onChange;
  void Function(EngineResult)? onFinish;
  void Function(bool good)? onHit;

  SongEngine({required this.arr, required this.mode, required this.hand, required this.speed, required this.metronome, required this.lenient, this.range}) {
    final from = range?.$1 ?? double.negativeInfinity, to = range?.$2 ?? double.infinity;
    final offset = range?.$1 ?? 0;
    steps = arr.steps.where((s) => s.t >= from && s.t < to).map((s) => s.copyWith(t: s.t - offset)).toList();
  }

  double get secPerBeat => 60 / (arr.bpm * speed);
  int get bpb => arr.beatsPerBar;
  double get endBeat => steps.isEmpty ? 0 : steps.last.t + steps.last.d;

  List<int> playerNotes(Step s) {
    if (status == EngineStatus.demo) return const [];
    if (hand == Hand.b) return s.notes;
    if (hand == Hand.l) return s.lh;
    return s.notes.where((m) => !s.lh.contains(m)).toList();
  }

  List<int> autoNotes(Step s) {
    final p = playerNotes(s);
    return s.notes.where((m) => !p.contains(m)).toList();
  }

  int get total => steps.fold(0, (n, s) => n + (lenient && playerNotes(s).isNotEmpty ? 1 : playerNotes(s).length));

  List<int> expected() {
    if (mode == PlayMode.wait) {
      if (cur >= steps.length) return const [];
      return playerNotes(steps[cur]).where((m) => !hits.contains('$cur:$m')).toList();
    }
    final out = <int>[];
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (s.t >= beat - 0.2 && s.t <= beat + 1) out.addAll(playerNotes(s).where((m) => !hits.contains('$i:$m')));
    }
    return out;
  }

  void _reset() {
    hits.clear();
    _missed.clear();
    _autoPlayed.clear();
    wrongFlash.clear();
    _events.clear();
    _weak.clear();
    _barErrors.clear();
    wrong = onTime = streak = cur = 0;
    _lastClickBeat = -99;
  }

  void start() {
    _reset();
    status = EngineStatus.countin;
    final now = nowMs();
    _startMs = now + (bpb * secPerBeat * 1000).round();
    for (var i = 0; i < bpb; i++) {
      synth.click(accent: i == 0, delay: i * secPerBeat);
    }
    beat = -bpb.toDouble();
    _lastFrame = now;
    _skipAutoSteps();
    onChange?.call();
  }

  void demo() {
    _reset();
    status = EngineStatus.demo;
    _startMs = nowMs() + 300;
    beat = -0.5;
    onChange?.call();
  }

  void stop() {
    status = EngineStatus.idle;
    synth.allOff();
    onChange?.call();
  }

  void _playAuto(int i) {
    if (!_autoPlayed.add(i)) return;
    final s = steps[i];
    final notes = status == EngineStatus.demo ? s.notes : autoNotes(s);
    for (final m in notes) {
      synth.play(m, dur: s.d * secPerBeat * 0.95, vel: s.lh.contains(m) ? 0.45 : 0.6);
    }
  }

  void _skipAutoSteps() {
    while (cur < steps.length && playerNotes(steps[cur]).isEmpty) {
      cur++;
    }
    _targetBeat = cur < steps.length ? steps[cur].t : endBeat;
  }

  void tick(int now) {
    final dt = math.min(0.1, (now - _lastFrame) / 1000);
    _lastFrame = now;
    if (status == EngineStatus.idle || status == EngineStatus.done) return;
    final timeBeat = (now - _startMs) / 1000 / secPerBeat;

    if (status == EngineStatus.countin) {
      beat = timeBeat;
      if (timeBeat < 0) return;
      status = EngineStatus.playing;
      onChange?.call();
    }

    if (status == EngineStatus.demo || mode == PlayMode.timed) {
      beat = timeBeat;
      for (var i = 0; i < steps.length; i++) {
        if (steps[i].t <= beat) _playAuto(i);
      }
      if (metronome && status != EngineStatus.demo) {
        final b = beat.floor();
        if (b > _lastClickBeat && b >= 0) {
          _lastClickBeat = b;
          synth.click(accent: b % bpb == 0);
        }
      }
      if (status != EngineStatus.demo) _markMisses();
      if (beat > endBeat + 0.6) _finish();
      return;
    }

    // Wait mode: glide the playhead toward the step the child must play.
    for (var i = 0; i < cur; i++) {
      if (steps[i].t <= beat + 0.02) _playAuto(i);
    }
    final diff = _targetBeat - beat;
    final v = math.max(2, diff.abs() * 6) / secPerBeat;
    beat += diff.sign * math.min(diff.abs(), v * dt * secPerBeat);
    if (metronome) {
      final b = (beat + 1e-6).floor();
      if (b > _lastClickBeat && b >= 0 && diff.abs() < 0.05) {
        _lastClickBeat = b;
        synth.click(accent: b % bpb == 0);
      }
    }
  }

  void _markMisses() {
    final windowBeats = _timedWindowMs / 1000 / secPerBeat;
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      if (s.t + windowBeats >= beat) continue;
      final notes = playerNotes(s);
      final anyHit = notes.any((m) => hits.contains('$i:$m'));
      for (final m in notes) {
        final key = '$i:$m';
        if (hits.contains(key) || _missed.contains(key) || (lenient && anyHit)) continue;
        _missed.add(key);
        streak = 0;
        _weak[noteName(m)] = (_weak[noteName(m)] ?? 0) + 1;
        final bar = s.t ~/ bpb;
        _barErrors[bar] = (_barErrors[bar] ?? 0) + 1;
      }
    }
  }

  void input(NoteEvt e) {
    if (status == EngineStatus.playing || status == EngineStatus.countin) {
      _events.add(PerfEvent(math.max(0, e.at - _startMs), e.m, (e.v * 100).round() / 100, e.on));
    }
    if (!e.on) return;
    if (status == EngineStatus.countin && mode == PlayMode.timed) {
      final beatAt = (e.at - _startMs) / 1000 / secPerBeat;
      if (beatAt < -_timedWindowMs / 1000 / secPerBeat) return;
      status = EngineStatus.playing;
    } else if (status != EngineStatus.playing) {
      return;
    }
    if (mode == PlayMode.wait) {
      _inputWait(e.m);
    } else {
      _inputTimed(e.m, e.at);
    }
    onChange?.call();
  }

  bool _matches(int expected, int played) => expected == played || (lenient && pc(expected) == pc(played) && (expected - played).abs() <= 12);

  void _inputWait(int m) {
    if (cur >= steps.length) return;
    final s = steps[cur];
    final need = playerNotes(s);
    final target = need.where((x) => _matches(x, m) && !hits.contains('$cur:$x')).firstOrNull;
    if (target != null) {
      hits.add('$cur:$target');
      final done = lenient || need.every((x) => hits.contains('$cur:$x'));
      if (done) {
        if (lenient) hits.addAll(need.map((x) => '$cur:$x'));
        streak++;
        onHit?.call(true);
        _playAuto(cur);
        cur++;
        _skipAutoSteps();
        if (cur >= steps.length) Future.delayed(const Duration(milliseconds: 500), _finish);
      }
      return;
    }
    if (need.contains(m) && hits.contains('$cur:$m')) return;
    _registerWrong(m, need.firstOrNull, s);
  }

  void _registerWrong(int m, int? expected, Step s) {
    wrong++;
    streak = 0;
    wrongFlash[m] = nowMs();
    if (expected != null) _weak[noteName(expected)] = (_weak[noteName(expected)] ?? 0) + 1;
    final bar = s.t ~/ bpb;
    _barErrors[bar] = (_barErrors[bar] ?? 0) + 1;
    onHit?.call(false);
  }

  void _inputTimed(int m, int at) {
    final beatAt = (at - _startMs) / 1000 / secPerBeat;
    final windowBeats = _timedWindowMs / 1000 / secPerBeat;
    ({int i, int x, double err})? best;
    for (var i = 0; i < steps.length; i++) {
      final err = beatAt - steps[i].t;
      if (err.abs() > windowBeats) continue;
      final notes = playerNotes(steps[i]);
      if (lenient && notes.any((x) => hits.contains('$i:$x'))) continue;
      for (final x in notes) {
        if (hits.contains('$i:$x') || !_matches(x, m)) continue;
        if (best == null || err.abs() < best.err.abs()) best = (i: i, x: x, err: err);
      }
    }
    if (best != null) {
      hits.add('${best.i}:${best.x}');
      _missed.remove('${best.i}:${best.x}');
      if ((best.err * secPerBeat * 1000).abs() <= _onTimeMs) onTime++;
      streak++;
      onHit?.call(true);
      return;
    }
    final near = steps.where((s) => (beatAt - s.t).abs() < 1).firstOrNull ?? steps.first;
    _registerWrong(m, playerNotes(near).firstOrNull, near);
  }

  void _finish() {
    if (status == EngineStatus.done || status == EngineStatus.idle) return;
    final wasDemo = status == EngineStatus.demo;
    status = wasDemo ? EngineStatus.idle : EngineStatus.done;
    onChange?.call();
    if (!wasDemo) onFinish?.call(result());
  }

  EngineResult result() {
    final tot = math.max(1, total);
    final hitNotes = lenient
        ? [for (var i = 0; i < steps.length; i++) i].where((i) => playerNotes(steps[i]).any((m) => hits.contains('$i:$m'))).length
        : hits.length;
    final timed = mode == PlayMode.timed;
    final noteAcc = timed ? hitNotes / (tot + wrong * 0.5) : tot / (tot + wrong);
    final rhythmAcc = timed ? onTime / tot : 0.0;
    var stars = 1;
    if (noteAcc >= 0.9) stars = 2;
    if (timed && noteAcc >= 0.9 && rhythmAcc >= 0.75) stars = 3;
    if (timed && hitNotes / tot < 0.4) stars = 0;
    final worst = _barErrors.entries.fold<MapEntry<int, int>?>(null, (a, b) => a == null || b.value > a.value ? b : a);
    return EngineResult(
      stars: stars, noteAcc: math.min(1, noteAcc), rhythmAcc: math.min(1, rhythmAcc), hits: hitNotes, total: tot, wrong: wrong,
      events: List.of(_events), durationMs: nowMs() - _startMs, weak: Map.of(_weak), worstBar: worst?.key ?? -1,
    );
  }

  double progress() => endBeat <= 0 ? 0 : (beat / endBeat).clamp(0, 1);
}
