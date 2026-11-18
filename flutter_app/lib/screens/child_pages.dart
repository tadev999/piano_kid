import 'package:flutter/material.dart' hide Step, Badge;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/synth.dart';
import '../content/curriculum.dart';
import '../content/rewards.dart';
import '../content/songs.dart';
import '../data/api.dart';
import '../logic/dates.dart';
import '../logic/progress.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../ui/common.dart';
import '../ui/kit.dart';
import '../ui/piano.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  ItemKind tab = ItemKind.hat;
  String msg = '';

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final child = app.child!;
    final eq = child.equipped;
    bool isOn(String id) => eq.hat == id || eq.skin == id || eq.petAcc == id || eq.room.contains(id);
    final list = items.where((i) => i.kind == tab && (!i.rewardOnly || child.inventory.contains(i.id))).toList();

    void act(ShopItem item) {
      if (child.inventory.contains(item.id)) {
        app.updateChild((c) => equipItem(c, item.id));
        synth.sfx(Sfx.tap);
        return;
      }
      if (child.coins < item.price) {
        setState(() => msg = 'Cần thêm ${item.price - child.coins} nốt vàng. Luyện đàn để kiếm thêm nhé!');
        return;
      }
      final next = buyItem(child, item.id);
      if (next != null) {
        synth.sfx(Sfx.coin);
        app.updateChild((_) => next);
        setState(() => msg = 'Đã mua ${item.emoji} ${item.name}!');
      }
    }

    return Scaffold(
      appBar: const TopBar(back: '/', title: '🛍️ Cửa hàng'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        CardBox(
          child: Wrap(alignment: WrapAlignment.spaceAround, crossAxisAlignment: WrapCrossAlignment.center, spacing: 20, runSpacing: 12, children: [
            AvatarView(child.avatar, hat: eq.hat, size: 100),
            Stack(clipBehavior: Clip.none, children: [
              Text(pets[child.pet]!.stages[petStage(child.petXp).clamp(1, 3)], style: const TextStyle(fontSize: 70)),
              if (eq.petAcc != null) Positioned(top: -6, right: -14, child: Text(itemById(eq.petAcc)!.emoji, style: const TextStyle(fontSize: 30))),
            ]),
            SizedBox(width: 200, child: PianoKeyboard(lo: 60, hi: 72, labels: 'none', skin: eq.skin, height: 90)),
            Wrap(spacing: 8, children: [for (final id in eq.room) Text(itemById(id)?.emoji ?? '', style: const TextStyle(fontSize: 34))]),
          ]),
        ),
        const SizedBox(height: 12),
        Center(child: Seg<ItemKind>(options: const [(ItemKind.hat, '🎩 Phụ kiện'), (ItemKind.skin, '🎹 Đàn'), (ItemKind.room, '🏠 Phòng tập'), (ItemKind.petAcc, '🐾 Thú cưng')], value: tab, onChanged: (t) => setState(() => tab = t))),
        if (msg.isNotEmpty) Padding(padding: const EdgeInsets.all(8), child: Center(child: Pill(msg, color: const Color(0xff2b2d42).withValues(alpha: 0.05)))),
        const SizedBox(height: 10),
        Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
          for (final i in list)
            GestureDetector(
              onTap: () => act(i),
              child: Container(
                width: 140,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: child.inventory.contains(i.id) ? const Color(0xfff8f0fc) : Colors.white,
                  border: Border.all(color: isOn(i.id) ? C.good : Colors.transparent, width: 3),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: C.shadow,
                ),
                child: Column(children: [
                  Text(i.emoji, style: const TextStyle(fontSize: 42)),
                  Text(i.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(child.inventory.contains(i.id) ? (isOn(i.id) ? '✓ Đang dùng' : 'Dùng') : i.price == 0 ? 'Miễn phí' : '🪙 ${i.price}'),
                ]),
              ),
            ),
        ]),
        const Padding(padding: EdgeInsets.all(16), child: Text('Nốt vàng chỉ kiếm được bằng cách luyện đàn – không mua bằng tiền thật.', textAlign: TextAlign.center, style: TextStyle(color: C.muted))),
      ]),
    );
  }
}

class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    return Scaffold(
      appBar: const TopBar(back: '/', title: '🃏 Bộ sưu tập'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        SectionTitle('Thẻ âm nhạc (${child.cards.length}/${cards.length})'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final c in cards)
            GestureDetector(
              onTap: child.cards.contains(c.id) ? () => showAppModal(context, (_) => CollectCard(c, big: true)) : null,
              child: SizedBox(width: 120, child: CollectCard(MusicCard(c.id, c.name, c.emoji, c.rarity, ''), missing: !child.cards.contains(c.id))),
            ),
        ]),
        const SizedBox(height: 18),
        SectionTitle('Huy hiệu (${child.badges.length}/${badges.length})'),
        Wrap(spacing: 10, runSpacing: 10, children: [
          for (final b in badges)
            Opacity(
              opacity: child.badges.contains(b.id) ? 1 : 0.45,
              child: Container(
                width: 160,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: C.shadow),
                child: Column(children: [
                  Text(child.badges.contains(b.id) ? b.emoji : '🔘', style: const TextStyle(fontSize: 36)),
                  Text(b.name, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(b.desc, textAlign: TextAlign.center, style: const TextStyle(color: C.muted, fontSize: 12)),
                ]),
              ),
            ),
        ]),
      ]),
    );
  }
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Map<String, Recording> recs = {};

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    if (app.user != null && app.child != null) {
      api.listRecordings(app.user!.uid, app.child!.id).then((l) => mounted ? setState(() => recs = {for (final r in l) r.id: r}) : null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    final totalSec = child.log.values.fold<int>(0, (s, l) => s + l.sec);
    final pairs = child.songs.entries.where((e) => e.value.firstRec != null && e.value.bestRec != null && e.value.firstRec != e.value.bestRec).toList();
    final weak = (child.weakNotes.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5);
    Widget stat(String icon, String value, String label) => Container(
          width: 150,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: C.shadow),
          child: Column(children: [Text(icon, style: const TextStyle(fontSize: 28)), Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: C.muted))]),
        );
    return Scaffold(
      appBar: const TopBar(back: '/', title: '📈 Tiến bộ của tớ'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          stat('⭐', '${child.totalStars}', 'ngôi sao'),
          stat('📅', '${practiceDayCount(child)}', 'ngày luyện'),
          stat('⏱️', formatDuration(totalSec), 'tổng thời gian'),
          stat('🎵', '${child.songs.length}', 'bản nhạc'),
        ]),
        const SizedBox(height: 14),
        CardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle('🎧 Album Trước – Sau'),
            if (pairs.isEmpty) const Text('Chơi lại một bài nhiều lần để nghe mình tiến bộ thế nào nhé!', style: TextStyle(color: C.muted)),
            for (final e in pairs)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  Text('${songById(e.key.split('@').first)?.emoji} ${songById(e.key.split('@').first)?.title}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  PlayRecButton(events: recs[e.value.firstRec]?.events, label: 'Lần đầu'),
                  PlayRecButton(events: recs[e.value.bestRec]?.events, label: 'Bây giờ'),
                  StarsRow(e.value.stars, size: 16),
                ]),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        CardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SectionTitle('🌳 Cây kỹ năng'),
            for (final r in regions)
              Opacity(
                opacity: r.id > child.unlockedRegion ? 0.45 : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${r.emoji} ${r.name}', style: TextStyle(color: Color(r.color), fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final l in lessonsOf(r.id))
                        Builder(builder: (_) {
                          final s = child.lessons[l.id]?.stars ?? 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(color: s >= 2 ? const Color(0xffd3f9d8) : s > 0 ? const Color(0xfffff3bf) : const Color(0xfff1f3f5), borderRadius: BorderRadius.circular(999)),
                            child: Text('${s >= 2 ? '✅' : s > 0 ? '🌱' : '⚪'} ${l.skill}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          );
                        }),
                    ]),
                  ]),
                ),
              ),
            const Text('✅ đã vững · 🌱 đang luyện · ⚪ sắp học', style: TextStyle(color: C.muted, fontSize: 13)),
          ]),
        ),
        if (weak.isNotEmpty) ...[
          const SizedBox(height: 14),
          CardBox(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SectionTitle('🎯 Nốt cần luyện thêm'), Text(weak.map((e) => e.key).join(' · '))])),
        ],
      ]),
    );
  }
}

class StageScreen extends StatefulWidget {
  const StageScreen({super.key});
  @override
  State<StageScreen> createState() => _StageScreenState();
}

class _StageScreenState extends State<StageScreen> {
  List<Recording> recs = [];
  List<ShareDoc> shares = [];

  @override
  void initState() {
    super.initState();
    final app = context.read<AppState>();
    final u = app.user, c = app.child;
    if (u != null && c != null) {
      api.listRecordings(u.uid, c.id).then((l) => mounted ? setState(() => recs = l) : null);
      api.listShares(u.uid).then((l) => mounted ? setState(() => shares = l.where((s) => s.childId == c.id).toList()) : null).catchError((_) => null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = context.watch<AppState>().child!;
    final hearts = shares.fold<int>(0, (s, x) => s + x.hearts);
    final learned = songs.where((s) => s.levels.any((l) => child.songs.containsKey(songKey(s.id, l.level)))).toList();
    final best = <String, Recording>{};
    for (final r in recs) {
      final b = best[r.songId];
      if (b == null || r.stars > b.stars || (r.stars == b.stars && r.noteAcc > b.noteAcc)) best[r.songId] = r;
    }
    return Scaffold(
      appBar: const TopBar(back: '/', title: '🎭 Sân khấu'),
      body: ListView(padding: const EdgeInsets.all(14), children: [
        CardBox(
          gradient: const LinearGradient(colors: [Color(0xffffe3e3), Color(0xfff3d9fa)]),
          child: Row(children: [
            const Text('🎭', style: TextStyle(fontSize: 60)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Sân khấu của ${child.nickname}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                Text('❤️ $hearts trái tim từ gia đình · ${shares.length} buổi biểu diễn đã chia sẻ'),
                const SizedBox(height: 8),
                Btn('📣 Nhờ bố mẹ chia sẻ cho ông bà', kind: BtnKind.primary, onTap: () async {
                  if (await parentGate(context) && context.mounted) context.go('/parent?tab=share');
                }),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        const SectionTitle('Chọn bài để biểu diễn'),
        if (learned.isEmpty) const Text('Học xong bài hát đầu tiên để lên sân khấu nhé!', style: TextStyle(color: C.muted)),
        Wrap(spacing: 14, runSpacing: 14, children: [
          for (final s in learned)
            Builder(builder: (context) {
              final top = s.levels.reversed.firstWhere((l) => child.songs.containsKey(songKey(s.id, l.level)), orElse: () => s.levels.first);
              return Container(
                width: 230,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Color(s.color), width: 3), borderRadius: BorderRadius.circular(24), boxShadow: C.shadow),
                child: Column(children: [
                  Text(s.emoji, style: const TextStyle(fontSize: 40)),
                  Text(s.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: [
                    Btn('🎤 Biểu diễn', small: true, kind: BtnKind.primary, onTap: () => context.go('/song/${s.id}/${top.level}')),
                    PlayRecButton(events: best[s.id]?.events, label: 'Nghe lại'),
                  ]),
                ]),
              );
            }),
        ]),
      ]),
    );
  }
}
