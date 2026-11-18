import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/storage.dart';
import '../game/levels.dart';
import '../widgets/ui.dart';
import 'game_screen.dart';

/// Pemilihan level. Level yang belum terbuka tampil terkunci.
class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});
  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  Widget build(BuildContext context) {
    final unlocked = Store.unlocked;
    return PageShell(
      title: 'PILIH LEVEL',
      child: GridView.count(
        crossAxisCount: 5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.5,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (var n = 1; n <= LevelDef.count; n++) _tile(n, n <= unlocked),
        ],
      ),
    );
  }

  Widget _tile(int n, bool open) {
    final def = LevelDef.of(n);
    final color = LevelDef.themeColors[def.theme];
    return GestureDetector(
      onTap: () {
        if (!open) {
          Audio.play('hit');
          return;
        }
        Audio.play('click');
        Navigator.push(context, fadeRoute(GameScreen(level: n))).then((_) => setState(() {}));
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: open ? [color, Color.lerp(color, Colors.black, .35)!] : const [Colors.grey, Color(0xFF616161)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 4), blurRadius: 5)],
        ),
        child: Center(
          child: open
              ? Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$n',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  Text(def.themeName,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ])
              : const Icon(Icons.lock_rounded, color: Colors.white70, size: 30),
        ),
      ),
    );
  }
}
