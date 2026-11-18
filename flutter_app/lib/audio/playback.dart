import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

import '../models.dart';
import 'synth.dart';

class NoteSpan {
  final int m;
  final double v;
  final int start, end;
  const NoteSpan(this.m, this.v, this.start, this.end);
}

/// Pairs on/off events into notes (times in ms).
List<NoteSpan> toSpans(List<PerfEvent> events) {
  final open = <int, PerfEvent>{};
  final spans = <NoteSpan>[];
  final sorted = [...events]..sort((a, b) => a.t.compareTo(b.t));
  for (final e in sorted) {
    if (e.on) {
      final prev = open[e.m];
      if (prev != null) spans.add(NoteSpan(e.m, prev.v, prev.t, e.t));
      open[e.m] = e;
    } else {
      final s = open.remove(e.m);
      if (s != null) spans.add(NoteSpan(e.m, s.v, s.t, e.t < s.t + 80 ? s.t + 80 : e.t));
    }
  }
  open.forEach((m, s) => spans.add(NoteSpan(m, s.v, s.t, s.t + 600)));
  return spans..sort((a, b) => a.start.compareTo(b.start));
}

/// Plays recorded events. `onActive` reports the currently sounding notes. Returns a stop function.
void Function() playEvents(List<PerfEvent> events, {void Function(Set<int>)? onActive, void Function()? onEnd}) {
  final spans = toSpans(events);
  if (spans.isEmpty) {
    onEnd?.call();
    return () {};
  }
  final offset = spans.first.start;
  for (final s in spans) {
    synth.play(s.m, dur: ((s.end - s.start) / 1000).clamp(0.12, 8), vel: s.v < 0.3 ? 0.3 : s.v, delay: (s.start - offset) / 1000 + 0.05);
  }
  final total = spans.map((s) => s.end).reduce((a, b) => a > b ? a : b) - offset;
  final sw = Stopwatch()..start();
  late Timer timer;
  timer = Timer.periodic(const Duration(milliseconds: 40), (_) {
    final t = sw.elapsedMilliseconds - 50 + offset;
    onActive?.call(spans.where((s) => s.start <= t && s.end > t).map((s) => s.m).toSet());
    if (t - offset > total + 300) {
      timer.cancel();
      onActive?.call({});
      onEnd?.call();
    }
  });
  return () {
    timer.cancel();
    synth.allOff();
    onActive?.call({});
  };
}

class Speech {
  final _tts = FlutterTts();
  bool enabled = true;
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    _ready = true;
    await _tts.setLanguage('vi-VN');
    await _tts.setPitch(1.15);
    await _tts.setSpeechRate(0.5);
  }

  Future<void> speak(String text, {void Function()? onEnd}) async {
    if (!enabled) {
      onEnd?.call();
      return;
    }
    await _init();
    await _tts.stop();
    _tts.setCompletionHandler(() => onEnd?.call());
    _tts.setErrorHandler((_) => onEnd?.call());
    await _tts.speak(text.replaceAll('♯', ' thăng'));
  }

  Future<void> stop() => _tts.stop();
}

final speech = Speech();
