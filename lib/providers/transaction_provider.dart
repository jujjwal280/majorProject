import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionProvider with ChangeNotifier {
  double monthExpenses = 0.0;
  Map<String, double> categoryExpenses = {};

  TransactionProvider() {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .where('date', isGreaterThanOrEqualTo: startOfMonth)
            .where('date', isLessThan: endOfMonth)
            .get();

        double total = 0;
        Map<String, double> tempCategoryExpenses = {};
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['amount'] as num).toDouble();
          final category = data['category'] as String;
          total += amount;
          tempCategoryExpenses.update(category, (value) => value + amount, ifAbsent: () => amount);
        }

        monthExpenses = total;
        categoryExpenses = tempCategoryExpenses;
        notifyListeners();
      } catch (e) {
        print("Error fetching expenses: $e");
      }
    }
  }
}
