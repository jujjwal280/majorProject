import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:start1/auth/signup_screen.dart';
import 'package:start1/screens/home_screen.dart';
import 'package:start1/screens/profile_screen.dart';
import 'package:start1/screens/transactions_screen.dart';
import 'package:start1/ui/onboarding_screen.dart';
import 'package:start1/ui/splash_screen.dart';
import 'package:start1/auth/login_screen.dart';
import 'package:start1/firebase_options.dart';
import 'package:start1/ui/notification_services.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print("Background Notification Received: ${message.notification?.title}");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/onboard': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/dashboard': (context) => const HomeScreen(),
        '/transactions': (context) => const TransactionsScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}
