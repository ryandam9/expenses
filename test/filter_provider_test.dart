import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:expenses_dash/providers/filter_provider.dart';

void main() {
  const allCats = ['food', 'rent', 'travel'];

  late ProviderContainer container;
  late FilterNotifier notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(filterProvider.notifier);
  });

  tearDown(() => container.dispose());

  test('starts with everything selected and no period', () {
    final f = container.read(filterProvider);
    expect(f.allCategories, isTrue);
    expect(f.hasAnyFilter, isFalse);
  });

  test('deselecting one category switches to an explicit selection', () {
    notifier.toggleCategory('food', allCats);
    final f = container.read(filterProvider);
    expect(f.allCategories, isFalse);
    expect(f.categories, unorderedEquals(['rent', 'travel']));
  });

  test('re-selecting the last missing category normalises back to all', () {
    notifier.toggleCategory('food', allCats);
    notifier.toggleCategory('food', allCats);
    final f = container.read(filterProvider);
    expect(f.allCategories, isTrue);
    expect(f.categories, isEmpty);
  });

  test('deselecting everything yields the explicit "none" state', () {
    notifier.selectNoCategories();
    final f = container.read(filterProvider);
    expect(f.allCategories, isFalse);
    expect(f.categories, isEmpty);
    expect(f.hasCategoryFilter, isTrue);
  });

  test('setCategories normalises a full selection to all', () {
    notifier.setCategories(['rent', 'food', 'travel'], allCats);
    expect(container.read(filterProvider).allCategories, isTrue);
  });

  test('setRange preserves the category selection', () {
    notifier.toggleCategory('food', allCats);
    notifier.setRange('2024-01-01', '2024-01-31');
    final f = container.read(filterProvider);
    expect(f.startDate, '2024-01-01');
    expect(f.endDate, '2024-01-31');
    expect(f.allCategories, isFalse);
    expect(f.categories, unorderedEquals(['rent', 'travel']));
  });

  test('clearAll resets everything', () {
    notifier.toggleCategory('food', allCats);
    notifier.setRange('2024-01-01', '2024-01-31');
    notifier.clearAll();
    final f = container.read(filterProvider);
    expect(f.hasAnyFilter, isFalse);
  });
}
