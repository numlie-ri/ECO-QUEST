import 'package:sqlite3/sqlite3.dart';

import '../core/exceptions.dart';
import '../core/formatters.dart';
import '../models/guest.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import 'database_helper.dart';

/// Kontrak CRUD generik (abstraksi -> Dependency Inversion Principle).
abstract class Repository<T> {
  int create(T item);
  List<T> findAll();
  T? findById(int id);
  void update(T item);
  void delete(int id);
}

/// Kontrak khusus kamar (Interface Segregation: hanya yang dibutuhkan).
abstract class RoomRepository implements Repository<Room> {
  List<Room> findAvailable(DateTime checkIn, DateTime checkOut,
      {int? excludeReservationId});
}

void _ensureAffected(Database db, String what, int id) {
  if (db.updatedRows == 0) throw NotFoundException('$what #$id tidak ditemukan.');
}

// ───────────────────────── Room ─────────────────────────
class SqliteRoomRepository implements RoomRepository {
  SqliteRoomRepository(this._helper);
  final DatabaseHelper _helper;
  Database get _db => _helper.db;

  @override
  int create(Room r) => guardDb(() {
        _db.execute('INSERT INTO rooms (number, type, base_price) VALUES (?, ?, ?)',
            [r.number, r.type, r.basePrice]);
        return _db.lastInsertRowId;
      });

  @override
  List<Room> findAll() => guardDb(() => _db
      .select('SELECT * FROM rooms ORDER BY number')
      .map(RoomFactory.fromMap)
      .toList());

  @override
  Room? findById(int id) => guardDb(() {
        final rows = _db.select('SELECT * FROM rooms WHERE id = ?', [id]);
        return rows.isEmpty ? null : RoomFactory.fromMap(rows.first);
      });

  @override
  void update(Room r) => guardDb(() {
        _db.execute('UPDATE rooms SET number = ?, base_price = ? WHERE id = ?',
            [r.number, r.basePrice, r.id]);
        _ensureAffected(_db, 'Kamar', r.id ?? -1);
      });

  @override
  void delete(int id) => guardDb(() {
        _db.execute('DELETE FROM rooms WHERE id = ?', [id]);
        _ensureAffected(_db, 'Kamar', id);
      });

  @override
  List<Room> findAvailable(DateTime checkIn, DateTime checkOut,
          {int? excludeReservationId}) =>
      guardDb(() => _db.select('''
          SELECT * FROM rooms WHERE id NOT IN (
            SELECT room_id FROM reservations
            WHERE status IN ('booked', 'checked_in')
              AND check_in < ? AND check_out > ? AND id != ?
          ) ORDER BY number''', [
        dateStr(checkOut),
        dateStr(checkIn),
        excludeReservationId ?? -1,
      ]).map(RoomFactory.fromMap).toList());
}

// ───────────────────────── Guest ─────────────────────────
class SqliteGuestRepository implements Repository<Guest> {
  SqliteGuestRepository(this._helper);
  final DatabaseHelper _helper;
  Database get _db => _helper.db;

  Guest _map(Map<String, Object?> m) => Guest(
        id: m['id'] as int,
        name: m['name'] as String,
        phone: m['phone'] as String,
        email: m['email'] as String,
      );

  @override
  int create(Guest g) => guardDb(() {
        _db.execute('INSERT INTO guests (name, phone, email) VALUES (?, ?, ?)',
            [g.name, g.phone, g.email]);
        return _db.lastInsertRowId;
      });

  @override
  List<Guest> findAll() => guardDb(
      () => _db.select('SELECT * FROM guests ORDER BY name').map(_map).toList());

  @override
  Guest? findById(int id) => guardDb(() {
        final rows = _db.select('SELECT * FROM guests WHERE id = ?', [id]);
        return rows.isEmpty ? null : _map(rows.first);
      });

  @override
  void update(Guest g) => guardDb(() {
        _db.execute('UPDATE guests SET name = ?, phone = ?, email = ? WHERE id = ?',
            [g.name, g.phone, g.email, g.id]);
        _ensureAffected(_db, 'Tamu', g.id ?? -1);
      });

  @override
  void delete(int id) => guardDb(() {
        _db.execute('DELETE FROM guests WHERE id = ?', [id]);
        _ensureAffected(_db, 'Tamu', id);
      });
}

// ───────────────────────── Reservation ─────────────────────────
class SqliteReservationRepository implements Repository<Reservation> {
  SqliteReservationRepository(this._helper);
  final DatabaseHelper _helper;
  Database get _db => _helper.db;

  static const _select = '''
      SELECT r.*, g.name AS guest_name, rm.number AS room_number
      FROM reservations r
      JOIN guests g ON g.id = r.guest_id
      JOIN rooms rm ON rm.id = r.room_id''';

  Reservation _map(Map<String, Object?> m) => Reservation(
        id: m['id'] as int,
        guestId: m['guest_id'] as int,
        roomId: m['room_id'] as int,
        checkIn: parseDate(m['check_in'] as String),
        checkOut: parseDate(m['check_out'] as String),
        totalPrice: (m['total_price'] as num).toDouble(),
        status: ReservationStatus.fromDb(m['status'] as String),
        guestName: m['guest_name'] as String?,
        roomNumber: m['room_number'] as String?,
      );

  @override
  int create(Reservation r) => guardDb(() {
        _db.execute('''
            INSERT INTO reservations
              (guest_id, room_id, check_in, check_out, total_price, status)
            VALUES (?, ?, ?, ?, ?, ?)''', [
          r.guestId,
          r.roomId,
          dateStr(r.checkIn),
          dateStr(r.checkOut),
          r.totalPrice,
          r.status.dbValue,
        ]);
        return _db.lastInsertRowId;
      });

  @override
  List<Reservation> findAll() => guardDb(() => _db
      .select('$_select ORDER BY r.check_in DESC, r.id DESC')
      .map(_map)
      .toList());

  @override
  Reservation? findById(int id) => guardDb(() {
        final rows = _db.select('$_select WHERE r.id = ?', [id]);
        return rows.isEmpty ? null : _map(rows.first);
      });

  @override
  void update(Reservation r) => guardDb(() {
        _db.execute(
            'UPDATE reservations SET check_in = ?, check_out = ?, total_price = ?, status = ? WHERE id = ?',
            [dateStr(r.checkIn), dateStr(r.checkOut), r.totalPrice, r.status.dbValue, r.id]);
        _ensureAffected(_db, 'Reservasi', r.id ?? -1);
      });

  @override
  void delete(int id) => guardDb(() {
        _db.execute('DELETE FROM reservations WHERE id = ?', [id]);
        _ensureAffected(_db, 'Reservasi', id);
      });
}
