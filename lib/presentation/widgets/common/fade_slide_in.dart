import 'package:flutter/material.dart';

class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        final offset = (1 - value) * 16;
        return Opacity(
          opacity: value,
          child: Transform.translate(offset: Offset(0, offset), child: child),
        );
      },
      onEnd: () {},
    );
  }
}
