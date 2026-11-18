import '../core/exceptions.dart';

/// Kelas abstrak Room.
/// - Enkapsulasi : field private (_number, _basePrice) + getter/setter ber-validasi.
/// - Inheritance : StandardRoom, DeluxeRoom, SuiteRoom mewarisi Room.
/// - Polimorfisme: calculatePrice(), label, facilities di-override tiap tipe.
abstract class Room {
  final int? _id;
  String _number;
  double _basePrice;

  Room({int? id, required String number, required double basePrice})
      : _id = id,
        _number = _checkNumber(number),
        _basePrice = _checkPrice(basePrice);

  static String _checkNumber(String v) {
    final n = v.trim();
    if (n.isEmpty) throw ValidationException('Nomor kamar tidak boleh kosong.');
    return n;
  }

  static double _checkPrice(double v) {
    if (v <= 0) throw ValidationException('Harga harus lebih dari 0.');
    return v;
  }

  int? get id => _id;
  String get number => _number;
  set number(String v) => _number = _checkNumber(v);
  double get basePrice => _basePrice;
  set basePrice(double v) => _basePrice = _checkPrice(v);

  String get type; // kunci untuk database
  String get label; // nama tampilan
  List<String> get facilities;

  /// Harga total untuk [nights] malam (bisa di-override).
  double calculatePrice(int nights) {
    if (nights <= 0) throw ValidationException('Jumlah malam minimal 1.');
    return _basePrice * nights;
  }
}

class StandardRoom extends Room {
  StandardRoom({super.id, required super.number, required super.basePrice});

  @override
  String get type => 'standard';
  @override
  String get label => 'Standard';
  @override
  List<String> get facilities => ['AC', 'TV', 'WiFi'];
}

class DeluxeRoom extends Room {
  static const double breakfastFee = 75000;

  DeluxeRoom({super.id, required super.number, required super.basePrice});

  @override
  String get type => 'deluxe';
  @override
  String get label => 'Deluxe';
  @override
  List<String> get facilities =>
      ['AC', 'Smart TV', 'WiFi', 'Breakfast', 'Bathtub'];

  @override
  double calculatePrice(int nights) =>
      super.calculatePrice(nights) + breakfastFee * nights;
}

class SuiteRoom extends Room {
  static const double butlerFee = 200000;

  SuiteRoom({super.id, required super.number, required super.basePrice});

  @override
  String get type => 'suite';
  @override
  String get label => 'Suite';
  @override
  List<String> get facilities =>
      ['AC', 'Smart TV', 'WiFi', 'Breakfast', 'Jacuzzi', 'Lounge', 'Butler'];

  @override
  double calculatePrice(int nights) =>
      super.calculatePrice(nights) + butlerFee * nights;
}

/// Design Pattern: Factory.
class RoomFactory {
  static Room create({
    required String type,
    int? id,
    required String number,
    required double basePrice,
  }) {
    switch (type) {
      case 'standard':
        return StandardRoom(id: id, number: number, basePrice: basePrice);
      case 'deluxe':
        return DeluxeRoom(id: id, number: number, basePrice: basePrice);
      case 'suite':
        return SuiteRoom(id: id, number: number, basePrice: basePrice);
      default:
        throw ValidationException('Tipe kamar tidak dikenal: $type');
    }
  }

  static Room fromMap(Map<String, Object?> m) => create(
        type: m['type'] as String,
        id: m['id'] as int,
        number: m['number'] as String,
        basePrice: (m['base_price'] as num).toDouble(),
      );
}
