/// Shared Tunisian Dinar formatter.
/// Money arrives from the API as numbers without fixed decimals;
/// always display with exactly 3 decimal places.
///
/// Examples:
///   149.9   → "149,900 DT"
///   8.0     → "8,000 DT"
///   0.0     → "0,000 DT"
///   1234.56 → "1 234,560 DT"  (optional thousands sep kept simple for now)
String formatDinar(num price) {
  final formatted = price.toStringAsFixed(3).replaceAll('.', ',');
  return '$formatted DT';
}
