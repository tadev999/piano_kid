import 'dart:async';

import 'package:flutter/material.dart' hide Step;
import 'package:provider/provider.dart';

import '../audio/input.dart';
import '../audio/playback.dart';
import '../audio/synth.dart';
import '../data/api.dart';
import '../logic/progress.dart';
import '../models.dart';
import '../music/notes.dart';
import '../state/app_state.dart';
import '../ui/common.dart';
import '../ui/kit.dart';
import '../ui/piano.dart';
import '../ui/widgets.dart';

class FreePlayScreen extends StatefulWidget {
  const FreePlayScreen({super.key});
  @override
  State<FreePlayScreen> createState() => _FreePlayScreenState();
}

class _FreePlayScreenState extends State<FreePlayScreen> {
  int lo = 48;
  bool labels = true, recording = false;
  List<PerfEvent> events = [];
  final name = TextEditingController();
  List<Composition> list = [];
  String? playingId;
  Set<int> held = {};
  String message = 'Chơi bất cứ điều gì bạn thích! Bấm ⏺ để ghi lại giai điệu của riêng mình.';
  int _recStart = 0, _played = 0;
  final _sw = Stopwatch()..start();
  void Function()? _stop;
  StreamSubscription<NoteEvt>? _sub;
  late final AppState _app = context.read<AppState>();

  @override
  void initState() {
    super.initState();
    final u = _app.user, c = _app.child;
    if (u != null && c != null) api.listCompositions(u.uid, c.id).then((l) => mounted ? setState(() => list = l) : null);
    _sub = hub.events.listen((e) {
      if (e.on) _played++;
      if (!recording) return;
      if (_recStart == 0) _recStart = e.at;
      if (events.length < 2000) setState(() => events = [...events, PerfEvent(e.at - _recStart, e.m, e.v, e.on)]);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _stop?.call();
    final sec = _sw.elapsedMilliseconds / 1000;
    if (sec >= 30 && _played >= 10) _app.record(Activity(kind: 'free', ref: 'free', title: 'Chơi tự do', stars: 0, sec: sec));
    super.dispose();
  }

  int get _notesCount => events.where((e) => e.on).length;

  void _play(List<PerfEvent> ev, String id) {
    _stop?.call();
    setState(() => playingId = id);
    _stop = playEvents(ev, onActive: (h) => mounted ? setState(() => held = h) : null, onEnd: () => mounted ? setState(() => playingId = null) : null);
  }

  Future<void> _save() async {
    final u = _app.user, c = _app.child;
    if (u == null || c == null || _notesCount == 0) return;
    final comp = Composition(id: newId(), childId: c.id, name: name.text.trim().isEmpty ? 'Giai điệu số ${list.length + 1}' : name.text.trim(), events: events, createdAt: DateTime.now().millisecondsSinceEpoch);
    await api.saveComposition(u.uid, comp);
    final spans = toSpans(events);
    final challenge = spans.length >= 8 && pc(spans.last.m) == 0;
    final out = _app.record(Activity(kind: 'free', ref: 'compose', title: comp.name, stars: challenge ? 3 : 1, sec: 0, composed: true));
    synth.sfx(Sfx.win);
    final msg = challenge
        ? 'Tuyệt vời! Bạn hoàn thành thử thách nhà soạn nhạc và nhận ${out.coins} nốt vàng!'
        : 'Đã lưu bài sáng tác! Thử thách: sáng tác ít nhất 8 nốt và kết thúc bằng nốt Đô nhé!';
    setState(() {
      list = [comp, ...list];
      events = [];
      message = msg;
    });
    name.clear();
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    return Scaffold(
      appBar: const TopBar(back: '/', title: '🎹 Chơi tự do & Sáng tác'),
      body: Column(children: [
        Expanded(
          child: ListView(padding: const EdgeInsets.all(12), children: [
            Guide(message, compact: true, size: 70),
            Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              IconBtn('◀', onTap: () => setState(() => lo = (lo - 12).clamp(36, 72))),
              IconBtn('▶', onTap: () => setState(() => lo = (lo + 12).clamp(36, 72))),
              Btn(recording ? '⏹ Dừng ($_notesCount nốt)' : '⏺ Ghi giai điệu', kind: recording ? BtnKind.danger : BtnKind.primary, pulse: recording, onTap: () async {
                await synth.ensure();
                setState(() {
                  if (!recording) {
                    events = [];
                    _recStart = 0;
                  }
                  recording = !recording;
                });
              }),
              if (!recording && _notesCount > 0) ...[
                Btn('▶ Nghe lại', onTap: () => _play(events, 'draft')),
                SizedBox(width: 200, child: TextField(controller: name, maxLength: 30, decoration: const InputDecoration(hintText: 'Đặt tên bài nhạc', counterText: ''))),
                Btn('💾 Lưu', kind: BtnKind.primary, onTap: _save),
              ],
              FilterChip(label: const Text('Tên nốt'), selected: labels, onSelected: (v) => setState(() => labels = v)),
            ]),
            if (list.isNotEmpty) ...[
              const SizedBox(height: 14),
              CardBox(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SectionTitle('🎼 Bài sáng tác của ${child.nickname}'),
                  for (final c in list)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(child: Text('🎶 ${c.name}', style: const TextStyle(fontWeight: FontWeight.w700))),
                        Text(_date(c.createdAt), style: const TextStyle(color: C.muted)),
                        const SizedBox(width: 8),
                        Btn(playingId == c.id ? '⏹' : '▶', small: true, onTap: () {
                          if (playingId == c.id) {
                            _stop?.call();
                            setState(() => playingId = null);
                          } else {
                            _play(c.events, c.id);
                          }
                        }),
                        const SizedBox(width: 6),
                        Btn('🗑️', small: true, kind: BtnKind.ghost, onTap: () async {
                          final u = _app.user;
                          if (u == null) return;
                          await api.deleteComposition(u.uid, child.id, c.id);
                          setState(() => list = list.where((x) => x.id != c.id).toList());
                        }),
                      ]),
                    ),
                ]),
              ),
            ],
          ]),
        ),
        PianoKeyboard(lo: lo, hi: lo + 24, labels: labels ? 'all' : 'none', hints: {for (final m in held) m: null}, skin: child.equipped.skin, height: (MediaQuery.sizeOf(context).height * 0.34).clamp(150.0, 280.0)),
      ]),
    );
  }
}

String _date(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${d.day}/${d.month}/${d.year}';
}

String formatDate(int ms) => _date(ms);
