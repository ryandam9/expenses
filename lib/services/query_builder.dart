import '../models/app_filter.dart';
import '../models/expense.dart';

/// Pure, dependency-free helpers for building SQL fragments and exporting data.
/// Kept separate from [DatabaseService] so the logic can be unit-tested without
/// a live database.

/// Transfers between a user's own accounts aren't real income or spending, so
/// this category is excluded from every query, app-wide.
const excludeTransfersClause = "UPPER(category) <> 'TRANSFERS'";

/// Builds the date-bounds part of a `WHERE` body (transfers exclusion plus
/// any start/end date in [f]). Category selection is ignored, so this suits
/// queries that need "everything in the period" (e.g. the category options
/// for the filter sidebar).
({String clause, List<String> args}) buildDateWhere(AppFilter f) {
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
  return (clause: clauses.join(' AND '), args: args);
}

/// Builds the `WHERE` body (without the `WHERE` keyword) for a query over the
/// expenses table, always excluding transfers. Returns the clause and the
/// positional arguments in matching order.
({String clause, List<String> args}) buildWhere(AppFilter f) {
  final date = buildDateWhere(f);
  final clauses = <String>[date.clause];
  final args = List<String>.from(date.args);
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

/// The period immediately before the one selected by [f], for "vs previous
/// period" comparisons. Whole calendar months compare with the previous
/// month and whole years with the previous year; any other complete range is
/// shifted back by its own length. Returns null when [f] has no complete
/// date range. Category selection is preserved.
AppFilter? previousPeriod(AppFilter f) {
  final s = f.startDate == null ? null : DateTime.tryParse(f.startDate!);
  final e = f.endDate == null ? null : DateTime.tryParse(f.endDate!);
  if (s == null || e == null || e.isBefore(s)) return null;

  final lastOfStartMonth = DateTime(s.year, s.month + 1, 0);
  final isWholeYear = s.month == 1 &&
      s.day == 1 &&
      e.year == s.year &&
      e.month == 12 &&
      e.day == 31;
  final isWholeMonth = s.day == 1 &&
      e.year == s.year &&
      e.month == s.month &&
      e.day == lastOfStartMonth.day;

  DateTime prevStart, prevEnd;
  if (isWholeYear) {
    prevStart = DateTime(s.year - 1, 1, 1);
    prevEnd = DateTime(s.year - 1, 12, 31);
  } else if (isWholeMonth) {
    prevStart = DateTime(s.year, s.month - 1, 1);
    prevEnd = DateTime(s.year, s.month, 0);
  } else {
    final len = e.difference(s).inDays + 1;
    prevEnd = s.subtract(const Duration(days: 1));
    prevStart = prevEnd.subtract(Duration(days: len - 1));
  }
  String fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
  return AppFilter(
    startDate: fmt(prevStart),
    endDate: fmt(prevEnd),
    categories: f.categories,
    allCategories: f.allCategories,
  );
}

/// Sums the debit amounts of [rows] grouped by [keyOf], sorted high to low.
/// Credits are ignored. Used for the category/bank breakdowns so they always
/// reflect exactly the rows on screen (including any text search).
Map<String, double> debitTotalsBy(
    Iterable<Expense> rows, String Function(Expense e) keyOf) {
  final totals = <String, double>{};
  for (final e in rows) {
    if (e.debit <= 0) continue;
    final k = keyOf(e);
    totals[k] = (totals[k] ?? 0) + e.debit;
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return {for (final e in entries) e.key: e.value};
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
