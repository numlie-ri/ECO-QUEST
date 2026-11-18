/// Design Pattern: Strategy -> aturan diskon bisa diganti tanpa mengubah service
/// (Open/Closed Principle).
abstract class DiscountStrategy {
  String get name;
  double rateFor(int nights); // 0.10 = 10%
}

class NoDiscount implements DiscountStrategy {
  @override
  String get name => 'Tanpa diskon';
  @override
  double rateFor(int nights) => 0;
}

class LongStayDiscount implements DiscountStrategy {
  @override
  String get name => 'Diskon menginap lama';
  @override
  double rateFor(int nights) => nights >= 7 ? 0.15 : (nights >= 3 ? 0.10 : 0);
}

class PriceQuote {
  final double subtotal;
  final String discountName;
  final double discountRate;

  PriceQuote(this.subtotal, this.discountName, this.discountRate);

  double get discountAmount => subtotal * discountRate;
  double get total => subtotal - discountAmount;
}
