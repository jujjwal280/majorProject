import 'package:flutter/material.dart';
import 'package:start1/ui/splash_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final SplashServices splashServices = SplashServices();
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    splashServices.checkAuthentication(context);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(height: 50),
            Center(
              child: FadeTransition(
                opacity: _animation,
                child: Column(
                  children: [
                    const Icon(Icons.currency_rupee_rounded, size: 150, color: Color(0xFF053F5C)),
                    const SizedBox(height: 5),
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0), // Fade-in effect
                      duration: const Duration(seconds: 1),
                      builder: (context, double opacity, child) {
                        return const Text(
                          'MoneyMINDER',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  CircularProgressIndicator(color: Color(0xFF053F5C)), // Show progress indicator
                  SizedBox(height: 20),
                  Text(
                    '❤️ Made by',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF053F5C),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'TEAM DHANRAKSHAK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
