import 'package:flutter/material.dart';

/// Lightweight skeleton used while store products are loading.
class SubscriptionLoadingShimmer extends StatefulWidget {
  const SubscriptionLoadingShimmer({super.key, required this.padding});

  final EdgeInsetsGeometry padding;

  @override
  State<SubscriptionLoadingShimmer> createState() =>
      _SubscriptionLoadingShimmerState();
}

class _SubscriptionLoadingShimmerState extends State<SubscriptionLoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(-1 + (_controller.value * 2), 0),
          end: Alignment(1 + (_controller.value * 2), 0),
          colors: [color, color.withValues(alpha: 0.35), color],
        ).createShader(bounds),
        child: child,
      ),
      child: ListView(
        padding: widget.padding,
        children: [
          _PlaceholderBox(color: color, height: 36, width: 220),
          const SizedBox(height: 20),
          for (var index = 0; index < 3; index++) ...[
            _PlaceholderBox(color: color, height: 112),
            if (index < 2) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderBox extends StatelessWidget {
  const _PlaceholderBox({required this.color, this.height = 24, this.width});

  final Color color;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}
