import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FutureInsightScreen extends StatefulWidget {
  final String? username;
  final double? predictedExpense;
  final String? nextMonth;

  const FutureInsightScreen({
    super.key,
    this.username,
    required this.predictedExpense,
    required this.nextMonth,
  });

  @override
  State<FutureInsightScreen> createState() => _FutureInsightScreenState();
}

class _FutureInsightScreenState extends State<FutureInsightScreen> {
  double? predictedExpense;
  String? nextMonth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    predictedExpense = widget.predictedExpense;
    nextMonth = widget.nextMonth;
    loadPredictedExpense();
  }

  Future<void> loadPredictedExpense() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? storedExpense = prefs.getDouble('predictedExpense');
    if (storedExpense != null) {
      setState(() {
        predictedExpense = storedExpense;
      });
    }
  }

  Future<void> triggerPredictionAPI() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        showSnackbar("❌ No user logged in.");
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://ae60f539-d299-4b88-af7e-d19af12b951d-00-3b1kce09qe2qk.sisko.replit.dev/predict',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'uid': user.uid}),
      );

      if (response.statusCode == 200) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('prediction')
            .doc('next_month')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final newPredictedExpense = data['predicted_expense']?.toDouble();
          setState(() {
            predictedExpense = newPredictedExpense;
          });

          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setDouble('predictedExpense', predictedExpense ?? 0.0);
        }
      } else {
        if (kDebugMode) {
          showSnackbar("❌ Prediction API failed: ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        showSnackbar("🔥 Error calling prediction API: $e");
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: const Color(0xFF053F5C),
        onRefresh: triggerPredictionAPI,
        child: ListView(
          padding: const EdgeInsets.all(10.0),
          children: [
            const SizedBox(height: 5),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Predicted Value!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Card(
              elevation: 8,
              color: const Color(0xFFF5F5F5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: Text(
                        "$nextMonth's Expenditure",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF053F5C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    predictedExpense != null
                        ? Text(
                      "₹${predictedExpense!.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    )
                        : Text(
                      "Not enough data to predict 💤",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Push down to refresh",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
            ),
            const SizedBox(height: 450),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                "📝 To get your predicted expense, make sure you’ve added transactions for at least 2 months.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Column(
            //   children: widget.categoryExpenses.entries.map((entry) {
            //     return Card(
            //       color: categoryColors[entry.key] ?? Colors.grey,
            //       elevation: 4,
            //       margin: const EdgeInsets.symmetric(vertical: 8),
            //       child: ListTile(
            //         leading: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF053F5C)),
            //         title: Text(
            //           entry.key,
            //           style: const TextStyle(
            //             fontSize: 18,
            //             fontWeight: FontWeight.bold,
            //             color: Color(0xFF053F5C),
            //           ),
            //         ),
            //         trailing: Text(
            //           "₹${entry.value.toStringAsFixed(2)}",
            //           style: const TextStyle(
            //             fontSize: 15,
            //             fontWeight: FontWeight.bold,
            //             color: Colors.black,
            //           ),
            //         ),
            //       ),
            //     );
            //   }).toList(),
            // )
          ],
        ),
      ),
    );
  }
}