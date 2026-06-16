import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/theme_provider.dart';
import '../theme/app_themes.dart';
import '../utils/category_icons.dart';
import '../utils/format.dart';

/// Stable per-category accent drawn from the theme's chart palette (hashed on
/// the name, so a category keeps its colour everywhere in the app).
Color categoryAccent(BuildContext context, WidgetRef ref, String category) {
  final palette = appThemes[ref.read(themeIndexProvider)].palette;
  if (palette.isEmpty) return Theme.of(context).colorScheme.primary;
  final h = category.codeUnits.fold<int>(0, (s, c) => s + c);
  return palette[h % palette.length];
}

/// A category as a tinted pill — its icon plus Title Case name in the
/// category's stable accent colour. Used by the transactions tables.
class CategoryPill extends ConsumerWidget {
  final String category;
  const CategoryPill({super.key, required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = categoryAccent(context, ref, category);
    final hsl = HSLColor.fromColor(color);
    final textColor = hsl
        .withLightness(theme.brightness == Brightness.dark ? 0.78 : 0.30)
        .toColor();
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.40), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(categoryIcon(category), size: 10.5, color: textColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                prettyCategory(category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
