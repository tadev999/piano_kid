import 'package:flutter/material.dart' hide Step, Badge;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/playback.dart';
import '../audio/synth.dart';
import '../content/curriculum.dart';
import '../content/rewards.dart';
import '../logic/dates.dart';
import '../logic/progress.dart';
import '../state/app_state.dart';
import '../ui/common.dart';
import '../ui/kit.dart';
import '../ui/widgets.dart';

final _greeted = <String>{};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _petTap = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  void _greet() {
    final app = context.read<AppState>();
    final child = app.child;
    if (child == null) return;
    final key = '${child.id}-${dayKey()}';
    if (!_greeted.add(key)) return;
    final nl = nextLesson(child);
    final h = DateTime.now().hour;
    final hello = h < 11 ? 'Chào buổi sáng' : h < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';
    speech.speak('$hello ${child.nickname}! ${child.petName} đang chờ bạn đó. ${nl != null ? 'Hôm nay mình học bài ${nl.title} nhé!' : 'Mình cùng chơi nhạc nhé!'}');
    if (app.inviteBonus > 0) _inviteModal(app.inviteBonus);
  }

  void _inviteModal(int n) {
    showAppModal(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          const LottieFx(Fx.confetti, height: 140),
          const Text('🎉 Có bạn mới tham gia nhờ lời mời của bố mẹ!', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          Text('Bạn nhận được 🐉 Rồng Vàng và ${n * 100} nốt vàng!', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Btn('Tuyệt quá!', kind: BtnKind.primary, onTap: () => Navigator.pop(ctx)),
        ])).then((_) {
      if (mounted) context.read<AppState>().clearInviteBonus();
    });
  }

  void _reveal(String title, List<String> lines, String? cardId) {
    final card = cardById(cardId);
    showAppModal(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(alignment: Alignment.center, children: [const LottieFx(Fx.confetti, height: 160), PopIn(child: const Text('🎁', style: TextStyle(fontSize: 70)))]),
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          for (final l in lines) Text(l, style: const TextStyle(fontSize: 17)),
          if (card != null) Padding(padding: const EdgeInsets.all(8), child: PopIn(delay: const Duration(milliseconds: 300), child: CollectCard(card))),
          const SizedBox(height: 10),
          Btn('Tuyệt vời!', kind: BtnKind.primary, onTap: () => Navigator.pop(ctx)),
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final child = app.child;
    if (child == null) return const SizedBox();
    final nl = nextLesson(child);
    final nlRegion = nl != null ? regionById(nl.region) : null;
    final daily = child.daily;
    final week = weekProgress(child);
    final ev = activeEvent();
    final evProgress = child.eventProgress[ev.key] ?? 0;
    final evClaimed = child.eventClaimed.contains(ev.key);
    final stage = petStage(child.petXp);
    final nextXp = stage + 1 < petStageXp.length ? petStageXp[stage + 1] : null;
    final petAcc = itemById(child.equipped.petAcc)?.emoji;
    final wide = MediaQuery.sizeOf(context).width > 900;

    final continueCard = CardBox(
      gradient: nlRegion == null ? null : LinearGradient(colors: nlRegion.bg.map((c) => Color(c)).toList()),
      child: Row(children: [
        const Mascot(size: 110, mood: Mood.cheer),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(nlRegion != null ? '${nlRegion.emoji} ${nlRegion.name}' : '🎉 Bạn đã hoàn thành hành trình!', style: const TextStyle(color: C.muted, fontWeight: FontWeight.w700)),
            Text(nl != null ? '${nl.emoji} ${nl.title}' : 'Chơi lại bài yêu thích nhé!', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Btn(nl != null ? '▶ Học tiếp' : '▶ Thư viện bài hát', kind: BtnKind.primary, huge: true, pulse: true, onTap: () => context.go(nl != null ? '/lesson/${nl.id}' : '/songs')),
          ]),
        ),
      ]),
    );

    final petCard = CardBox(
      onTap: () {
        setState(() => _petTap++);
        synth.sfx(Sfx.pop);
        speech.speak(stage == 0 ? 'Quả trứng đang rung rinh! Luyện đàn để nó nở nhé!' : '${child.petName} thích nghe bạn chơi đàn lắm!');
      },
      child: Stack(alignment: Alignment.center, children: [
        if (_petTap > 0) Positioned.fill(child: LottieFx(Fx.hearts, key: ValueKey(_petTap))),
        Column(children: [
          PopIn(key: ValueKey('pet$_petTap'), child: Stack(clipBehavior: Clip.none, children: [
            Text(petEmoji(child.pet, child.petXp), style: TextStyle(fontSize: 48 + stage * 12.0)),
            if (petAcc != null && stage > 0) Positioned(top: -8, right: -16, child: Text(petAcc, style: TextStyle(fontSize: 22 + stage * 4.0))),
          ])),
          Text(child.petName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(petStageNames[stage], style: const TextStyle(color: C.muted)),
          const SizedBox(height: 6),
          if (nextXp != null) ...[
            ProgressBar((child.petXp - petStageXp[stage]).toDouble(), (nextXp - petStageXp[stage]).toDouble(), color: const Color(0xfff783ac)),
            Text('Luyện đàn để ${child.petName} lớn lên!', style: const TextStyle(color: C.muted, fontSize: 13)),
          ] else
            const Text('Đã lớn hết cỡ! 💞'),
        ]),
      ]),
    );

    final missions = CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SectionTitle('🎯 Nhiệm vụ hôm nay'),
        for (final m in daily?.missions ?? const [])
          Opacity(
            opacity: m.claimed ? 0.6 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(m.text, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  ProgressBar(m.progress.clamp(0, m.target).toDouble(), m.target.toDouble(), color: const Color(0xff51cf66)),
                ])),
                const SizedBox(width: 10),
                if (m.claimed)
                  const Text('✓', style: TextStyle(color: C.good, fontWeight: FontWeight.w800, fontSize: 22))
                else if (m.done)
                  Btn('+${m.reward} 🪙', small: true, kind: BtnKind.gold, pulse: true, onTap: () {
                    final (next, coins) = claimMission(child, m.id);
                    if (coins == 0) return;
                    synth.sfx(Sfx.coin);
                    app.updateChild((_) => next);
                  })
                else
                  Text('${m.progress.floor()}/${m.target}', style: const TextStyle(color: C.muted)),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        if (daily?.chestClaimed == true)
          const Btn('✨ Đã mở rương hôm nay')
        else if (chestReady(child))
          Btn('🎁 Mở rương kho báu!', kind: BtnKind.gold, pulse: true, onTap: () {
            final (next, coins, card) = openChest(child);
            if (coins == 0) return;
            synth.sfx(Sfx.levelup);
            app.updateChild((_) => next);
            _reveal('Rương kho báu!', ['+$coins nốt vàng', '${child.petName} được thêm 15 điểm lớn lên'], card);
          })
        else
          const Btn('🔒 Xong 3 nhiệm vụ để mở rương'),
      ]),
    );

    final weekCard = CardBox(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionTitle('📅 Tuần này: ${week.count}/${week.goal} ngày'),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (var i = 0; i < 7; i++)
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: week.done[i] ? const Color(0xfffff4e6) : const Color(0xfff1f3f5),
                border: week.days[i] == dayKey() ? Border.all(color: C.primary2, width: 3) : null,
              ),
              child: Text(week.done[i] ? '🔥' : weekdayShort[i], style: TextStyle(fontWeight: FontWeight.w800, color: C.muted, fontSize: week.done[i] ? 22 : 14)),
            ),
        ]),
        const SizedBox(height: 8),
        if (week.claimed)
          const Text('Đã nhận quà tuần này ✓', style: TextStyle(color: C.muted))
        else if (week.ready)
          Btn('🎁 Nhận quà tuần', kind: BtnKind.primary, pulse: true, onTap: () {
            final (next, coins, card) = claimWeek(child);
            if (coins == 0) return;
            synth.sfx(Sfx.levelup);
            app.updateChild((_) => next);
            _reveal('Tuần chăm chỉ!', ['+$coins nốt vàng', 'Huy hiệu 📅 Tuần chăm chỉ'], card);
          })
        else
          const Text('Luyện đàn 4 ngày trong tuần để nhận quà. Nghỉ một ngày cũng không sao!', style: TextStyle(color: C.muted)),
      ]),
    );

    final eventCard = CardBox(
      gradient: const LinearGradient(colors: [Color(0xfffff9db), Color(0xffffe8cc)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SectionTitle('${ev.event.emoji} ${ev.event.name}'),
        Text(ev.event.desc),
        const SizedBox(height: 6),
        ProgressBar(evProgress.clamp(0, ev.event.goal).toDouble(), ev.event.goal.toDouble(), color: C.gold),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: Text('${evProgress.clamp(0, ev.event.goal)}/${ev.event.goal} · còn ${daysLeft(ev.endsAt)} ngày', style: const TextStyle(color: C.muted))),
          if (evClaimed)
            const Text('✓ Đã nhận', style: TextStyle(color: C.good, fontWeight: FontWeight.w800))
          else if (evProgress >= ev.event.goal)
            Btn('Nhận quà', small: true, kind: BtnKind.primary, pulse: true, onTap: () {
              final (next, item, coins) = claimEvent(child);
              app.updateChild((_) => next);
              synth.sfx(Sfx.levelup);
              final it = itemById(item);
              _reveal('${ev.event.emoji} ${ev.event.name}', [it != null ? 'Quà sự kiện: ${it.emoji} ${it.name}' : '+$coins nốt vàng', 'Huy hiệu 🏅 Nhà vô địch sự kiện'], null);
            }),
        ]),
      ]),
    );

    const tiles = [
      ('/map', '🗺️', 'Bản đồ', 0xfffff4e6), ('/songs', '🎵', 'Bài hát', 0xfffff0f6), ('/games', '🎮', 'Trò chơi', 0xffe7f5ff), ('/free', '🎹', 'Sáng tác', 0xfff3f0ff),
      ('/shop', '🛍️', 'Cửa hàng', 0xffebfbee), ('/collection', '🃏', 'Bộ sưu tập', 0xfffff9db), ('/progress', '📈', 'Tiến bộ', 0xffe6fcf5), ('/stage', '🎭', 'Sân khấu', 0xfffff5f5),
    ];
    final tileGrid = GridView.count(
      crossAxisCount: wide ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: wide ? 1.6 : 1.5,
      children: [
        for (final (path, emoji, label, color) in tiles)
          CardBox(
            color: Color(color),
            padding: const EdgeInsets.all(10),
            onTap: () => context.go(path),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text(emoji, style: const TextStyle(fontSize: 40)), Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))]),
          ),
      ],
    );

    final room = child.equipped.room.isEmpty
        ? null
        : CardBox(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionTitle('🏠 Phòng tập của ${child.nickname}'),
              Container(
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xffd9480f), width: 6))),
                child: Wrap(spacing: 12, children: [for (final id in child.equipped.room) Text(itemById(id)?.emoji ?? '', style: const TextStyle(fontSize: 38))]),
              ),
            ]),
          );

    return Scaffold(
      appBar: const TopBar(),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        if (wide)
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(flex: 2, child: continueCard), const SizedBox(width: 14), Expanded(child: petCard)]))
        else ...[continueCard, const SizedBox(height: 14), petCard],
        const SizedBox(height: 14),
        if (wide)
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Expanded(child: missions), const SizedBox(width: 14), Expanded(child: weekCard)]))
        else ...[missions, const SizedBox(height: 14), weekCard],
        const SizedBox(height: 14),
        eventCard,
        const SizedBox(height: 14),
        tileGrid,
        if (room != null) ...[const SizedBox(height: 14), room],
      ]),
    );
  }
}
