class AppFilter {
  final String? startDate;
  final String? endDate;

  /// Explicit category selection. Only meaningful when [allCategories] is
  /// false. An empty list with [allCategories] false means "none selected".
  final List<String> categories;

  /// When true, no category filter is applied (every category is included).
  final bool allCategories;

  const AppFilter({
    this.startDate,
    this.endDate,
    this.categories = const [],
    this.allCategories = true,
  });

  bool get hasPeriod => startDate != null || endDate != null;

  /// A category filter is active whenever we are not showing everything.
  bool get hasCategoryFilter => !allCategories;

  bool get hasAnyFilter => hasPeriod || hasCategoryFilter;

  AppFilter copyWith({
    String? startDate,
    String? endDate,
    List<String>? categories,
    bool? allCategories,
  }) {
    return AppFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categories: categories ?? this.categories,
      allCategories: allCategories ?? this.allCategories,
    );
  }

  AppFilter clearPeriod() => copyWith(startDate: null, endDate: null);

  @override
  bool operator ==(Object other) =>
      other is AppFilter &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.allCategories == allCategories &&
      other.categories.length == categories.length &&
      other.categories.every(categories.contains);

  @override
  int get hashCode =>
      Object.hash(startDate, endDate, allCategories, Object.hashAll(categories));
}
