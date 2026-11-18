import 'dart:async';

import 'package:flutter/material.dart' hide Step, Badge;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/input.dart';
import '../audio/playback.dart';
import '../audio/synth.dart';
import '../content/curriculum.dart';
import '../content/rewards.dart';
import '../logic/progress.dart';
import '../models.dart';
import '../state/app_state.dart';
import 'kit.dart';
import 'widgets.dart';

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final String? back;
  final String? title;
  const TopBar({super.key, this.back, this.title});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final child = app.child;
    if (child == null) return const SizedBox(height: 68);
    final narrow = MediaQuery.sizeOf(context).width < 640;
    final icon = child.input == InputKind.midi ? '🔌' : child.input == InputKind.mic ? '🎤' : '📱';
    return SafeArea(
      bottom: false,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        color: C.bg.withValues(alpha: 0.92),
        child: Row(children: [
          back != null
              ? IconBtn('⬅', onTap: () => context.go(back!))
              : GestureDetector(onTap: () => context.go('/profiles'), child: AvatarView(child.avatar, hat: child.equipped.hat, size: 46)),
          const SizedBox(width: 10),
          Expanded(child: Text(title ?? child.nickname, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
          if (!narrow) ...[Pill(petEmoji(child.pet, child.petXp)), const SizedBox(width: 6), Pill('⭐ ${child.totalStars}', color: const Color(0xfffff9db)), const SizedBox(width: 6)],
          Pill('🪙 ${child.coins}', color: const Color(0xfffff3bf)),
          const SizedBox(width: 6),
          IconBtn(icon, tooltip: 'Thiết bị', onTap: () => showDevicePanel(context)),
          const SizedBox(width: 6),
          IconBtn('🔒', tooltip: 'Phụ huynh', onTap: () async {
            if (await parentGate(context) && context.mounted) context.go('/parent');
          }),
        ]),
      ),
    );
  }
}

class CollectCard extends StatelessWidget {
  final MusicCard card;
  final bool big, missing;
  const CollectCard(this.card, {super.key, this.big = false, this.missing = false});
  @override
  Widget build(BuildContext context) {
    final (List<Color> grad, Color border) = switch (card.rarity) {
      'rare' => ([Colors.white, const Color(0xfff3d9fa)], const Color(0xffcc5de8)),
      'epic' => ([const Color(0xfffff9db), const Color(0xffffd43b)], const Color(0xfff59f00)),
      _ => ([Colors.white, const Color(0xffe7f5ff)], const Color(0xff74c0fc)),
    };
    return Opacity(
      opacity: missing ? 0.45 : 1,
      child: Container(
        constraints: BoxConstraints(maxWidth: big ? 420 : 260),
        padding: EdgeInsets.all(big ? 22 : 12),
        decoration: BoxDecoration(gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight), border: Border.all(color: border, width: 3), borderRadius: BorderRadius.circular(18)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(missing ? '❔' : card.emoji, style: TextStyle(fontSize: big ? 72 : 44)),
          Text(missing ? '???' : card.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
          if (!missing && big) ...[const SizedBox(height: 6), Text(card.fact, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16))],
          if (!missing && big) Text(card.rarity == 'common' ? 'Thẻ thường' : card.rarity == 'rare' ? '✨ Thẻ hiếm' : '🌟 Thẻ huyền thoại', style: const TextStyle(color: C.muted)),
          if (!missing && !big && card.fact.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(card.fact, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
        ]),
      ),
    );
  }
}

class ResultPanel extends StatelessWidget {
  final String title;
  final int stars;
  final List<String> lines;
  final Outcome? outcome;
  final List<Widget> actions;
  const ResultPanel({super.key, required this.title, required this.stars, this.lines = const [], this.outcome, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final child = context.read<AppState>().child;
    final o = outcome;
    final card = cardById(o?.card);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        clipBehavior: Clip.antiAlias,
        child: Stack(children: [
          Positioned.fill(child: Stack(children: [
            if (stars >= 2) const Positioned.fill(child: LottieFx(Fx.confetti)),
            const Align(alignment: Alignment.topCenter, child: LottieFx(Fx.starBurst, width: 260, height: 260)),
          ])),
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              StarsRow(stars, size: 54, animate: true),
              for (final l in lines) Padding(padding: const EdgeInsets.only(top: 4), child: Text(l, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
              if (o != null) ...[
                const SizedBox(height: 8),
                if (o.coins > 0) _reward(Row(mainAxisSize: MainAxisSize.min, children: [const SizedBox(width: 36, height: 36, child: LottieFx(Fx.coin)), Text('+${o.coins} nốt vàng')]), const Color(0xfffff9db)),
                if (o.regionUnlocked != null) _reward(Text('🗺️ Mở khóa vùng đất mới: ${regionById(o.regionUnlocked!).emoji} ${regionById(o.regionUnlocked!).name}!'), const Color(0xfffff3bf)),
                if (o.petStageUp != null && child != null) _reward(Text('${pets[child.pet]!.stages[o.petStageUp!]} ${child.petName} đã lớn lên: ${petStageNames[o.petStageUp!]}!')),
                for (final b in o.newBadges)
                  if (badgeById(b) != null) _reward(Text('🏅 Huy hiệu mới: ${badgeById(b)!.emoji} ${badgeById(b)!.name}')),
                if (card != null) Padding(padding: const EdgeInsets.all(6), child: PopIn(delay: const Duration(milliseconds: 400), child: CollectCard(card))),
                for (final m in o.missionsCompleted) _reward(Text('✅ Nhiệm vụ xong: $m')),
                if (o.eventReady) _reward(const Text('🎁 Bạn đã hoàn thành thử thách sự kiện! Về nhà để nhận quà nhé.'), const Color(0xfffff3bf)),
              ],
              const SizedBox(height: 12),
              Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: actions),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _reward(Widget child, [Color color = const Color(0xfff8f0fc)]) => PopIn(
        child: Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: DefaultTextStyle.merge(style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16), child: child),
        ),
      );
}

/// Dimmed overlay used to show results above a game or song.
class ResultOverlay extends StatelessWidget {
  final Widget child;
  const ResultOverlay({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Positioned.fill(
        child: Container(color: const Color(0x8c211550), padding: const EdgeInsets.all(16), alignment: Alignment.center, child: child),
      );
}

Future<void> showDevicePanel(BuildContext context) => showAppModal(context, (_) => const _DevicePanel());

class _DevicePanel extends StatefulWidget {
  const _DevicePanel();
  @override
  State<_DevicePanel> createState() => _DevicePanelState();
}

class _DevicePanelState extends State<_DevicePanel> {
  String _error = '';
  bool _busy = false;
  String _last = '';
  StreamSubscription<NoteEvt>? _sub;
  Timer? _meter;

  @override
  void initState() {
    super.initState();
    _sub = hub.events.listen((e) {
      if (e.on && mounted) setState(() => _last = '${e.m} (${e.src.name})');
    });
    _meter = Timer.periodic(const Duration(milliseconds: 120), (_) {
      if (mounted && hub.micActive) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _meter?.cancel();
    super.dispose();
  }

  Future<void> _choose(InputKind kind) async {
    setState(() {
      _error = '';
      _busy = true;
    });
    try {
      await synth.ensure();
      await hub.useInput(kind);
      if (mounted) context.read<AppState>().updateChild((c) => c.clone()..input = kind);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = context.watch<AppState>().child?.input ?? InputKind.screen;
    Widget option(InputKind k, String icon, String title, String sub) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: _busy ? null : () => _choose(k),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cur == k ? const Color(0xfff3f0ff) : Colors.white, border: Border.all(color: cur == k ? C.primary : const Color(0xffe9ecef), width: 3), borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Text(icon, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)), Text(sub, style: const TextStyle(color: C.muted))])),
              ]),
            ),
          ),
        );
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('🎹 Bé chơi bằng gì?', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 10),
      option(InputKind.screen, '📱', 'Bàn phím màn hình', 'Chạm phím trên màn hình (hoặc phím máy tính A S D F…)'),
      option(InputKind.midi, '🔌', 'Đàn điện tử (MIDI)', 'Cắm cáp USB hoặc kết nối Bluetooth MIDI. Chính xác nhất!'),
      option(InputKind.mic, '🎤', 'Đàn thật qua micro', 'Đặt máy gần đàn. Phù hợp đàn cơ, nghe từng nốt.'),
      if (_error.isNotEmpty) Text(_error, style: const TextStyle(color: C.bad, fontWeight: FontWeight.w700)),
      if (cur == InputKind.midi)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xfff8f9fa), borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Thiết bị: ${hub.midiNames.isEmpty ? 'chưa thấy đàn – cắm cáp rồi bấm lại nút MIDI' : hub.midiNames.join(', ')}'),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: hub.muteMidiSound,
              onChanged: (v) => setState(() => hub.muteMidiSound = v ?? false),
              title: const Text('Tắt tiếng app (dùng loa của đàn)'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ]),
        ),
      if (cur == InputKind.mic)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xfff8f9fa), borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Âm lượng micro:'),
            const SizedBox(height: 4),
            ProgressBar(hub.micLevel * 6, 1, color: C.good, height: 14),
            const SizedBox(height: 4),
            const Text('Mẹo: phòng yên tĩnh, chơi từng nốt rõ ràng. Hợp âm được tính khi đúng một nốt.', style: TextStyle(color: C.muted)),
          ]),
        ),
      const SizedBox(height: 8),
      Text('Thử bấm một phím: ${_last.isEmpty ? '…' : _last}', style: const TextStyle(color: C.muted)),
      const SizedBox(height: 10),
      Center(child: Btn('Xong', kind: BtnKind.primary, onTap: () => Navigator.pop(context))),
    ]);
  }
}

/// Friendly daily-limit screen and periodic break reminders, layered over child screens.
class Wellbeing extends StatefulWidget {
  final Widget child;
  const Wellbeing({super.key, required this.child});
  @override
  State<Wellbeing> createState() => _WellbeingState();
}

class _WellbeingState extends State<Wellbeing> {
  Timer? _timer;
  DateTime _activeSince = DateTime.now();
  bool _break = false;
  int _countdown = 20;
  bool _spokeTimeUp = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final mins = context.read<AppState>().settings.breakReminderMin;
      if (_break) {
        if (_countdown > 0) setState(() => _countdown--);
        return;
      }
      if (mins > 0 && DateTime.now().difference(_activeSince).inMinutes >= mins) {
        setState(() {
          _break = true;
          _countdown = 20;
        });
        speech.speak('Mình nghỉ mắt một chút nhé! Đứng dậy vươn vai nào!');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final child = app.child;
    final timeUp = app.timeUp;
    if (timeUp && !_spokeTimeUp) {
      _spokeTimeUp = true;
      speech.speak('Hôm nay bạn đã luyện đàn đủ rồi. Hẹn gặp lại ngày mai nhé!');
    }
    if (!timeUp) _spokeTimeUp = false;
    return Stack(children: [
      widget.child,
      if (timeUp && child != null)
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xff1b1464), Color(0xff5f3dc4)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${petEmoji(child.pet, child.petXp)}💤', style: const TextStyle(fontSize: 64)),
                const Mascot(size: 120, mood: Mood.sleep),
                const Text('Hôm nay con luyện đủ rồi! 🌙', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${child.petName} cũng đi ngủ rồi. Ngày mai quay lại để nhận nhiệm vụ mới nhé!', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18)),
                const SizedBox(height: 16),
                Btn('Bố mẹ cho thêm 10 phút', kind: BtnKind.ghost, onTap: () async {
                  if (await parentGate(context) && context.mounted) context.read<AppState>().extendTime(10);
                }),
              ]),
            ),
          ),
        ),
      if (_break && !timeUp)
        Positioned.fill(
          child: Container(
            color: const Color(0x8c211550),
            alignment: Alignment.center,
            child: CardBox(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Mascot(size: 110, mood: Mood.cheer),
                const Text('Nghỉ mắt một chút nhé! 👀', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const Text('Nhìn ra xa, vươn vai, xoay cổ tay nào!', style: TextStyle(fontSize: 17)),
                Text('$_countdown', style: const TextStyle(fontSize: 60, fontWeight: FontWeight.w800, color: C.primary)),
                Btn(_countdown > 0 ? 'Đang nghỉ…' : 'Tiếp tục luyện đàn ▶', kind: BtnKind.primary, onTap: _countdown > 0
                    ? null
                    : () => setState(() {
                          _break = false;
                          _activeSince = DateTime.now();
                        })),
              ]),
            ),
          ),
        ),
    ]);
  }
}

/// Replays a recording with a play/stop toggle.
class PlayRecButton extends StatefulWidget {
  final List<PerfEvent>? events;
  final String label;
  const PlayRecButton({super.key, required this.events, required this.label});
  @override
  State<PlayRecButton> createState() => _PlayRecButtonState();
}

class _PlayRecButtonState extends State<PlayRecButton> {
  void Function()? _stop;
  @override
  void dispose() {
    _stop?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.events == null) return const SizedBox.shrink();
    return Btn('${_stop != null ? '⏹' : '▶'} ${widget.label}', small: true, onTap: () async {
      if (_stop != null) {
        _stop!();
        setState(() => _stop = null);
        return;
      }
      await synth.ensure();
      final s = playEvents(widget.events!, onEnd: () {
        if (mounted) setState(() => _stop = null);
      });
      setState(() => _stop = s);
    });
  }
}
