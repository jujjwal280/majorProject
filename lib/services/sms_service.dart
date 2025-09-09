import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart'; // Import the intl package for date formatting
import 'package:permission_handler/permission_handler.dart';

class SmsImportService {
  final SmsQuery _smsQuery = SmsQuery();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> getAndProcessSms(BuildContext context) async {
    // ... (Permission logic, duplicate check, and SMS reading logic are unchanged) ...
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) {
        _showSnackbar(context, "❌ SMS permission is required.");
        return;
      }
    }
    _showSnackbar(context, "🔄 Syncing transactions from SMS...");
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        _showSnackbar(context, "❌ User not logged in.");
        return;
      }
      final transactionsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('transactions');
      final existingTransactions = await transactionsRef.where('smsId', isNotEqualTo: null).get();
      final importedSmsIds = existingTransactions.docs
          .map((doc) => doc.data()['smsId'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      final messages = await _smsQuery.querySms(
        kinds: [SmsQueryKind.inbox],
        count: 200,
      );
      int transactionsAdded = 0;
      final WriteBatch batch = _firestore.batch();
      for (final message in messages) {
        final smsBody = message.body;
        final sender = message.sender;
        final date = message.date;
        if (smsBody == null || sender == null || date == null) continue;
        final smsId = '${sender}_${date.millisecondsSinceEpoch}';
        if (importedSmsIds.contains(smsId)) {
          continue;
        }
        final transactionData = _parseSmsBody(smsBody);
        if (transactionData != null) {
          final docRef = transactionsRef.doc();

          // --- THE FIX ---
          // Calculate the month, week, and day from the SMS date
          String month = DateFormat('MMMM').format(date);
          int weekOfMonth = ((date.day - 1) ~/ 7) + 1;
          String day = DateFormat('yyyy-MM-dd').format(date);
          // --- END FIX ---

          batch.set(docRef, {
            'amount': transactionData['amount'],
            'category': 'Other',
            'description': transactionData['merchant'],
            'date': Timestamp.fromDate(date),
            'smsId': smsId,

            // --- THE FIX ---
            // Add the new fields for consistency
            'month': month,
            'week': 'Week $weekOfMonth',
            'day': day,
            // --- END FIX ---
          });
          transactionsAdded++;
        }
      }
      if (transactionsAdded > 0) {
        await batch.commit();
        _showSnackbar(context, "✅ Successfully added $transactionsAdded new transactions!");
      } else {
        _showSnackbar(context, "👍 No new debit transactions found.");
      }
    } catch (e) {
      _showSnackbar(context, "🔥 Error reading SMS: $e");
    }
  }

  Map<String, dynamic>? _parseSmsBody(String body) {
    // ... (Parsing logic is unchanged) ...
    final patterns = [
      RegExp(r'debited INR\s*([\d,]+\.?\d*).*thru\s(.+?)\.'),
      RegExp(r'Debited by Rs\.?\s*([\d,]+\.?\d*).*to\s(.+?)\s'),
      RegExp(r'Transaction of INR\s*([\d,]+\.?\d*)\s*at\s(.+?)\s'),
      RegExp(r'spent Rs\s*([\d,]+\.?\d*)\s*at\s(.+?)\s'),
    ];
    for (var pattern in patterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        try {
          final amountStr = match.group(1)!.replaceAll(',', '');
          final amount = double.parse(amountStr);
          final merchant = match.group(2)!.trim();
          return {'amount': amount, 'merchant': merchant};
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

