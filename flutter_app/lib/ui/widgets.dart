import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart' hide Step;
import 'package:lottie/lottie.dart';

import '../audio/playback.dart';
import '../models.dart';
import '../music/notes.dart';
import 'kit.dart';
import 'lottie_factory.dart';
import 'painters.dart';
import 'piano.dart';

enum Mood { happy, cheer, sleep }

class Mascot extends StatefulWidget {
  final double size;
  final bool talking;
  final Mood mood;
  const Mascot({super.key, this.size = 120, this.talking = false, this.mood = Mood.happy});
  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          final t = _c.value * 4; // seconds
          final period = widget.mood == Mood.cheer ? 0.9 : 2.4;
          final bob = (0.5 - 0.5 * _cos(t / period)).toDouble() * (widget.mood == Mood.cheer ? 1.6 : 0.7);
          final beak = widget.talking ? (0.5 - 0.5 * _cos(t / 0.22)) : 0.0;
          final blinkPhase = (t % 4) / 4;
          final blink = blinkPhase > 0.46 && blinkPhase < 0.5 ? 1.0 : 0.0;
          final wing = 0.5 - 0.5 * _cos(t / 1.2);
          return CustomPaint(size: Size.square(widget.size), painter: MascotPainter(bob: bob, beak: beak, blink: blink, wing: wing, sleep: widget.mood == Mood.sleep));
        },
      );
  static double _cos(double cycles) => math.cos(cycles * 2 * math.pi);
}

/// Mascot with a speech bubble that reads its text aloud.
class Guide extends StatefulWidget {
  final String text;
  final double size;
  final Mood mood;
  final bool auto, compact;
  const Guide(this.text, {super.key, this.size = 110, this.mood = Mood.happy, this.auto = true, this.compact = false});
  @override
  State<Guide> createState() => _GuideState();
}

class _GuideState extends State<Guide> {
  bool _talking = false;
  Timer? _t;

  void _say() {
    setState(() => _talking = true);
    speech.speak(widget.text, onEnd: () {
      if (mounted) setState(() => _talking = false);
    });
    _t?.cancel();
    _t = Timer(Duration(milliseconds: (600 + widget.text.length * 70).clamp(0, 12000)), () {
      if (mounted) setState(() => _talking = false);
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.auto) WidgetsBinding.instance.addPostFrameCallback((_) => _say());
  }

  @override
  void didUpdateWidget(Guide old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && widget.auto) _say();
  }

  @override
  void dispose() {
    _t?.cancel();
    speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 600;
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 640),
      padding: EdgeInsets.fromLTRB(16, widget.compact ? 8 : 12, 8, widget.compact ? 8 : 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: C.shadow),
      child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Flexible(child: Text(widget.text, style: TextStyle(fontSize: widget.compact ? 16 : 19, fontWeight: FontWeight.w700, height: 1.3))),
        IconBtn('🔊', size: 34, onTap: _say),
      ]),
    );
    final mascot = Mascot(size: widget.size, talking: _talking, mood: widget.mood);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: widget.compact ? 4 : 8),
      child: narrow
          ? Column(mainAxisSize: MainAxisSize.min, children: [mascot, bubble])
          : Row(mainAxisSize: MainAxisSize.min, children: [mascot, const SizedBox(width: 12), Flexible(child: bubble)]),
    );
  }
}

enum Fx { confetti, starBurst, hearts, sparkles, coin }

final _fxCache = <Fx, Uint8List>{};

class LottieFx extends StatelessWidget {
  final Fx fx;
  final bool repeat;
  final double? width, height;
  const LottieFx(this.fx, {super.key, this.repeat = false, this.width, this.height});
  @override
  Widget build(BuildContext context) {
    final bytes = repeat
        ? _fxCache.putIfAbsent(fx, () => _gen(fx))
        : _gen(fx);
    return IgnorePointer(child: Lottie.memory(bytes, repeat: repeat, width: width, height: height, fit: BoxFit.contain));
  }

  static Uint8List _gen(Fx fx) => switch (fx) {
        Fx.confetti => confettiJson(),
        Fx.starBurst => starBurstJson(),
        Fx.hearts => heartsJson(),
        Fx.sparkles => sparklesJson(),
        Fx.coin => coinJson(),
      };
}

/// Two small hands with the fingers to use right now highlighted.
class HandGuide extends StatelessWidget {
  final List<int> right, left;
  final bool showLeft, showRight;
  const HandGuide({super.key, required this.right, required this.left, required this.showLeft, required this.showRight});
  @override
  Widget build(BuildContext context) {
    String say(bool l, List<int> fs) => '${l ? 'Tay trái' : 'Tay phải'}: ngón ${fs.join(' – ')}';
    Widget hand(bool l, List<int> fs) => Opacity(
          opacity: fs.isEmpty ? 0.55 : 1,
          child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (!l) Padding(padding: const EdgeInsets.only(bottom: 8, right: 6), child: Text(fs.isEmpty ? 'Tay phải' : say(false, fs), style: const TextStyle(color: handRight, fontWeight: FontWeight.w800))),
            CustomPaint(size: const Size(62, 69), painter: HandPainter(left: l, active: fs)),
            if (l) Padding(padding: const EdgeInsets.only(bottom: 8, left: 6), child: Text(fs.isEmpty ? 'Tay trái' : say(true, fs), style: const TextStyle(color: handLeft, fontWeight: FontWeight.w800))),
          ]),
        );
    return Container(
      color: const Color(0xff1b1840),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Row(children: [
        if (showLeft) hand(true, left),
        const Spacer(),
        if (showRight) hand(false, right),
      ]),
    );
  }
}

class Illustration extends StatelessWidget {
  final PicKey pic;
  const Illustration(this.pic, {super.key});

  Widget _box(Widget child, String caption) => Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(22)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [child, const SizedBox(height: 6), Text(caption, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))]),
      );

  Widget _piano(int lo, int hi, Map<int, String?> hints, {String labels = 'none'}) => SizedBox(width: 480, child: PianoKeyboard(lo: lo, hi: hi, hints: hints, labels: labels, disabled: true, height: 130));

  Widget _card(String big, String small, {Color color = C.ink, double size = 48}) => Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: C.shadow),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(big, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, color: color, fontFamily: 'serif')),
          Text(small, style: const TextStyle(fontSize: 14)),
        ]),
      );

  @override
  Widget build(BuildContext context) => switch (pic) {
        PicKey.posture => _box(const Text('🧒🎹', style: TextStyle(fontSize: 80)), 'Ngồi giữa đàn · lưng thẳng · cổ tay ngang phím · chân chạm sàn'),
        PicKey.fingers => _box(Row(mainAxisSize: MainAxisSize.min, children: [
            Column(children: [CustomPaint(size: const Size(120, 133), painter: HandPainter(left: true, active: const [])), const Text('Tay trái')]),
            const SizedBox(width: 20),
            Column(children: [CustomPaint(size: const Size(120, 133), painter: HandPainter(left: false, active: const [])), const Text('Tay phải')]),
          ]), 'Ngón cái là số 1, ngón út là số 5'),
        PicKey.groups => _box(_piano(48, 72, {48: 'Đô', 60: 'Đô', 72: 'Đô', 53: 'Fa', 65: 'Fa'}), 'Đô ở bên trái nhóm 2 phím đen · Fa ở bên trái nhóm 3 phím đen'),
        PicKey.cPosition => _box(_piano(60, 72, {60: '1', 62: '2', 64: '3', 65: '4', 67: '5'}, labels: 'all'), 'Vị trí Đô: ngón 1 ở Đô, ngón 5 ở Sol'),
        PicKey.staff || PicKey.bass => _box(
            SizedBox(width: 420, height: 180, child: CustomPaint(painter: StaffPainter(steps: pic == PicKey.bass ? seq('C3 D3 E3 F3 G3', 0, true) : seq('C4 D4 E4 F4 G4'), current: 0, isPlayer: (_, __) => true, count: 5, fingers: false))),
            pic == PicKey.bass ? 'Khóa Fa 𝄢 dành cho nốt trầm – tay trái' : 'Khóa Sol 𝄞 dành cho nốt cao – tay phải'),
        PicKey.chord => _box(_piano(48, 60, {48: 'Đô', 52: 'Mi', 55: 'Sol'}), 'Hợp âm Đô trưởng = Đô + Mi + Sol (ngón 5 – 3 – 1 tay trái)'),
        PicKey.sharp => _box(_piano(60, 72, {65: 'Fa', 66: 'Fa♯'}), '♯ thăng = phím ngay bên phải (thường là phím đen)'),
        PicKey.dynamics => Wrap(alignment: WrapAlignment.center, children: [_card('f', 'forte – mạnh', color: const Color(0xffe03131)), _card('p', 'piano – nhẹ', color: const Color(0xff74c0fc))]),
        PicKey.rhythm => Wrap(alignment: WrapAlignment.center, children: [_card('♩', 'Nốt đen – 1 phách – “Ta”'), _card('𝅗𝅥', 'Nốt trắng – 2 phách – “Ta-a”'), _card('𝅝', 'Nốt tròn – 4 phách')]),
      };
}
