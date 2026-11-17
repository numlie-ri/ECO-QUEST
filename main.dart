import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/audio.dart';
import 'core/storage.dart';
import 'screens/menu_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Game dimainkan dalam mode landscape layar penuh.
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Store.init();
  await Audio.init();
  runApp(const EcoQuestApp());
}

class EcoQuestApp extends StatefulWidget {
  const EcoQuestApp({super.key});
  @override
  State<EcoQuestApp> createState() => _EcoQuestAppState();
}

class _EcoQuestAppState extends State<EcoQuestApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Musik berhenti saat aplikasi masuk background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    s == AppLifecycleState.resumed ? Audio.resumeMusic() : Audio.pauseMusic();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'ECO QUEST',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
        home: const MenuScreen(),
      );
}