import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// One point in the historical-vs-predicted series shown on the chart.
class MonthlyPoint {
  final String label; // e.g. "May"
  final DateTime month;
  final double actual;

  const MonthlyPoint({
    required this.label,
    required this.month,
    required this.actual,
  });
}

/// Full output of a prediction run. Every field is computed from the
/// user's actual transactions -- nothing here is hardcoded.
class PredictionResult {
  final bool hasSufficientData;
  final double predictedTotal;
  final double currentMonthTotal;
  final double lastCompleteMonthTotal;
  final double percentChange; // vs the last completed month
  final Map<String, double> categoryPredictions;
  final List<double> weeklyPredictions; // 5 slots: W1..W5
  final List<MonthlyPoint> history; // completed months, oldest -> newest
  final int confidence; // 0-100
  final String reasonText;
  final double? backtestErrorPercent; // avg % error from backtesting, null if not enough data

  const PredictionResult({
    required this.hasSufficientData,
    required this.predictedTotal,
    required this.currentMonthTotal,
    required this.lastCompleteMonthTotal,
    required this.percentChange,
    required this.categoryPredictions,
    required this.weeklyPredictions,
    required this.history,
    required this.confidence,
    required this.reasonText,
    this.backtestErrorPercent,
  });

  factory PredictionResult.insufficient({
    required double currentMonthTotal,
    required List<MonthlyPoint> history,
  }) {
    return PredictionResult(
      hasSufficientData: false,
      predictedTotal: 0,
      currentMonthTotal: currentMonthTotal,
      lastCompleteMonthTotal: history.isNotEmpty ? history.last.actual : 0,
      percentChange: 0,
      categoryPredictions: const {},
      weeklyPredictions: const [],
      history: history,
      confidence: 0,
      reasonText: 'Add more expense history to improve prediction accuracy.',
    );
  }
}

/// Computes a next-month expense forecast purely from the user's own
/// transaction history in Firestore. Deliberately buckets everything by
/// each transaction's own `date` field rather than relying on stored
/// month/week/day strings, since manually-added transactions don't always
/// have those fields populated the way SMS-imported ones do.
class ExpensePredictionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _monthsOfHistory = 6;
  static const List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  Future<PredictionResult> generate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('No authenticated user.');
    }

    final now = DateTime.now();
    final rangeStart = DateTime(now.year, now.month - _monthsOfHistory, 1);

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(rangeStart))
        .orderBy('date')
        .get();

    final Map<String, double> monthTotals = {}; // key: "yyyy-M"
    final Map<String, Map<String, double>> monthCategoryTotals = {};
    final Map<String, double> currentMonthWeekTotals = {}; // key: 'w1'..'w5'
    double currentMonthTotal = 0;

    String monthKey(DateTime d) => '${d.year}-${d.month}';

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final ts = data['date'];
      final amountRaw = data['amount'];
      if (ts is! Timestamp || amountRaw is! num) continue;

      final date = ts.toDate();
      final amount = amountRaw.toDouble();
      final rawCategory = data['category'];
      final category = (rawCategory is String && rawCategory.trim().isNotEmpty)
          ? rawCategory.trim()
          : 'Other';

      final key = monthKey(date);
      monthTotals.update(key, (v) => v + amount, ifAbsent: () => amount);
      monthCategoryTotals.putIfAbsent(key, () => {});
      monthCategoryTotals[key]!
          .update(category, (v) => v + amount, ifAbsent: () => amount);

      if (date.year == now.year && date.month == now.month) {
        currentMonthTotal += amount;
        final weekIndex = ((date.day - 1) ~/ 7) + 1; // 1..5
        currentMonthWeekTotals.update(
          'w$weekIndex',
              (v) => v + amount,
          ifAbsent: () => amount,
        );
      }
    }

    // Ordered list of the last N *completed* months (current month excluded
    // since it's still in progress).
    final completedMonths = <DateTime>[
      for (int i = _monthsOfHistory; i >= 1; i--)
        DateTime(now.year, now.month - i, 1),
    ];
    final history = completedMonths
        .map((m) => MonthlyPoint(
      label: _monthLabels[m.month - 1],
      month: m,
      actual: monthTotals[monthKey(m)] ?? 0,
    ))
        .where((p) => p.actual > 0) // skip months with no activity at all
        .toList();

    if (history.length < 2) {
      return PredictionResult.insufficient(
        currentMonthTotal: currentMonthTotal,
        history: history,
      );
    }

    // --- Weighted moving average over the most recent up-to-3 months ---
    final recent =
    history.length >= 3 ? history.sublist(history.length - 3) : history;
    final List<double> weights = recent.length == 3
        ? [0.2, 0.3, 0.5]
        : recent.length == 2
        ? [0.4, 0.6]
        : [1.0];

    double weightedAvg = 0;
    for (var i = 0; i < recent.length; i++) {
      weightedAvg += recent[i].actual * weights[i];
    }

    // --- Linear trend nudge (least-squares slope across all history) ---
    final trendSlope = _linearSlope(history);
    final rawPredicted = weightedAvg + (trendSlope * 0.5);
    final predictedTotal = rawPredicted < 0 ? 0.0 : rawPredicted;

    final lastCompleteMonthTotal = history.last.actual;
    final percentChange = lastCompleteMonthTotal > 0
        ? ((predictedTotal - lastCompleteMonthTotal) / lastCompleteMonthTotal) * 100
        : 0.0;

    // --- Category-wise prediction: weighted average per category over the
    // same recent months, rescaled so categories sum to predictedTotal. ---
    final Map<String, double> categoryWeightedSums = {};
    for (var i = 0; i < recent.length; i++) {
      final key = monthKey(recent[i].month);
      final cats = monthCategoryTotals[key] ?? {};
      cats.forEach((cat, amt) {
        categoryWeightedSums.update(
          cat,
              (v) => v + amt * weights[i],
          ifAbsent: () => amt * weights[i],
        );
      });
    }
    final categorySum =
    categoryWeightedSums.values.fold(0.0, (a, b) => a + b);
    final Map<String, double> categoryPredictions = {};
    if (categorySum > 0) {
      categoryWeightedSums.forEach((cat, amt) {
        categoryPredictions[cat] = (amt / categorySum) * predictedTotal;
      });
    }

    // --- Weekly split: shape of spending-so-far this month, applied to
    // the predicted total. Falls back to an even split if too early. ---
    final weekTotalSoFar =
    currentMonthWeekTotals.values.fold(0.0, (a, b) => a + b);
    final List<double> weeklyPredictions = weekTotalSoFar > 0
        ? List.generate(5, (i) {
      final share = (currentMonthWeekTotals['w${i + 1}'] ?? 0) / weekTotalSoFar;
      return share * predictedTotal;
    })
        : List.filled(5, predictedTotal / 5);

    // --- Confidence: more history + lower month-to-month variance = higher.
    // Floored at 30 (never claim near-zero when we did produce a number)
    // and capped at 95 (never claim false certainty). ---
    final mean = history.map((p) => p.actual).reduce((a, b) => a + b) / history.length;
    double variance = 0;
    for (final p in history) {
      variance += (p.actual - mean) * (p.actual - mean);
    }
    variance /= history.length;
    final coeffOfVariation = mean > 0 ? (variance / (mean * mean)) : 1.0;
    final dataVolumeScore =
    (history.length / _monthsOfHistory).clamp(0.0, 1.0).toDouble();
    final stabilityScore = (1 - coeffOfVariation).clamp(0.0, 1.0).toDouble();
    int confidence =
    ((dataVolumeScore * 0.5 + stabilityScore * 0.5) * 100).round();
    if (confidence < 30) confidence = 30;
    if (confidence > 95) confidence = 95;

    // --- Backtest: for each historical month (from the 3rd onward), predict
    // it from the months before it and compare to what actually happened. ---
    double? backtestErrorPercent;
    if (history.length >= 3) {
      final errors = <double>[];
      for (int i = 2; i < history.length; i++) {
        final windowStart = (i - 2).clamp(0, i);
        final window = history.sublist(windowStart, i);
        final avg = window.map((p) => p.actual).reduce((a, b) => a + b) / window.length;
        final actual = history[i].actual;
        if (actual > 0) errors.add((avg - actual).abs() / actual);
      }
      if (errors.isNotEmpty) {
        backtestErrorPercent = (errors.reduce((a, b) => a + b) / errors.length) * 100;
      }
    }

    // --- Reason text: which category grew the most between the last two
    // completed months (a real, checkable comparison, not a guess). ---
    final reasonText = _buildReasonText(history, monthCategoryTotals, monthKey);

    return PredictionResult(
      hasSufficientData: true,
      predictedTotal: predictedTotal,
      currentMonthTotal: currentMonthTotal,
      lastCompleteMonthTotal: lastCompleteMonthTotal,
      percentChange: percentChange,
      categoryPredictions: categoryPredictions,
      weeklyPredictions: weeklyPredictions,
      history: history,
      confidence: confidence,
      reasonText: reasonText,
      backtestErrorPercent: backtestErrorPercent,
    );
  }

  double _linearSlope(List<MonthlyPoint> points) {
    final n = points.length;
    final xs = List.generate(n, (i) => i.toDouble());
    final ys = points.map((p) => p.actual).toList();
    final xMean = xs.reduce((a, b) => a + b) / n;
    final yMean = ys.reduce((a, b) => a + b) / n;
    double numerator = 0, denominator = 0;
    for (int i = 0; i < n; i++) {
      numerator += (xs[i] - xMean) * (ys[i] - yMean);
      denominator += (xs[i] - xMean) * (xs[i] - xMean);
    }
    return denominator == 0 ? 0 : numerator / denominator;
  }

  String _buildReasonText(
      List<MonthlyPoint> history,
      Map<String, Map<String, double>> monthCategoryTotals,
      String Function(DateTime) monthKey,
      ) {
    if (history.length < 2) {
      return 'Keep tracking expenses to unlock category-level trends.';
    }
    final lastMonthCats = monthCategoryTotals[monthKey(history.last.month)] ?? {};
    final prevMonthCats =
        monthCategoryTotals[monthKey(history[history.length - 2].month)] ?? {};

    final Map<String, double> deltas = {};
    lastMonthCats.forEach((cat, amt) {
      final prev = prevMonthCats[cat] ?? 0;
      deltas[cat] = amt - prev;
    });

    final increased = deltas.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (increased.isEmpty) {
      return 'Your spending eased off last month across most categories.';
    }
    final top = increased.take(2).map((e) => e.key).toList();
    if (top.length == 1) {
      return '${top[0]} has contributed most to the recent increase.';
    }
    return '${top[0]} and ${top[1]} have contributed most to the recent increase.';
  }

  /// Caches a lightweight version of the result so the home dashboard tile
  /// can read a cheap value without recomputing on every app open.
  Future<void> cacheResult(PredictionResult result) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('prediction')
        .doc('next_month')
        .set({
      'predicted_expense': result.predictedTotal,
      'current_month_total': result.currentMonthTotal,
      'percent_change': result.percentChange,
      'confidence': result.confidence,
      'reason_text': result.reasonText,
      'category_predictions': result.categoryPredictions,
      'has_sufficient_data': result.hasSufficientData,
      'generated_at': FieldValue.serverTimestamp(),
    });
  }
}