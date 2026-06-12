import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:expenses_dash/utils/category_icons.dart';

void main() {
  test('maps known categories to their icons, case-insensitively', () {
    expect(categoryIcon('MELLOW'), FontAwesomeIcons.dog);
    expect(categoryIcon('mellow'), FontAwesomeIcons.dog);
    expect(categoryIcon('HOME-EXPENSES'), FontAwesomeIcons.house);
    expect(categoryIcon('GROCERIES'), FontAwesomeIcons.basketShopping);
    expect(categoryIcon('FOOD'), FontAwesomeIcons.utensils);
    expect(categoryIcon('RENT'), FontAwesomeIcons.fileContract);
    expect(categoryIcon('TRANSFERS'), FontAwesomeIcons.moneyBillTransfer);
    expect(categoryIcon('INCOME'), FontAwesomeIcons.sackDollar);
    expect(categoryIcon('UTILITIES'), FontAwesomeIcons.bolt);
    expect(categoryIcon('CAR-EXPENSES'), FontAwesomeIcons.car);
  });

  test('short keywords only match whole words, not substrings', () {
    // 'card' must not match the 'car' keyword.
    expect(categoryIcon('CREDIT-CARD'), isNot(FontAwesomeIcons.car));
    // 'barber' must not match the alcohol rule via 'bar'.
    expect(categoryIcon('BARBER'), FontAwesomeIcons.scissors);
  });

  test('unknown categories fall back to a generic tag', () {
    expect(categoryIcon('ZZZZ-UNKNOWN'), FontAwesomeIcons.tag);
    expect(categoryIcon(''), FontAwesomeIcons.tag);
  });
}
