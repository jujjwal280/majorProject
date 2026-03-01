import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:start1/providers/theme_provider.dart';
import 'package:start1/ui/splash_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  final SplashServices splashServices = SplashServices();

  late AnimationController _logoController;
  late Animation<double> _logoScaleAnimation;
  late AnimationController _textController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Logo Pop
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _logoScaleAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );

    // 2. Text Slide
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutQuart));

    // 3. Background Pulse
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    _startAnimations();
  }

  void _startAnimations() async {
    HapticFeedback.mediumImpact();
    _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    _textController.forward();

    Timer(const Duration(seconds: 4), () {
      if (mounted) splashServices.checkAuthentication(context);
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access global theme
    final tp = Provider.of<ThemeProvider>(context);
    final bool isDark = tp.isDarkMode;

    const Color primaryDark = Color(0xFF053F5C);
    const Color accentOrange = Color(0xFFF27F0C);

    return Scaffold(
      // FIX: Background now reacts to saved theme preference
      backgroundColor: tp.scaffoldBg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A0A0A), const Color(0xFF121212)]
                : [Colors.white, const Color(0xFFF0F9FF), const Color(0xFFE0F7FA)],
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse Ripple
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: FadeTransition(
                          opacity: ReverseAnimation(_pulseController),
                          child: Container(
                            height: 180,
                            width: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accentOrange.withOpacity(isDark ? 0.2 : 0.4),
                            ),
                          ),
                        ),
                      ),

                      // Main Logo
                      ScaleTransition(
                        scale: _logoScaleAnimation,
                        child: Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black54 : primaryDark.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              )
                            ],
                          ),
                          child: Center(
                            child: Icon(
                                Icons.currency_rupee_rounded,
                                size: 90,
                                color: isDark ? Colors.white : primaryDark
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Text Section
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _textController,
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'Money',
                                style: TextStyle(color: tp.textColor),
                              ),
                              const TextSpan(
                                text: 'MINDER',
                                style: TextStyle(color: accentOrange),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: tp.textColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'SECURE • MANAGE • GROW',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: tp.subTextColor,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Footer Section
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _textController,
                child: Column(
                  children: [
                    SizedBox(
                      width: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          backgroundColor: isDark ? Colors.white10 : Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(accentOrange),
                          minHeight: 4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      'SECURED BY',
                      style: TextStyle(
                          fontSize: 10,
                          color: tp.subTextColor,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TEAM DHANRAKSHAK',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: tp.textColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}