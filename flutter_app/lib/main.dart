import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';

import 'audio/input.dart';
import 'audio/synth.dart';
import 'data/api.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'state/app_state.dart';
import 'ui/kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    api = FirebaseApi();
  } catch (e) {
    debugPrint('Firebase unavailable, using local demo data: $e');
    final demo = DemoApi();
    await demo.init();
    api = demo;
  }
  HardwareKeyboard.instance.addHandler(handleComputerKey);
  final app = AppState();
  await app.init();
  runApp(PianoQuestApp(app: app));
}

class PianoQuestApp extends StatefulWidget {
  final AppState app;
  const PianoQuestApp({super.key, required this.app});
  @override
  State<PianoQuestApp> createState() => _PianoQuestAppState();
}

class _PianoQuestAppState extends State<PianoQuestApp> with WidgetsBindingObserver {
  late final router = buildRouter(widget.app);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) widget.app.flushAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: widget.app,
        child: Listener(
          // Audio engines on web and iOS can only start after a user gesture.
          onPointerDown: (_) => synth.ensure(),
          child: MaterialApp.router(
            title: 'Piano Quest – Hành Trình Phím Đàn',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(),
            routerConfig: router,
          ),
        ),
      );
}
