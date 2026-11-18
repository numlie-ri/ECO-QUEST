import 'exceptions.dart';

/// 1250000 -> "Rp 1.250.000"
String rupiah(num value) {
  final s = value.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '${value < 0 ? '-' : ''}Rp $buf';
}

String dateStr(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// Parse "YYYY-MM-DD" menjadi DateTime UTC (menghindari masalah DST).
DateTime parseDate(String input) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(input.trim());
  if (m == null) {
    throw ValidationException('Format tanggal harus YYYY-MM-DD (contoh: 2026-12-25).');
  }
  final y = int.parse(m.group(1)!);
  final mo = int.parse(m.group(2)!);
  final d = int.parse(m.group(3)!);
  final dt = DateTime.utc(y, mo, d);
  if (dt.month != mo || dt.day != d) {
    throw ValidationException('Tanggal tidak valid.');
  }
  return dt;
}

DateTime today() {
  final n = DateTime.now();
  return DateTime.utc(n.year, n.month, n.day);
}
