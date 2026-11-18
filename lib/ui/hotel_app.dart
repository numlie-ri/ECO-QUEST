import '../core/exceptions.dart';
import '../core/formatters.dart';
import '../data/repositories.dart';
import '../models/guest.dart';
import '../models/reservation.dart';
import '../models/room.dart';
import '../services/pricing.dart';
import '../services/reservation_service.dart';
import 'console.dart';

class HotelApp {
  HotelApp({
    required this.rooms,
    required this.guests,
    required this.reservations,
    required this.service,
  });

  final RoomRepository rooms;
  final Repository<Guest> guests;
  final Repository<Reservation> reservations;
  final ReservationService service;

  // ═════════════════ Main loop ═════════════════
  void run() {
    while (true) {
      Console.clear();
      Console.banner();
      _dashboard();
      final c = Console.menu(
        ['Manajemen Kamar', 'Manajemen Tamu', 'Reservasi'],
        back: 'Keluar',
      );
      switch (c) {
        case '1':
          _roomMenu();
        case '2':
          _guestMenu();
        case '3':
          _reservationMenu();
        case '0':
          Console.info('Terima kasih sudah menggunakan Grand Dart Hotel. Sampai jumpa!');
          return;
        default:
          Console.error('Pilihan tidak valid.');
          Console.pause();
      }
    }
  }

  void _dashboard() {
    final s = service.dashboard();
    Console.cards([
      ['Total Kamar', '${s['rooms']}'],
      ['Total Tamu', '${s['guests']}'],
      ['Reservasi Aktif', '${s['active']}'],
      ['Pendapatan', rupiah(s['revenue']!)],
    ]);
  }

  /// Error Handling terpusat: semua aksi dibungkus try/catch.
  void _safe(void Function() action) {
    try {
      action();
    } on AppException catch (e) {
      Console.error(e.message);
    } catch (e) {
      Console.error('Terjadi kesalahan tak terduga: $e');
    }
    Console.pause();
  }

  void _invalid() {
    Console.error('Pilihan tidak valid.');
    Console.pause();
  }

  // ═════════════════ Kamar ═════════════════
  void _roomMenu() {
    while (true) {
      Console.clear();
      Console.header('MANAJEMEN KAMAR');
      final c = Console.menu([
        'Daftar kamar',
        'Tambah kamar',
        'Ubah kamar',
        'Hapus kamar',
        'Cek ketersediaan kamar',
      ]);
      switch (c) {
        case '1':
          _safe(() => _roomTable(rooms.findAll()));
        case '2':
          _safe(_addRoom);
        case '3':
          _safe(_editRoom);
        case '4':
          _safe(_deleteRoom);
        case '5':
          _safe(_checkAvailability);
        case '0':
          return;
        default:
          _invalid();
      }
    }
  }

  void _roomTable(List<Room> list, {int? nights}) {
    final headers = ['ID', 'No', 'Tipe', 'Harga/malam', 'Fasilitas'];
    if (nights != null) headers.add('Total $nights malam');
    Console.table(
      headers,
      list.map((r) {
        final row = [
          '${r.id}',
          r.number,
          r.label,
          rupiah(r.basePrice),
          r.facilities.join(', '),
        ];
        if (nights != null) row.add(rupiah(service.quoteFor(r, nights).total));
        return row;
      }).toList(),
    );
  }

  void _addRoom() {
    Console.header('TAMBAH KAMAR');
    final number = Console.ask('Nomor kamar');
    Console.println('  Tipe: [1] Standard   [2] Deluxe   [3] Suite');
    final type = switch (Console.ask('Pilih tipe')) {
      '1' => 'standard',
      '2' => 'deluxe',
      '3' => 'suite',
      _ => throw ValidationException('Tipe kamar tidak valid.'),
    };
    final price = Console.askDouble('Harga dasar per malam (Rp)');
    final room = RoomFactory.create(type: type, number: number, basePrice: price);
    final id = rooms.create(room);
    Console.success('Kamar ${room.number} (${room.label}) ditambahkan dengan ID $id.');
  }

  void _editRoom() {
    Console.header('UBAH KAMAR');
    _roomTable(rooms.findAll());
    final id = Console.askInt('ID kamar');
    final room = rooms.findById(id) ?? (throw NotFoundException('Kamar #$id tidak ditemukan.'));
    Console.info('Kosongkan input untuk mempertahankan nilai lama.');
    room.number = Console.ask('Nomor kamar', current: room.number);
    room.basePrice = Console.askDouble('Harga per malam', current: room.basePrice);
    rooms.update(room);
    Console.success('Kamar berhasil diperbarui.');
  }

  void _deleteRoom() {
    Console.header('HAPUS KAMAR');
    _roomTable(rooms.findAll());
    final id = Console.askInt('ID kamar');
    if (!Console.confirm('Yakin hapus kamar #$id?')) {
      Console.warn('Dibatalkan.');
      return;
    }
    rooms.delete(id);
    Console.success('Kamar berhasil dihapus.');
  }

  void _checkAvailability() {
    Console.header('CEK KETERSEDIAAN KAMAR');
    final ci = Console.askDate('Check-in  (YYYY-MM-DD)');
    final co = Console.askDate('Check-out (YYYY-MM-DD)');
    final free = service.availableRooms(ci, co);
    if (free.isEmpty) {
      Console.warn('Tidak ada kamar kosong pada tanggal tersebut.');
      return;
    }
    Console.println();
    _roomTable(free, nights: co.difference(ci).inDays);
  }

  // ═════════════════ Tamu ═════════════════
  void _guestMenu() {
    while (true) {
      Console.clear();
      Console.header('MANAJEMEN TAMU');
      final c = Console.menu(['Daftar tamu', 'Tambah tamu', 'Ubah tamu', 'Hapus tamu']);
      switch (c) {
        case '1':
          _safe(() => _guestTable(guests.findAll()));
        case '2':
          _safe(_addGuest);
        case '3':
          _safe(_editGuest);
        case '4':
          _safe(_deleteGuest);
        case '0':
          return;
        default:
          _invalid();
      }
    }
  }

  void _guestTable(List<Guest> list) => Console.table(
        ['ID', 'Nama', 'No. HP', 'Email'],
        list.map((g) => ['${g.id}', g.name, g.phone, g.email]).toList(),
      );

  void _addGuest() {
    Console.header('TAMBAH TAMU');
    final g = Guest(
      name: Console.ask('Nama lengkap'),
      phone: Console.ask('No. HP'),
      email: Console.ask('Email'),
    );
    final id = guests.create(g);
    Console.success('Tamu ${g.name} ditambahkan dengan ID $id.');
  }

  void _editGuest() {
    Console.header('UBAH TAMU');
    _guestTable(guests.findAll());
    final id = Console.askInt('ID tamu');
    final g = guests.findById(id) ?? (throw NotFoundException('Tamu #$id tidak ditemukan.'));
    Console.info('Kosongkan input untuk mempertahankan nilai lama.');
    g.name = Console.ask('Nama', current: g.name);
    g.phone = Console.ask('No. HP', current: g.phone);
    g.email = Console.ask('Email', current: g.email);
    guests.update(g);
    Console.success('Data tamu berhasil diperbarui.');
  }

  void _deleteGuest() {
    Console.header('HAPUS TAMU');
    _guestTable(guests.findAll());
    final id = Console.askInt('ID tamu');
    if (!Console.confirm('Yakin hapus tamu #$id?')) {
      Console.warn('Dibatalkan.');
      return;
    }
    guests.delete(id);
    Console.success('Tamu berhasil dihapus.');
  }

  // ═════════════════ Reservasi ═════════════════
  void _reservationMenu() {
    while (true) {
      Console.clear();
      Console.header('RESERVASI');
      final c = Console.menu([
        'Daftar reservasi',
        'Buat reservasi baru',
        'Jadwal ulang reservasi',
        'Check-in tamu',
        'Check-out tamu',
        'Batalkan reservasi',
        'Hapus riwayat reservasi',
      ]);
      switch (c) {
        case '1':
          _safe(_showReservations);
        case '2':
          _safe(_newBooking);
        case '3':
          _safe(_reschedule);
        case '4':
          _safe(_checkIn);
        case '5':
          _safe(_checkOut);
        case '6':
          _safe(_cancel);
        case '7':
          _safe(_deleteReservation);
        case '0':
          return;
        default:
          _invalid();
      }
    }
  }

  String _statusStyle(int col, String padded) {
    if (col != 7) return padded;
    return switch (padded.trim()) {
      'Booked' => Ansi.paint(padded, Ansi.yellow),
      'Check-in' => Ansi.paint(padded, Ansi.green),
      'Check-out' => Ansi.paint(padded, Ansi.blue),
      'Cancelled' => Ansi.paint(padded, Ansi.red),
      _ => padded,
    };
  }

  void _showReservations() {
    Console.table(
      ['ID', 'Tamu', 'Kamar', 'Check-in', 'Check-out', 'Malam', 'Total', 'Status'],
      reservations
          .findAll()
          .map((r) => [
                '${r.id}',
                r.guestName ?? '-',
                r.roomNumber ?? '-',
                dateStr(r.checkIn),
                dateStr(r.checkOut),
                '${r.nights}',
                rupiah(r.totalPrice),
                r.status.label,
              ])
          .toList(),
      style: _statusStyle,
    );
  }

  void _printQuote(Room room, int nights, PriceQuote q) {
    Console.println();
    Console.println('  ${Ansi.paint('RINGKASAN BIAYA', Ansi.bold)}');
    Console.println('  Kamar     : ${room.number} (${room.label})');
    Console.println('  Durasi    : $nights malam');
    Console.println('  Subtotal  : ${rupiah(q.subtotal)}');
    if (q.discountRate > 0) {
      Console.println(
          '  Diskon    : ${q.discountName} ${(q.discountRate * 100).round()}%  -${rupiah(q.discountAmount)}');
    }
    Console.println('  ${Ansi.paint('TOTAL     : ${rupiah(q.total)}', Ansi.bold + Ansi.green)}');
  }

  void _newBooking() {
    Console.header('RESERVASI BARU');
    final ci = Console.askDate('Check-in  (YYYY-MM-DD)');
    final co = Console.askDate('Check-out (YYYY-MM-DD)');
    final free = service.availableRooms(ci, co);
    if (free.isEmpty) {
      Console.warn('Tidak ada kamar kosong pada tanggal tersebut.');
      return;
    }
    final nights = co.difference(ci).inDays;
    Console.println();
    _roomTable(free, nights: nights);
    final roomId = Console.askInt('ID kamar yang dipilih');
    final room = free.firstWhere(
      (r) => r.id == roomId,
      orElse: () => throw RoomUnavailableException('Kamar #$roomId tidak ada di daftar tersedia.'),
    );

    Console.println();
    _guestTable(guests.findAll());
    final guestId = Console.askInt('ID tamu');

    _printQuote(room, nights, service.quoteFor(room, nights));
    Console.println();
    if (!Console.confirm('Konfirmasi reservasi?')) {
      Console.warn('Reservasi dibatalkan.');
      return;
    }
    final res = service.book(guestId: guestId, roomId: roomId, checkIn: ci, checkOut: co);
    Console.success('Reservasi #${res.id} untuk ${res.guestName} berhasil dibuat!');
  }

  void _reschedule() {
    Console.header('JADWAL ULANG');
    _showReservations();
    final id = Console.askInt('ID reservasi');
    final ci = Console.askDate('Check-in baru  (YYYY-MM-DD)');
    final co = Console.askDate('Check-out baru (YYYY-MM-DD)');
    service.reschedule(id, ci, co);
    Console.success('Jadwal reservasi #$id berhasil diubah (harga dihitung ulang).');
  }

  void _checkIn() {
    Console.header('CHECK-IN');
    _showReservations();
    final id = Console.askInt('ID reservasi');
    final r = service.checkIn(id);
    Console.success('${r.guestName} berhasil check-in di kamar ${r.roomNumber}. Selamat menginap!');
  }

  void _checkOut() {
    Console.header('CHECK-OUT');
    _showReservations();
    final id = Console.askInt('ID reservasi');
    final r = service.checkOut(id);
    Console.success('${r.guestName} check-out dari kamar ${r.roomNumber}.');
    Console.println('  Total tagihan: ${Ansi.paint(rupiah(r.totalPrice), Ansi.bold + Ansi.green)}');
  }

  void _cancel() {
    Console.header('BATALKAN RESERVASI');
    _showReservations();
    final id = Console.askInt('ID reservasi');
    if (!Console.confirm('Yakin batalkan reservasi #$id?')) {
      Console.warn('Dibatalkan.');
      return;
    }
    service.cancel(id);
    Console.success('Reservasi #$id dibatalkan.');
  }

  void _deleteReservation() {
    Console.header('HAPUS RIWAYAT');
    _showReservations();
    final id = Console.askInt('ID reservasi');
    if (!Console.confirm('Hapus permanen reservasi #$id?')) {
      Console.warn('Dibatalkan.');
      return;
    }
    service.deleteRecord(id);
    Console.success('Riwayat reservasi dihapus.');
  }
}