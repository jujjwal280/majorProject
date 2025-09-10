import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDataProvider with ChangeNotifier {
  String? username;
  String? accountNumber;
  String? bankName;
  bool isAdmin = false;

  UserDataProvider() {
    fetchUserDetails();
  }

  Future<void> fetchUserDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          username = data['username'] ?? 'User Name';
          accountNumber = data['account_number'] ?? 'Account Number';
          bankName = data['bank_name'] ?? 'Bank Name';
          isAdmin = data['isAdmin'] ?? false;
          notifyListeners(); // Notify widgets that data has changed
        }
      } catch (e) {
        print("Error fetching user details: $e");
      }
    }
  }
}

