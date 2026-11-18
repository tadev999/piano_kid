import 'package:flutter/material.dart' hide Step;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'audio/input.dart';
import 'audio/synth.dart';
import 'models.dart';
import 'screens/child_pages.dart';
import 'screens/entry.dart';
import 'screens/free_play.dart';
import 'screens/home.dart';
import 'screens/lesson.dart';
import 'screens/library.dart';
import 'screens/parent.dart';
import 'screens/share.dart';
import 'state/app_state.dart';
import 'ui/common.dart';
import 'ui/widgets.dart';

const _childRoutes = ['/', '/welcome', '/map', '/region', '/lesson', '/songs', '/song', '/games', '/game', '/free', '/shop', '/collection', '/progress', '/stage'];

bool _needsChild(String path) => _childRoutes.any((r) => r == '/' ? path == '/' : path == r || path.startsWith('$r/'));

GoRouter buildRouter(AppState app) => GoRouter(
      refreshListenable: app,
      redirect: (context, state) {
        final path = state.uri.path;
        if (path.startsWith('/s/')) return null;
        if (!app.ready) return path == '/loading' ? null : '/loading?to=${Uri.encodeComponent(state.uri.toString())}';
        if (path == '/loading') return state.uri.queryParameters['to'] ?? '/';
        if (app.user == null) return path == '/login' ? null : '/login${state.uri.query.isEmpty ? '' : '?${state.uri.query}'}';
        if (path == '/login') return '/profiles';
        if (_needsChild(path) && app.child == null) return '/profiles';
        return null;
      },
      routes: [
        GoRoute(path: '/loading', builder: (_, __) => const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Mascot(size: 120, talking: true), Text('Đang mở cây đàn…')])))),
        GoRoute(path: '/s/:id', builder: (_, s) => ShareScreen(id: s.pathParameters['id']!)),
        GoRoute(path: '/login', builder: (_, s) => LoginScreen(referral: s.uri.queryParameters['ref'])),
        GoRoute(path: '/profiles', builder: (_, __) => const ProfilesScreen()),
        GoRoute(path: '/new-child', builder: (_, __) => const NewChildScreen()),
        GoRoute(path: '/parent', builder: (_, s) => ParentScreen(tab: s.uri.queryParameters['tab'] ?? 'overview')),
        ShellRoute(
          builder: (_, __, child) => _ChildShell(child: child),
          routes: [
            GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
            GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
            GoRoute(path: '/map', builder: (_, __) => const MapScreen()),
            GoRoute(path: '/region/:id', builder: (_, s) => RegionScreen(id: int.tryParse(s.pathParameters['id']!) ?? 1)),
            GoRoute(path: '/lesson/:id', builder: (_, s) => LessonScreen(id: s.pathParameters['id']!)),
            GoRoute(path: '/songs', builder: (_, __) => const SongbookScreen()),
            GoRoute(path: '/song/:id/:level', builder: (_, s) => SongScreen(id: s.pathParameters['id']!, level: int.tryParse(s.pathParameters['level']!) ?? 1)),
            GoRoute(path: '/games', builder: (_, __) => const GamesScreen()),
            GoRoute(path: '/game/:kind', builder: (_, s) => GameScreen(kind: s.pathParameters['kind']!)),
            GoRoute(path: '/free', builder: (_, __) => const FreePlayScreen()),
            GoRoute(path: '/shop', builder: (_, __) => const ShopScreen()),
            GoRoute(path: '/collection', builder: (_, __) => const CollectionScreen()),
            GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
            GoRoute(path: '/stage', builder: (_, __) => const StageScreen()),
          ],
        ),
      ],
    );

/// Connects the child's chosen instrument and overlays daily-limit / break reminders.
class _ChildShell extends StatefulWidget {
  final Widget child;
  const _ChildShell({required this.child});
  @override
  State<_ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<_ChildShell> {
  InputKind? _connected;

  void _connect(InputKind? kind) {
    if (kind == null || kind == _connected) return;
    _connected = kind;
    if (kind == InputKind.midi) hub.connectMidi().catchError((_) => <String>[]);
    if (kind == InputKind.mic) {
      synth.ensure().then((_) => hub.startMic()).catchError((_) {});
    } else {
      hub.stopMic();
    }
  }

  @override
  Widget build(BuildContext context) {
    _connect(context.select<AppState, InputKind?>((a) => a.child?.input));
    return Wellbeing(child: widget.child);
  }
}
