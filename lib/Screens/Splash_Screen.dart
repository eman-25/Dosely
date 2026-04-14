import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const SplashScreen({Key? key, required this.nextScreen}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Logo moves: far left → overshoots right → snaps back to center
  late Animation<double> _logoXAnimation;

  // Logo fades in as it moves
  late Animation<double> _logoFadeAnimation;

  // Small scale pulse when it lands at center
  late Animation<double> _logoScaleAnimation;

  // Text fades + slides up after logo settles
  late Animation<double> _textFadeAnimation;
  late Animation<double> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // left (-350) → right (+80 overshoot) → center (0)
    _logoXAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -350.0, end: 80.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 80.0, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_controller);

    // Fades in during the left-to-right sweep
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Tiny scale pulse when landing at center
    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.10, end: 0.95), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.62, 0.80, curve: Curves.easeInOut),
      ),
    );

    // Text appears after logo is settled
    _textFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0, curve: Curves.easeIn),
      ),
    );

    _textSlideAnimation = Tween<double>(begin: 16.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigate after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => widget.nextScreen,
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FAF8),
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // "Hello! Welcome To" fades in after logo settles
                FadeTransition(
                  opacity: _textFadeAnimation,
                  child: Transform.translate(
                    offset: Offset(0, _textSlideAnimation.value),
                    child: const Text(
                      'Hello! Welcome To',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A3A5C),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // Logo sweeps left → right → center
                FadeTransition(
                  opacity: _logoFadeAnimation,
                  child: Transform.translate(
                    offset: Offset(_logoXAnimation.value, 0),
                    child: Transform.scale(
                      scale: _logoScaleAnimation.value,
                      child: Image.asset(
                        'assets/images/dosely_logo.png', // ✅ your asset
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
