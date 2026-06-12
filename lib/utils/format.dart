import 'package:intl/intl.dart';

/// Compact money for chart axes and dense labels ($950, $1.2k, $3.4M).
String compactMoney(double v) {
  if (v.abs() >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
  if (v.abs() >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}k';
  return '\$${v.toStringAsFixed(0)}';
}

/// Display form of a raw category name, in Title Case:
/// 'HOME-EXPENSES' → 'Home Expenses', 'MELLOW' → 'Mellow'.
String prettyCategory(String category) {
  return category
      .split(RegExp(r'[-_\s]+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
      .join(' ');
}

/// Whole-dollar currency, for KPI tiles.
final NumberFormat currency0 = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

/// Cent-precise currency, for individual transactions.
final NumberFormat currency2 = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
