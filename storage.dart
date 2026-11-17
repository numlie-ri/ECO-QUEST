import 'package:shared_preferences/shared_preferences.dart';

/// Penyimpanan lokal: high score, level terbuka, dan volume suara.
class Store {
  static late SharedPreferences _p;
  static Future<void> init() async => _p = await SharedPreferences.getInstance();

  static int get highScore => _p.getInt('high') ?? 0;
  static set highScore(int v) => _p.setInt('high', v);

  /// Level tertinggi yang sudah terbuka (minimal 1).
  static int get unlocked => _p.getInt('unlocked') ?? 1;
  static set unlocked(int v) => _p.setInt('unlocked', v);

  static double get music => _p.getDouble('music') ?? 0.5;
  static set music(double v) => _p.setDouble('music', v);

  static double get sfx => _p.getDouble('sfx') ?? 0.8;
  static set sfx(double v) => _p.setDouble('sfx', v);
}
