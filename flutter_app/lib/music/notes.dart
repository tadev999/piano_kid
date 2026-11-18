import 'dart:math' as math;
import 'package:flutter/painting.dart';
import '../models.dart';

const _names = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
const _solfege = ['Đô', 'Đô#', 'Rê', 'Rê#', 'Mi', 'Fa', 'Fa#', 'Sol', 'Sol#', 'La', 'La#', 'Si'];
const _pcColors = [0xffff6b6b, 0xffc0392b, 0xffffa94d, 0xffd35400, 0xffffd43b, 0xff51cf66, 0xff2b8a3e, 0xff4dabf7, 0xff1864ab, 0xff9775fa, 0xff5f3dc4, 0xfff783ac];

int pc(int m) => ((m % 12) + 12) % 12;
bool isBlack(int m) => const {1, 3, 6, 8, 10}.contains(pc(m));
int octave(int m) => (m ~/ 12) - 1;
String noteName(int m) => '${_names[pc(m)]}${octave(m)}';
String solfege(int m) => _solfege[pc(m)];
Color noteColor(int m) => Color(_pcColors[pc(m)]);
double midiToFreq(num m) => 440 * math.pow(2, (m - 69) / 12).toDouble();
double freqToMidi(double f) => 69 + 12 * math.log(f / 440) / math.ln2;

int parseNote(String s) {
  final match = RegExp(r'^([A-Ga-g])([#b]?)(-?\d)$').firstMatch(s.trim());
  if (match == null) throw ArgumentError('Bad note: $s');
  final base = _names.indexOf(match.group(1)!.toUpperCase());
  final acc = match.group(2) == '#' ? 1 : match.group(2) == 'b' ? -1 : 0;
  return (int.parse(match.group(3)!) + 1) * 12 + base + acc;
}

/// Shorthand for a list of note names, e.g. n('C4 D4 E4').
List<int> n(String s) => s.trim().split(RegExp(r'\s+')).map(parseNote).toList();

/// Tokens: `C4` (1 beat), `C4:2`, `C3+E3+G3` (chord), `r:1` (rest), `|` (bar line, ignored).
List<Step> seq(String src, [double start = 0, bool left = false]) {
  final steps = <Step>[];
  var t = start;
  for (final tok in src.trim().split(RegExp(r'\s+'))) {
    if (tok.isEmpty || tok == '|') continue;
    final parts = tok.split(':');
    final d = parts.length > 1 ? double.parse(parts[1]) : 1.0;
    if (parts[0] != 'r') {
      final notes = parts[0].split('+').map(parseNote).toList();
      steps.add(Step(t: t, d: d, notes: notes, lh: left ? [...notes] : []));
    }
    t += d;
  }
  return steps;
}

/// Merges steps that start at the same beat into a single chord step.
List<Step> merge(List<List<Step>> tracks) {
  final map = <int, Step>{};
  for (final s in tracks.expand((x) => x)) {
    final key = (s.t * 1000).round();
    final cur = map[key];
    if (cur != null) {
      map[key] = Step(t: cur.t, d: math.max(cur.d, s.d), notes: [...cur.notes, ...s.notes], lh: [...cur.lh, ...s.lh]);
    } else {
      map[key] = Step(t: key / 1000, d: s.d, notes: [...s.notes], lh: [...s.lh]);
    }
  }
  return map.values.toList()..sort((a, b) => a.t.compareTo(b.t));
}

(int, int) rangeOf(List<Step> steps) {
  var lo = 127, hi = 0;
  for (final s in steps) {
    for (final m in s.notes) {
      lo = math.min(lo, m);
      hi = math.max(hi, m);
    }
  }
  return rangeForNotes(lo > hi ? [60, 72] : [lo, hi]);
}

(int, int) rangeForNotes(List<int> notes) {
  final lo = (notes.reduce(math.min) ~/ 12) * 12;
  var hi = ((notes.reduce(math.max) + 1) / 12).ceil() * 12;
  if (hi - lo < 12) hi = lo + 12;
  return (lo, hi);
}
