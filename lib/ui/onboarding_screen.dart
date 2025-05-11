import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key}); // Ensure the constructor is marked as 'const'

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: [
              const OnboardingPage(
                image: Icons.tune,
                title: "Gain total control of your money",
                description: "Become your own money manager and make every cent count.",
              ),
              const OnboardingPage(
                image: Icons.account_balance_wallet,
                title: "Know where your money goes",
                description: "Track your transactions easily with categories and financial reports.",
              ),
              OnboardingPage(
                image: Icons.checklist,
                title: "Planning ahead",
                description: "Setup your budget for each category so you're in control.",
                showButtons: true,
                onSignUp: () {
                  Navigator.pushNamed(context, '/signup');
                },
                onLogin: () {
                  Navigator.pushNamed(context, '/login');
                },
              ),
            ],
          ),
          if (_currentPage == 2)
            Positioned(
              bottom: 80,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF053F5C),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Sign Up", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,color: Colors.white)),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF053F5C)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF053F5C))),
                  ),
                ],
              ),
            ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => buildDot(index)),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 10,
      width: _currentPage == index ? 20 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFF053F5C) : Colors.grey,
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final IconData image;
  final String title;
  final String description;
  final VoidCallback? onSignUp;
  final VoidCallback? onLogin;
  final bool showButtons;

  const OnboardingPage({super.key,
    required this.image,
    required this.title,
    required this.description,
    this.onSignUp,
    this.onLogin,
    this.showButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(image, size: 150, color: const Color(0xFF053F5C)),
          const SizedBox(height: 30),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

