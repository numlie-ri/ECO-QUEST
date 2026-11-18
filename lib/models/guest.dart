import '../core/exceptions.dart';

class Guest {
  final int? _id;
  String _name;
  String _phone;
  String _email;

  Guest({int? id, required String name, required String phone, required String email})
      : _id = id,
        _name = _checkName(name),
        _phone = _checkPhone(phone),
        _email = _checkEmail(email);

  static String _checkName(String v) {
    final n = v.trim();
    if (n.length < 2) throw ValidationException('Nama minimal 2 karakter.');
    return n;
  }

  static String _checkPhone(String v) {
    final p = v.trim();
    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(p)) {
      throw ValidationException('No. HP harus 8-15 digit (boleh diawali +).');
    }
    return p;
  }

  static String _checkEmail(String v) {
    final e = v.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      throw ValidationException('Format email tidak valid.');
    }
    return e;
  }

  int? get id => _id;
  String get name => _name;
  set name(String v) => _name = _checkName(v);
  String get phone => _phone;
  set phone(String v) => _phone = _checkPhone(v);
  String get email => _email;
  set email(String v) => _email = _checkEmail(v);
}
