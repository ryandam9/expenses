import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// A category's icon that plays a quick, springy "pop" — a bounce-in scale with
/// a slight rotation — the moment its category becomes selected, drawing the
/// eye to the icon first. At rest (and when deselected) it simply shows the
/// icon, so the flourish only ever plays on the select transition.
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
  // Starts settled (value 1) so the icon is at its resting size on first build;
  // the pop only plays when selection flips on.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: 1,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.5,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
  late final Animation<double> _rotation = Tween<double>(
    begin: -0.2,
    end: 0.0,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

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
      builder: (context, child) => Transform.rotate(
        angle: _rotation.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: FaIcon(widget.icon, size: widget.size, color: widget.color),
    );
  }
}
