import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionProvider with ChangeNotifier {
  double? predictedExpense;

  PredictionProvider() {
    fetchPredictedExpense();
  }

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
          predictedExpense = (doc.data()!['predicted_expense'] as num?)?.toDouble();
          notifyListeners();
        }
      } catch (e) {
        print("Error fetching initial prediction: $e");
      }
    }
  }

  void updatePrediction(double? newPrediction) {
    predictedExpense = newPrediction;
    notifyListeners();
  }
}

