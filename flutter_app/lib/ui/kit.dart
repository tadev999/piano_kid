import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/rewards.dart';
import '../models.dart';

class C {
  static const bg = Color(0xfff5f3ff);
  static const ink = Color(0xff2b2d42);
  static const muted = Color(0xff6c757d);
  static const primary = Color(0xff7048e8);
  static const primary2 = Color(0xff9775fa);
  static const good = Color(0xff40c057);
  static const bad = Color(0xfffa5252);
  static const gold = Color(0xfffab005);
  static const shadow = [BoxShadow(color: Color(0x1f3c288c), offset: Offset(0, 6)), BoxShadow(color: Color(0x1f3c288c), blurRadius: 30, offset: Offset(0, 12))];
}

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true, colorScheme: ColorScheme.fromSeed(seedColor: C.primary), scaffoldBackgroundColor: C.bg);
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: C.ink, displayColor: C.ink).copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: C.ink),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: C.ink),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: C.ink),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xffe5dbff), width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xffe5dbff), width: 2)),
    ),
  );
}

enum BtnKind { normal, primary, ghost, danger, gold }

class Btn extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final bool small, huge, pulse;
  const Btn(this.label, {super.key, this.onTap, this.kind = BtnKind.normal, this.small = false, this.huge = false, this.pulse = false});
  @override
  State<Btn> createState() => _BtnState();
}

class _BtnState extends State<Btn> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final (Color bg, Color fg, Color sh) = switch (widget.kind) {
      BtnKind.primary => (C.primary, Colors.white, const Color(0xff5229c7)),
      BtnKind.danger => (C.bad, Colors.white, const Color(0xffc92a2a)),
      BtnKind.gold => (const Color(0xfffcc419), C.ink, const Color(0xffe67700)),
      BtnKind.ghost => (Colors.white.withValues(alpha: 0.65), C.ink, const Color(0x337048e8)),
      BtnKind.normal => (Colors.white, C.ink, const Color(0x1f000000)),
    };
    final pad = widget.huge ? const EdgeInsets.symmetric(horizontal: 28, vertical: 16) : widget.small ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6) : const EdgeInsets.symmetric(horizontal: 18, vertical: 10);
    final fs = widget.huge ? 22.0 : widget.small ? 14.0 : 17.0;
    Widget b = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
      padding: pad,
      decoration: BoxDecoration(
        color: bg,
        gradient: widget.kind == BtnKind.primary ? const LinearGradient(colors: [C.primary2, C.primary], begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
        borderRadius: BorderRadius.circular(widget.huge ? 24 : 18),
        border: widget.kind == BtnKind.ghost ? Border.all(color: const Color(0x4d7048e8), width: 2) : null,
        boxShadow: [BoxShadow(color: sh, offset: Offset(0, _down ? 1 : 4))],
      ),
      child: Text(widget.label, textAlign: TextAlign.center, style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: fs)),
    );
    if (widget.pulse && !disabled) b = Pulse(child: b);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: disabled ? null : (_) => setState(() => _down = false),
        onTap: disabled
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: MouseRegion(cursor: disabled ? MouseCursor.defer : SystemMouseCursors.click, child: b),
      ),
    );
  }
}

class IconBtn extends StatelessWidget {
  final String icon;
  final VoidCallback? onTap;
  final bool on;
  final String? tooltip;
  final double size;
  const IconBtn(this.icon, {super.key, this.onTap, this.on = false, this.tooltip, this.size = 48});
  @override
  Widget build(BuildContext context) {
    final w = Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: on ? const Color(0xffffe066) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x1f000000), offset: Offset(0, 3))]),
            alignment: Alignment.center,
            child: Text(icon, style: TextStyle(fontSize: size * 0.45)),
          ),
        ),
      ),
    );
    return tooltip == null ? w : Tooltip(message: tooltip!, child: w);
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;
  const Pill(this.text, {super.key, this.color = Colors.white, this.fontSize = 15});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0x14000000), offset: Offset(0, 2))]),
        child: Text(text, style: TextStyle(fontWeight: FontWeight.w800, fontSize: fontSize)),
      );
}

class CardBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  const CardBox({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.gradient, this.onTap});
  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(color: color ?? Colors.white, gradient: gradient, borderRadius: BorderRadius.circular(22), boxShadow: C.shadow),
      child: child,
    );
    return onTap == null ? box : GestureDetector(onTap: onTap, child: MouseRegion(cursor: SystemMouseCursors.click, child: box));
  }
}

class StarsRow extends StatelessWidget {
  final int value, max;
  final double size;
  final bool animate;
  const StarsRow(this.value, {super.key, this.max = 3, this.size = 24, this.animate = false});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(max, (i) {
          final on = i < value;
          final star = Text('★', style: TextStyle(fontSize: size, height: 1, color: on ? const Color(0xfffcc419) : const Color(0xffdee2e6), shadows: on ? const [Shadow(color: Color(0xffe67700), offset: Offset(0, 2))] : null));
          return animate && on ? PopIn(delay: Duration(milliseconds: 250 + i * 300), child: star) : star;
        }),
      );
}

class ProgressBar extends StatelessWidget {
  final double value, max;
  final Color color;
  final double height;
  const ProgressBar(this.value, this.max, {super.key, this.color = C.primary, this.height = 12});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: height,
          color: const Color(0xfff1f3f5),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(widthFactor: (value / math.max(1, max)).clamp(0, 1).toDouble(), child: Container(color: color)),
        ),
      );
}

class AvatarView extends StatelessWidget {
  final AvatarConfig avatar;
  final String? hat;
  final double size;
  const AvatarView(this.avatar, {super.key, this.hat, this.size = 56});
  @override
  Widget build(BuildContext context) {
    final hatEmoji = itemById(hat)?.emoji;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: hexColor(avatar.color), shape: BoxShape.circle),
          child: Text(avatar.animal, style: TextStyle(fontSize: size * 0.58, height: 1.1)),
        ),
        if (hatEmoji != null)
          Positioned(top: -size * 0.18, right: -size * 0.1, child: Transform.rotate(angle: 0.2, child: Text(hatEmoji, style: TextStyle(fontSize: size * 0.4)))),
      ]),
    );
  }
}

class Pulse extends StatefulWidget {
  final Widget child;
  final double scale;
  const Pulse({super.key, required this.child, this.scale = 1.06});
  @override
  State<Pulse> createState() => _PulseState();
}

class _PulseState extends State<Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: Tween(begin: 1.0, end: widget.scale).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)), child: widget.child);
}

class PopIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const PopIn({super.key, required this.child, this.delay = Duration.zero});
  @override
  State<PopIn> createState() => _PopInState();
}

class _PopInState extends State<PopIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut), child: widget.child);
}

class Seg<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T>? onChanged;
  const Seg({super.key, required this.options, required this.value, this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(16)),
        child: Wrap(
          spacing: 2,
          children: [
            for (final (v, label) in options)
              GestureDetector(
                onTap: onChanged == null ? null : () => onChanged!(v),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: v == value ? C.primary : Colors.transparent, borderRadius: BorderRadius.circular(13)),
                  child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: v == value ? Colors.white : (onChanged == null ? C.muted : C.ink))),
                ),
              ),
          ],
        ),
      );
}

Future<T?> showAppModal<T>(BuildContext context, Widget Function(BuildContext) builder, {bool dismissible = true}) => showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      barrierColor: const Color(0x8c211550),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: builder(ctx)),
        ),
      ),
    );

/// Simple adult check so children cannot open parent-only areas.
Future<bool> parentGate(BuildContext context, {String? reason}) async {
  final r = math.Random();
  final a = 6 + r.nextInt(4), b = 6 + r.nextInt(4);
  final ctrl = TextEditingController();
  var error = false;
  final ok = await showAppModal<bool>(
    context,
    (ctx) => StatefulBuilder(
      builder: (ctx, set) {
        void submit() {
          if (int.tryParse(ctrl.text) == a * b) {
            Navigator.pop(ctx, true);
          } else {
            set(() => error = true);
            ctrl.clear();
          }
        }

        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text('🔒 Dành cho bố mẹ', style: Theme.of(ctx).textTheme.headlineSmall),
          if (reason != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(reason, style: const TextStyle(color: C.muted))),
          const SizedBox(height: 10),
          Text('$a × $b = ?', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
            onSubmitted: (_) => submit(),
          ),
          if (error) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Chưa đúng, thử lại nhé.', style: TextStyle(color: C.bad, fontWeight: FontWeight.w700))),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Btn('Hủy', kind: BtnKind.ghost, onTap: () => Navigator.pop(ctx, false)),
            const SizedBox(width: 10),
            Btn('Xác nhận', kind: BtnKind.primary, onTap: submit),
          ]),
        ]);
      },
    ),
  );
  return ok == true;
}

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)), behavior: SnackBarBehavior.floating));
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: Theme.of(context).textTheme.titleLarge));
}
