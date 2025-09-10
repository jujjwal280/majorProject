import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionProvider with ChangeNotifier {
  double? predictedExpense;

  PredictionProvider() {
    // Fetch the initial value when the provider is first created.
    fetchPredictedExpense();
  }

  /// Fetches the last known prediction from Firestore.
  /// This is useful for showing data immediately when the app starts.
  Future<void> fetchPredictedExpense() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('prediction')
            .doc('next_month')
            .get();

        if (doc.exists) {
          // Safely cast the value from Firestore to a double.
          predictedExpense = (doc.data()!['predicted_expense'] as num?)?.toDouble();
          notifyListeners(); // Notify listening widgets to update.
        }
      } catch (e) {
        print("Error fetching initial prediction: $e");
      }
    }
  }

  /// Updates the state with a new value received from the API response.
  /// This is called from the FutureInsightScreen to avoid race conditions.
  void updatePrediction(double? newPrediction) {
    predictedExpense = newPrediction;
    notifyListeners(); // Notify listening widgets to update with the new value.
  }
}

