import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A category's icon that, the moment its category is selected, performs a
/// playful 3D "coin flip" — a full barrel rotation about the Y axis with real
/// perspective — while springing up in scale and settling with an elastic
/// bounce. The flourish only plays on the select transition; at rest it simply
/// shows the icon, front-facing and at its normal size.
class AnimatedCategoryIcon extends StatefulWidget {
  final FaIconData icon;
  final Color color;
  final double size;
  final bool selected;

  const AnimatedCategoryIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.selected,
    this.size = 15,
  });

  @override
  State<AnimatedCategoryIcon> createState() => _AnimatedCategoryIconState();
}

class _AnimatedCategoryIconState extends State<AnimatedCategoryIcon>
    with SingleTickerProviderStateMixin {
  // Rests at value 1 (settled) so the icon shows front-facing at normal size on
  // first build; the flip only plays when selection flips on.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
    value: 1,
  );

  // One full turn about the Y axis — ends back at the front (2π ≡ 0).
  late final Animation<double> _flip = Tween<double>(
    begin: 0,
    end: 2 * math.pi,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  // Spring up, then bounce back to rest — gives the flip a tactile landing.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.3,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.3,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_controller);

  @override
  void didUpdateWidget(covariant AnimatedCategoryIcon old) {
    super.didUpdateWidget(old);
    if (widget.selected && !old.selected) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.0016) // perspective
          ..rotateY(_flip.value)
          ..scaleByDouble(_scale.value, _scale.value, _scale.value, 1);
        return Transform(
          alignment: Alignment.center,
          transform: transform,
          child: child,
        );
      },
      child: FaIcon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
