import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../music/notes.dart';
import 'synth.dart';

/// YIN pitch estimate in Hz, or -1 when no clear pitch is found.
double detectPitch(Float32List buf, int sampleRate) {
  final minTau = sampleRate ~/ 1400;
  final maxTau = math.min(sampleRate ~/ 60, buf.length ~/ 2);
  final win = buf.length - maxTau;
  final diff = Float32List(maxTau + 1);
  for (var tau = 1; tau <= maxTau; tau++) {
    var sum = 0.0;
    for (var i = 0; i < win; i++) {
      final d = buf[i] - buf[i + tau];
      sum += d * d;
    }
    diff[tau] = sum;
  }
  var running = 0.0;
  diff[0] = 1;
  for (var tau = 1; tau <= maxTau; tau++) {
    running += diff[tau];
    diff[tau] = running > 0 ? diff[tau] * tau / running : 1;
  }
  for (var tau = minTau; tau < maxTau; tau++) {
    if (diff[tau] < 0.15) {
      while (tau + 1 < maxTau && diff[tau + 1] < diff[tau]) {
        tau++;
      }
      final a = diff[tau - 1], b = diff[tau], c = tau + 1 <= maxTau ? diff[tau + 1] : b;
      final denom = a + c - 2 * b;
      final shift = denom != 0 ? (a - c) / (2 * denom) : 0;
      return sampleRate / (tau + shift);
    }
  }
  return -1;
}

/// Listens to an acoustic piano through the microphone and reports single notes.
class MicListener {
  static const sampleRate = 22050;
  static const window = 2048;
  final _rec = AudioRecorder();
  StreamSubscription<Uint8List>? _sub;
  final _buf = Float32List(window);
  final _ring = Float32List(window);
  var _pos = 0;
  var _filled = 0, _sinceLast = 0;
  var _current = -1, _candidate = -1, _candidateFrames = 0, _silentFrames = 0;
  var _lastRms = 0.0;
  double level = 0;
  double sensitivity = 0.012;

  Future<void> start({required void Function(int m, double v) onNote, required void Function(int m) onOff}) async {
    if (!await _rec.hasPermission()) throw Exception('Chưa được cấp quyền dùng micro.');
    final stream = await _rec.startStream(RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: sampleRate,
      numChannels: 1,
      iosConfig: const IosRecordConfig(categoryOptions: [IosAudioCategoryOption.defaultToSpeaker, IosAudioCategoryOption.mixWithOthers, IosAudioCategoryOption.allowBluetooth]),
    ));
    _sub = stream.listen((bytes) {
      final data = ByteData.sublistView(bytes);
      for (var i = 0; i + 1 < bytes.length; i += 2) {
        _ring[_pos] = data.getInt16(i, Endian.little) / 32768.0;
        _pos = (_pos + 1) % window;
        if (_filled < window) _filled++;
        if (++_sinceLast >= 768 && _filled == window) {
          _sinceLast = 0;
          for (var j = 0; j < window; j++) {
            _buf[j] = _ring[(_pos + j) % window];
          }
          _analyse(onNote, onOff);
        }
      }
    });
  }

  void _analyse(void Function(int, double) onNote, void Function(int) onOff) {
    var sum = 0.0;
    for (final s in _buf) {
      sum += s * s;
    }
    final rms = math.sqrt(sum / window);
    level = rms;
    final selfPlaying = DateTime.now().millisecondsSinceEpoch < synth.busyUntil;
    if (rms < sensitivity || selfPlaying) {
      if (++_silentFrames >= 3 && _current >= 0) {
        onOff(_current);
        _current = -1;
      }
      _lastRms = rms;
      return;
    }
    _silentFrames = 0;
    final f = detectPitch(_buf, sampleRate);
    if (f <= 0) return;
    final m = freqToMidi(f).round();
    if (m < 28 || m > 100) return;
    if (m == _candidate) {
      _candidateFrames++;
    } else {
      _candidate = m;
      _candidateFrames = 1;
    }
    final onset = rms > _lastRms * 1.8 && rms > sensitivity * 3;
    if (_candidateFrames >= 2 && (m != _current || onset)) {
      if (_current >= 0) onOff(_current);
      _current = m;
      onNote(m, math.min(1, rms * 8));
    }
    _lastRms = rms * 0.7 + _lastRms * 0.3;
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await _rec.stop();
    } catch (e) {
      debugPrint('mic stop: $e');
    }
    _current = -1;
    _filled = 0;
  }
}
