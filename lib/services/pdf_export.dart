import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/expense.dart';
import '../utils/format.dart';

/// Builds a polished, multi-page PDF "Expenses Report" from [rows] (already
/// scoped to the selected categories / period by the caller).
///
/// The document leads with a branded heading, then a summary section — a
/// stacked "composition" bar and a per-category amounts chart + table — and
/// finally the full transactions table (S.No, Date, Description, Amount, Bank,
/// Category) sorted by date and then category, with a repeating header that
/// flows across pages.

class _CatAgg {
  final String name;
  final double total;
  final int count;
  const _CatAgg(this.name, this.total, this.count);
}

// Brand + chart palette (mirrors the app's Periwinkle theme so the report
// feels of a piece with the on-screen UI).
const PdfColor _brand = PdfColor.fromInt(0xFF6260FF);
const PdfColor _ink = PdfColor.fromInt(0xFF23232B);
const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
const PdfColor _line = PdfColor.fromInt(0xFFD8DAE5);
const PdfColor _zebra = PdfColor.fromInt(0xFFF5F6FB);
const PdfColor _trackGrey = PdfColor.fromInt(0xFFE9EAF2);
const List<PdfColor> _palette = [
  PdfColor.fromInt(0xFF6260FF),
  PdfColor.fromInt(0xFF34E0A1),
  PdfColor.fromInt(0xFFF5A623),
  PdfColor.fromInt(0xFFFF6584),
  PdfColor.fromInt(0xFF3447AA),
  PdfColor.fromInt(0xFF1FB6B6),
  PdfColor.fromInt(0xFF9B5DE5),
  PdfColor.fromInt(0xFF00BBF9),
];

PdfColor _colorFor(String category) {
  final h = category.codeUnits.fold<int>(0, (s, c) => s + c);
  return _palette[h % _palette.length];
}

final _dateFmt = DateFormat('dd MMM yyyy');

String _fmtDate(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : _dateFmt.format(d);
}

/// The report's file name: `YYYY-MM-Expenses.pdf`, where `YYYY-MM` is the most
/// recent month present in [rows] (falling back to the current month when the
/// selection is empty).
String expensesPdfFileName(List<Expense> rows) {
  var latest = '';
  for (final e in rows) {
    if (e.date.length >= 7) {
      final k = e.date.substring(0, 7);
      if (k.compareTo(latest) > 0) latest = k;
    }
  }
  if (latest.isEmpty) latest = DateFormat('yyyy-MM').format(DateTime.now());
  return '$latest-Expenses.pdf';
}

Future<Uint8List> buildExpensesPdf({
  required List<Expense> rows,
  required String periodLabel,
}) async {
  // ---- aggregate (GROUP BY category) -------------------------------------
  final totals = <String, double>{};
  final counts = <String, int>{};
  double grandTotal = 0;
  for (final e in rows) {
    if (e.debit <= 0) continue;
    totals[e.category] = (totals[e.category] ?? 0) + e.debit;
    counts[e.category] = (counts[e.category] ?? 0) + 1;
    grandTotal += e.debit;
  }
  final cats =
      [
        for (final entry in totals.entries)
          _CatAgg(entry.key, entry.value, counts[entry.key] ?? 0),
      ]..sort((a, b) => b.total.compareTo(a.total));

  // ---- transactions sorted by date, then category ------------------------
  final sorted = List<Expense>.from(rows)
    ..sort((a, b) {
      final d = a.date.compareTo(b.date);
      return d != 0 ? d : a.category.compareTo(b.category);
    });

  final doc = pw.Document(
    title: 'Expenses Report',
    author: 'Expenses Dashboard',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 38),
      header: (ctx) => ctx.pageNumber == 1 ? pw.SizedBox() : _runningHeader(),
      footer: _footer,
      build: (ctx) => [
        _titleBlock(periodLabel, grandTotal),
        pw.SizedBox(height: 20),
        if (cats.isNotEmpty) ...[
          _sectionHeading('Spending by Category'),
          pw.SizedBox(height: 12),
          _categoryBars(cats, grandTotal),
          pw.SizedBox(height: 18),
          _categoryTable(cats, grandTotal),
          pw.SizedBox(height: 24),
        ],
        _sectionHeading('Transactions'),
        pw.SizedBox(height: 12),
        _transactionsTable(sorted),
      ],
    ),
  );

  return doc.save();
}

// ------------------------------------------------------------------- heading
pw.Widget _titleBlock(String period, double total) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(18),
    decoration: const pw.BoxDecoration(
      color: _brand,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                _moneyBadge(),
                pw.SizedBox(width: 12),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Expenses',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      'Period: $period',
                      style: const pw.TextStyle(
                        color: PdfColor.fromInt(0xFFE4E4FF),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  currency2.format(total),
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'total spent',
                  style: const pw.TextStyle(
                    color: PdfColor.fromInt(0xFFE4E4FF),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

// A "money" icon: a white rounded badge with a brand-coloured dollar mark.
// Drawn from primitives so the report needs no embedded icon font.
pw.Widget _moneyBadge() => pw.Container(
  width: 36,
  height: 36,
  decoration: const pw.BoxDecoration(
    color: PdfColors.white,
    borderRadius: pw.BorderRadius.all(pw.Radius.circular(9)),
  ),
  alignment: pw.Alignment.center,
  child: pw.Text(
    '\$',
    style: pw.TextStyle(
      color: _brand,
      fontSize: 24,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
);

pw.Widget _sectionHeading(String title) => pw.Row(
  crossAxisAlignment: pw.CrossAxisAlignment.center,
  children: [
    pw.Container(width: 4, height: 16, color: _brand),
    pw.SizedBox(width: 8),
    pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
      ),
    ),
  ],
);

// A horizontal bar chart of amount per category (top ten), each bar sized
// relative to the biggest category.
pw.Widget _categoryBars(List<_CatAgg> cats, double total) {
  final shown = cats.take(10).toList();
  final maxVal = shown.first.total;
  return pw.Container(
    padding: const pw.EdgeInsets.fromLTRB(14, 14, 14, 8),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
    ),
    child: pw.Column(
      children: [
        for (final c in shown)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(
                  width: 96,
                  child: pw.Text(
                    prettyCategory(c.name),
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: _bar(c.total, maxVal, _colorFor(c.name))),
                pw.SizedBox(width: 8),
                pw.SizedBox(
                  width: 70,
                  child: pw.Text(
                    currency2.format(c.total),
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// A grey track with a coloured fill proportional to [value]/[max]. Built from
// nested rounded Containers (no ClipRRect — the PDF engine renders rounded
// clips as pointed lens shapes).
pw.Widget _bar(double value, double max, PdfColor color) {
  final filled = max <= 0 ? 0 : (value / max * 1000).round().clamp(0, 1000);
  final rest = 1000 - filled;
  return pw.Container(
    height: 11,
    decoration: const pw.BoxDecoration(
      color: _trackGrey,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
    ),
    child: pw.Row(
      children: [
        if (filled > 0)
          pw.Expanded(
            flex: filled,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: color,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
              ),
            ),
          ),
        if (rest > 0) pw.Expanded(flex: rest, child: pw.SizedBox()),
      ],
    ),
  );
}

// The amounts-per-category table: Category, Transactions, Amount, % of total.
pw.Widget _categoryTable(List<_CatAgg> cats, double total) {
  return pw.TableHelper.fromTextArray(
    headers: ['Category', 'Transactions', 'Amount', '% of Total'],
    data: [
      for (final c in cats)
        [
          prettyCategory(c.name),
          '${c.count}',
          currency2.format(c.total),
          total <= 0 ? '0%' : '${(c.total / total * 100).toStringAsFixed(1)}%',
        ],
      [
        'TOTAL',
        '${cats.fold<int>(0, (s, c) => s + c.count)}',
        currency2.format(total),
        '100%',
      ],
    ],
    border: pw.TableBorder.all(color: _line, width: 0.5),
    headerStyle: pw.TextStyle(
      color: PdfColors.white,
      fontSize: 9.5,
      fontWeight: pw.FontWeight.bold,
    ),
    headerDecoration: const pw.BoxDecoration(color: _brand),
    headerHeight: 22,
    cellHeight: 18,
    cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
    oddRowDecoration: const pw.BoxDecoration(color: _zebra),
    cellAlignments: {
      0: pw.Alignment.centerLeft,
      1: pw.Alignment.center,
      2: pw.Alignment.centerRight,
      3: pw.Alignment.centerRight,
    },
    columnWidths: {
      0: const pw.FlexColumnWidth(3),
      1: const pw.FlexColumnWidth(1.4),
      2: const pw.FlexColumnWidth(1.8),
      3: const pw.FlexColumnWidth(1.4),
    },
  );
}

// The full ledger: S.No, Date, Description, Amount, Bank, Category — sorted by
// date then category, with a header that repeats on every page.
pw.Widget _transactionsTable(List<Expense> rows) {
  return pw.TableHelper.fromTextArray(
    headers: ['S.No', 'Date', 'Description', 'Amount', 'Bank', 'Category'],
    data: [
      for (var i = 0; i < rows.length; i++)
        [
          '${i + 1}',
          _fmtDate(rows[i].date),
          rows[i].description,
          currency2.format(rows[i].debit > 0 ? -rows[i].debit : rows[i].credit),
          rows[i].source,
          prettyCategory(rows[i].category),
        ],
    ],
    border: pw.TableBorder.all(color: _line, width: 0.5),
    headerStyle: pw.TextStyle(
      color: PdfColors.white,
      fontSize: 9,
      fontWeight: pw.FontWeight.bold,
    ),
    headerDecoration: const pw.BoxDecoration(color: _ink),
    headerHeight: 22,
    cellHeight: 16,
    cellStyle: const pw.TextStyle(fontSize: 8.5, color: _ink),
    oddRowDecoration: const pw.BoxDecoration(color: _zebra),
    cellAlignments: {
      0: pw.Alignment.center,
      1: pw.Alignment.centerLeft,
      2: pw.Alignment.centerLeft,
      3: pw.Alignment.centerRight,
      4: pw.Alignment.centerLeft,
      5: pw.Alignment.centerLeft,
    },
    columnWidths: {
      0: const pw.FlexColumnWidth(0.7),
      1: const pw.FlexColumnWidth(1.6),
      2: const pw.FlexColumnWidth(3.6),
      3: const pw.FlexColumnWidth(1.5),
      4: const pw.FlexColumnWidth(1.3),
      5: const pw.FlexColumnWidth(1.8),
    },
  );
}

pw.Widget _runningHeader() => pw.Container(
  alignment: pw.Alignment.centerRight,
  margin: const pw.EdgeInsets.only(bottom: 8),
  child: pw.Text(
    'Expenses Report',
    style: const pw.TextStyle(fontSize: 9, color: _muted),
  ),
);

pw.Widget _footer(pw.Context ctx) => pw.Container(
  alignment: pw.Alignment.centerRight,
  margin: const pw.EdgeInsets.only(top: 8),
  child: pw.Text(
    'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
    style: const pw.TextStyle(fontSize: 9, color: _muted),
  ),
);
