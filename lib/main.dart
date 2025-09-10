import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:start1/auth/signup_screen.dart';
import 'package:start1/screens/home_screen.dart';
import 'package:start1/screens/drawer/profile_screen.dart';
import 'package:start1/screens/drawer/transactions_screen.dart';
import 'package:start1/providers/theme_provider.dart';
import 'package:start1/providers/user_data_provider.dart';
import 'package:start1/providers/transaction_provider.dart';
import 'package:start1/providers/prediction_provider.dart';
import 'package:start1/ui/onboarding_screen.dart';
import 'package:start1/ui/splash_screen.dart';
import 'package:start1/auth/login_screen.dart';
import 'package:start1/firebase_options.dart';
import 'package:start1/ui/notification_services.dart';
import 'screens/bottomBar/insight_screen.dart';
import 'screens/bottomBar/notification_screen.dart';
import 'screens/drawer/admin_screen.dart';
import 'screens/drawer/feedback_screen.dart';

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
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserDataProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => PredictionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'MoneyMinder',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF053F5C),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF429EBD),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/onboard': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/home': (context) => const HomeScreen(),
            '/insight': (context) => const FutureInsightScreen(),
            '/notify': (context) => NotificationScreen(),
            '/transactions': (context) => const TransactionsScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/feedback': (context) => const FeedbackScreen(),
            '/admin': (context) => const AdminScreen(),
          },
        );
      },
    );
  }
}
