import 'package:flutter/material.dart' hide Step;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/playback.dart';
import '../audio/synth.dart';
import '../data/api.dart';
import '../models.dart';
import '../ui/kit.dart';
import '../ui/piano.dart';
import '../ui/widgets.dart';

/// Public "family stage" page: anyone with the link can listen and send hearts.
class ShareScreen extends StatefulWidget {
  final String id;
  const ShareScreen({super.key, required this.id});
  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  ShareDoc? share;
  bool loading = true, playing = false, hearted = false;
  Set<int> held = {};
  int burst = 0;
  void Function()? _stop;

  @override
  void initState() {
    super.initState();
    api.getShare(widget.id).then((s) => mounted ? setState(() {
          share = s;
          loading = false;
        }) : null).catchError((_) => mounted ? setState(() => loading = false) : null);
    SharedPreferences.getInstance().then((p) => mounted ? setState(() => hearted = p.getBool('pq-heart-${widget.id}') ?? false) : null);
  }

  @override
  void dispose() {
    _stop?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: Mascot(size: 100, talking: true)));
    final s = share;
    if (s == null) {
      return Scaffold(
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Mascot(size: 100, mood: Mood.sleep),
          const Text('Buổi biểu diễn này không còn nữa.', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          Btn('Khám phá Piano Quest', kind: BtnKind.primary, onTap: () => context.go('/login')),
        ])),
      );
    }
    final spans = toSpans(s.events);
    final notes = spans.isEmpty ? [60, 72] : spans.map((x) => x.m).toList();
    final lo = (notes.reduce((a, b) => a < b ? a : b) ~/ 12) * 12;
    final hiRaw = ((notes.reduce((a, b) => a > b ? a : b) + 1) / 12).ceil() * 12;
    final hi = hiRaw - lo < 12 ? lo + 12 : hiRaw;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xff3b0764), Color(0xff9c36b5)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SafeArea(
          child: ListView(padding: const EdgeInsets.all(20), children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(children: [
                  Container(height: 30, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xffc92a2a), Color(0xffa61e4d), Color(0xffc92a2a), Color(0xffa61e4d)]), borderRadius: BorderRadius.circular(20))),
                  const SizedBox(height: 16),
                  AvatarView(s.avatar, size: 110),
                  Text('${s.nickname} đang biểu diễn!', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                  Text('🎵 ${s.title}', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Btn(playing ? '⏹ Dừng' : '▶ Nghe con chơi', kind: BtnKind.primary, huge: true, pulse: !playing, onTap: () async {
                    if (playing) {
                      _stop?.call();
                      setState(() => playing = false);
                      return;
                    }
                    await synth.ensure();
                    setState(() => playing = true);
                    _stop = playEvents(s.events, onActive: (h) => mounted ? setState(() => held = h) : null, onEnd: () => mounted ? setState(() => playing = false) : null);
                  }),
                  const SizedBox(height: 14),
                  PianoKeyboard(lo: lo, hi: hi, hints: {for (final m in held) m: null}, labels: 'none', disabled: true, height: 150),
                  const SizedBox(height: 14),
                  Stack(alignment: Alignment.bottomCenter, clipBehavior: Clip.none, children: [
                    if (burst > 0) Positioned(bottom: 30, child: LottieFx(Fx.hearts, key: ValueKey(burst), width: 240, height: 240)),
                    GestureDetector(
                      onTap: () async {
                        setState(() => burst++);
                        if (hearted) return;
                        setState(() {
                          hearted = true;
                          s.hearts++;
                        });
                        (await SharedPreferences.getInstance()).setBool('pq-heart-${widget.id}', true);
                        await api.heartShare(widget.id).catchError((_) {});
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        decoration: BoxDecoration(color: hearted ? const Color(0xffffe3e3) : Colors.white, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Color(0xffc2255c), offset: Offset(0, 5))]),
                        child: Text('❤️ ${s.hearts}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Color(0xffe03131))),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text(hearted ? 'Cảm ơn bạn đã cổ vũ con!' : 'Thả tim để cổ vũ con nhé!', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 24),
                  CardBox(
                    child: Wrap(spacing: 14, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
                      const Mascot(size: 70, mood: Mood.cheer),
                      const SizedBox(
                        width: 320,
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Bé nhà bạn cũng muốn học đàn?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                          Text('Piano Quest giúp bé 6–10 tuổi tự học piano qua trò chơi, mỗi ngày 10–15 phút.'),
                        ]),
                      ),
                      Btn('Học miễn phí 🎁', kind: BtnKind.primary, onTap: () => context.go('/login?ref=${s.inviteCode}')),
                    ]),
                  ),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
