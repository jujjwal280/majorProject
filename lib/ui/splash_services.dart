import 'package:flutter/material.dart';
import 'package:start1/screens/home_screen.dart';
import 'package:start1/ui/onboarding_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashServices {
  Future<bool> isAuthenticated() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user != null;
  }

  void checkAuthentication(BuildContext context) async {
    await Future.delayed(const Duration(seconds: 3));
    bool loggedIn = await isAuthenticated();
    if (loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen(toggleDarkMode: () {  }, isDarkMode: false,)),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }
}
