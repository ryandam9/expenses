import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_filter.dart';

class FilterNotifier extends Notifier<AppFilter> {
  @override
  AppFilter build() => const AppFilter();

  void apply(AppFilter f) => state = f;

  void clearAll() => state = const AppFilter();

  void setPeriod({String? startDate, String? endDate}) {
    state = state.copyWith(startDate: startDate, endDate: endDate);
  }

  void toggleCategory(String category) {
    final current = List<String>.from(state.categories);
    if (current.contains(category)) {
      current.remove(category);
    } else {
      current.add(category);
    }
    state = state.copyWith(categories: current);
  }

  void setCategories(List<String> cats) {
    state = state.copyWith(categories: cats);
  }

  String get periodLabel {
    final f = state;
    if (!f.hasPeriod) return 'All Time';
    final s = f.startDate;
    final e = f.endDate;
    if (s == e && s != null) {
      final parts = s.split('-');
      if (parts.length >= 2) {
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        final m = int.tryParse(parts[1]) ?? 0;
        if (m >= 1 && m <= 12) return '${months[m - 1]} ${parts[0]}';
        return parts[0];
      }
      return s;
    }
    return '$s – $e';
  }

  String get categoriesLabel {
    final c = state.categories;
    if (c.isEmpty) return 'All';
    if (c.length == 1) return c.first.replaceAll('-', ' ').toLowerCase();
    return '${c.length} selected';
  }
}

final filterProvider = NotifierProvider<FilterNotifier, AppFilter>(FilterNotifier.new);
