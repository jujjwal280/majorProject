import 'package:flutter/material.dart';
import 'package:start1/services/expense_prediction_service.dart';

class PredictionProvider with ChangeNotifier {
  final ExpensePredictionService _service = ExpensePredictionService();

  PredictionResult? _result;
  bool _isLoading = false;
  String? _error;

  PredictionResult? get result => _result;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Backward-compatible surface -------------------------------------
  // NOTE: I don't have your existing prediction_provider.dart in front of
  // me, so this file is a full rewrite rather than a patch. I kept the two
  // members insight_screen.dart was already calling (`predictedExpense`
  // getter, `updatePrediction`) so nothing else in the app breaks. If your
  // real file has other methods other screens depend on (e.g. admin_screen
  // may reference it too), add them back in here before dropping this in.
  double? get predictedExpense =>
      (_result?.hasSufficientData ?? false) ? _result!.predictedTotal : null;

  void updatePrediction(double? value) {
    if (value == null) return;
    _result = PredictionResult(
      hasSufficientData: true,
      predictedTotal: value,
      currentMonthTotal: _result?.currentMonthTotal ?? 0,
      lastCompleteMonthTotal: _result?.lastCompleteMonthTotal ?? 0,
      percentChange: _result?.percentChange ?? 0,
      categoryPredictions: _result?.categoryPredictions ?? const {},
      weeklyPredictions: _result?.weeklyPredictions ?? const [],
      history: _result?.history ?? const [],
      confidence: _result?.confidence ?? 50,
      reasonText: _result?.reasonText ?? '',
    );
    notifyListeners();
  }
  // --- end backward-compatible surface ----------------------------------

  Future<void> generatePrediction({bool cache = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final result = await _service.generate();
      _result = result;
      if (cache && result.hasSufficientData) {
        await _service.cacheResult(result);
      }
    } catch (e) {
      _error = 'Could not generate a forecast right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}