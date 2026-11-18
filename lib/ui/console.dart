import 'dart:io';

import '../core/exceptions.dart';
import '../core/formatters.dart';

class Ansi {
  static final bool enabled = stdout.supportsAnsiEscapes;
  static const reset = '\x1B[0m';
  static const bold = '\x1B[1m';
  static const dim = '\x1B[2m';
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const magenta = '\x1B[35m';
  static const cyan = '\x1B[36m';

  static String paint(String text, String style) =>
      enabled ? '$style$text$reset' : text;
}

/// Helper tampilan & input terminal.
class Console {
  static const int width = 62;

  static void println([String text = '']) => print(text);

  static void clear() {
    if (Ansi.enabled) stdout.write('\x1B[2J\x1B[3J\x1B[H');
  }

  static String _center(String t, int w) {
    final left = ((w - t.length) / 2).floor();
    return ' ' * left + t + ' ' * (w - t.length - left);
  }

  static void banner() {
    final bar = '═' * width;
    println(Ansi.paint('  ╔$bar╗', Ansi.cyan));
    println(Ansi.paint('  ║${_center('', width)}║', Ansi.cyan));
    println('${Ansi.paint('  ║', Ansi.cyan)}'
        '${Ansi.paint(_center('GRAND DART HOTEL', width), Ansi.bold + Ansi.yellow)}'
        '${Ansi.paint('║', Ansi.cyan)}');
    println('${Ansi.paint('  ║', Ansi.cyan)}'
        '${Ansi.paint(_center('Sistem Reservasi Hotel  ·  CLI Edition', width), Ansi.dim)}'
        '${Ansi.paint('║', Ansi.cyan)}');
    println(Ansi.paint('  ║${_center('', width)}║', Ansi.cyan));
    println(Ansi.paint('  ╚$bar╝', Ansi.cyan));
    println();
  }

  static void header(String title) {
    println('  ${Ansi.paint('▌', Ansi.magenta)} ${Ansi.paint(title, Ansi.bold)}');
    println(Ansi.paint('  ${'─' * width}', Ansi.dim));
  }

  static void cards(List<List<String>> items) {
    const w = 18;
    final top = items.map((_) => '┌${'─' * w}┐').join(' ');
    final label = items.map((i) => '│${' ${i[0]}'.padRight(w)}│').join(' ');
    final value = items.map((i) {
      final padded = ' ${i[1]}'.padRight(w);
      return '│${Ansi.paint(padded, Ansi.bold + Ansi.green)}│';
    }).join(' ');
    final bottom = items.map((_) => '└${'─' * w}┘').join(' ');
    println('  $top');
    println('  $label');
    println('  $value');
    println('  $bottom');
    println();
  }

  static void success(String m) => println('\n  ${Ansi.paint('✔ $m', Ansi.green)}');
  static void error(String m) => println('\n  ${Ansi.paint('✘ $m', Ansi.red)}');
  static void warn(String m) => println('\n  ${Ansi.paint('! $m', Ansi.yellow)}');
  static void info(String m) => println('  ${Ansi.paint(m, Ansi.dim)}');

  static void pause() {
    stdout.write('\n  ${Ansi.paint('Tekan ENTER untuk lanjut...', Ansi.dim)}');
    stdin.readLineSync();
  }

  // ── Menu & input ──
  static String menu(List<String> items, {String back = 'Kembali'}) {
    println();
    for (var i = 0; i < items.length; i++) {
      println('  ${Ansi.paint('[${i + 1}]', Ansi.yellow)} ${items[i]}');
    }
    println('  ${Ansi.paint('[0]', Ansi.red)} $back');
    println();
    return ask('Pilih menu');
  }

  static String ask(String label, {String? current}) {
    final hint = current != null ? ' ${Ansi.paint('[$current]', Ansi.dim)}' : '';
    stdout.write('  ${Ansi.paint('›', Ansi.cyan)} $label$hint: ');
    final input = (stdin.readLineSync() ?? '').trim();
    return input.isEmpty && current != null ? current : input;
  }

  static int askInt(String label) {
    final v = int.tryParse(ask(label));
    if (v == null) throw ValidationException('Masukkan angka yang valid.');
    return v;
  }

  static double askDouble(String label, {double? current}) {
    final raw = ask(label, current: current?.round().toString());
    final v = double.tryParse(raw);
    if (v == null) throw ValidationException('Masukkan angka yang valid.');
    return v;
  }

  static DateTime askDate(String label) => parseDate(ask(label));

  static bool confirm(String message) {
    final a = ask('$message (y/n)').toLowerCase();
    return a == 'y' || a == 'ya';
  }

  // ── Tabel ──
  static void table(
    List<String> headers,
    List<List<String>> rows, {
    String Function(int col, String paddedText)? style,
  }) {
    if (rows.isEmpty) {
      warn('Belum ada data.');
      return;
    }
    final widths = List<int>.generate(headers.length, (i) => headers[i].length);
    for (final r in rows) {
      for (var i = 0; i < r.length; i++) {
        if (r[i].length > widths[i]) widths[i] = r[i].length;
      }
    }
    String rule(String l, String m, String r) {
      final parts = widths.map((w) => '─' * (w + 2)).join(m);
      return '  $l$parts$r';
    }

    final head = List.generate(headers.length, (i) {
      final cell = headers[i].padRight(widths[i]);
      return ' ${Ansi.paint(cell, Ansi.bold + Ansi.cyan)} ';
    }).join('│');

    println(rule('┌', '┬', '┐'));
    println('  │$head│');
    println(rule('├', '┼', '┤'));
    for (final r in rows) {
      final line = List.generate(r.length, (i) {
        final cell = r[i].padRight(widths[i]);
        return ' ${style != null ? style(i, cell) : cell} ';
      }).join('│');
      println('  │$line│');
    }
    println(rule('└', '┴', '┘'));
  }
}