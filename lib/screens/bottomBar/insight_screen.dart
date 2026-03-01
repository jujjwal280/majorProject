import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:start1/providers/prediction_provider.dart';
import 'package:start1/providers/theme_provider.dart'; // Import for theme access

// Design Constants
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);
const Color cardBlue = Color(0xFF1E5C78);

class FutureInsightScreen extends StatefulWidget {
  const FutureInsightScreen({super.key});

  @override
  State<FutureInsightScreen> createState() => _FutureInsightScreenState();
}

class _FutureInsightScreenState extends State<FutureInsightScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerPredictionAPI() async {
    setState(() { _isLoading = true; });
    HapticFeedback.selectionClick();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showStatusSnackbar("❌ No user logged in.", accentOrange);
      setState(() { _isLoading = false; });
      return;
    }

    try {
      final idToken = await user.getIdToken();
      final url = Uri.parse('https://ec7e20d3-e5ba-40e2-845e-187b9f5b8daf-00-eorlqbv9c1kw.sisko.replit.dev/predict');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({}),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final double? newPredictionValue = (responseData['predicted_expense'] as num?)?.toDouble();

        if (mounted) {
          Provider.of<PredictionProvider>(context, listen: false).updatePrediction(newPredictionValue);
          _showStatusSnackbar("✅ Forecast Synced!", accentOrange);
        }
      } else {
        _showStatusSnackbar("❌ API Error ${response.statusCode}", accentOrange);
      }
    } on TimeoutException {
      _showStatusSnackbar("🔥 Request timed out. Server is busy.", accentOrange);
    } on SocketException {
      _showStatusSnackbar("🔥 Check your internet connection.", accentOrange);
    } catch (e) {
      _showStatusSnackbar("🔥 Error: $e", accentOrange);
    }

    setState(() { _isLoading = false; });
  }

  void _showStatusSnackbar(String message, Color bgColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: bgColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the global theme provider
    final tp = Provider.of<ThemeProvider>(context);
    final predictionProvider = Provider.of<PredictionProvider>(context);
    final nextMonth = DateFormat('MMMM').format(DateTime(DateTime.now().year, DateTime.now().month + 1));
    final predictedExpense = predictionProvider.predictedExpense;

    return Scaffold(
      // FIX: Set to transparent so it inherits the background from HomeScreen's Scaffold
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: accentOrange,
        onRefresh: _triggerPredictionAPI,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 10),
            // HEADER UPDATED WITH DYNAMIC COLOR
            _buildHeader(tp),
            const SizedBox(height: 30),

            // THE AI PREDICTION CARD (Stays Dark/Navy for Premium Vault look)
            _buildPredictionCard(nextMonth, predictedExpense),

            const SizedBox(height: 40),

            // INSIGHT TIP UPDATED WITH DYNAMIC CARD COLOR
            if (predictedExpense != null) _buildInsightAnalysis(predictedExpense, tp),

            const SizedBox(height: 40),

            // ACTION BUTTON
            _buildForecastButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider tp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.auto_awesome, color: accentOrange, size: 20),
            SizedBox(width: 8),
            Text("AI FORECAST", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Future Wealth Insight",
          // tp.textColor adapts to dark/light mode automatically
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor),
        ),
      ],
    );
  }

  Widget _buildPredictionCard(String month, double? value) {
    // We keep the navy gradient card here because it acts as a brand anchor
    // that looks good in both Light and Dark modes.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, cardBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Expected in $month",
            style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? _buildLoadingState()
              : (value != null
              ? Text(
            "₹${value.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
          )
              : const Text(
            "Data Pending",
            style: TextStyle(color: Colors.white54, fontSize: 18),
          )),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.query_stats_rounded, color: accentOrange, size: 18),
                SizedBox(width: 8),
                Text("94% AI Accuracy", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return FadeTransition(
      opacity: _pulseController,
      child: const Column(
        children: [
          CircularProgressIndicator(color: accentOrange, strokeWidth: 3),
          SizedBox(height: 15),
          Text("Analyzing patterns...", style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInsightAnalysis(double value, ThemeProvider tp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Adapts from white to dark surface automatically
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: tp.isDarkMode ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            // Subtle circle background adapts to theme
            backgroundColor: tp.isDarkMode ? Colors.white10 : const Color(0xFFF0F4F7),
            child: Icon(Icons.lightbulb_outline_rounded, color: tp.isDarkMode ? accentOrange : primaryDark),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("AI Strategy", style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor)),
                Text(
                  "Based on your trends, expect ₹${(value * 0.1).toStringAsFixed(0)} in unplanned costs.",
                  style: TextStyle(color: tp.subTextColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastButton() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [primaryDark, Color(0xFF11698E)]),
        boxShadow: [
          BoxShadow(color: primaryDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _triggerPredictionAPI,
        icon: const Icon(Icons.psychology_rounded, color: Colors.white),
        label: const Text(
          "RE-CALCULATE FORECAST",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}