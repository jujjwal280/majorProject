import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:start1/services/sms_service.dart'; // Make sure this path is correct

class TransactionsScreen extends StatefulWidget {
  final VoidCallback? onTransactionChanged;
  const TransactionsScreen({super.key, this.onTransactionChanged});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Removed form-specific state variables from here, as they are now managed in the modal.
  int _selectedYear = DateTime.now().year;

  // The single source of truth for categories
  final List<String> _categories = categoryColors.keys.toList();

  void showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Unified method to add a transaction
  void _addTransaction(Map<String, dynamic> transactionData) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnackbar('User not logged in!');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .add(transactionData);

      showSnackbar('Transaction added successfully!');
      widget.onTransactionChanged?.call();
      Navigator.pop(context); // Close the modal
    } catch (error) {
      showSnackbar('Failed to add transaction: $error');
    }
  }

  // Completed method to update a transaction
  void _updateTransaction(String docId, Map<String, dynamic> transactionData) async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnackbar('User not logged in!');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .doc(docId)
          .update(transactionData);

      showSnackbar('Transaction updated successfully!');
      widget.onTransactionChanged?.call();
      Navigator.pop(context); // Close the modal
    } catch (error) {
      showSnackbar('Failed to update transaction: $error');
    }
  }

  // Refactored and unified modal for both adding and editing
  // Refactored modal with the requested UI styling
  void _showTransactionModal({DocumentSnapshot? transactionDoc}) {
    final formKey = GlobalKey<FormState>();
    bool isEditing = transactionDoc != null;

    // Initialize local variables for the form
    String? selectedCategory;
    double? amount;
    String? description;
    // Use DateTime.now() as default for adding, or the existing date for editing
    DateTime selectedDate = isEditing
        ? (transactionDoc.data() as Map<String, dynamic>)['date'].toDate()
        : DateTime.now();

    // If we are editing, pre-fill the form with existing data.
    if (isEditing) {
      final data = transactionDoc.data() as Map<String, dynamic>;
      selectedCategory = data['category'];
      amount = (data['amount'] as num).toDouble();
      description = data['description'];
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Category Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: _categories
                        .map((category) => DropdownMenuItem(
                      value: category,
                      child: Text(category, style: const TextStyle(fontSize: 16)),
                    ))
                        .toList(),
                    onChanged: (value) => selectedCategory = value,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                    validator: (value) => value == null ? 'Please select a category' : null,
                  ),
                  const SizedBox(height: 10),

                  // Amount Input
                  TextFormField(
                    initialValue: amount?.toString() ?? '',
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                    onSaved: (value) => amount = double.tryParse(value!.trim()),
                    validator: (value) {
                      if (value == null || value.isEmpty || double.tryParse(value) == null || double.parse(value) <= 0) {
                        return 'Please enter a valid positive amount';
                      }
                      return null;
                    },
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 10),

                  // Description Input
                  TextFormField(
                    initialValue: description ?? '',
                    decoration: InputDecoration(
                      labelText: 'Description',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                    onSaved: (value) => description = value,
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 10),

                  // Date Picker Row
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return Row(
                        children: [
                          Text(
                            DateFormat('yyyy-MM-dd').format(selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today_rounded, color: Color(0xFF1E5C78)),
                            onPressed: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null && picked != selectedDate) {
                                setState(() => selectedDate = picked);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 60),

                  // Submit Button
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        formKey.currentState!.save();

                        final transactionData = {
                          'amount': amount,
                          'category': selectedCategory,
                          'description': description ?? '',
                          'date': Timestamp.fromDate(selectedDate),
                        };

                        if (isEditing) {
                          _updateTransaction(transactionDoc.id, transactionData);
                        } else {
                          _addTransaction(transactionData);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(0xFF053F5C),
                    ),
                    child: Text(
                      isEditing ? '   Save Changes   ' : '   Add Transaction   ',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 160),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for the Month Header
  Widget _buildMonthHeader(String monthName, double total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            monthName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            'Total: ₹${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const Divider(thickness: 1.5, height: 10),
        ],
      ),
    );
  }

// Helper method for the Week Header
  Widget _buildWeekHeader(int weekNumber, double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Week $weekNumber',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
          ),
          Text(
            '₹${total.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

// Helper method for the Day Header
  Widget _buildDayHeader(String dayKey) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, top: 8, bottom: 4),
      child: Text(
        DateFormat('EEEE, MMM d').format(DateTime.parse(dayKey)),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to see transactions."));
    }

    final CollectionReference transactions = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    DateTime startOfYear = DateTime(_selectedYear, 1, 1);
    DateTime endOfYear = DateTime(_selectedYear + 1, 1, 1);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final smsService = SmsImportService();
                await smsService.getAndProcessSms(context);
                widget.onTransactionChanged?.call();
              },
              icon: const Icon(Icons.sms_rounded, color: Colors.white,),
              label: const Text('Sync Transactions from SMS', style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF053F5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: transactions
                  .where('date', isGreaterThanOrEqualTo: startOfYear)
                  .where('date', isLessThan: endOfYear)
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Failed to load transactions.'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Use an empty list as a default if there's no data
                final dataDocs = snapshot.data?.docs ?? [];

                double totalExpenditure = 0.0;
                Map<String, Map<int, Map<String, List<Widget>>>> groupedTransactions = {};
                Map<String, double> monthlyTotalExpenditure = {};
                Map<String, Map<int, double>> weeklyTotalExpenditure = {};

                // This loop will not run if dataDocs is empty, leaving all totals at 0
                for (var doc in dataDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['amount'] == null || data['date'] == null) continue;

                  DateTime date = (data['date'] as Timestamp).toDate();
                  String monthName = DateFormat('MMMM').format(date);
                  int weekOfMonth = ((date.day - 1) ~/ 7) + 1;
                  String dayKey = DateFormat('yyyy-MM-dd').format(date);
                  Color categoryColor = categoryColors[data['category']] ?? Colors.grey;
                  double amount = (data['amount'] as num).toDouble();

                  totalExpenditure += amount;

                  groupedTransactions.putIfAbsent(monthName, () => {});
                  groupedTransactions[monthName]!.putIfAbsent(weekOfMonth, () => {});
                  groupedTransactions[monthName]![weekOfMonth]!.putIfAbsent(dayKey, () => []);

                  monthlyTotalExpenditure.update(monthName, (value) => value + amount, ifAbsent: () => amount);

                  weeklyTotalExpenditure.putIfAbsent(monthName, () => {});
                  weeklyTotalExpenditure[monthName]!.update(weekOfMonth, (value) => value + amount, ifAbsent: () => amount);

                  groupedTransactions[monthName]![weekOfMonth]![dayKey]!.add(
                    Card(
                      color: categoryColor.withOpacity(0.8),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF053F5C)),
                        title: Text(data['category'] ?? 'No Category', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['description'] ?? 'No description'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "₹${amount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF053F5C)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note, color: Colors.blueGrey),
                              onPressed: () => _showTransactionModal(transactionDoc: doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.redAccent),
                              onPressed: () async {
                                await transactions.doc(doc.id).delete();
                                widget.onTransactionChanged?.call();
                                showSnackbar("Transaction deleted.");
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final sortedMonths = groupedTransactions.keys.toList();
                return ListView(
                  padding: const EdgeInsets.all(12.0),
                  children: [
                    // 1. Overall Expenditure Card (Stays the Same)
                    Card(
                      elevation: 8,
                      color: Colors.white.withAlpha(230),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              "$_selectedYear Overall Expenditure",
                              style: const TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF053F5C),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "₹${totalExpenditure.toStringAsFixed(2)}",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[900],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Year Selector (Stays the Same)
                    _buildYearSelector(),
                    const Divider(thickness: 1, height: 20),

                    // 3. NEW: Generate Flat List with Header Cards
                    if (dataDocs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 50.0),
                        child: Center(
                          child: Text(
                            'No transactions found for this year.',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                    // Use collection-for loops to build a flat list of widgets
                      for (var month in sortedMonths) ...[
                        // MONTH HEADER
                        _buildMonthHeader(
                            month, monthlyTotalExpenditure[month]!),

                        for (var week in groupedTransactions[month]!.keys.toList()..sort()) ...[
                          // WEEK HEADER
                          _buildWeekHeader(
                              week, weeklyTotalExpenditure[month]![week]!),

                          for (var day in groupedTransactions[month]![week]!.keys.toList()..sort()) ...[
                            // DAY HEADER
                            _buildDayHeader(day),

                            // TRANSACTION CARDS
                            ...groupedTransactions[month]![week]![day]!,
                          ],
                          const SizedBox(height: 10), // Space after each week
                        ]
                      ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTransactionModal(),
        backgroundColor: const Color(0xFF053F5C),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildYearSelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 15,
        itemBuilder: (context, index) {
          int year = DateTime.now().year - index;
          bool isSelected = _selectedYear == year;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedYear = year;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? const Color(0xFF053F5C) : Colors.grey[200],
                foregroundColor: isSelected ? Colors.white : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: Text(
                year.toString(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Define this map outside the class so it's a constant
final Map<String, Color> categoryColors = {
  'Groceries': const Color(0xFFECB762),
  'Transportation': const Color(0xFFA5CCA9),
  'Entertainment': const Color(0xFFF4BAB0),
  'Rent': const Color(0xFFB2967D),
  'Dining Out': const Color(0xFFF47F7D),
  'Other': Colors.grey,
};