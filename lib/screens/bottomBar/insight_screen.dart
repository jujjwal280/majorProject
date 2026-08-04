import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:start1/providers/prediction_provider.dart';
import 'package:start1/providers/theme_provider.dart';
import 'package:start1/services/expense_prediction_service.dart';

// Design Constants
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);
const Color cardBlue = Color(0xFF1E5C78);

const List<Color> _categoryPalette = [
  Color(0xFFF27F0C),
  Color(0xFF11698E),
  Color(0xFFECB762),
  Color(0xFFA5CCA9),
  Color(0xFFF4BAB0),
  Color(0xFFB2967D),
  Color(0xFF429EBD),
  Color(0xFF7A6FF0),
];

class FutureInsightScreen extends StatefulWidget {
  const FutureInsightScreen({super.key});

  @override
  State<FutureInsightScreen> createState() => _FutureInsightScreenState();
}

class _FutureInsightScreenState extends State<FutureInsightScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PredictionProvider>(context, listen: false);
      if (provider.result == null && !provider.isLoading) {
        provider.generatePrediction();
      }
    });
  }

  Future<void> _recalculate() async {
    HapticFeedback.selectionClick();
    await Provider.of<PredictionProvider>(context, listen: false)
        .generatePrediction();
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    final predictionProvider = Provider.of<PredictionProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: accentOrange,
        onRefresh: _recalculate,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 10),
            _buildHeader(tp),
            const SizedBox(height: 30),
            _buildBody(tp, predictionProvider),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ThemeProvider tp, PredictionProvider provider) {
    if (provider.isLoading && provider.result == null) {
      return _buildLoadingCard();
    }
    if (provider.error != null && provider.result == null) {
      return _buildErrorCard(provider.error!);
    }
    final result = provider.result;
    if (result == null) {
      return _buildLoadingCard();
    }
    if (!result.hasSufficientData) {
      return _buildInsufficientDataCard(tp, result);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroCard(result, provider.isLoading),
        const SizedBox(height: 24),
        _buildReasonCard(result, tp),
        const SizedBox(height: 32),
        _buildSectionLabel(tp, "Historical vs Predicted"),
        const SizedBox(height: 15),
        _buildHistoryChart(result, tp),
        const SizedBox(height: 32),
        _buildSectionLabel(tp, "Predicted by Category"),
        const SizedBox(height: 15),
        _buildCategoryBreakdown(result, tp),
        const SizedBox(height: 32),
        _buildSectionLabel(tp, "Predicted by Week"),
        const SizedBox(height: 15),
        _buildWeeklyChart(result, tp),
        if (result.backtestErrorPercent != null) ...[
          const SizedBox(height: 20),
          _buildBacktestNote(result, tp),
        ],
        const SizedBox(height: 32),
        _buildRecalculateButton(provider.isLoading),
      ],
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
            Text("PREDICTION DASHBOARD",
                style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 8),
        Text("Next Month Forecast",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor)),
      ],
    );
  }

  Widget _buildSectionLabel(ThemeProvider tp, String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5));
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryDark, cardBlue]),
        borderRadius: BorderRadius.circular(35),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: accentOrange, strokeWidth: 3),
          SizedBox(height: 15),
          Text("Analyzing your spending history...", style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: [
          const Icon(Icons.error_outline_rounded, color: accentOrange, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: primaryDark, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _recalculate,
            style: ElevatedButton.styleFrom(backgroundColor: primaryDark),
            child: const Text("Try Again", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildInsufficientDataCard(ThemeProvider tp, PredictionResult result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: accentOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty_rounded, color: accentOrange, size: 40),
          const SizedBox(height: 16),
          Text("Not enough history yet",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: tp.textColor)),
          const SizedBox(height: 8),
          Text(
            "Add more expense history to improve prediction accuracy. We need at least two months of tracked expenses to forecast next month.",
            textAlign: TextAlign.center,
            style: TextStyle(color: tp.subTextColor, fontSize: 13, height: 1.5),
          ),
          if (result.currentMonthTotal > 0) ...[
            const SizedBox(height: 16),
            Text("So far this month: ₹${result.currentMonthTotal.toStringAsFixed(0)}",
                style: TextStyle(color: tp.textColor, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroCard(PredictionResult result, bool isRefreshing) {
    final isIncrease = result.percentChange >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryDark, cardBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: primaryDark.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Text("Expected Next Month", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          if (isRefreshing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: accentOrange, strokeWidth: 2)),
            )
          else
            Text("₹${result.predictedTotal.toStringAsFixed(0)}",
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: isIncrease ? const Color(0xFFFF8A65) : const Color(0xFF7ED6A5), size: 18),
                const SizedBox(width: 6),
                Text(
                  "${isIncrease ? '+' : ''}${result.percentChange.toStringAsFixed(1)}% vs last month",
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.query_stats_rounded, color: accentOrange, size: 18),
                const SizedBox(width: 8),
                Text("${result.confidence}% confidence, based on your history",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonCard(PredictionResult result, ThemeProvider tp) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: tp.isDarkMode ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: tp.isDarkMode ? Colors.white10 : const Color(0xFFF0F4F7),
            child: Icon(Icons.lightbulb_outline_rounded, color: tp.isDarkMode ? accentOrange : primaryDark),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Why", style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor)),
                const SizedBox(height: 2),
                Text(result.reasonText, style: TextStyle(color: tp.subTextColor, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChart(PredictionResult result, ThemeProvider tp) {
    final bars = [...result.history.map((p) => p.actual), result.predictedTotal];
    final labels = [...result.history.map((p) => p.label), 'Next'];
    final maxY = (bars.reduce((a, b) => a > b ? a : b)) * 1.25;

    return Container(
      height: 240,
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
      decoration: BoxDecoration(color: tp.cardColor, borderRadius: BorderRadius.circular(30)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 1 : maxY,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox();
                  final isPredicted = idx == labels.length - 1;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[idx],
                      style: TextStyle(
                        fontSize: 11,
                        color: isPredicted ? accentOrange : tp.subTextColor,
                        fontWeight: isPredicted ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(bars.length, (i) {
            final isPredicted = i == bars.length - 1;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: bars[i],
                width: 18,
                borderRadius: BorderRadius.circular(6),
                color: isPredicted ? accentOrange : primaryDark.withOpacity(tp.isDarkMode ? 0.6 : 0.35),
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(PredictionResult result, ThemeProvider tp) {
    final entries = result.categoryPredictions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = entries.isEmpty ? 1.0 : entries.first.value;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: tp.cardColor, borderRadius: BorderRadius.circular(30)),
      child: Column(
        children: entries.asMap().entries.map((e) {
          final index = e.key;
          final category = e.value.key;
          final amount = e.value.value;
          final color = _categoryPalette[index % _categoryPalette.length];
          final fraction = maxVal > 0 ? (amount / maxVal).clamp(0.0, 1.0) : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                      CircleAvatar(radius: 5, backgroundColor: color),
                      const SizedBox(width: 8),
                      Text(category, style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor, fontSize: 13)),
                    ]),
                    Text("₹${amount.toStringAsFixed(0)}",
                        style: TextStyle(fontWeight: FontWeight.w900, color: tp.textColor, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: tp.isDarkMode ? Colors.white10 : Colors.grey.shade200,
                    color: color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyChart(PredictionResult result, ThemeProvider tp) {
    final bars = result.weeklyPredictions;
    final labels = ['W1', 'W2', 'W3', 'W4', 'W5'];
    final maxY = bars.isEmpty ? 1.0 : bars.reduce((a, b) => a > b ? a : b) * 1.3;

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(color: tp.cardColor, borderRadius: BorderRadius.circular(30)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY == 0 ? 1 : maxY,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= labels.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(labels[idx], style: TextStyle(fontSize: 11, color: tp.subTextColor)),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(bars.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: bars[i],
                width: 22,
                borderRadius: BorderRadius.circular(6),
                color: cardBlue,
              ),
            ]);
          }),
        ),
      ),
    );
  }

  Widget _buildBacktestNote(PredictionResult result, ThemeProvider tp) {
    return Row(
      children: [
        Icon(Icons.verified_outlined, size: 14, color: tp.subTextColor),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            "This method has averaged about ${result.backtestErrorPercent!.toStringAsFixed(0)}% error when tested against your past months.",
            style: TextStyle(fontSize: 11, color: tp.subTextColor),
          ),
        ),
      ],
    );
  }

  Widget _buildRecalculateButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [primaryDark, Color(0xFF11698E)]),
        boxShadow: [BoxShadow(color: primaryDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _recalculate,
        icon: const Icon(Icons.refresh_rounded, color: Colors.white),
        label: const Text("RECALCULATE FORECAST",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }
}