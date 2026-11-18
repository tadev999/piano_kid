import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Step;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../content/rewards.dart';
import '../data/api.dart';
import '../models.dart';
import '../state/app_state.dart';
import '../ui/common.dart';
import '../ui/kit.dart';
import '../ui/widgets.dart';

const _authErrors = {
  'invalid-credential': 'Email hoặc mật khẩu chưa đúng.',
  'wrong-password': 'Email hoặc mật khẩu chưa đúng.',
  'user-not-found': 'Email hoặc mật khẩu chưa đúng.',
  'email-already-in-use': 'Email này đã có tài khoản. Hãy đăng nhập.',
  'weak-password': 'Mật khẩu cần ít nhất 6 ký tự.',
  'invalid-email': 'Email chưa hợp lệ.',
  'popup-closed-by-user': 'Bạn đã đóng cửa sổ đăng nhập.',
};

class LoginScreen extends StatefulWidget {
  final String? referral;
  const LoginScreen({super.key, this.referral});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool signUp = true, busy = false;
  String error = '', info = '';
  final email = TextEditingController(), password = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.referral != null) context.read<AppState>().rememberReferral(widget.referral!);
  }

  Future<void> _run(Future<void> Function() fn) async {
    setState(() {
      error = '';
      busy = true;
    });
    try {
      await fn();
    } on FirebaseAuthException catch (e) {
      error = _authErrors[e.code] ?? 'Có lỗi xảy ra, thử lại nhé.';
    } catch (e) {
      error = 'Có lỗi xảy ra, thử lại nhé.';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _submit() {
    if (password.text.length < 6) {
      setState(() => error = 'Mật khẩu cần ít nhất 6 ký tự.');
      return;
    }
    _run(() => signUp ? api.signUpEmail(email.text.trim(), password.text) : api.signInEmail(email.text.trim(), password.text));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 820;
    final hero = Column(mainAxisSize: MainAxisSize.min, children: [
      Stack(alignment: Alignment.center, children: [
        const LottieFx(Fx.sparkles, repeat: true, width: 260, height: 220),
        const Mascot(size: 150, mood: Mood.cheer, talking: true),
      ]),
      const Text('Piano Quest', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: C.primary)),
      const Text('Hành trình tự học piano cho bé 6–10 tuổi 🎹', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      for (final p in const [
        '🗺️ 6 vùng đất, gần 50 bài học từ số 0 đến biểu diễn',
        '🎮 Trò chơi, nhiệm vụ mỗi ngày, thú cưng âm nhạc',
        '🎤 Dùng bàn phím màn hình, đàn điện tử hoặc đàn thật',
        '👨‍👩‍👧 Bố mẹ theo dõi tiến bộ, chia sẻ màn biểu diễn của con',
      ])
        Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Text(p, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
      if (widget.referral != null)
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xfffff9db), borderRadius: BorderRadius.circular(14)),
          child: const Text('🎁 Bạn được mời! Tạo tài khoản để bé nhận Rồng Vàng hiếm.', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
    ]);
    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: CardBox(
        padding: const EdgeInsets.all(26),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(signUp ? 'Bố mẹ tạo tài khoản' : 'Bố mẹ đăng nhập', style: Theme.of(context).textTheme.headlineSmall),
          if (api.demo)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xfffff9db), borderRadius: BorderRadius.circular(14)),
              child: const Text('Chế độ thử nghiệm: dữ liệu lưu trên thiết bị này. Chạy `flutterfire configure` để dùng Firebase.', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          const SizedBox(height: 12),
          Btn('G  Tiếp tục với Google', onTap: busy ? null : () => _run(api.signInGoogle)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Center(child: Text('hoặc', style: TextStyle(color: C.muted)))),
          TextField(controller: email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(hintText: 'Email của bố mẹ')),
          const SizedBox(height: 10),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: 'Mật khẩu (ít nhất 6 ký tự)'), onSubmitted: (_) => _submit()),
          if (error.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(error, style: const TextStyle(color: C.bad, fontWeight: FontWeight.w700))),
          if (info.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(info, style: const TextStyle(color: C.good, fontWeight: FontWeight.w700))),
          const SizedBox(height: 12),
          Btn(signUp ? 'Tạo tài khoản' : 'Đăng nhập', kind: BtnKind.primary, onTap: busy ? null : _submit),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(onPressed: () => setState(() => signUp = !signUp), child: Text(signUp ? 'Đã có tài khoản? Đăng nhập' : 'Chưa có tài khoản? Tạo mới')),
            if (!signUp)
              TextButton(
                onPressed: () => email.text.isEmpty
                    ? setState(() => error = 'Nhập email trước nhé.')
                    : _run(() async {
                        await api.resetPassword(email.text.trim());
                        info = 'Đã gửi email đặt lại mật khẩu.';
                      }),
                child: const Text('Quên mật khẩu?'),
              ),
          ]),
          const Text('Tài khoản thuộc về phụ huynh. Bé chỉ có hồ sơ bên trong, không cần email. Không quảng cáo, không chat.', style: TextStyle(color: C.muted, fontSize: 13)),
        ]),
      ),
    );
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xffe5dbff), Color(0xffffdeeb), Color(0xfffff3bf)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: wide
                  ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [Flexible(child: hero), const SizedBox(width: 30), Flexible(child: card)])
                  : Column(children: [hero, const SizedBox(height: 20), card]),
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilesScreen extends StatelessWidget {
  const ProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xffe5dbff), Color(0xffd0ebff)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Mascot(size: 110, mood: Mood.cheer),
                const Text('Ai đang học đàn hôm nay?', textAlign: TextAlign.center, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                Wrap(spacing: 18, runSpacing: 18, alignment: WrapAlignment.center, children: [
                  for (final k in app.kids)
                    PopIn(
                      child: CardBox(
                        onTap: () {
                          app.selectChild(k.id);
                          context.go(k.onboarded ? '/' : '/welcome');
                        },
                        child: SizedBox(
                          width: 150,
                          child: Column(children: [
                            AvatarView(k.avatar, hat: k.equipped.hat, size: 110),
                            const SizedBox(height: 6),
                            Text(k.nickname, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                            Text('${petEmoji(k.pet, k.petXp)} ⭐ ${k.totalStars}', style: const TextStyle(fontSize: 16)),
                          ]),
                        ),
                      ),
                    ),
                  if (app.kids.length < 4)
                    CardBox(
                      color: Colors.white.withValues(alpha: 0.6),
                      onTap: () async {
                        if (await parentGate(context, reason: 'Bố mẹ giúp bé tạo hồ sơ nhé.') && context.mounted) context.go('/new-child');
                      },
                      child: const SizedBox(width: 150, height: 170, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('＋', style: TextStyle(fontSize: 60, color: C.primary)), Text('Thêm bé', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))])),
                    ),
                ]),
                const SizedBox(height: 24),
                Btn('🔒 Khu vực phụ huynh', kind: BtnKind.ghost, onTap: () async {
                  if (await parentGate(context) && context.mounted) context.go('/parent');
                }),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class NewChildScreen extends StatefulWidget {
  const NewChildScreen({super.key});
  @override
  State<NewChildScreen> createState() => _NewChildScreenState();
}

class _NewChildScreenState extends State<NewChildScreen> {
  final name = TextEditingController();
  int birthYear = DateTime.now().year - 7;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: CardBox(
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('👨‍👩‍👧 Tạo hồ sơ cho bé', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text('Tên gọi ở nhà (biệt danh)', style: TextStyle(fontWeight: FontWeight.w700)),
                TextField(controller: name, maxLength: 20, autofocus: true, decoration: const InputDecoration(hintText: 'Ví dụ: Bông, Na, Bin…')),
                const Text('Năm sinh', style: TextStyle(fontWeight: FontWeight.w700)),
                DropdownButtonFormField<int>(
                  initialValue: birthYear,
                  items: [for (var i = 0; i < 10; i++) DropdownMenuItem(value: year - 4 - i, child: Text('${year - 4 - i} (${4 + i} tuổi)'))],
                  onChanged: (v) => setState(() => birthYear = v ?? birthYear),
                ),
                const SizedBox(height: 8),
                const Text('Chỉ dùng biệt danh, không cần họ tên thật. Năm sinh giúp app chọn cách hướng dẫn phù hợp.', style: TextStyle(color: C.muted, fontSize: 13)),
                const SizedBox(height: 14),
                Row(children: [
                  Btn('Hủy', kind: BtnKind.ghost, onTap: () => context.go('/profiles')),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Btn('Tiếp tục ➜', kind: BtnKind.primary, onTap: busy
                        ? null
                        : () async {
                            if (name.text.trim().isEmpty) return;
                            setState(() => busy = true);
                            final app = context.read<AppState>();
                            final c = await app.createChild(nickname: name.text.trim(), birthYear: birthYear);
                            app.selectChild(c.id);
                            if (context.mounted) context.go('/welcome');
                          }),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int step = 0;
  late final petName = TextEditingController(text: context.read<AppState>().child?.petName ?? '');

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final child = app.child;
    if (child == null) return const SizedBox();
    void upd(void Function(ChildProfile c) fn) => app.updateChild((c) => c.clone()..let(fn));

    void finish(bool knowsSome) {
      upd((c) {
        c.onboarded = true;
        if (knowsSome && c.unlockedRegion < 2) c.unlockedRegion = 2;
      });
      context.go(knowsSome ? '/map' : '/lesson/r1-1');
    }

    final content = switch (step) {
      0 => Column(children: [
          Guide('Chào ${child.nickname}! Mình là Đô Rê, chú chim yêu âm nhạc. Mình sẽ cùng bạn phiêu lưu qua thế giới phím đàn! Trước tiên, hãy chọn nhân vật của bạn nhé!', size: 130),
          const SizedBox(height: 8),
          AvatarView(child.avatar, size: 130),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            for (final a in animals)
              _Pick(selected: child.avatar.animal == a, onTap: () => upd((c) => c.avatar = AvatarConfig(a, c.avatar.color)), child: Text(a, style: const TextStyle(fontSize: 34))),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final col in avatarColors)
              GestureDetector(
                onTap: () => upd((c) => c.avatar = AvatarConfig(c.avatar.animal, col)),
                child: Container(width: 46, height: 46, decoration: BoxDecoration(color: hexColor(col), shape: BoxShape.circle, border: Border.all(color: child.avatar.color == col ? C.primary : Colors.transparent, width: 3))),
              ),
          ]),
          const SizedBox(height: 16),
          Btn('Chọn xong ➜', kind: BtnKind.primary, huge: true, onTap: () => setState(() => step = 1)),
        ]),
      1 => Column(children: [
          const Guide('Đây là quả trứng thú cưng âm nhạc! Mỗi lần bạn luyện đàn, nó sẽ lớn lên. Bạn chọn bạn nào?', size: 110),
          Wrap(spacing: 14, runSpacing: 14, alignment: WrapAlignment.center, children: [
            for (final e in pets.entries)
              _Pick(
                selected: child.pet == e.key,
                onTap: () {
                  petName.text = e.value.name;
                  upd((c) {
                    c.pet = e.key;
                    c.petName = e.value.name;
                  });
                },
                child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [Text(e.value.stages[3], style: const TextStyle(fontSize: 54)), Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.w800))])),
              ),
          ]),
          const SizedBox(height: 12),
          const Text('Đặt tên cho thú cưng:', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(width: 260, child: TextField(controller: petName, maxLength: 16, textAlign: TextAlign.center, onChanged: (v) => upd((c) => c.petName = v))),
          Btn('Tiếp tục ➜', kind: BtnKind.primary, huge: true, onTap: () => setState(() => step = 2)),
        ]),
      2 => Column(children: [
          const Guide('Bạn sẽ chơi bằng đàn nào? Bố mẹ giúp bạn chọn nhé!', size: 110),
          Btn('🎹 Chọn đàn (${child.input == InputKind.midi ? 'Đàn điện tử' : child.input == InputKind.mic ? 'Đàn thật qua micro' : 'Màn hình'})', huge: true, onTap: () => showDevicePanel(context)),
          const SizedBox(height: 12),
          Btn('Tiếp tục ➜', kind: BtnKind.primary, huge: true, onTap: () => setState(() => step = 3)),
        ]),
      _ => Column(children: [
          const LottieFx(Fx.hearts, repeat: true, width: 200, height: 160),
          const Guide('Bạn đã từng chơi đàn piano chưa?', size: 110),
          Wrap(spacing: 12, runSpacing: 12, alignment: WrapAlignment.center, children: [
            Btn('🌱 Chưa, mình mới bắt đầu', kind: BtnKind.primary, huge: true, onTap: () => finish(false)),
            Btn('🎶 Mình biết chơi một chút', huge: true, onTap: () => finish(true)),
          ]),
        ]),
    };
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xfffff4e6), Color(0xffffdeeb)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: SafeArea(child: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: content))),
      ),
    );
  }
}

class _Pick extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  const _Pick({required this.selected, required this.onTap, required this.child});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: selected ? 1.1 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: selected ? C.primary : Colors.transparent, width: 3), boxShadow: const [BoxShadow(color: Color(0x1a000000), offset: Offset(0, 3))]),
            child: child,
          ),
        ),
      );
}

extension Let<T> on T {
  T let(void Function(T) fn) {
    fn(this);
    return this;
  }
}
