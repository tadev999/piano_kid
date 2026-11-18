import 'dart:math' as math;

import 'package:flutter/material.dart' hide Step;

import '../models.dart';
import '../music/fingering.dart';
import '../music/notes.dart';
import 'piano.dart';

final _tpCache = <String, TextPainter>{};

TextPainter _tp(String text, double size, Color color, {FontWeight weight = FontWeight.w800}) {
  final key = '$text|$size|${color.toARGB32()}|${weight.value}';
  return _tpCache.putIfAbsent(key, () {
    if (_tpCache.length > 400) _tpCache.clear();
    return TextPainter(text: TextSpan(text: text, style: TextStyle(fontSize: size, color: color, fontWeight: weight, height: 1)), textDirection: TextDirection.ltr)..layout();
  });
}

void _drawCentered(Canvas c, TextPainter t, Offset center) => t.paint(c, center - Offset(t.width / 2, t.height / 2));

class FallingPainter extends CustomPainter {
  final List<Step> steps;
  final int lo, hi, bpb;
  final double Function() beat;
  final Set<String> hits;
  final bool Function(Step, int) isPlayer;
  final int? Function() current;
  final bool showFingers;
  FallingPainter({required this.steps, required this.lo, required this.hi, required this.bpb, required this.beat, required this.hits, required this.isPlayer, required this.current, required this.showFingers, required Listenable repaint})
      : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final hitY = h - 6;
    final b = beat();
    final pxPerBeat = math.max(40.0, h / (bpb * 1.6));
    final keys = {for (final k in keyLayout(lo, hi)) k.m: k};
    final lane = Paint()..color = const Color(0x0affffff);
    for (final k in keys.values) {
      if (k.black) canvas.drawRect(Rect.fromLTWH(k.left * w, 0, k.width * w, h), lane);
    }
    final barPaint = Paint()..color = const Color(0x2effffff);
    final firstBar = (b / bpb).floor();
    for (var bar = firstBar; bar < firstBar + 40; bar++) {
      final y = hitY - (bar * bpb - b) * pxPerBeat;
      if (y < 0) break;
      canvas.drawRect(Rect.fromLTWH(0, y, w, 1), barPaint);
    }
    final cur = current();
    final fs = (w / 60).clamp(10.0, 16.0);
    for (var i = 0; i < steps.length; i++) {
      final s = steps[i];
      final yBottom = hitY - (s.t - b) * pxPerBeat;
      final nh = math.max(14.0, s.d * pxPerBeat - 4);
      final yTop = yBottom - nh;
      if (yTop > h || yBottom < -20) continue;
      for (final m in s.notes) {
        final k = keys[m];
        if (k == null) continue;
        final player = isPlayer(s, m);
        final hit = hits.contains('$i:$m');
        final x = k.left * w + 2, kw = k.width * w - 4;
        final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x, yTop, kw, nh), const Radius.circular(8));
        final alpha = hit || !player ? 0.35 : 1.0;
        canvas.drawRRect(rr, Paint()..color = noteColor(m).withValues(alpha: alpha));
        if (i == cur && player && !hit) {
          canvas.drawRRect(rr, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..color = Colors.white);
        }
        if (s.lh.contains(m)) {
          canvas.drawRRect(rr, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..color = const Color(0x59000000));
        }
        final finger = showFingers && player ? s.fingers[m] : null;
        if (finger != null && kw > 12) {
          final r = (kw / 2 - 2).clamp(7.0, 11.0);
          final cy = yBottom - r - 3;
          canvas.drawCircle(Offset(x + kw / 2, cy), r, Paint()..color = Colors.white.withValues(alpha: alpha));
          _drawCentered(canvas, _tp('$finger', r * 1.3, s.lh.contains(m) ? const Color(0xff1971c2) : const Color(0xffd9480f)), Offset(x + kw / 2, cy));
          if (nh > r * 2 + 20) _drawCentered(canvas, _tp(solfege(m), fs, Colors.white), Offset(x + kw / 2, cy - r - 9));
        } else if (kw > 14 && nh > 16) {
          _drawCentered(canvas, _tp(solfege(m), fs, Colors.white), Offset(x + kw / 2, yBottom - math.min(12, nh / 2)));
        }
      }
    }
    final grad = Paint()
      ..shader = const LinearGradient(colors: [Color(0x00ffd43b), Color(0xf2ffd43b)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, hitY - 8, w, 14));
    canvas.drawRect(Rect.fromLTWH(0, hitY - 8, w, 14), grad);
  }

  @override
  bool shouldRepaint(covariant FallingPainter old) => true;
}

const _letterOfPc = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6];
int _diatonic(int m) => (m ~/ 12 - 1) * 7 + _letterOfPc[pc(m)];

/// Grand staff showing the next few steps, with the current one highlighted.
class StaffPainter extends CustomPainter {
  final List<Step> steps;
  final int current, count;
  final bool Function(Step, int) isPlayer;
  final bool fingers;
  StaffPainter({required this.steps, required this.current, required this.isPlayer, this.count = 8, this.fingers = true});

  static const half = 7.0, trebleBottom = 92.0, bassBottom = 182.0, left = 70.0;

  @override
  void paint(Canvas canvas, Size size) {
    final vw = left + count * 64 + 20;
    final scale = math.min(size.width / vw, size.height / 210);
    canvas.save();
    canvas.translate((size.width - vw * scale) / 2, (size.height - 210 * scale) / 2);
    canvas.scale(scale);
    final line = Paint()
      ..color = const Color(0xff495057)
      ..strokeWidth = 1.4;
    for (final bottom in [trebleBottom, bassBottom]) {
      for (var i = 0; i < 5; i++) {
        final y = bottom - i * half * 2;
        canvas.drawLine(Offset(10, y), Offset(vw - 10, y), line);
      }
    }
    canvas.drawLine(const Offset(10, trebleBottom - 56), const Offset(10, bassBottom), line..strokeWidth = 2);
    _tp('𝄞', 58, const Color(0xff343a40), weight: FontWeight.w400).paint(canvas, const Offset(14, trebleBottom - 68));
    _tp('𝄢', 40, const Color(0xff343a40), weight: FontWeight.w400).paint(canvas, const Offset(16, bassBottom - 58));
    final from = math.max(0, current - 1);
    for (var k = 0; k < count && from + k < steps.length; k++) {
      final i = from + k;
      final s = steps[i];
      final x = left + k * 64 + 24;
      final active = i == current;
      final op = i < current ? 0.35 : 1.0;
      if (active) canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 22, 10, 44, 190), const Radius.circular(10)), Paint()..color = const Color(0xfffff3bf));
      for (final m in s.notes) {
        final bass = s.lh.contains(m);
        final d = _diatonic(m);
        final y = bass ? bassBottom - (d - 18) * half : trebleBottom - (d - 30) * half;
        final ledgerPaint = Paint()
          ..color = const Color(0xff495057).withValues(alpha: op)
          ..strokeWidth = 1.4;
        final ledgers = <int>[];
        if (!bass) {
          for (var l = 28; l >= d; l -= 2) {
            ledgers.add(l);
          }
          for (var l = 40; l <= d; l += 2) {
            ledgers.add(l);
          }
        } else {
          for (var l = 28; l <= d; l += 2) {
            ledgers.add(l);
          }
          for (var l = 16; l >= d; l -= 2) {
            ledgers.add(l);
          }
        }
        for (final l in ledgers) {
          final ly = bass ? bassBottom - (l - 18) * half : trebleBottom - (l - 30) * half;
          canvas.drawLine(Offset(x - 14, ly), Offset(x + 14, ly), ledgerPaint);
        }
        if (isBlack(m)) _tp('♯', 18, const Color(0xff343a40).withValues(alpha: op)).paint(canvas, Offset(x - 30, y - 10));
        final player = isPlayer(s, m);
        final hollow = s.d >= 2;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(-0.31);
        final oval = Rect.fromCenter(center: Offset.zero, width: 18, height: 13);
        canvas.drawOval(oval, Paint()..color = (hollow ? Colors.white : player ? noteColor(m) : const Color(0xffadb5bd)).withValues(alpha: op));
        canvas.drawOval(oval, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hollow ? 2.5 : 1
          ..color = (player ? const Color(0xff212529) : const Color(0xffadb5bd)).withValues(alpha: op));
        canvas.restore();
        if (s.d < 4) canvas.drawLine(Offset(x + 8, y), Offset(x + 8, y - 40), Paint()..color = const Color(0xff212529).withValues(alpha: op)..strokeWidth = 1.5);
        final f = s.fingers[m];
        if (fingers && player && f != null) {
          _drawCentered(canvas, _tp('$f', 13, bass ? const Color(0xff1971c2) : const Color(0xffd9480f)), Offset(x - 14, bass ? y + 20 : y - 10));
        }
        if (active && player) _drawCentered(canvas, _tp(solfege(m), 12, const Color(0xff212529)), Offset(x, 203));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StaffPainter old) => true;
}

/// The guide bird "Đô Rê".
class MascotPainter extends CustomPainter {
  final double bob, beak, blink, wing;
  final bool sleep;
  MascotPainter({required this.bob, required this.beak, required this.blink, required this.wing, this.sleep = false});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    canvas.scale(s);
    canvas.drawOval(Rect.fromCenter(center: const Offset(60, 112), width: 60, height: 10), Paint()..color = const Color(0x1f000000));
    canvas.translate(0, -bob * 6);
    final blue = Paint()..color = const Color(0xff4dabf7);
    for (final side in [-1.0, 1.0]) {
      canvas.save();
      final pivot = Offset(60 + side * 26, 74);
      canvas.translate(pivot.dx, pivot.dy);
      canvas.rotate(side * wing * 0.3);
      canvas.translate(-pivot.dx, -pivot.dy);
      final p = Path()
        ..moveTo(60 + side * 32, 70)
        ..quadraticBezierTo(60 + side * 50, 66, 60 + side * 46, 86)
        ..quadraticBezierTo(60 + side * 36, 90, 60 + side * 26, 82)
        ..close();
      canvas.drawPath(p, blue);
      canvas.restore();
    }
    canvas.drawOval(Rect.fromCenter(center: const Offset(60, 70), width: 68, height: 72), Paint()..color = const Color(0xff74c0fc));
    canvas.drawOval(Rect.fromCenter(center: const Offset(60, 80), width: 44, height: 44), Paint()..color = const Color(0xffe7f5ff));
    final note = Paint()
      ..color = const Color(0xff1971c2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(54, 36)..quadraticBezierTo(60, 18, 68, 32), note);
    canvas.drawCircle(const Offset(70, 30), 5, Paint()..color = const Color(0xff1971c2));
    if (sleep) {
      final lid = Paint()
        ..color = const Color(0xff212529)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawPath(Path()..moveTo(40, 60)..quadraticBezierTo(46, 65, 52, 60), lid);
      canvas.drawPath(Path()..moveTo(68, 60)..quadraticBezierTo(74, 65, 80, 60), lid);
    } else {
      for (final ex in [46.0, 74.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(ex, 58), width: 16, height: 16 * (1 - blink * 0.9)), Paint()..color = Colors.white);
        if (blink < 0.5) {
          canvas.drawCircle(Offset(ex + 1, 59), 4.5, Paint()..color = const Color(0xff212529));
          canvas.drawCircle(Offset(ex + 3, 57), 1.5, Paint()..color = Colors.white);
        }
      }
    }
    final cheek = Paint()..color = const Color(0xb3ffa8a8);
    canvas.drawCircle(const Offset(36, 72), 5, cheek);
    canvas.drawCircle(const Offset(84, 72), 5, cheek);
    canvas.drawPath(Path()..moveTo(53, 68)..lineTo(60, 64)..lineTo(67, 68)..lineTo(60, 73)..close(), Paint()..color = const Color(0xffffa94d));
    canvas.drawPath(Path()..moveTo(54, 70 + beak * 4)..lineTo(60, 77 + beak * 4)..lineTo(66, 70 + beak * 4)..close(), Paint()..color = const Color(0xffff922b));
    final feet = Paint()
      ..color = const Color(0xffff922b)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (a, b2) in [(const Offset(48, 104), const Offset(44, 110)), (const Offset(52, 104), const Offset(52, 111)), (const Offset(68, 104), const Offset(68, 111)), (const Offset(72, 104), const Offset(76, 110))]) {
      canvas.drawLine(a, b2, feet);
    }
  }

  @override
  bool shouldRepaint(covariant MascotPainter old) => old.bob != bob || old.beak != beak || old.blink != blink || old.wing != wing || old.sleep != sleep;
}

/// A small hand with numbered fingers; `active` fingers glow.
class HandPainter extends CustomPainter {
  final bool left;
  final List<int> active;
  final double glow;
  HandPainter({required this.left, required this.active, this.glow = 0});

  static const _fingers = [(6.0, 34.0, 30.0, -30.0), (22.0, 10.0, 46.0, -8.0), (38.0, 4.0, 52.0, 0.0), (54.0, 10.0, 46.0, 8.0), (68.0, 22.0, 36.0, 16.0)];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 90, size.height / 100);
    if (left) {
      canvas.translate(90, 0);
      canvas.scale(-1, 1);
    }
    final skin = Paint()..color = const Color(0xffffe8cc);
    final color = left ? handLeft : handRight;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 56, 62, 42), const Radius.circular(20)), skin);
    for (var i = 0; i < 5; i++) {
      final (x, y, h, r) = _fingers[i];
      final on = active.contains(i + 1);
      canvas.save();
      canvas.translate(x + 7, y + h);
      canvas.rotate(r * math.pi / 180);
      canvas.translate(-(x + 7), -(y + h));
      final rr = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 14, h + 14), const Radius.circular(7));
      canvas.drawRRect(rr, Paint()..color = on ? Color.lerp(color, Colors.white, glow * 0.25)! : const Color(0xffffe8cc));
      canvas.drawRRect(rr, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = on ? color : const Color(0xfff4a261));
      final t = _tp('${i + 1}', 11, on ? Colors.white : const Color(0xffe8590c));
      canvas.save();
      canvas.translate(x + 7, y + 10);
      if (left) canvas.scale(-1, 1);
      _drawCentered(canvas, t, Offset.zero);
      canvas.restore();
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant HandPainter old) => true;
}

Map<int, FingerHint> pickFingers(Map<int, FingerHint> map, Iterable<int> notes) => {for (final m in notes) if (map[m] != null) m: map[m]!};
