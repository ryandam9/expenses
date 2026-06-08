import '../models/app_filter.dart';
import '../models/expense.dart';

/// Pure, dependency-free helpers for building SQL fragments and exporting data.
/// Kept separate from [DatabaseService] so the logic can be unit-tested without
/// a live database.

/// Transfers between a user's own accounts aren't real income or spending, so
/// this category is excluded from every query, app-wide.
const excludeTransfersClause = "UPPER(category) <> 'TRANSFERS'";

/// Builds the `WHERE` body (without the `WHERE` keyword) for a query over the
/// expenses table, always excluding transfers. Returns the clause and the
/// positional arguments in matching order.
({String clause, List<String> args}) buildWhere(AppFilter f) {
  final clauses = <String>[excludeTransfersClause];
  final args = <String>[];
  if (f.startDate != null) {
    clauses.add('date >= ?');
    args.add(f.startDate!);
  }
  if (f.endDate != null) {
    clauses.add('date <= ?');
    args.add(f.endDate!);
  }
  if (!f.allCategories) {
    if (f.categories.isEmpty) {
      // Explicit "none selected" -> match no rows.
      clauses.add('1 = 0');
    } else {
      clauses.add('category IN (${f.categories.map((_) => '?').join(', ')})');
      args.addAll(f.categories);
    }
  }
  return (clause: clauses.join(' AND '), args: args);
}

/// Escapes a single CSV field per RFC 4180 (quote when it contains a comma,
/// quote, or newline; double up embedded quotes).
String csvField(Object? value) {
  final s = value?.toString() ?? '';
  if (s.contains(',') || s.contains('"') || s.contains('\n') || s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String csvRow(List<Object?> fields) => fields.map(csvField).join(',');

/// Renders a list of transactions as CSV text (with a header row).
String transactionsToCsv(List<Expense> rows) {
  final buf = StringBuffer();
  buf.writeln(csvRow(
      ['Date', 'Description', 'Bank', 'Debit', 'Credit', 'Amount', 'Category']));
  for (final e in rows) {
    buf.writeln(csvRow([
      e.date,
      e.description,
      e.source,
      e.debit,
      e.credit,
      e.amount,
      e.category,
    ]));
  }
  return buf.toString();
}

/// Renders a category -> total map as CSV text (with a header row), sorted
/// high to low.
String categorySummaryToCsv(Map<String, double> byCategory) {
  final entries = byCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final total = entries.fold<double>(0, (s, e) => s + e.value);
  final buf = StringBuffer();
  buf.writeln(csvRow(['Category', 'Total', 'Percent']));
  for (final e in entries) {
    final pct = total == 0 ? 0 : (e.value / total * 100);
    buf.writeln(csvRow(
        [e.key, e.value.toStringAsFixed(2), '${pct.toStringAsFixed(1)}%']));
  }
  return buf.toString();
}
