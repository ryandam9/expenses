class AppFilter {
  final String? startDate;
  final String? endDate;
  final List<String> categories;

  const AppFilter({this.startDate, this.endDate, this.categories = const []});

  bool get hasPeriod => startDate != null || endDate != null;
  bool get hasCategories => categories.isNotEmpty;

  AppFilter copyWith({
    String? startDate,
    String? endDate,
    List<String>? categories,
    bool clearCategories = false,
  }) {
    return AppFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categories: clearCategories ? [] : (categories ?? this.categories),
    );
  }

  AppFilter clearPeriod() => copyWith(startDate: null, endDate: null);
  AppFilter clearCategories() => copyWith(clearCategories: true);
  AppFilter clearAll() => const AppFilter();

  @override
  bool operator ==(Object other) =>
      other is AppFilter &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.categories.length == categories.length &&
      other.categories.every(categories.contains);

  @override
  int get hashCode => Object.hash(startDate, endDate, Object.hashAll(categories));
}
