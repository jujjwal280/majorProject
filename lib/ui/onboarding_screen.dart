import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart'; // Ensure correct path

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Brand Colors (Moved to local scope for internal highlights)
  final Color primaryDark = const Color(0xFF053F5C);
  final Color accentOrange = const Color(0xFFF27F0C);

  // Data for Onboarding
  final List<Map<String, dynamic>> onboardingData = [
    {
      "title": "Total Control",
      "desc": "Become your own money manager and make every cent count.",
      "icon": Icons.tune_rounded,
    },
    {
      "title": "Know Where It Goes",
      "desc": "Track your transactions easily with categories and reports.",
      "icon": Icons.account_balance_wallet_rounded,
    },
    {
      "title": "Planning Ahead",
      "desc": "Setup your budget for each category so you're in control.",
      "icon": Icons.checklist_rounded,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // FIX: Use Global Background Color from Provider
      backgroundColor: tp.scaffoldBg,
      body: Stack(
        children: [
          // 1. Top Decorative Background (Adapts to Theme)
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            // Light blue tint in Light mode, Darker Navy tint in Dark mode
            color: tp.isDarkMode ? primaryDark.withOpacity(0.2) : const Color(0xFFE0F7FA),
            height: MediaQuery.of(context).size.height * 0.6,
          ),

          SafeArea(
            child: Column(
              children: [
                // 2. Header with Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentPage != 2)
                        TextButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _pageController.animateToPage(2,
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutExpo);
                          },
                          child: Text(
                            "SKIP",
                            style: TextStyle(
                              color: tp.textColor, // FIX: Theme Aware
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // 3. Floating Illustration Area
                Expanded(
                  flex: 3,
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                      HapticFeedback.selectionClick();
                    },
                    itemCount: onboardingData.length,
                    itemBuilder: (context, index) {
                      return _buildParallaxIllustration(index, tp);
                    },
                  ),
                ),

                // 4. Content Card (Adapts to surface color)
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: tp.cardColor, // FIX: Theme Aware (White to SurfaceDark)
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(50),
                      topRight: Radius.circular(50),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tp.isDarkMode ? Colors.black45 : Colors.black12,
                        blurRadius: 30,
                        offset: const Offset(0, -10),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        // Animated Indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (index) => _buildDot(index)),
                        ),
                        const SizedBox(height: 35),

                        // Animated Text
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            child: Column(
                              key: ValueKey<int>(_currentPage),
                              children: [
                                Text(
                                  onboardingData[_currentPage]['title'],
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: tp.textColor, // FIX: Theme Aware
                                  ),
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  onboardingData[_currentPage]['desc'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: tp.subTextColor, // FIX: Theme Aware
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 5. Action Button
                        _buildActionArea(tp),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParallaxIllustration(int index, ThemeProvider tp) {
    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        double value = 1.0;
        if (_pageController.position.haveDimensions) {
          value = _pageController.page! - index;
          value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
        }
        return Center(
          child: Transform.scale(
            scale: value,
            child: Container(
              height: 240,
              width: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tp.cardColor.withOpacity(0.9), // FIX: Theme Aware
                boxShadow: [
                  BoxShadow(
                    color: tp.isDarkMode ? Colors.black54 : primaryDark.withOpacity(0.1),
                    blurRadius: 40,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Icon(
                onboardingData[index]['icon'],
                size: 100,
                color: accentOrange,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionArea(ThemeProvider tp) {
    bool isLastPage = _currentPage == 2;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: isLastPage
          ? Column(
        key: const ValueKey("get_started"),
        children: [
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/signup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 18),
              minimumSize: const Size(double.infinity, 0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              shadowColor: primaryDark.withOpacity(0.4),
            ),
            child: const Text(
              "START YOUR JOURNEY",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            child: RichText(
              text: TextSpan(
                text: "Already protected? ",
                style: TextStyle(color: tp.subTextColor), // FIX: Theme Aware
                children: [
                  TextSpan(
                    text: "Login",
                    style: TextStyle(color: tp.isDarkMode ? accentOrange : primaryDark, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
          : Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: tp.subTextColor.withOpacity(0.2), width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: tp.isDarkMode ? accentOrange : primaryDark, // FIX: More vibrant in dark mode
              radius: 30,
              child: Icon(Icons.arrow_forward_ios_rounded, color: tp.isDarkMode ? primaryDark : Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: _currentPage == index ? 28 : 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? accentOrange : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}