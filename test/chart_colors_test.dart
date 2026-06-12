import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expenses_dash/theme/app_themes.dart';

void main() {
  test('buildChartColors returns exactly the requested count', () {
    final base = [Colors.red, Colors.green, Colors.blue];
    expect(buildChartColors(base, 3).length, 3);
    expect(buildChartColors(base, 7).length, 7);
  });

  test('buildChartColors handles empty input and zero count', () {
    expect(buildChartColors(const [], 5), isEmpty);
    expect(buildChartColors([Colors.red], 0), isEmpty);
  });

  test('first cycle reuses the base colours unchanged', () {
    final base = [Colors.red, Colors.green];
    final out = buildChartColors(base, 2);
    expect(out[0], Colors.red);
    expect(out[1], Colors.green);
  });

  test('every theme exposes a chart palette of distinct colours', () {
    for (final t in appThemes) {
      expect(t.palette.length, greaterThanOrEqualTo(4),
          reason: '${t.name} should have a rich chart palette');
      expect(t.palette.toSet().length, t.palette.length,
          reason: '${t.name} palette colours should be distinct');
    }
  });
}
