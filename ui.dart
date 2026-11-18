import 'dart:math';

import 'package:flutter/material.dart';

import '../core/audio.dart';

/// Transisi halaman: fade + geser halus.
Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, a, __, child) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, .06), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );

const _shadow = [Shadow(color: Color(0x88000000), offset: Offset(0, 2), blurRadius: 3)];

/// Tombol bergaya game mobile dengan animasi tekan.
class GameButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> colors;
  final double width;
  const GameButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.colors = const [Color(0xFFFFC107), Color(0xFFFF9800)],
    this.width = 190,
  });
  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> {
  bool _down = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) {
          setState(() => _down = false);
          Audio.play('click');
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _down ? .94 : 1,
          duration: const Duration(milliseconds: 80),
          child: Container(
            width: widget.width,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: widget.colors),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x55000000), offset: Offset(0, 5), blurRadius: 6)],
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(widget.icon, color: Colors.white, shadows: _shadow),
              const SizedBox(width: 8),
              Flexible(
                child: Text(widget.label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900, shadows: _shadow)),
              ),
            ]),
          ),
        ),
      );
}

/// Kartu putih bersudut bulat untuk konten.
class Panel extends StatelessWidget {
  final Widget child;
  const Panel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xEEFFFFFF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF2E7D32), width: 4),
        ),
        child: child,
      );
}

/// Kerangka halaman standar: latar animasi + tombol kembali + judul.
class PageShell extends StatelessWidget {
  final String title;
  final Widget child;
  const PageShell({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(
        body: MenuBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Row(children: [
                  IconButton.filled(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFFFF7043)),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, shadows: _shadow)),
                ]),
                const SizedBox(height: 8),
                Expanded(child: child),
              ]),
            ),
          ),
        ),
      );
}

/// Latar animasi: matahari, awan bergerak, bukit, dan daun berjatuhan.
class MenuBackground extends StatefulWidget {
  final Widget child;
  const MenuBackground({super.key, required this.child});
  @override
  State<MenuBackground> createState() => _MenuBackgroundState();
}

class _MenuBackgroundState extends State<MenuBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: CustomPaint(painter: _BgPainter(_c))),
        widget.child,
      ]);
}

class _BgPainter extends CustomPainter {
  final Animation<double> a;
  _BgPainter(this.a) : super(repaint: a);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    final r = Offset.zero & s;
    p.shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FC3F7), Color(0xFFE1F5FE)])
        .createShader(r);
    c.drawRect(r, p);
    p.shader = null;
    p.color = const Color(0xFFFFF176);
    c.drawCircle(Offset(s.width * .85, s.height * .2), 42 + sin(a.value * 2 * pi * 40) * 2, p);
    // Awan bergerak (periode 920 agar loop mulus)
    p.color = const Color(0xDDFFFFFF);
    for (var i = 0; i < 4; i++) {
      final x = ((i * 230 + a.value * 920) % 920) * (s.width + 200) / 920 - 100;
      c.drawOval(Rect.fromLTWH(x, s.height * (.1 + .12 * (i % 3)), 110, 34), p);
    }
    // Bukit & pepohonan
    p.color = const Color(0xFF81C784);
    c.drawCircle(Offset(s.width * .2, s.height * 1.15), s.height * .55, p);
    c.drawCircle(Offset(s.width * .75, s.height * 1.2), s.height * .6, p);
    p.color = const Color(0xFF43A047);
    c.drawRect(Rect.fromLTWH(0, s.height * .92, s.width, s.height * .08), p);
    for (var i = 0; i < 8; i++) {
      final x = s.width * (i + .5) / 8;
      p.color = const Color(0xFF6D4C41);
      c.drawRect(Rect.fromLTWH(x, s.height * .78, 8, s.height * .16), p);
      p.color = const Color(0xFF2E7D32);
      c.drawCircle(Offset(x + 4, s.height * .76), 22 + (i % 3) * 5, p);
    }
    // Daun berjatuhan
    p.color = const Color(0xFF66BB6A);
    for (var i = 0; i < 8; i++) {
      final y = ((a.value * 3 + i / 8) % 1) * (s.height + 40) - 20;
      final x = (i * 131.0) % s.width + sin(a.value * 2 * pi * 6 + i) * 20;
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 14, height: 8), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
