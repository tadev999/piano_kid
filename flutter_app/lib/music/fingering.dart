import 'dart:math' as math;
import '../models.dart';
import 'notes.dart';

const _letterOfPc = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];

/// Position on the white-key ladder (sharps share their natural's slot).
int dia(int m) => (m ~/ 12) * 7 + _letterOfPc[pc(m)];

int _fingerAt(int d, int anchor, bool right) => (right ? d - anchor + 1 : anchor - d + 1).clamp(1, 5);

/// Chooses a five-finger hand position per chord so the hand moves as little as possible.
List<List<int>> fingerSequence(List<List<int>> chords, bool right, [List<bool> breaths = const []]) {
  if (chords.isEmpty) return [];
  final cands = chords.map((c) {
    final ds = c.map(dia);
    final lo = ds.reduce(math.min), hi = ds.reduce(math.max);
    final out = <int>[];
    if (right) {
      for (var a = lo; a >= hi - 4; a--) {
        out.add(a);
      }
    } else {
      for (var a = hi; a <= lo + 4; a++) {
        out.add(a);
      }
    }
    return out.isEmpty ? [right ? lo : hi] : out;
  }).toList();

  double local(int i, int a) {
    final c = chords[i];
    return c.length == 1 && isBlack(c[0]) && _fingerAt(dia(c[0]), a, right) == 1 ? 0.3 : 0;
  }

  double trans(int i, int pa, int a) {
    var cost = pa == a ? 0.0 : 1 + 0.15 * (pa - a).abs();
    final p = chords[i - 1], c = chords[i];
    if (p.length == 1 && c.length == 1) {
      final pd = dia(p[0]), cd = dia(c[0]);
      final pf = _fingerAt(pd, pa, right), cf = _fingerAt(cd, a, right);
      if (p[0] != c[0] && pf == cf) cost += 0.8;
      if (p[0] == c[0] && pf != cf) cost += 0.9;
      final crossing = right ? (cd - pd) * (cf - pf) < 0 : (cd - pd) * (cf - pf) > 0;
      if (crossing) cost += 0.7;
    }
    // Moving the hand is easy after a long note or a rest.
    return i < breaths.length && breaths[i] ? cost * 0.4 : cost;
  }

  final cost = <List<double>>[cands[0].asMap().entries.map((e) => local(0, e.value)).toList()];
  final back = <List<int>>[List.filled(cands[0].length, -1)];
  for (var i = 1; i < chords.length; i++) {
    final row = <double>[], br = <int>[];
    for (final a in cands[i]) {
      var best = double.infinity, arg = 0;
      for (var k = 0; k < cands[i - 1].length; k++) {
        final v = cost[i - 1][k] + trans(i, cands[i - 1][k], a);
        if (v < best) {
          best = v;
          arg = k;
        }
      }
      row.add(best + local(i, a));
      br.add(arg);
    }
    cost.add(row);
    back.add(br);
  }
  final last = cost.last;
  var k = last.indexOf(last.reduce(math.min));
  final anchors = List.filled(chords.length, 0);
  for (var i = chords.length - 1; i >= 0; i--) {
    anchors[i] = cands[i][k];
    k = back[i][k];
  }
  return [for (var i = 0; i < chords.length; i++) chords[i].map((m) => _fingerAt(dia(m), anchors[i], right)).toList()];
}

/// Writes `fingers` onto each step. Overrides list fingers in note order (low to high within a chord).
List<Step> applyFingering(List<Step> steps, {List<int>? rf, List<int>? lf}) {
  for (final right in [true, false]) {
    final idx = <int>[], chords = <List<int>>[], breaths = <bool>[];
    var prevEnd = double.negativeInfinity, prevLen = 0.0;
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final notes = (right ? s.notes.where((m) => !s.lh.contains(m)) : s.lh).toList()..sort();
      if (notes.isEmpty) continue;
      idx.add(i);
      chords.add(notes);
      breaths.add(prevLen >= 2 || s.t - prevEnd > 0.01);
      prevEnd = s.t + s.d;
      prevLen = s.d;
    }
    final manual = right ? rf : lf;
    var pos = 0;
    final fingers = manual != null
        ? chords.map((c) => c.map((_) => pos < manual.length ? manual[pos++] : 1).toList()).toList()
        : fingerSequence(chords, right, breaths);
    for (var j = 0; j < idx.length; j++) {
      for (var q = 0; q < chords[j].length; q++) {
        steps[idx[j]].fingers[chords[j][q]] = fingers[j][q];
      }
    }
  }
  return steps;
}

typedef FingerHint = ({int f, bool left});

/// Fingers for short lesson exercises: C position for single notes, five-finger shape for chords.
Map<int, FingerHint> lessonFingers(List<int> notes, {bool chord = false}) {
  final out = <int, FingerHint>{};
  if (notes.isEmpty) return out;
  final left = chord || notes.reduce(math.max) < 60;
  final sorted = notes.toSet().toList()..sort();
  if (!chord) {
    final base = (sorted.first ~/ 12) * 12;
    final offsets = sorted.map((m) => dia(m) - dia(base)).toList();
    if (offsets.every((o) => o <= 4)) {
      for (var i = 0; i < sorted.length; i++) {
        out[sorted[i]] = (f: left ? 5 - offsets[i] : offsets[i] + 1, left: left);
      }
      return out;
    }
  }
  final fs = chord ? fingerSequence([sorted], !left).first : fingerSequence(notes.map((m) => [m]).toList(), !left).map((x) => x.first).toList();
  final src = chord ? sorted : notes;
  for (var i = 0; i < src.length; i++) {
    out.putIfAbsent(src[i], () => (f: fs[i], left: left));
  }
  return out;
}
