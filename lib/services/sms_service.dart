import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class ParsedTransaction {
  final double amount;
  final String merchant;
  final String type;
  const ParsedTransaction({required this.amount, required this.merchant, required this.type});
}

String normalizeUnicode(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) { buffer.write(_runeToAscii(rune)); }
  return buffer.toString();
}

String _runeToAscii(int r) {
  if (r >= 0x1D5A0 && r <= 0x1D5B9) return String.fromCharCode(r - 0x1D5A0 + 65);
  if (r >= 0x1D5BA && r <= 0x1D5D3) return String.fromCharCode(r - 0x1D5BA + 97);
  if (r >= 0x1D400 && r <= 0x1D419) return String.fromCharCode(r - 0x1D400 + 65);
  if (r >= 0x1D41A && r <= 0x1D433) return String.fromCharCode(r - 0x1D41A + 97);
  if (r >= 0x1D7E2 && r <= 0x1D7EB) return String.fromCharCode(r - 0x1D7E2 + 48);
  if (r >= 0x1D7CE && r <= 0x1D7D7) return String.fromCharCode(r - 0x1D7CE + 48);
  return String.fromCharCode(r);
}

const List<String> _bankSenderKeywords = [
  'pnb', 'sbi', 'hdfc', 'icici', 'axis', 'kotak', 'bob', 'canara',
  'union', 'yes', 'indusind', 'federal', 'idbi', 'idfc', 'rbl',
  'paytm', 'phonepe', 'gpay', 'airtel', 'bank', 'upi',
];

bool _isBankSender(String sender) {
  final s = sender.toLowerCase();
  return _bankSenderKeywords.any(s.contains);
}

class _SmsPattern {
  final RegExp regex;
  final int amountGroup;
  final int merchantGroup;
  final String merchantFallback;
  const _SmsPattern({required this.regex, required this.amountGroup, required this.merchantGroup, this.merchantFallback = 'Bank Transfer'});
}

final List<_SmsPattern> _debitPatterns = [
  _SmsPattern(regex: RegExp(r'A/c\s+\w+\s+debited\s+INR\s*([\d,]+\.?\d*).*?thru\s+(UPI:\d+)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'PNB UPI'),
  _SmsPattern(regex: RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)\s+debited.*?to\s+VPA\s+([A-Za-z0-9@._\-]{3,60})', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'HDFC Transfer'),
  _SmsPattern(regex: RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)\s+debited.*?Info:\s*([A-Za-z0-9@._\- ]{3,50}?)(?:\s+UPI|\s+Ref|\.|$)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'HDFC Transfer'),
  _SmsPattern(regex: RegExp(r'debited\s+for\s+(?:Rs\.?|INR)\s*([\d,]+\.?\d*).*?(?:trf\s+to|transfer\s+to)\s+([A-Za-z][A-Za-z0-9 @._\-]{2,40}?)(?:\s+Ref|\s+UPI|\.|$)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'ICICI Transfer'),
  _SmsPattern(regex: RegExp(r'INR\s*([\d,]+\.?\d*)\s+debited.*?Info:\s*([A-Za-z0-9@._\- ]{3,50}?)(?:\s+UPI|\s+Ref|\.|$)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'Axis Transfer'),
  _SmsPattern(regex: RegExp(r'(?:Rs\.?|INR)\s*([\d,]+\.?\d*)\s+sent.*?to\s+(?:VPA\s+)?([A-Za-z0-9@._\-]{3,60})', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'Kotak Transfer'),
  _SmsPattern(regex: RegExp(r'debited\s+(?:by\s+)?(?:Rs\.?|INR)\s*([\d,]+\.?\d*).*?(?:transfer\s+to|trf\s+to)\s+([A-Za-z][A-Za-z0-9 @._\-]{2,40}?)(?:\.|Ref|Avl|$)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'SBI Transfer'),
  _SmsPattern(regex: RegExp(r'debited\s+INR\s*([\d,]+\.?\d*).*?for\s+(?:UPI/)?([A-Za-z][A-Za-z0-9@._\- /]{2,50}?)(?:\s*\.|Ref|$)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'Bank Transfer'),
  _SmsPattern(regex: RegExp(r'INR\s*([\d,]+\.?\d*).*?(?:has been )?debited.*?for\s+([A-Za-z][A-Za-z0-9 @._\-]{2,50}?)(?:\s+on\s|\.|$)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'Bank Transfer'),
  _SmsPattern(regex: RegExp(r'(?:card|txn).*?(?:Rs\.?|INR)\s*([\d,]+\.?\d*).*?at\s+([A-Za-z][A-Za-z0-9 ,._\-]{2,50}?)(?:\s+on\s|\s+Dt|\.|$)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'Card Payment'),
  _SmsPattern(regex: RegExp(r'spent\s+(?:Rs\.?|INR)\s*([\d,]+\.?\d*)\s+(?:at|on|for)\s+([A-Za-z][A-Za-z0-9 ,._\-]{2,50}?)(?:\s+on\s|\s+using|\.|$)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'Payment'),
  _SmsPattern(regex: RegExp(r'[Tt]ransaction\s+(?:of\s+)?(?:Rs\.?|INR)\s*([\d,]+\.?\d*)\s+(?:at|to|for)\s+([A-Za-z][A-Za-z0-9 ,._\-]{2,50}?)(?:\.|,|\s+Ref)', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'UPI Payment'),
  _SmsPattern(regex: RegExp(r'(?:debited|debit).*?(?:Rs\.?|INR)\s*([\d,]+\.?\d*).*?UPI[:/](\d{8,})', caseSensitive: false), amountGroup: 1, merchantGroup: 2, merchantFallback: 'UPI Transfer'),
  _SmsPattern(regex: RegExp(r'(?:debited|debit(?:ed)?)\D{0,30}?(?:Rs\.?|INR)\s*([\d,]+\.?\d*)', caseSensitive: false), amountGroup: 1, merchantGroup: 0, merchantFallback: 'Bank Debit'),
];

bool _isDebitSms(String normalizedBody) {
  final lower = normalizedBody.toLowerCase();
  const debitKeywords = ['debited', 'debit', 'spent', 'withdrawn', 'payment of', 'paid', 'purchase', 'transaction of'];
  if (!debitKeywords.any(lower.contains)) return false;
  const noiseWords = ['otp', 'one time password', 'password is', 'verification code'];
  if (noiseWords.any(lower.contains)) return false;
  if (!RegExp(r'(?:rs\.?|inr)\s*[\d,]+', caseSensitive: false).hasMatch(lower)) return false;
  return true;
}

ParsedTransaction? parseSmsBody(String rawBody) {
  final body = normalizeUnicode(rawBody);
  if (!_isDebitSms(body)) return null;
  for (final p in _debitPatterns) {
    final match = p.regex.firstMatch(body);
    if (match == null) continue;
    try {
      final amountStr = match.group(p.amountGroup)!.replaceAll(',', '');
      final amount = double.parse(amountStr);
      if (amount <= 0) continue;
      String merchant;
      if (p.merchantGroup == 0 || match.groupCount < p.merchantGroup) {
        merchant = p.merchantFallback;
      } else {
        final raw = match.group(p.merchantGroup)?.trim() ?? '';
        merchant = raw.isEmpty ? p.merchantFallback : _cleanMerchant(raw);
      }
      return ParsedTransaction(amount: amount, merchant: merchant, type: 'debit');
    } catch (_) { continue; }
  }
  return null;
}

String _cleanMerchant(String raw) {
  var clean = raw.replaceAll(RegExp(r'\s+'), ' ').trim().replaceAll(RegExp(r'[.,;:]+$'), '');
  const noiseEndings = ['bal', 'balance', 'ref', 'reference', 'avl', 'available', 'not u', 'fwd', 'download'];
  for (final noise in noiseEndings) {
    final idx = clean.toLowerCase().lastIndexOf(' $noise');
    if (idx > 2) clean = clean.substring(0, idx).trim();
  }
  return clean.isEmpty ? 'Unknown Merchant' : clean;
}

String guessCategory(String merchant) {
  final m = merchant.toLowerCase();
  const Map<String, List<String>> map = {
    'Food & Dining':  ['swiggy', 'zomato', 'domino', 'pizza', 'restaurant', 'cafe', 'mcdonald', 'kfc', 'burger', 'subway', 'food', 'biryani', 'dhaba', 'eat', 'kitchen'],
    'Groceries':      ['bigbasket', 'blinkit', 'grofer', 'dmart', 'reliance fresh', 'grocery', 'kirana', 'vegetables'],
    'Transport':      ['uber', 'ola', 'rapido', 'metro', 'irctc', 'railway', 'bus', 'redbus', 'petrol', 'fuel', 'indigo', 'spicejet', 'air india', 'vistara', 'fastag', 'toll'],
    'Shopping':       ['amazon', 'flipkart', 'myntra', 'ajio', 'nykaa', 'meesho', 'snapdeal', 'tatacliq', 'croma', 'decathlon'],
    'Entertainment':  ['netflix', 'hotstar', 'primevideo', 'youtube', 'spotify', 'jio cinema', 'bookmyshow', 'pvr', 'inox'],
    'Utilities':      ['electricity', 'bescom', 'tata power', 'water bill', 'gas', 'indane', 'broadband', 'airtel', 'jio', 'bsnl', 'vodafone', 'mobile recharge', 'internet'],
    'Health':         ['pharmacy', 'medical', 'hospital', 'clinic', 'doctor', 'apollo', 'medplus', 'netmeds', '1mg'],
    'Education':      ['school', 'college', 'university', 'byju', 'unacademy', 'vedantu', 'udemy', 'fees', 'tuition'],
    'Finance':        ['emi', 'loan', 'insurance', 'lic', 'sip', 'mutual fund', 'zerodha', 'groww', 'upstox'],
    'UPI Transfer':   ['upi:', 'upi/', '@okaxis', '@okicici', '@okhdfcbank', '@ybl', '@paytm', '@ibl', '@sbi', 'phonepe', 'gpay', 'google pay', 'paytm'],
  };
  for (final entry in map.entries) {
    if (entry.value.any(m.contains)) return entry.key;
  }
  return 'Other';
}

class SmsImportService {
  final SmsQuery _smsQuery = SmsQuery();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> getAndProcessSms(BuildContext context) async {
    var status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
      if (!status.isGranted) { _snack(context, '❌ SMS permission required.'); return; }
    }

    _snack(context, '🔄 Syncing from SMS…');

    try {
      final user = _auth.currentUser;
      if (user == null) { _snack(context, '❌ Not logged in.'); return; }

      final txRef = _firestore.collection('users').doc(user.uid).collection('transactions');
      final existing = await txRef.where('smsId', isNotEqualTo: null).get();
      final importedIds = existing.docs.map((d) => d.data()['smsId'] as String?).whereType<String>().toSet();

      final messages = await _smsQuery.querySms(kinds: [SmsQueryKind.inbox], count: 1000);

      // ── DEBUG: show all bank SMS with filter + parse result ──
      debugPrint('📱 Total SMS read: ${messages.length}');
      final bankMessages = messages.where((m) => m.sender != null && _isBankSender(m.sender!)).toList();
      debugPrint('🏦 Bank SMS found: ${bankMessages.length}');
      for (final msg in bankMessages) {
        final normalized = normalizeUnicode(msg.body ?? '');
        final passedFilter = _isDebitSms(normalized);
        final parsed = parseSmsBody(msg.body ?? '');
        debugPrint('---');
        debugPrint('FROM   : ${msg.sender}');
        debugPrint('NORM   : ${normalized.substring(0, normalized.length.clamp(0, 120))}');
        debugPrint('FILTER : ${passedFilter ? "✅ passed" : "❌ blocked by filter"}');
        debugPrint('PARSED : ${parsed != null ? "✅ Rs${parsed.amount} | ${parsed.merchant}" : "❌ no pattern matched"}');
      }
      // ── END DEBUG ──

      int added = 0;
      final batch = _firestore.batch();

      for (final msg in messages) {
        final body = msg.body; final sender = msg.sender; final date = msg.date;
        if (body == null || sender == null || date == null) continue;
        final smsId = '${sender}_${date.millisecondsSinceEpoch}';
        if (importedIds.contains(smsId)) continue;
        final parsed = parseSmsBody(body);
        if (parsed == null) continue;
        final month = DateFormat('MMMM').format(date);
        final week = 'Week ${((date.day - 1) ~/ 7) + 1}';
        final day = DateFormat('yyyy-MM-dd').format(date);
        batch.set(txRef.doc(), {
          'amount': parsed.amount, 'type': parsed.type,
          'category': guessCategory(parsed.merchant),
          'description': parsed.merchant,
          'date': Timestamp.fromDate(date), 'smsId': smsId, 'sender': sender,
          'month': month, 'week': week, 'day': day, 'year': date.year,
          'source': 'sms', 'importedAt': FieldValue.serverTimestamp(),
        });
        added++;
      }

      if (added > 0) {
        await batch.commit();
        _snack(context, '✅ Added $added new transaction${added == 1 ? '' : 's'}!');
      } else {
        _snack(context, '👍 No new transactions found.');
      }
    } catch (e, st) {
      debugPrint('SmsImportService error: $e\n$st');
      _snack(context, '🔥 Error: $e');
    }
  }

  void _snack(BuildContext context, String msg) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}