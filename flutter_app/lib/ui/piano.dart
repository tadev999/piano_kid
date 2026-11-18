import 'dart:async';

import 'package:flutter/material.dart';

import '../audio/input.dart';
import '../content/rewards.dart';
import '../music/fingering.dart';
import '../music/notes.dart';

class KeyGeom {
  final int m;
  final bool black;
  final double left, width;
  const KeyGeom(this.m, this.black, this.left, this.width);
}

/// Key positions as fractions (0–1) of keyboard width, for lo..hi inclusive.
List<KeyGeom> keyLayout(int lo, int hi) {
  final whites = [for (var m = lo; m <= hi; m++) if (!isBlack(m)) m];
  final ww = 1 / whites.length;
  final out = <KeyGeom>[];
  for (var m = lo; m <= hi; m++) {
    if (!isBlack(m)) {
      out.add(KeyGeom(m, false, whites.indexOf(m) * ww, ww));
    } else {
      final prev = whites.indexOf(m - 1);
      if (prev >= 0) out.add(KeyGeom(m, true, (prev + 1) * ww - ww * 0.3, ww * 0.6));
    }
  }
  return out;
}

const handRight = Color(0xffff922b);
const handLeft = Color(0xff339af0);

class PianoKeyboard extends StatefulWidget {
  final int lo, hi;

  /// Keys to glow; value is an optional label (null shows the solfege name).
  final Map<int, String?> hints;

  /// true = good flash, false = wrong flash.
  final Map<int, bool> marks;
  final String labels; // all | c | none
  final String? skin;
  final bool disabled;
  final double? height;
  final Set<int> leftHand;
  final Map<int, FingerHint> fingers;
  const PianoKeyboard({super.key, required this.lo, required this.hi, this.hints = const {}, this.marks = const {}, this.labels = 'all', this.skin, this.disabled = false, this.height, this.leftHand = const {}, this.fingers = const {}});

  @override
  State<PianoKeyboard> createState() => _PianoKeyboardState();
}

class _PianoKeyboardState extends State<PianoKeyboard> with SingleTickerProviderStateMixin {
  Set<int> _held = {...hub.held};
  final _pointers = <int, int>{};
  StreamSubscription<NoteEvt>? _sub;
  late final _bob = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _sub = hub.events.listen((_) {
      if (mounted) setState(() => _held = {...hub.held});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    for (final m in _pointers.values) {
      hub.release(m, Source.screen);
    }
    _bob.dispose();
    super.dispose();
  }

  KeyGeom? _hit(Offset p, Size size, List<KeyGeom> keys) {
    final x = p.dx / size.width;
    if (p.dy < size.height * 0.62) {
      for (final k in keys) {
        if (k.black && x >= k.left && x < k.left + k.width) return k;
      }
    }
    for (final k in keys) {
      if (!k.black && x >= k.left && x < k.left + k.width) return k;
    }
    return null;
  }

  double _vel(Offset p, Size size, KeyGeom k) => (0.3 + 0.65 * (p.dy / (size.height * (k.black ? 0.62 : 1))).clamp(0, 1)).toDouble();

  @override
  Widget build(BuildContext context) {
    final keys = keyLayout(widget.lo, widget.hi);
    final skin = skinStyles[widget.skin] ?? skinStyles['skin-classic']!;
    final h = widget.height ?? (MediaQuery.sizeOf(context).height * 0.27).clamp(120.0, 230.0);
    return Container(
      height: h,
      decoration: const BoxDecoration(color: Color(0xff212529), border: Border(top: BorderSide(color: Color(0xffc92a2a), width: 6))),
      child: LayoutBuilder(builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        void down(PointerEvent e) {
          if (widget.disabled) return;
          final k = _hit(e.localPosition, size, keys);
          if (k == null) return;
          _pointers[e.pointer] = k.m;
          hub.press(k.m, _vel(e.localPosition, size, k), Source.screen);
        }

        void move(PointerEvent e) {
          final cur = _pointers[e.pointer];
          if (cur == null) return;
          final k = _hit(e.localPosition, size, keys);
          if (k == null || k.m == cur) return;
          hub.release(cur, Source.screen);
          _pointers[e.pointer] = k.m;
          hub.press(k.m, 0.6, Source.screen);
        }

        void up(PointerEvent e) {
          final m = _pointers.remove(e.pointer);
          if (m != null) hub.release(m, Source.screen);
        }

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: down,
          onPointerMove: move,
          onPointerUp: up,
          onPointerCancel: up,
          child: Stack(children: [
            for (final k in keys.where((k) => !k.black)) _key(k, size, skin),
            for (final k in keys.where((k) => k.black)) _key(k, size, skin),
          ]),
        );
      }),
    );
  }

  Widget _key(KeyGeom k, Size size, KeySkin skin) {
    final held = _held.contains(k.m);
    final hint = widget.hints.containsKey(k.m);
    final mark = widget.marks[k.m];
    final finger = widget.fingers[k.m];
    final color = noteColor(k.m);
    final showLabel = !k.black && (widget.labels == 'all' || (widget.labels == 'c' && k.m % 12 == 0));
    final kh = k.black ? size.height * 0.62 : size.height;
    final fill = mark == true
        ? const [Color(0xffb2f2bb), Color(0xffb2f2bb)]
        : mark == false
            ? const [Color(0xffffc9c9), Color(0xffffc9c9)]
            : held
                ? [color, color]
                : (k.black ? skin.black : skin.white);
    return Positioned(
      left: k.left * size.width,
      top: 0,
      width: k.width * size.width,
      height: kh,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: Matrix4.translationValues(0, held ? 2 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: fill, begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(k.black ? 7 : 10)),
          border: k.black
              ? (hint ? Border.all(color: skin.glow, width: 3) : null)
              : Border(
                  left: const BorderSide(color: Color(0xffced4da)),
                  right: const BorderSide(color: Color(0xffced4da)),
                  bottom: BorderSide(color: hint ? color : (widget.leftHand.contains(k.m) ? handLeft.withValues(alpha: 0.6) : const Color(0xffced4da)), width: hint ? 10 : (widget.leftHand.contains(k.m) ? 4 : 1)),
                ),
          boxShadow: [
            if (k.black) const BoxShadow(color: Colors.black, offset: Offset(0, 3)),
            if (hint && !k.black) BoxShadow(color: skin.glow, spreadRadius: 2),
            if (hint && k.black) BoxShadow(color: skin.glow, blurRadius: 12),
          ],
        ),
        child: Stack(clipBehavior: Clip.none, alignment: Alignment.bottomCenter, children: [
          if (showLabel)
            Positioned(bottom: hint ? 12 : 6, child: Text(solfege(k.m), style: TextStyle(fontSize: (size.width / 50).clamp(9.0, 15.0), fontWeight: FontWeight.w800, color: const Color(0xff868e96)))),
          if (hint)
            AnimatedBuilder(
              animation: _bob,
              builder: (_, child) => Positioned(bottom: (k.black ? 8 : 30) + _bob.value * 4, child: child!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 2))]),
                child: Text(widget.hints[k.m] ?? solfege(k.m), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: (size.width / 55).clamp(9.0, 15.0))),
              ),
            ),
          if (finger != null)
            AnimatedBuilder(
              animation: _bob,
              builder: (_, child) => Positioned(bottom: (k.black ? 36 : 62) + _bob.value * 4, child: child!),
              child: Container(
                width: k.black ? 24 : 28,
                height: k.black ? 24 : 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: finger.left ? handLeft : handRight, width: 3)),
                child: Text('${finger.f}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: k.black ? 13 : 15, color: finger.left ? const Color(0xff1971c2) : const Color(0xffd9480f))),
              ),
            ),
        ]),
      ),
    );
  }
}
