import '../core/exceptions.dart';

enum ReservationStatus {
  booked,
  checkedIn,
  checkedOut,
  cancelled;

  String get dbValue => switch (this) {
        ReservationStatus.booked => 'booked',
        ReservationStatus.checkedIn => 'checked_in',
        ReservationStatus.checkedOut => 'checked_out',
        ReservationStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        ReservationStatus.booked => 'Booked',
        ReservationStatus.checkedIn => 'Check-in',
        ReservationStatus.checkedOut => 'Check-out',
        ReservationStatus.cancelled => 'Cancelled',
      };

  static ReservationStatus fromDb(String v) => values.firstWhere(
        (e) => e.dbValue == v,
        orElse: () => throw DatabaseException('Status tidak dikenal: $v'),
      );
}

/// Entitas reservasi. Perubahan status hanya lewat method (enkapsulasi),
/// sehingga aturan transisi status selalu terjaga.
class Reservation {
  final int? _id;
  final int guestId;
  final int roomId;
  DateTime _checkIn;
  DateTime _checkOut;
  double _totalPrice;
  ReservationStatus _status;
  final String? guestName; // hasil JOIN (untuk tampilan)
  final String? roomNumber; // hasil JOIN (untuk tampilan)

  Reservation({
    int? id,
    required this.guestId,
    required this.roomId,
    required DateTime checkIn,
    required DateTime checkOut,
    required double totalPrice,
    ReservationStatus status = ReservationStatus.booked,
    this.guestName,
    this.roomNumber,
  })  : _id = id,
        _checkIn = checkIn,
        _checkOut = checkOut,
        _totalPrice = totalPrice,
        _status = status {
    _checkDates(checkIn, checkOut);
  }

  static void _checkDates(DateTime ci, DateTime co) {
    if (!co.isAfter(ci)) {
      throw ValidationException('Tanggal check-out harus setelah check-in.');
    }
  }

  int? get id => _id;
  DateTime get checkIn => _checkIn;
  DateTime get checkOut => _checkOut;
  double get totalPrice => _totalPrice;
  ReservationStatus get status => _status;
  int get nights => _checkOut.difference(_checkIn).inDays;
  bool get isActive =>
      _status == ReservationStatus.booked || _status == ReservationStatus.checkedIn;
  bool get canReschedule => _status == ReservationStatus.booked;

  void reschedule(DateTime ci, DateTime co, double newTotal) {
    if (!canReschedule) {
      throw InvalidOperationException(
          'Hanya reservasi berstatus Booked yang bisa dijadwal ulang.');
    }
    _checkDates(ci, co);
    _checkIn = ci;
    _checkOut = co;
    _totalPrice = newTotal;
  }

  void checkInGuest() {
    if (_status != ReservationStatus.booked) {
      throw InvalidOperationException(
          'Check-in hanya untuk reservasi berstatus Booked (sekarang: ${_status.label}).');
    }
    _status = ReservationStatus.checkedIn;
  }

  void checkOutGuest() {
    if (_status != ReservationStatus.checkedIn) {
      throw InvalidOperationException(
          'Check-out hanya untuk tamu yang sedang Check-in (sekarang: ${_status.label}).');
    }
    _status = ReservationStatus.checkedOut;
  }

  void cancel() {
    if (_status != ReservationStatus.booked) {
      throw InvalidOperationException(
          'Hanya reservasi berstatus Booked yang bisa dibatalkan (sekarang: ${_status.label}).');
    }
    _status = ReservationStatus.cancelled;
  }
}
