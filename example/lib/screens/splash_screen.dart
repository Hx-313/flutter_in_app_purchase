import 'dart:async';

import 'package:flutter/material.dart';

import '../ithx_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.nextScreenBuilder,
    this.duration = const Duration(milliseconds: 1200),
  });

  final WidgetBuilder nextScreenBuilder;
  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _continue);
  }

  void _continue() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, _, _) => widget.nextScreenBuilder(context),
        transitionDuration: const Duration(milliseconds: 350),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: IthxPalette.deepForest,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                image: true,
                label: 'ITHX app icon',
                child: Image.asset(
                  'assets/branding/ithx-app-icon.png',
                  width: 164,
                  height: 164,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'ACT ETHICALLY',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: IthxPalette.cream,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
