import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/storage.dart';
import '../widgets/ui.dart';

/// Petunjuk cara bermain.
class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  static const _rows = <(IconData, Color, String)>[
    (Icons.gamepad_rounded, Color(0xFF1976D2), 'Tekan tombol kiri/kanan untuk bergerak dan tombol lompat untuk melompat.'),
    (Icons.recycling_rounded, Color(0xFF2E7D32), 'Kumpulkan sampah (+25 poin). Kumpulkan hampir semuanya untuk mendapat 3 bintang.'),
    (Icons.monetization_on_rounded, Color(0xFFFFA000), 'Ambil koin untuk tambahan skor (+10 poin).'),
    (Icons.bug_report_rounded, Color(0xFF8E24AA), 'Hindari musuh polusi, atau injak dari atas untuk mengalahkannya (+50).'),
    (Icons.warning_amber_rounded, Color(0xFFE53935), 'Awas duri dan jurang! Setiap kesalahan mengurangi 1 nyawa dari 3 nyawa.'),
    (Icons.flag_rounded, Color(0xFF43A047), 'Capai bendera di ujung level untuk menyelesaikannya dan membuka level berikutnya.'),
  ];

  @override
  Widget build(BuildContext context) => PageShell(
        title: 'HOW TO PLAY',
        child: Panel(
          child: ListView(children: [
            for (final r in _rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(r.$1, color: r.$2, size: 34),
                  const SizedBox(width: 14),
                  Expanded(
                      child: Text(r.$3,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                ]),
              ),
          ]),
        ),
      );
}

/// Pengaturan volume musik/efek dan reset progres.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Widget _slider(String label, IconData icon, double value, ValueChanged<double> onChanged,
          [ValueChanged<double>? onEnd]) =>
      Row(children: [
        Icon(icon, color: const Color(0xFF2E7D32)),
        const SizedBox(width: 10),
        SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
        Expanded(child: Slider(value: value, onChanged: onChanged, onChangeEnd: onEnd)),
        SizedBox(width: 44, child: Text('${(value * 100).round()}%')),
      ]);

  @override
  Widget build(BuildContext context) => PageShell(
        title: 'SETTINGS',
        child: Center(
          child: SingleChildScrollView(
            child: Panel(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _slider('Musik', Icons.music_note_rounded, Store.music, (v) {
                  Audio.setMusicVolume(v);
                  setState(() {});
                }),
                _slider('Efek suara', Icons.volume_up_rounded, Store.sfx, (v) {
                  Store.sfx = v;
                  setState(() {});
                }, (_) => Audio.play('coin')),
                const SizedBox(height: 8),
                GameButton(
                  label: 'RESET PROGRES',
                  icon: Icons.restart_alt_rounded,
                  width: 230,
                  colors: const [Color(0xFFEF5350), Color(0xFFC62828)],
                  onTap: () {
                    Store.highScore = 0;
                    Store.unlocked = 1;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Skor tertinggi dan level direset.')));
                  },
                ),
              ]),
            ),
          ),
        ),
      );
}
