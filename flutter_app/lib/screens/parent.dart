import 'package:flutter/material.dart' hide Step, Badge;
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../content/curriculum.dart';
import '../content/rewards.dart';
import '../content/songs.dart';
import '../data/api.dart';
import '../logic/dates.dart';
import '../logic/progress.dart';
import '../logic/share_images.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../ui/common.dart';
import '../ui/kit.dart';
import 'free_play.dart' show formatDate;

class ParentScreen extends StatefulWidget {
  final String tab;
  const ParentScreen({super.key, this.tab = 'overview'});
  @override
  State<ParentScreen> createState() => _ParentScreenState();
}

class _ParentScreenState extends State<ParentScreen> {
  String? kidId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    if (app.parent == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final kid = app.kids.where((k) => k.id == (kidId ?? app.child?.id)).firstOrNull ?? app.kids.firstOrNull;
    final tab = widget.tab;
    final wide = MediaQuery.sizeOf(context).width > 860;
    Widget grid(List<Widget> cards) => wide
        ? Wrap(spacing: 14, runSpacing: 14, children: [for (final c in cards) SizedBox(width: (MediaQuery.sizeOf(context).width - 46) / 2, child: c)])
        : Column(children: [for (final c in cards) Padding(padding: const EdgeInsets.only(bottom: 14), child: c)]);
    final body = switch (tab) {
      'share' => kid == null ? null : _ShareTab(key: ValueKey('share-${kid.id}'), kid: kid, grid: grid),
      'invite' => const _InviteTab(),
      'settings' => _SettingsTab(key: ValueKey('settings-${kid?.id}'), kid: kid, grid: grid),
      _ => kid == null ? null : _Overview(key: ValueKey('ov-${kid.id}'), kid: kid, grid: grid),
    };
    return Scaffold(
      backgroundColor: const Color(0xfff8f9fa),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Text('⬅', style: TextStyle(fontSize: 22)), onPressed: () => context.go(app.child != null ? '/' : '/profiles')),
        title: const Text('👨‍👩‍👧 Khu vực phụ huynh', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [TextButton(onPressed: () => context.go('/profiles'), child: const Text('🎹 Về chế độ của bé'))],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Seg<String>(
          options: const [('overview', '📊 Tiến độ'), ('share', '📣 Chia sẻ'), ('invite', '🎁 Mời bạn'), ('settings', '⚙️ Cài đặt')],
          value: tab,
          onChanged: (t) => context.go('/parent?tab=$t'),
        ),
        const SizedBox(height: 10),
        if (app.kids.isNotEmpty && tab != 'invite')
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final k in app.kids)
              ChoiceChip(
                avatar: Text(k.avatar.animal),
                label: Text(k.nickname, style: const TextStyle(fontWeight: FontWeight.w700)),
                selected: k.id == kid?.id,
                onSelected: (_) => setState(() => kidId = k.id),
              ),
          ]),
        const SizedBox(height: 12),
        if (body != null)
          body
        else
          CardBox(child: Column(children: [const Text('Chưa có hồ sơ bé nào.'), const SizedBox(height: 8), Btn('＋ Tạo hồ sơ cho bé', kind: BtnKind.primary, onTap: () => context.go('/new-child'))])),
      ]),
    );
  }
}

class _Overview extends StatefulWidget {
  final ChildProfile kid;
  final Widget Function(List<Widget>) grid;
  const _Overview({super.key, required this.kid, required this.grid});
  @override
  State<_Overview> createState() => _OverviewState();
}

class _OverviewState extends State<_Overview> {
  List<SessionLog> sessions = [];

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user;
    if (u != null) {
      api.listSessions(u.uid, widget.kid.id, DateTime.now().millisecondsSinceEpoch - 14 * 86400000).then((s) => mounted ? setState(() => sessions = s) : null).catchError((_) => null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kid = widget.kid;
    final days = lastNDays(7);
    final mins = days.map((d) => ((kid.log[d]?.sec ?? 0) / 60).round()).toList();
    final maxMin = [10, ...mins].reduce((a, b) => a > b ? a : b);
    final weekSec = weekDays().fold<int>(0, (s, d) => s + (kid.log[d]?.sec ?? 0));
    final weekDone = weekDays().where((d) => (kid.log[d]?.sec ?? 0) >= 60).length;
    final nl = nextLesson(kid);
    final region = regionById(kid.unlockedRegion);
    final mastered = kid.lessons.values.where((l) => l.stars >= 2).length;
    final weak = (kid.weakNotes.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).take(5).toList();
    final recentSongs = (kid.songs.entries.toList()..sort((a, b) => b.value.last.compareTo(a.value.last))).take(12);
    Widget stat(String v, String l) => Expanded(child: Column(children: [Text(v, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)), Text(l, style: const TextStyle(color: C.muted))]));
    return widget.grid([
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Tuần này'),
          Row(children: [stat(formatDuration(weekSec), 'luyện tập'), stat('$weekDone/7', 'ngày có luyện'), stat('${practiceDayCount(kid)}', 'tổng số ngày')]),
          const SizedBox(height: 12),
          SizedBox(
            height: 140,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(
                        height: 4 + 100 * mins[i] / maxMin,
                        alignment: Alignment.topCenter,
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.primary2, C.primary], begin: Alignment.topCenter, end: Alignment.bottomCenter), borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
                        child: mins[i] > 0 ? Text('${mins[i]}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)) : null,
                      ),
                      const SizedBox(height: 4),
                      Text('${days[i].substring(8)}/${days[i].substring(5, 7)}', style: const TextStyle(fontSize: 11)),
                    ]),
                  ),
                ),
            ]),
          ),
          const Text('Phút luyện đàn mỗi ngày (7 ngày gần nhất)', style: TextStyle(color: C.muted, fontSize: 13)),
        ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SectionTitle('Lộ trình'),
          Text('Đang ở: ${region.emoji} ${region.name} (${region.rank})', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          ProgressBar(kid.lessons.length.toDouble(), lessons.length.toDouble()),
          const SizedBox(height: 6),
          Text('${kid.lessons.length}/${lessons.length} bài học · $mastered kỹ năng đã vững · ⭐ ${kid.totalStars}'),
          Text('Bước tiếp theo: ${nl != null ? '${nl.emoji} ${nl.title} – ${nl.skill}' : 'Đã hoàn thành toàn bộ lộ trình 🎉'}', style: const TextStyle(fontWeight: FontWeight.w700)),
          if (weak.isNotEmpty) Text('Nốt bé hay nhầm: ${weak.map((e) => '${e.key} (${e.value})').join(', ')}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Gợi ý: 10–15 phút mỗi ngày hiệu quả hơn một buổi dài mỗi tuần. Hãy khen sự cố gắng của con, không chỉ điểm số.', style: TextStyle(color: C.muted, fontSize: 13)),
        ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Bài hát'),
          if (kid.songs.isEmpty) const Text('Chưa chơi bài hát nào.', style: TextStyle(color: C.muted)),
          for (final e in recentSongs)
            Builder(builder: (_) {
              final parts = e.key.split('@');
              final s = songById(parts.first);
              final label = s?.levels.where((l) => l.level == int.parse(parts[1])).firstOrNull?.label ?? '';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text('${s?.emoji} ${s?.title} ($label)')),
                  StarsRow(e.value.stars, size: 14),
                  const SizedBox(width: 8),
                  Text('${(e.value.bestNote * 100).round()}% nốt · ${e.value.plays} lần', style: const TextStyle(color: C.muted, fontSize: 13)),
                ]),
              );
            }),
        ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Hoạt động gần đây'),
          if (sessions.isEmpty) const Text('Chưa có hoạt động trong 2 tuần qua.', style: TextStyle(color: C.muted)),
          for (final s in sessions.take(15))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                Expanded(child: Text('${s.type == 'lesson' ? '📘' : s.type == 'song' ? '🎵' : s.type == 'game' ? '🎮' : '🎹'} ${s.title}')),
                Text(_dt(s.at), style: const TextStyle(color: C.muted, fontSize: 12)),
                if (s.stars > 0) ...[const SizedBox(width: 6), StarsRow(s.stars, size: 12)],
              ]),
            ),
        ]),
      ),
    ]);
  }
}

String _dt(int ms) {
  final d = DateTime.fromMillisecondsSinceEpoch(ms);
  String p(int x) => x.toString().padLeft(2, '0');
  return '${p(d.day)}/${p(d.month)} ${p(d.hour)}:${p(d.minute)}';
}

class _ShareTab extends StatefulWidget {
  final ChildProfile kid;
  final Widget Function(List<Widget>) grid;
  const _ShareTab({super.key, required this.kid, required this.grid});
  @override
  State<_ShareTab> createState() => _ShareTabState();
}

class _ShareTabState extends State<_ShareTab> {
  List<Recording> recs = [];
  List<ShareDoc> shares = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final u = context.read<AppState>().user;
    if (u == null) return;
    api.listRecordings(u.uid, widget.kid.id).then((r) => mounted ? setState(() => recs = r) : null);
    api.listShares(u.uid).then((s) => mounted ? setState(() => shares = s.where((x) => x.childId == widget.kid.id).toList()) : null).catchError((_) => null);
  }

  void _markStage() => context.read<AppState>().updateKid(widget.kid.id, (c) => c.clone()..let(addBadge, 'stage'));

  Future<void> _createLink(BuildContext btnContext, {required String title, required List<PerfEvent> events}) async {
    final app = context.read<AppState>();
    final base = webBaseUrl();
    if (base.isEmpty) {
      toast(context, 'Hãy build app với --dart-define=WEB_URL=<địa chỉ web của app> để tạo link chia sẻ.');
      return;
    }
    final nameCtrl = TextEditingController(text: widget.kid.nickname);
    final ok = await showAppModal<bool>(context, (ctx) => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text('🔗 Tạo link Sân khấu gia đình', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Người nhận link có thể nghe con chơi và thả tim. Chỉ hiển thị tên dưới đây:'),
          const SizedBox(height: 8),
          TextField(controller: nameCtrl, maxLength: 30),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Btn('Hủy', kind: BtnKind.ghost, onTap: () => Navigator.pop(ctx, false)),
            const SizedBox(width: 10),
            Btn('Tạo link', kind: BtnKind.primary, onTap: () => Navigator.pop(ctx, true)),
          ]),
        ]));
    if (ok != true || app.user == null || app.parent == null) return;
    final name = nameCtrl.text.trim().isEmpty ? widget.kid.nickname : nameCtrl.text.trim();
    final id = await api.createShare(ShareDoc(
      id: '', ownerUid: app.user!.uid, childId: widget.kid.id, nickname: name.length > 30 ? name.substring(0, 30) : name, avatar: widget.kid.avatar,
      title: title, kind: 'performance', events: events.take(3800).toList(), hearts: 0,
      createdAt: DateTime.now().millisecondsSinceEpoch, inviteCode: app.parent!.inviteCode,
    ));
    _markStage();
    _reload();
    if (btnContext.mounted) await shareLink(btnContext, '$base/s/$id', 'Nghe $name chơi đàn nè! Thả tim cho con nhé ❤️');
    if (mounted) toast(context, 'Đã tạo và sao chép link sân khấu gia đình!');
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final kid = widget.kid;
    if (!app.settings.allowSharing) return const CardBox(child: Text('Tính năng chia sẻ đang tắt. Bật trong ⚙️ Cài đặt để tạo link và ảnh chia sẻ.'));
    final byId = {for (final r in recs) r.id: r};
    final pairs = kid.songs.entries.where((e) => e.value.firstRec != null && e.value.bestRec != null && e.value.firstRec != e.value.bestRec && byId.containsKey(e.value.firstRec) && byId.containsKey(e.value.bestRec)).toList();
    final regionsDone = regions.where((r) => kid.badges.contains('region-${r.id}')).toList();
    return widget.grid([
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('🎭 Bản thu & link biểu diễn'),
          const Text('Link sân khấu chỉ chứa nốt nhạc con chơi, nhân vật và biệt danh – không có khuôn mặt hay giọng nói. Chỉ ai có link mới xem được.', style: TextStyle(color: C.muted, fontSize: 13)),
          const SizedBox(height: 6),
          if (recs.isEmpty) const Text('Chưa có bản thu. Bản thu tự lưu khi bé chơi trọn một bài (có thể tắt trong Cài đặt).', style: TextStyle(color: C.muted)),
          for (final r in recs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                SizedBox(width: 220, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)), Text('${formatDate(r.createdAt)} · ${(r.noteAcc * 100).round()}% đúng nốt', style: const TextStyle(color: C.muted, fontSize: 12))])),
                StarsRow(r.stars, size: 14),
                PlayRecButton(events: r.events, label: 'Nghe'),
                Builder(builder: (b) => Btn('🔗 Link', small: true, onTap: () => _createLink(b, title: r.title, events: r.events))),
                Btn('🗑️', small: true, kind: BtnKind.ghost, onTap: () async {
                  final u = app.user;
                  if (u == null) return;
                  await api.deleteRecording(u.uid, kid.id, r.id);
                  _reload();
                }),
              ]),
            ),
        ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('⏪ Trước – Sau'),
          if (pairs.isEmpty) const Text('Khi bé chơi lại một bài và tiến bộ hơn, phần so sánh sẽ xuất hiện ở đây.', style: TextStyle(color: C.muted)),
          for (final e in pairs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(byId[e.value.bestRec]!.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                PlayRecButton(events: byId[e.value.firstRec]!.events, label: 'Lần đầu'),
                PlayRecButton(events: byId[e.value.bestRec]!.events, label: 'Bây giờ'),
                Builder(builder: (b) => Btn('🔗 Link bản mới nhất', small: true, kind: BtnKind.primary, onTap: () => _createLink(b, title: byId[e.value.bestRec]!.title, events: byId[e.value.bestRec]!.events))),
              ]),
            ),
        ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('📜 Chứng nhận & Tổng kết'),
          if (regionsDone.isEmpty) const Text('Chứng nhận xuất hiện khi bé thắng trùm cuối mỗi vùng đất.', style: TextStyle(color: C.muted)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final r in regionsDone)
              Builder(builder: (b) => Btn('${r.emoji} Chứng nhận ${r.name}', small: true, onTap: () async {
                    final png = await renderCertificate(nickname: kid.nickname, regionName: r.name, rank: r.rank, emoji: r.emoji, date: DateTime.now());
                    if (b.mounted) await shareImage(b, png, 'chung-nhan-${r.id}.png', '${kid.nickname} đã chinh phục ${r.name} trên Piano Quest! 🏅');
                  })),
            Builder(builder: (b) => Btn('🖼️ Ảnh tổng kết tháng này', small: true, kind: BtnKind.primary, onTap: () async {
                  final mk = monthKey();
                  final logs = kid.log.entries.where((e) => e.key.startsWith(mk)).map((e) => e.value).toList();
                  final top = (kid.songs.entries.toList()..sort((a, b) => b.value.plays.compareTo(a.value.plays))).firstOrNull;
                  final png = await renderRecap(
                    nickname: kid.nickname, avatar: kid.avatar, monthLabel: 'tháng ${int.parse(mk.substring(5))}/${mk.substring(0, 4)}',
                    minutes: (logs.fold<int>(0, (s, l) => s + l.sec) / 60).round(), days: logs.where((l) => l.sec >= 60).length,
                    songs: logs.fold(0, (s, l) => s + l.songs), lessons: logs.fold(0, (s, l) => s + l.lessons), stars: logs.fold(0, (s, l) => s + l.stars),
                    topSong: top == null ? null : songById(top.key.split('@').first)?.title,
                    badges: kid.badges.map((b) => badgeById(b)?.emoji ?? '').where((e) => e.isNotEmpty).toList(),
                  );
                  if (b.mounted) await shareImage(b, png, 'tong-ket-$mk.png', 'Tháng này ${kid.nickname} đã luyện đàn thật chăm chỉ! 🎹');
                })),
          ]),
        ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('❤️ Link sân khấu đã chia sẻ'),
          if (shares.isEmpty) const Text('Chưa có link nào.', style: TextStyle(color: C.muted)),
          for (final s in shares)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(s.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('❤️ ${s.hearts}'),
                Btn('📋 Sao chép', small: true, onTap: () async {
                  await Clipboard.setData(ClipboardData(text: '${webBaseUrl()}/s/${s.id}'));
                  if (context.mounted) toast(context, 'Đã sao chép link');
                }),
                Btn('🗑️ Gỡ', small: true, kind: BtnKind.ghost, onTap: () async {
                  await api.deleteShare(s.id);
                  _reload();
                }),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

class _InviteTab extends StatefulWidget {
  const _InviteTab();
  @override
  State<_InviteTab> createState() => _InviteTabState();
}

class _InviteTabState extends State<_InviteTab> {
  int joins = 0;
  @override
  void initState() {
    super.initState();
    final p = context.read<AppState>().parent;
    if (p != null) api.countInviteJoins(p.inviteCode).then((n) => mounted ? setState(() => joins = n) : null).catchError((_) => null);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AppState>().parent!;
    final base = webBaseUrl();
    final link = '${base.isEmpty ? '' : base}/login?ref=${p.inviteCode}';
    const text = 'Con mình đang tự học piano với Piano Quest – có trò chơi, nhiệm vụ mỗi ngày và thú cưng âm nhạc. Thử cho bé nhà bạn nhé!';
    return CardBox(
      child: Column(children: [
        const Text('🎁 Mời gia đình khác cùng học', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Mỗi gia đình tham gia qua link của bạn: các bé nhà bạn nhận 100 nốt vàng + 🐉 Rồng Vàng hiếm, bé nhà bạn bè cũng nhận Rồng Vàng khi tạo hồ sơ.', textAlign: TextAlign.center),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xfff3f0ff), borderRadius: BorderRadius.circular(18)),
          child: Text(p.inviteCode, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: 10, color: C.primary)),
        ),
        const SizedBox(height: 10),
        if (base.isEmpty) const Text('Bé nhà bạn bè nhập mã này khi tạo tài khoản qua link web của app.', style: TextStyle(color: C.muted)) else SelectableText(link),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
          Builder(builder: (b) => Btn('📤 Chia sẻ lời mời', kind: BtnKind.primary, onTap: () => shareLink(b, base.isEmpty ? 'Mã mời: ${p.inviteCode}' : link, text))),
          if (base.isNotEmpty) Btn('Facebook', onTap: () => launchUrl(Uri.parse('https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(link)}'), mode: LaunchMode.externalApplication)),
        ]),
        const SizedBox(height: 10),
        Text('👨‍👩‍👧 Đã có $joins gia đình tham gia nhờ bạn.', style: const TextStyle(fontWeight: FontWeight.w700)),
        if (api.demo) const Text('Chế độ thử nghiệm: lời mời chỉ hoạt động trên thiết bị này.', style: TextStyle(color: C.muted, fontSize: 13)),
      ]),
    );
  }
}

class _SettingsTab extends StatefulWidget {
  final ChildProfile? kid;
  final Widget Function(List<Widget>) grid;
  const _SettingsTab({super.key, required this.kid, required this.grid});
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  late final name = TextEditingController(text: widget.kid?.nickname ?? '');
  final confirm = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final s = app.settings;
    final kid = widget.kid;
    Widget toggle(String label, bool v, void Function(ParentSettings, bool) set) => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(label), value: v, onChanged: (x) => app.updateSettings((st) => set(st, x)));
    return widget.grid([
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('⏰ Thời gian học'),
          const Text('Giới hạn mỗi ngày', style: TextStyle(fontWeight: FontWeight.w700)),
          DropdownButton<int>(
            value: s.dailyLimitMin,
            isExpanded: true,
            items: [for (final m in [0, 15, 20, 30, 45, 60]) DropdownMenuItem(value: m, child: Text(m == 0 ? 'Không giới hạn' : '$m phút'))],
            onChanged: (v) => app.updateSettings((st) => st.dailyLimitMin = v ?? st.dailyLimitMin),
          ),
          const Text('Nhắc nghỉ mắt sau', style: TextStyle(fontWeight: FontWeight.w700)),
          DropdownButton<int>(
            value: s.breakReminderMin,
            isExpanded: true,
            items: [for (final m in [0, 15, 20, 30]) DropdownMenuItem(value: m, child: Text(m == 0 ? 'Không nhắc' : '$m phút'))],
            onChanged: (v) => app.updateSettings((st) => st.breakReminderMin = v ?? st.breakReminderMin),
          ),
        ]),
      ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('🔐 Riêng tư & âm thanh'),
          toggle('Lưu bản thu khi bé chơi (chỉ nốt nhạc, không ghi âm giọng nói)', s.allowRecording, (st, v) => st.allowRecording = v),
          toggle('Cho phép tạo link & ảnh chia sẻ', s.allowSharing, (st, v) => st.allowSharing = v),
          toggle('Giọng đọc hướng dẫn', s.voice, (st, v) => st.voice = v),
          toggle('Hiệu ứng âm thanh', s.sfx, (st, v) => st.sfx = v),
        ]),
      ),
      if (kid != null)
        CardBox(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SectionTitle('🧒 Hồ sơ ${kid.nickname}'),
            Row(children: [
              Expanded(child: TextField(controller: name, maxLength: 20, decoration: const InputDecoration(labelText: 'Biệt danh', counterText: ''))),
              const SizedBox(width: 8),
              Btn('Lưu', small: true, onTap: () => name.text.trim().isEmpty ? null : app.updateKid(kid.id, (c) => c.clone()..nickname = name.text.trim())),
            ]),
            const SizedBox(height: 8),
            const Text('Thiết bị chơi', style: TextStyle(fontWeight: FontWeight.w700)),
            DropdownButton<InputKind>(
              value: kid.input,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: InputKind.screen, child: Text('Bàn phím màn hình')),
                DropdownMenuItem(value: InputKind.midi, child: Text('Đàn điện tử (MIDI)')),
                DropdownMenuItem(value: InputKind.mic, child: Text('Đàn thật qua micro')),
              ],
              onChanged: (v) => app.updateKid(kid.id, (c) => c.clone()..input = v ?? c.input),
            ),
            const Text('Mở khóa đến vùng (nếu bé đã biết chơi)', style: TextStyle(fontWeight: FontWeight.w700)),
            DropdownButton<int>(
              value: kid.unlockedRegion,
              isExpanded: true,
              items: [for (final r in regions) DropdownMenuItem(value: r.id, child: Text('${r.id}. ${r.name}'))],
              onChanged: (v) => app.updateKid(kid.id, (c) => c.clone()..unlockedRegion = v ?? c.unlockedRegion),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              Btn('🗑️ Xóa mọi bản thu', small: true, kind: BtnKind.ghost, onTap: () async {
                final u = app.user;
                if (u == null) return;
                final ok = await showAppModal<bool>(context, (ctx) => _confirm(ctx, 'Xóa toàn bộ bản thu của ${kid.nickname}?'));
                if (ok != true) return;
                for (final r in await api.listRecordings(u.uid, kid.id)) {
                  await api.deleteRecording(u.uid, kid.id, r.id);
                }
                app.updateKid(kid.id, (c) => c.clone()..songs.forEach((_, p) => p..firstRec = null..bestRec = null));
                if (context.mounted) toast(context, 'Đã xóa.');
              }),
              Btn('Xóa hồ sơ bé', small: true, kind: BtnKind.danger, onTap: () async {
                final ok = await showAppModal<bool>(context, (ctx) => _confirm(ctx, 'Xóa hồ sơ ${kid.nickname} và toàn bộ tiến độ?'));
                if (ok == true) await app.removeChild(kid.id);
              }),
            ]),
          ]),
        ),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('👤 Tài khoản'),
          Text('${app.parent?.email}${api.demo ? ' (chế độ thử nghiệm)' : ''}'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            Btn('＋ Thêm hồ sơ bé', onTap: () => context.go('/new-child')),
            Btn('Đăng xuất', kind: BtnKind.ghost, onTap: () async {
              app.flushAll();
              await api.signOut();
              if (context.mounted) context.go('/login');
            }),
          ]),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Xóa tài khoản và toàn bộ dữ liệu', style: TextStyle(color: C.bad, fontWeight: FontWeight.w700)),
            children: [
              const Text('Gõ XOA để xác nhận. Hành động này không thể hoàn tác.'),
              TextField(controller: confirm, onChanged: (_) => setState(() {})),
              const SizedBox(height: 8),
              Btn('Xóa vĩnh viễn', kind: BtnKind.danger, onTap: confirm.text != 'XOA'
                  ? null
                  : () async {
                      final u = app.user;
                      if (u == null) return;
                      try {
                        await api.deleteAccount(u.uid);
                        if (context.mounted) context.go('/login');
                      } catch (_) {
                        if (context.mounted) toast(context, 'Vui lòng đăng nhập lại rồi thử xóa tài khoản lần nữa.');
                      }
                    }),
            ],
          ),
        ]),
      ),
    ]);
  }

  Widget _confirm(BuildContext ctx, String text) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Btn('Hủy', kind: BtnKind.ghost, onTap: () => Navigator.pop(ctx, false)),
          const SizedBox(width: 10),
          Btn('Xóa', kind: BtnKind.danger, onTap: () => Navigator.pop(ctx, true)),
        ]),
      ]);
}

extension _Let<T> on T {
  T let<A>(void Function(T, A) fn, A arg) {
    fn(this, arg);
    return this;
  }
}
