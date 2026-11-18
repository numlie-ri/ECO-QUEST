import '../core/exceptions.dart';
import '../core/formatters.dart';
import '../data/repositories.dart';
import '../models/guest.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import 'pricing.dart';

/// Lapisan logika bisnis. Hanya bergantung pada abstraksi (DIP) sehingga
/// database bisa diganti (MySQL/PostgreSQL) tanpa mengubah service.
class ReservationService {
  ReservationService({
    required RoomRepository rooms,
    required Repository<Guest> guests,
    required Repository<Reservation> reservations,
    DiscountStrategy? discount,
  })  : _rooms = rooms,
        _guests = guests,
        _reservations = reservations,
        _discount = discount ?? LongStayDiscount();

  final RoomRepository _rooms;
  final Repository<Guest> _guests;
  final Repository<Reservation> _reservations;
  final DiscountStrategy _discount;

  void _validateStay(DateTime ci, DateTime co) {
    if (ci.isBefore(today())) {
      throw ValidationException('Tanggal check-in tidak boleh di masa lalu.');
    }
    if (!co.isAfter(ci)) {
      throw ValidationException('Tanggal check-out harus setelah check-in.');
    }
  }

  Reservation _get(int id) =>
      _reservations.findById(id) ?? (throw NotFoundException('Reservasi #$id tidak ditemukan.'));

  PriceQuote quoteFor(Room room, int nights) => PriceQuote(
      room.calculatePrice(nights), _discount.name, _discount.rateFor(nights));

  List<Room> availableRooms(DateTime ci, DateTime co) {
    _validateStay(ci, co);
    return _rooms.findAvailable(ci, co);
  }

  Reservation book({
    required int guestId,
    required int roomId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) {
    _validateStay(checkIn, checkOut);
    _guests.findById(guestId) ?? (throw NotFoundException('Tamu #$guestId tidak ditemukan.'));
    final room =
        _rooms.findById(roomId) ?? (throw NotFoundException('Kamar #$roomId tidak ditemukan.'));

    final free = _rooms.findAvailable(checkIn, checkOut);
    if (!free.any((r) => r.id == roomId)) {
      throw RoomUnavailableException(
          'Kamar ${room.number} sudah dipesan pada tanggal tersebut.');
    }

    final nights = checkOut.difference(checkIn).inDays;
    final quote = quoteFor(room, nights);
    final id = _reservations.create(Reservation(
      guestId: guestId,
      roomId: roomId,
      checkIn: checkIn,
      checkOut: checkOut,
      totalPrice: quote.total,
    ));
    return _get(id);
  }

  void reschedule(int id, DateTime ci, DateTime co) {
    _validateStay(ci, co);
    final res = _get(id);
    if (!res.canReschedule) {
      throw InvalidOperationException(
          'Hanya reservasi berstatus Booked yang bisa dijadwal ulang.');
    }
    final room = _rooms.findById(res.roomId) ??
        (throw NotFoundException('Kamar #${res.roomId} tidak ditemukan.'));
    final free = _rooms.findAvailable(ci, co, excludeReservationId: id);
    if (!free.any((r) => r.id == res.roomId)) {
      throw RoomUnavailableException(
          'Kamar ${room.number} tidak tersedia pada tanggal baru.');
    }
    res.reschedule(ci, co, quoteFor(room, co.difference(ci).inDays).total);
    _reservations.update(res);
  }

  Reservation checkIn(int id) {
    final res = _get(id)..checkInGuest();
    _reservations.update(res);
    return res;
  }

  Reservation checkOut(int id) {
    final res = _get(id)..checkOutGuest();
    _reservations.update(res);
    return res;
  }

  void cancel(int id) {
    final res = _get(id)..cancel();
    _reservations.update(res);
  }

  void deleteRecord(int id) {
    final res = _get(id);
    if (res.isActive) {
      throw InvalidOperationException(
          'Reservasi aktif tidak boleh dihapus. Batalkan atau check-out dulu.');
    }
    _reservations.delete(id);
  }

  Map<String, num> dashboard() {
    final all = _reservations.findAll();
    return {
      'rooms': _rooms.findAll().length,
      'guests': _guests.findAll().length,
      'active': all.where((r) => r.isActive).length,
      'revenue': all
          .where((r) => r.status == ReservationStatus.checkedOut)
          .fold<double>(0, (s, r) => s + r.totalPrice),
    };
  }
}
