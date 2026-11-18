import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';

import '../models.dart';
import 'pitch.dart';
import 'synth.dart';

enum Source { screen, keys, midi, mic }

class NoteEvt {
  final bool on;
  final int m;
  final double v;
  final Source src;
  final int at; // ms, monotonic
  const NoteEvt(this.on, this.m, this.v, this.src, this.at);
}

final _clock = Stopwatch()..start();
int nowMs() => _clock.elapsedMilliseconds;

/// Single place every note input (on-screen keys, computer keyboard, MIDI, microphone) flows through.
class InputHub {
  final _ctrl = StreamController<NoteEvt>.broadcast();
  final Set<int> held = {};
  Source lastSource = Source.screen;
  bool muteMidiSound = false;
  MidiCommand? _midi;
  StreamSubscription<MidiPacket>? _midiSub;
  List<String> midiNames = [];
  MicListener? _mic;

  Stream<NoteEvt> get events => _ctrl.stream;
  double get micLevel => _mic?.level ?? 0;
  bool get micActive => _mic != null;

  void press(int m, double v, Source src) {
    if (src != Source.mic && !(src == Source.midi && muteMidiSound)) synth.noteOn(m, v);
    held.add(m);
    lastSource = src;
    _ctrl.add(NoteEvt(true, m, v, src, nowMs()));
  }

  void release(int m, Source src) {
    if (src != Source.mic) synth.noteOff(m);
    held.remove(m);
    _ctrl.add(NoteEvt(false, m, 0, src, nowMs()));
  }

  Future<List<String>> connectMidi() async {
    _midi ??= MidiCommand();
    final devices = await _midi!.devices ?? [];
    for (final d in devices) {
      if (!d.connected) {
        try {
          await _midi!.connectToDevice(d, awaitConnectionTimeout: const Duration(seconds: 5));
        } catch (_) {/* skip devices that refuse */}
      }
    }
    midiNames = devices.map((d) => d.name).toList();
    _midiSub ??= _midi!.onMidiPacketReceived?.listen((p) {
      final d = p.data;
      if (d.length < 3) return;
      final cmd = d[0] & 0xf0;
      if (cmd == 0x90 && d[2] > 0) {
        press(d[1], d[2] / 127, Source.midi);
      } else if (cmd == 0x80 || (cmd == 0x90 && d[2] == 0)) {
        release(d[1], Source.midi);
      }
    });
    if (devices.isEmpty) throw Exception('Chưa thấy đàn. Hãy cắm cáp USB (hoặc bật Bluetooth MIDI) rồi thử lại.');
    return midiNames;
  }

  Future<void> startMic() async {
    if (_mic != null) return;
    final mic = MicListener();
    _mic = mic;
    try {
      await mic.start(onNote: (m, v) => press(m, v, Source.mic), onOff: (m) => release(m, Source.mic));
    } catch (e) {
      _mic = null;
      rethrow;
    }
  }

  Future<void> stopMic() async {
    final m = _mic;
    _mic = null;
    await m?.stop();
  }

  Future<void> useInput(InputKind kind) async {
    if (kind == InputKind.mic) {
      await startMic();
    } else {
      await stopMic();
    }
    if (kind == InputKind.midi) await connectMidi();
  }
}

final hub = InputHub();

final _keymap = {
  LogicalKeyboardKey.keyA: 0, LogicalKeyboardKey.keyW: 1, LogicalKeyboardKey.keyS: 2, LogicalKeyboardKey.keyE: 3, LogicalKeyboardKey.keyD: 4,
  LogicalKeyboardKey.keyF: 5, LogicalKeyboardKey.keyT: 6, LogicalKeyboardKey.keyG: 7, LogicalKeyboardKey.keyY: 8, LogicalKeyboardKey.keyH: 9,
  LogicalKeyboardKey.keyU: 10, LogicalKeyboardKey.keyJ: 11, LogicalKeyboardKey.keyK: 12, LogicalKeyboardKey.keyO: 13, LogicalKeyboardKey.keyL: 14,
};

var _pcOctave = 4;
final _down = <LogicalKeyboardKey, int>{};

/// Computer keyboard as a piano (A W S E D F T G Y H U J K); Z / X change octave. Ignored while typing in a text field.
bool handleComputerKey(KeyEvent e) {
  final focus = FocusManager.instance.primaryFocus?.context?.widget;
  if (focus is EditableText) return false;
  if (e is KeyDownEvent) {
    if (e.logicalKey == LogicalKeyboardKey.keyZ) _pcOctave = (_pcOctave - 1).clamp(2, 6);
    if (e.logicalKey == LogicalKeyboardKey.keyX) _pcOctave = (_pcOctave + 1).clamp(2, 6);
    final off = _keymap[e.logicalKey];
    if (off != null && !_down.containsKey(e.logicalKey)) {
      final m = (_pcOctave + 1) * 12 + off;
      _down[e.logicalKey] = m;
      hub.press(m, 0.75, Source.keys);
    }
  } else if (e is KeyUpEvent) {
    final m = _down.remove(e.logicalKey);
    if (m != null) hub.release(m, Source.keys);
  }
  return false;
}
