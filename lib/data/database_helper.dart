import 'package:sqlite3/sqlite3.dart';

import '../core/exceptions.dart';

/// Design Pattern: Singleton -> hanya ada satu koneksi database.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static const String _dbFile = 'hotel.db';
  Database? _db;

  Database get db => _db ??= _open();

  Database _open() {
    try {
      final database = sqlite3.open(_dbFile);
      database.execute('PRAGMA foreign_keys = ON;');
      _createSchema(database);
      _seed(database);
      return database;
    } catch (e) {
      throw DatabaseException('Gagal membuka database: $e');
    }
  }

  void _createSchema(Database d) {
    d.execute('''
      CREATE TABLE IF NOT EXISTS rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL,
        base_price REAL NOT NULL
      )''');
    d.execute('''
      CREATE TABLE IF NOT EXISTS guests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL
      )''');
    d.execute('''
      CREATE TABLE IF NOT EXISTS reservations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guest_id INTEGER NOT NULL REFERENCES guests(id),
        room_id INTEGER NOT NULL REFERENCES rooms(id),
        check_in TEXT NOT NULL,
        check_out TEXT NOT NULL,
        total_price REAL NOT NULL,
        status TEXT NOT NULL
      )''');
  }

  void _seed(Database d) {
    final count = d.select('SELECT COUNT(*) AS c FROM rooms').first['c'] as int;
    if (count > 0) return;
    final rooms = [
      ['101', 'standard', 350000],
      ['102', 'standard', 350000],
      ['103', 'standard', 375000],
      ['201', 'deluxe', 550000],
      ['202', 'deluxe', 575000],
      ['203', 'deluxe', 600000],
      ['301', 'suite', 950000],
      ['302', 'suite', 1250000],
    ];
    for (final r in rooms) {
      d.execute('INSERT INTO rooms (number, type, base_price) VALUES (?, ?, ?)', r);
    }
    d.execute(
        'INSERT INTO guests (name, phone, email) VALUES (?, ?, ?)',
        ['Budi Santoso', '081234567890', 'budi@example.com']);
  }

  void close() {
    _db?.dispose();
    _db = null;
  }
}

/// Menerjemahkan error SQLite menjadi exception aplikasi.
T guardDb<T>(T Function() action) {
  try {
    return action();
  } on SqliteException catch (e) {
    final msg = e.message.toUpperCase();
    if (msg.contains('UNIQUE')) {
      throw ValidationException('Data sudah ada (duplikat).');
    }
    if (msg.contains('FOREIGN KEY')) {
      throw ValidationException(
          'Relasi data tidak valid, atau data masih dipakai oleh data lain.');
    }
    throw DatabaseException(e.message);
  }
}
