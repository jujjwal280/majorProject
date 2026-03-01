import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; // Added for Provider
import 'package:start1/services/sms_service.dart';
import '../../providers/theme_provider.dart'; // Ensure this path is correct

// Brand Constants (kept as fallback/base)
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);

// Consistent Category Maps
final Map<String, Color> categoryColors = {
  'Groceries': const Color(0xFFECB762),
  'Transportation': const Color(0xFFA5CCA9),
  'Entertainment': const Color(0xFFF4BAB0),
  'Rent': const Color(0xFFB2967D),
  'Dining Out': const Color(0xFFF47F7D),
  'Other': Colors.grey,
};

final Map<String, IconData> categoryIcons = {
  'Groceries': Icons.shopping_basket_rounded,
  'Transportation': Icons.directions_car_rounded,
  'Entertainment': Icons.movie_filter_rounded,
  'Rent': Icons.home_rounded,
  'Dining Out': Icons.restaurant_rounded,
  'Other': Icons.miscellaneous_services_rounded,
};

class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onTransactionChanged;
  const TransactionsScreen({super.key, this.onTransactionChanged});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  int _selectedYear = DateTime.now().year;
  final List<String> _categories = categoryColors.keys.toList();

  void _addTransaction(Map<String, dynamic> transactionData) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('transactions').add(transactionData);
      _showStatusSnackbar('Added successfully!', false);
      widget.onTransactionChanged?.call();
      Navigator.pop(context);
    } catch (e) {
      _showStatusSnackbar('Error adding record', true);
    }
  }

  void _updateTransaction(String docId, Map<String, dynamic> transactionData) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).collection('transactions').doc(docId).update(transactionData);
      _showStatusSnackbar('Updated successfully!', false);
      widget.onTransactionChanged?.call();
      Navigator.pop(context);
    } catch (e) {
      _showStatusSnackbar('Update failed', true);
    }
  }

  void _showStatusSnackbar(String message, [bool isError = false]) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: isError ? accentOrange : primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  // --- PREMIUM DELETE DIALOG (Theme Aware) ---
  void _showDeleteDialog(String docId, ThemeProvider tp) {
    HapticFeedback.heavyImpact();

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: tp.cardColor, // Dynamic color
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_sweep_rounded,
                        color: accentOrange,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      "Delete Record?",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: tp.textColor, // Dynamic color
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "This will permanently erase this transaction from your vault. Continue?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tp.subTextColor, // Dynamic color
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("CANCEL", style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [primaryDark, Color(0xFF11698E)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                final User? user = FirebaseAuth.instance.currentUser;
                                if (user != null) {
                                  await FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(user.uid)
                                      .collection('transactions')
                                      .doc(docId)
                                      .delete();
                                  Navigator.pop(context);
                                  _showStatusSnackbar("Transaction Deleted", false);
                                  widget.onTransactionChanged?.call();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- REFINED MODAL FOR ADD/EDIT (Theme Aware) ---
  void _showTransactionModal({DocumentSnapshot? transactionDoc}) {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    bool isEditing = transactionDoc != null;
    String? selectedCategory;
    double? amount;
    String? description;
    DateTime selectedDate = isEditing ? (transactionDoc.data() as Map<String, dynamic>)['date'].toDate() : DateTime.now();

    if (isEditing) {
      final data = transactionDoc.data() as Map<String, dynamic>;
      selectedCategory = data['category'];
      amount = (data['amount'] as num).toDouble();
      description = data['description'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: tp.cardColor, // Dynamic color
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(35), topRight: Radius.circular(35)),
        ),
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 30),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 50, height: 5, decoration: BoxDecoration(color: tp.subTextColor.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(isEditing ? "Edit Transaction" : "New Transaction", style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: tp.textColor)),
                const SizedBox(height: 25),

                DropdownButtonFormField<String>(
                  dropdownColor: tp.cardColor,
                  value: selectedCategory,
                  decoration: _inputDecor(tp, "Select Category", Icons.category_outlined),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: TextStyle(color: tp.textColor)))).toList(),
                  onChanged: (v) => selectedCategory = v,
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  initialValue: amount?.toString() ?? '',
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: tp.textColor),
                  decoration: _inputDecor(tp, "Amount (₹)", Icons.currency_rupee_rounded),
                  onSaved: (v) => amount = double.tryParse(v!.trim()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 15),

                TextFormField(
                  initialValue: description ?? '',
                  style: TextStyle(color: tp.textColor),
                  decoration: _inputDecor(tp, "Description", Icons.description_outlined),
                  onSaved: (v) => description = v,
                ),
                const SizedBox(height: 20),

                StatefulBuilder(
                  builder: (context, setModalState) => GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2030),
                          builder: (context, child) {
                            return Theme(
                              data: tp.isDarkMode ? ThemeData.dark().copyWith(
                                  colorScheme: const ColorScheme.dark(primary: accentOrange, onPrimary: Colors.white, surface: primaryDark, onSurface: Colors.white)
                              ) : ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: primaryDark)),
                              child: child!,
                            );
                          }
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: tp.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100], borderRadius: BorderRadius.circular(15)),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded, color: tp.isDarkMode ? accentOrange : primaryDark),
                          const SizedBox(width: 12),
                          Text(DateFormat('EEEE, MMM d, yyyy').format(selectedDate), style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      final data = {'amount': amount, 'category': selectedCategory, 'description': description ?? '', 'date': Timestamp.fromDate(selectedDate)};
                      isEditing ? _updateTransaction(transactionDoc.id, data) : _addTransaction(data);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryDark,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(isEditing ? "SAVE CHANGES" : "ADD TRANSACTION", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecor(ThemeProvider tp, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: tp.subTextColor),
      prefixIcon: Icon(icon, color: tp.isDarkMode ? accentOrange : primaryDark),
      filled: true,
      fillColor: tp.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: accentOrange, width: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text("Access Denied"));

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from HomeScreen
      body: Column(
        children: [
          _buildHeader(tp),
          _buildSyncBar(tp),
          const SizedBox(height: 20),
          _buildYearSelector(tp),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('transactions')
                  .where('date', isGreaterThanOrEqualTo: DateTime(_selectedYear, 1, 1))
                  .where('date', isLessThan: DateTime(_selectedYear + 1, 1, 1))
                  .orderBy('date', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: accentOrange));
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return _buildEmptyState(tp);
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  physics: const BouncingScrollPhysics(),
                  children: _groupAndBuildTransactions(docs, tp),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionModal(),
        backgroundColor: primaryDark,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.history_toggle_off_rounded, color: accentOrange, size: 20),
              const SizedBox(width: 8),
              Text("TIMELINE", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text("Financial Vault", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor)),
        ],
      ),
    );
  }

  Widget _buildSyncBar(ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: InkWell(
        onTap: () async {
          HapticFeedback.mediumImpact();
          await SmsImportService().getAndProcessSms(context);
          widget.onTransactionChanged?.call();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: primaryDark,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: tp.isDarkMode ? Colors.black45 : primaryDark.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, color: accentOrange, size: 18),
              SizedBox(width: 10),
              Text("SYNC SMS LEDGER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _groupAndBuildTransactions(List<DocumentSnapshot> docs, ThemeProvider tp) {
    List<Widget> list = [];
    String lastMonth = "";
    Map<String, double> monthTotals = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final month = DateFormat('MMMM yyyy').format((data['date'] as Timestamp).toDate());
      monthTotals[month] = (monthTotals[month] ?? 0) + (data['amount'] as num).toDouble();
    }

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final month = DateFormat('MMMM yyyy').format((data['date'] as Timestamp).toDate());

      if (month != lastMonth) {
        list.add(Padding(
          padding: const EdgeInsets.only(top: 25, bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(month.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, color: tp.subTextColor, fontSize: 12, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: accentOrange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("₹${monthTotals[month]!.toStringAsFixed(0)}", style: const TextStyle(color: accentOrange, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ));
        lastMonth = month;
      }
      list.add(_buildTile(doc, data, tp));
    }
    return list;
  }

  Widget _buildTile(DocumentSnapshot doc, Map<String, dynamic> data, ThemeProvider tp) {
    final color = categoryColors[data['category']] ?? Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: tp.cardColor, // Dynamic color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: tp.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 6, decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)))),
            Expanded(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(categoryIcons[data['category']] ?? Icons.paid, color: color, size: 20)),
                title: Text(data['category'] ?? 'Other', style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor)),
                subtitle: Text(DateFormat('MMM d').format((data['date'] as Timestamp).toDate()), style: TextStyle(color: tp.subTextColor)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("₹${(data['amount'] as num).toStringAsFixed(0)}", style: TextStyle(fontWeight: FontWeight.w900, color: tp.textColor, fontSize: 16)),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: accentOrange), onPressed: () => _showDeleteDialog(doc.id, tp)),
                  ],
                ),
                onTap: () => _showTransactionModal(transactionDoc: doc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelector(ThemeProvider tp) {
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 5,
        itemBuilder: (context, index) {
          int year = DateTime.now().year - index;
          bool isSelected = _selectedYear == year;
          return GestureDetector(
            onTap: () => setState(() => _selectedYear = year),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: isSelected ? accentOrange : (tp.isDarkMode ? Colors.white10 : Colors.white),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: isSelected ? accentOrange : (tp.isDarkMode ? Colors.white12 : Colors.grey.shade200))
              ),
              child: Text(year.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : tp.subTextColor)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider tp) {
    return Center(child: Text("Vault is currently empty.", style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.bold)));
  }
}