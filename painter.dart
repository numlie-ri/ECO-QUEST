import 'dart:math';

import 'package:flutter/material.dart';

import 'engine.dart';

/// Menggambar seluruh dunia game (latar parallax, tanah, objek, karakter).
class GamePainter extends CustomPainter {
  final GameEngine e;
  GamePainter(this.e);
  final Paint _p = Paint();

  static const _skies = [
    [Color(0xFF7FD6FF), Color(0xFFE6FBFF)],
    [Color(0xFF9AA5B1), Color(0xFFD9D2C3)],
    [Color(0xFF58C7F3), Color(0xFFFFF1C9)],
    [Color(0xFF3B2F3F), Color(0xFFB0654A)],
  ];
  static const _top = [Color(0xFF4CAF50), Color(0xFF607D8B), Color(0xFFF2D28B), Color(0xFF5D4037)];
  static const _dirt = [Color(0xFF8D6E3F), Color(0xFF455A64), Color(0xFFD9B26A), Color(0xFF3E2723)];
  static const _liquid = [Color(0xFF42A5F5), Color(0xFF37474F), Color(0xFF0288D1), Color(0xFF76FF03)];

  /// Angka acak deterministik dari indeks (0..1).
  double _h(int i) => (sin(i * 12.9898) * 43758.5453).abs() % 1;

  @override
  void paint(Canvas c, Size size) {
    final s = size.height / GameEngine.worldH;
    final vw = size.width / s;
    final th = e.def.theme;
    c.save();
    c.scale(s);
    final rect = Rect.fromLTWH(0, 0, vw, 400);
    _p.shader = LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _skies[th])
        .createShader(rect);
    c.drawRect(rect, _p);
    _p.shader = null;
    _background(c, th, vw);

    c.save();
    c.translate(-e.camX, 0);
    _ground(c, th, vw);
    _obstacles(c);
    _items(c);
    _enemies(c);
    _flag(c);
    _player(c);
    _particles(c);
    c.restore();
    c.restore();
  }

  void _layer(double vw, double f, double sp, void Function(int, double) draw) {
    final off = e.camX * f;
    final first = (off / sp).floor() - 1;
    for (var i = first; i * sp - off < vw + sp; i++) {
      draw(i, i * sp - off);
    }
  }

  void _background(Canvas c, int th, double vw) {
    switch (th) {
      case 0: // Hutan
        _p.color = const Color(0xFFFFF176);
        c.drawCircle(Offset(vw - 80, 70), 36, _p);
        _layer(vw, .1, 260, (i, x) {
          _p.color = const Color(0xCCFFFFFF);
          c.drawOval(Rect.fromLTWH(x, 40 + _h(i) * 60, 90, 28), _p);
        });
        _layer(vw, .25, 300, (i, x) {
          _p.color = const Color(0xFF81C784);
          c.drawCircle(Offset(x + 150, 380), 130 + _h(i) * 40, _p);
        });
        _layer(vw, .55, 130, (i, x) {
          _p.color = const Color(0xFF6D4C41);
          c.drawRect(Rect.fromLTWH(x, 260, 10, 60), _p);
          _p.color = const Color(0xFF2E7D32);
          c.drawCircle(Offset(x + 5, 248), 26 + _h(i + 5) * 10, _p);
        });
        break;
      case 1: // Kota berpolusi
        _layer(vw, .25, 90, (i, x) {
          _p.color = const Color(0xFF78909C);
          final h = 100 + _h(i) * 120;
          c.drawRect(Rect.fromLTWH(x, 320 - h, 70, h), _p);
        });
        _layer(vw, .5, 120, (i, x) {
          final h = 80 + _h(i + 9) * 100;
          _p.color = const Color(0xFF546E7A);
          c.drawRect(Rect.fromLTWH(x, 320 - h, 90, h), _p);
          _p.color = const Color(0xFFFFE082);
          for (var r = 0; r < h ~/ 30; r++) {
            for (var k = 0; k < 3; k++) {
              c.drawRect(Rect.fromLTWH(x + 12 + k * 26, 320 - h + 10 + r * 30, 12, 14), _p);
            }
          }
        });
        _layer(vw, .15, 200, (i, x) {
          _p.color = const Color(0x448D8D8D);
          c.drawCircle(Offset(x, 60 + _h(i) * 40), 55, _p);
        });
        break;
      case 2: // Pantai
        _p.color = const Color(0xFFFFD54F);
        c.drawCircle(Offset(vw - 90, 80), 40, _p);
        _p.color = const Color(0xFF29B6F6);
        c.drawRect(Rect.fromLTWH(0, 230, vw, 90), _p);
        _p.color = const Color(0x88FFFFFF);
        _p.strokeWidth = 2;
        _layer(vw, .3, 60, (i, x) {
          c.drawLine(Offset(x, 250 + _h(i) * 50), Offset(x + 24, 250 + _h(i) * 50), _p);
        });
        _layer(vw, .6, 150, (i, x) {
          _p.color = const Color(0xFF8D8D8D);
          c.drawCircle(Offset(x, 316), 8 + _h(i) * 8, _p);
          _p.color = const Color(0xFF8D6E63);
          c.drawRect(Rect.fromLTWH(x + 14, 306, 8, 14), _p);
        });
        break;
      default: // Industri
        _layer(vw, .3, 160, (i, x) {
          final h = 90 + _h(i) * 50;
          _p.color = const Color(0xFF37474F);
          c.drawRect(Rect.fromLTWH(x, 320 - h, 100, h), _p);
          _p.color = const Color(0xFF263238);
          c.drawRect(Rect.fromLTWH(x + 70, 320 - h - 60, 18, 60), _p);
          _p.color = const Color(0x55212121);
          c.drawCircle(Offset(x + 80, 320 - h - 75), 22, _p);
          c.drawCircle(Offset(x + 95, 320 - h - 100), 28, _p);
        });
        _p.shader = LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: const [Color(0x88FF5722), Color(0x00FF5722)])
            .createShader(Rect.fromLTWH(0, 200, vw, 200));
        c.drawRect(Rect.fromLTWH(0, 200, vw, 200), _p);
        _p.shader = null;
    }
  }

  void _ground(Canvas c, int th, double vw) {
    final lo = e.camX - 40, hi = e.camX + vw + 40;
    var start = -100.0;
    final segs = <List<double>>[];
    for (final g in e.gaps) {
      segs.add([start, g[0]]);
      start = g[1];
    }
    segs.add([start, e.def.length + 400]);
    // Cairan di dasar jurang
    for (final g in e.gaps) {
      if (g[1] < lo || g[0] > hi) continue;
      _p.color = _liquid[th];
      c.drawRect(Rect.fromLTRB(g[0], 372 + sin(e.time * 3) * 2, g[1], 400), _p);
    }
    for (final sg in segs) {
      if (sg[1] < lo || sg[0] > hi) continue;
      _p.color = _dirt[th];
      c.drawRect(Rect.fromLTRB(sg[0], 320, sg[1], 400), _p);
      _p.color = _top[th];
      c.drawRect(Rect.fromLTRB(sg[0], 320, sg[1], 336), _p);
    }
  }

  void _obstacles(Canvas c) {
    for (final o in e.obstacles) {
      final b = o.b;
      if (b.x > e.camX + e.viewW + 50 || b.x + b.w < e.camX - 50) continue;
      if (o.spike) {
        _p.color = const Color(0xFFB0BEC5);
        final n = (b.w / 14).floor();
        final w = b.w / n;
        for (var i = 0; i < n; i++) {
          final path = Path()
            ..moveTo(b.x + i * w, b.y + b.h)
            ..lineTo(b.x + i * w + w / 2, b.y)
            ..lineTo(b.x + (i + 1) * w, b.y + b.h)
            ..close();
          c.drawPath(path, _p);
        }
      } else {
        final r = Rect.fromLTWH(b.x, b.y, b.w, b.h);
        _p.color = const Color(0xFFA1672E);
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), _p);
        _p.color = const Color(0xFF6D4420);
        _p.style = PaintingStyle.stroke;
        _p.strokeWidth = 3;
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), _p);
        c.drawLine(r.topLeft, r.bottomRight, _p);
        c.drawLine(r.topRight, r.bottomLeft, _p);
        _p.style = PaintingStyle.fill;
      }
    }
  }

  void _items(Canvas c) {
    for (final it in e.items) {
      if (it.taken || it.x > e.camX + e.viewW + 50 || it.x < e.camX - 50) continue;
      final bob = sin(e.time * 3 + it.x) * 3;
      c.save();
      c.translate(it.x, it.y + bob);
      if (it.trash) {
        _p.color = const Color(0x33FFFFFF);
        c.drawCircle(Offset.zero, 17, _p);
        switch (it.kind) {
          case 0: // kaleng
            _p.color = const Color(0xFFB0BEC5);
            c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -10, 14, 20), const Radius.circular(3)), _p);
            _p.color = const Color(0xFF78909C);
            c.drawRect(const Rect.fromLTWH(-7, -3, 14, 5), _p);
            break;
          case 1: // botol
            _p.color = const Color(0xFF4FC3F7);
            c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-5, -4, 10, 14), const Radius.circular(3)), _p);
            c.drawRect(const Rect.fromLTWH(-2, -12, 4, 8), _p);
            break;
          default: // kantong plastik
            _p.color = const Color(0xFF8D6E63);
            c.drawCircle(const Offset(0, 2), 9, _p);
            c.drawRect(const Rect.fromLTWH(-2, -11, 4, 6), _p);
        }
      } else {
        final w = 3 + 11 * cos(e.time * 4 + it.x * .1).abs();
        _p.color = const Color(0xFFFFB300);
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 2, height: 22), _p);
        _p.color = const Color(0xFFFFE082);
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 1.2, height: 14), _p);
      }
      c.restore();
    }
  }

  void _enemies(Canvas c) {
    for (final en in e.enemies) {
      if (!en.alive) continue;
      final b = en.b;
      c.save();
      c.translate(b.x + 17, b.y + 30);
      c.scale(en.dir, 1 + sin(e.time * 8 + b.x) * .07);
      _p.color = const Color(0xFF6A1B9A);
      c.drawOval(const Rect.fromLTWH(-17, -30, 34, 30), _p);
      _p.color = Colors.white;
      c.drawCircle(const Offset(-5, -17), 5, _p);
      c.drawCircle(const Offset(7, -17), 5, _p);
      _p.color = Colors.black;
      c.drawCircle(const Offset(-3, -16), 2.5, _p);
      c.drawCircle(const Offset(9, -16), 2.5, _p);
      _p.strokeWidth = 2.5;
      c.drawLine(const Offset(-11, -26), const Offset(-2, -22), _p);
      c.drawLine(const Offset(13, -26), const Offset(4, -22), _p);
      c.restore();
    }
  }

  void _flag(Canvas c) {
    final x = e.def.length;
    _p.color = const Color(0xFFECEFF1);
    c.drawRect(Rect.fromLTWH(x, 200, 6, 120), _p);
    _p.color = const Color(0xFF43A047);
    final w = sin(e.time * 4) * 3;
    final path = Path()
      ..moveTo(x + 6, 200)
      ..lineTo(x + 56 + w, 222)
      ..lineTo(x + 6, 244)
      ..close();
    c.drawPath(path, _p);
  }

  /// Karakter kartun: kaki berayun saat berlari, kaki terbuka saat melompat.
  void _player(Canvas c) {
    if (e.invincible > 0 && (e.invincible * 12).floor() % 2 == 0) return;
    final p = e.player;
    c.save();
    c.translate(p.x + p.w / 2, p.y);
    c.scale(e.facing, 1);
    final moving = (e.left || e.right) && e.onGround;
    final phase = moving ? e.time * 16 : 0.0;
    final air = !e.onGround;
    const skin = Color(0xFFFFD7A8);
    final l1 = air ? -4.0 : sin(phase) * 6;
    final l2 = air ? 5.0 : -sin(phase) * 6;
    _p.color = const Color(0xFF1E3A8A);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-9 + l1, 32, 8, 12), const Radius.circular(3)), _p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(1 + l2, 32, 8, 12), const Radius.circular(3)), _p);
    _p.color = const Color(0xFF2E9E4F);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, 16, 24, 20), const Radius.circular(7)), _p);
    _p.color = Colors.white;
    c.drawCircle(const Offset(0, 26), 4, _p);
    _p.color = skin;
    c.drawCircle(Offset(10 + sin(phase + pi) * 4, air ? 20 : 28), 4, _p);
    c.drawCircle(const Offset(0, 9), 12, _p);
    _p.color = const Color(0xFFE53935);
    c.drawArc(Rect.fromCircle(center: const Offset(0, 8), radius: 12.5), pi, pi, true, _p);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(2, 6, 14, 4), const Radius.circular(2)), _p);
    _p.color = Colors.black;
    c.drawCircle(const Offset(5, 11), 2, _p);
    c.restore();
  }

  void _particles(Canvas c) {
    for (final q in e.particles) {
      _p.color = q.color.withAlpha((255 * (q.life / q.max)).clamp(0, 255).toInt());
      c.drawCircle(Offset(q.x, q.y), q.size, _p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
