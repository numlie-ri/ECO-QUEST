import 'dart:io';

import 'package:hotel_reservation/core/exceptions.dart';
import 'package:hotel_reservation/data/database_helper.dart';
import 'package:hotel_reservation/data/repositories.dart';
import 'package:hotel_reservation/services/reservation_service.dart';
import 'package:hotel_reservation/ui/hotel_app.dart';

void main() {
  final helper = DatabaseHelper(); // Singleton
  try {
    final rooms = SqliteRoomRepository(helper);
    final guests = SqliteGuestRepository(helper);
    final reservations = SqliteReservationRepository(helper);

    // Dependency Injection manual: semua dependensi dirakit di sini.
    final service = ReservationService(
      rooms: rooms,
      guests: guests,
      reservations: reservations,
    );

    HotelApp(
      rooms: rooms,
      guests: guests,
      reservations: reservations,
      service: service,
    ).run();
  } on AppException catch (e) {
    stderr.writeln('Aplikasi berhenti: ${e.message}');
    exitCode = 1;
  } finally {
    helper.close();
  }
}