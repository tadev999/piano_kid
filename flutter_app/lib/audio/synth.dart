import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';

import '../music/notes.dart';

const _sr = 22050;

Uint8List _wav(Float32List samples) {
  final data = ByteData(44 + samples.length * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, _sr, Endian.little);
  data.setUint32(28, _sr * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  str(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    data.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
  }
  return data.buffer.asUint8List();
}

double _tri(double phase) {
  final x = phase - phase.floorToDouble();
  return 4 * (x < 0.5 ? x : 1 - x) - 1;
}

/// Piano-like tone: triangle + harmonics with a fast attack and natural decay.
Float32List _pianoSamples(int m) {
  final f = midiToFreq(m);
  final decay = 0.5 + math.max(0, (84 - m) / 40);
  final len = (_sr * math.min(3.2, decay * 2.4)).round();
  final out = Float32List(len);
  final sub = m < 55 ? 0.15 : 0.02;
  for (var i = 0; i < len; i++) {
    final t = i / _sr;
    final env = t < 0.006 ? t / 0.006 : 0.35 + 0.65 * math.exp(-(t - 0.006) / (decay * 0.25));
    final tail = t < 0.3 ? 1.0 : math.exp(-(t - 0.3) / decay);
    final s = 0.6 * _tri(f * t) + 0.25 * math.sin(2 * math.pi * 2 * f * t) + 0.08 * math.sin(2 * math.pi * 3 * f * t) + sub * math.sin(math.pi * f * t);
    out[i] = s * env * tail * 0.55;
  }
  final fade = math.min(len, _sr ~/ 50);
  for (var i = 0; i < fade; i++) {
    out[len - 1 - i] *= i / fade;
  }
  return out;
}

Float32List _tones(List<(double freq, double delay, double dur)> parts, {bool triangle = false, double vol = 0.25}) {
  final total = parts.map((p) => p.$2 + p.$3).reduce(math.max) + 0.05;
  final out = Float32List((total * _sr).round());
  for (final (freq, delay, dur) in parts) {
    final start = (delay * _sr).round();
    final n = (dur * _sr).round();
    for (var i = 0; i < n && start + i < out.length; i++) {
      final t = i / _sr;
      final env = t < 0.01 ? t / 0.01 : math.exp(-(t - 0.01) / (dur * 0.35));
      final w = triangle ? _tri(freq * t) : math.sin(2 * math.pi * freq * t);
      out[start + i] += w * env * vol;
    }
  }
  return out;
}

enum Sfx { ok, coin, pop, tap, win, levelup }

class Synth {
  final _so = SoLoud.instance;
  final _notes = <int, AudioSource>{};
  final _pending = <int, Future<AudioSource>>{};
  final _held = <int, SoundHandle>{};
  final _sfx = <Sfx, AudioSource>{};
  AudioSource? _clickHi, _clickLo;
  final _timers = <Timer>{};
  final _scheduled = <SoundHandle>{};
  bool sfxOn = true;
  bool ready = false;

  /// Wall-clock ms until which the app itself is producing sound (used to ignore microphone feedback).
  int busyUntil = 0;
  Future<void>? _initFuture;

  Future<void> ensure() => _initFuture ??= _init();

  Future<void> _init() async {
    if (!_so.isInitialized) await _so.init(bufferSize: 1024, channels: Channels.mono);
    _clickHi = await _so.loadMem('click-hi.wav', _wav(_tones([(1600, 0, 0.05)], vol: 0.45)));
    _clickLo = await _so.loadMem('click-lo.wav', _wav(_tones([(1100, 0, 0.05)], vol: 0.3)));
    const seqs = {
      Sfx.ok: [(880.0, 0.0, 0.12), (1320.0, 0.08, 0.18)],
      Sfx.coin: [(988.0, 0.0, 0.08), (1319.0, 0.07, 0.25)],
      Sfx.pop: [(600.0, 0.0, 0.06)],
      Sfx.tap: [(1200.0, 0.0, 0.04)],
      Sfx.win: [(523.0, 0.0, 0.15), (659.0, 0.12, 0.15), (784.0, 0.24, 0.15), (1047.0, 0.36, 0.5)],
      Sfx.levelup: [(392.0, 0.0, 0.12), (523.0, 0.1, 0.12), (659.0, 0.2, 0.12), (784.0, 0.3, 0.12), (1047.0, 0.4, 0.6)],
    };
    for (final e in seqs.entries) {
      _sfx[e.key] = await _so.loadMem('sfx-${e.key.name}.wav', _wav(_tones(e.value, triangle: e.key == Sfx.win || e.key == Sfx.levelup)));
    }
    ready = true;
    unawaited(_prewarm());
  }

  Future<void> _prewarm() async {
    for (var m = 48; m <= 84; m++) {
      await _source(m);
      await Future<void>.delayed(Duration.zero);
    }
  }

  Future<AudioSource> _source(int m) {
    final s = _notes[m];
    if (s != null) return Future.value(s);
    return _pending[m] ??= _so.loadMem('n$m.wav', _wav(_pianoSamples(m))).then((src) {
      _notes[m] = src;
      return src;
    });
  }

  double _vol(double vel) => 0.25 + vel * 0.6;

  Future<void> noteOn(int m, [double vel = 0.7]) async {
    if (!ready) await ensure();
    noteOff(m);
    final h = await _so.play(await _source(m), volume: _vol(vel));
    _held[m] = h;
  }

  void noteOff(int m) {
    final h = _held.remove(m);
    if (h == null) return;
    _fadeStop(h, 0.12);
  }

  void _fadeStop(SoundHandle h, double sec) {
    try {
      _so.fadeVolume(h, 0, Duration(milliseconds: (sec * 1000).round()));
      _so.scheduleStop(h, Duration(milliseconds: (sec * 1000).round() + 30));
    } catch (_) {/* handle already finished */}
  }

  void _later(double delaySec, void Function() fn) {
    if (delaySec <= 0.001) {
      fn();
      return;
    }
    late Timer t;
    t = Timer(Duration(microseconds: (delaySec * 1e6).round()), () {
      _timers.remove(t);
      fn();
    });
    _timers.add(t);
  }

  /// Plays a note for `dur` seconds after `delay` seconds.
  void play(int m, {double dur = 0.5, double vel = 0.7, double delay = 0}) {
    busyUntil = math.max(busyUntil, DateTime.now().millisecondsSinceEpoch + ((delay + dur) * 1000).round() + 250);
    _later(delay, () async {
      if (!ready) await ensure();
      final h = await _so.play(await _source(m), volume: _vol(vel));
      _scheduled.add(h);
      _later(dur, () {
        _scheduled.remove(h);
        _fadeStop(h, 0.08);
      });
    });
  }

  void playChord(List<int> notes, {double dur = 0.6, double vel = 0.65, double delay = 0}) {
    for (final m in notes) {
      play(m, dur: dur, vel: vel, delay: delay);
    }
  }

  void click({bool accent = false, double delay = 0}) {
    _later(delay, () {
      final s = accent ? _clickHi : _clickLo;
      if (s != null) _so.play(s);
    });
  }

  void sfx(Sfx kind) {
    if (!sfxOn) return;
    final s = _sfx[kind];
    if (s != null) _so.play(s, volume: 0.9);
  }

  void allOff() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    for (final m in _held.keys.toList()) {
      noteOff(m);
    }
    for (final h in _scheduled) {
      _fadeStop(h, 0.03);
    }
    _scheduled.clear();
    busyUntil = 0;
  }
}

final synth = Synth();
