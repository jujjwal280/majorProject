import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashServices {

  void checkAuthentication(BuildContext context) async {

    await Future.delayed(const Duration(seconds: 2));

    FirebaseAuth.instance.authStateChanges().first.then((user) {

      if (!context.mounted) return;

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/onboard');
      }

    });
  }
}