import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  _TransactionsScreenState createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  double? _amount;
  String? _description;
  DateTime? _selectedDate;
  int _selectedYear = DateTime.now().year;
  bool isDashboard = false;
  bool isProfile = false;
  bool isTransaction = false;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching user details: $e");
        }
      }
    }
  }

  final List<String> _categories = [
    'Groceries',
    'Transportation',
    'Entertainment',
    'Rent',
    'Dining Out',
  ];

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        try {
          DateTime date = _selectedDate ?? DateTime.now();

          String month = DateFormat('MMMM').format(date);
          int weekOfMonth = ((date.day - 1) ~/ 7) + 1;
          String day = DateFormat('yyyy-MM-dd').format(date);

          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions')
              .add({
            'amount': _amount,
            'category': _selectedCategory,
            'description': _description ?? '',
            'date': Timestamp.fromDate(date),
            'month': month,
            'week': 'Week $weekOfMonth',
            'day': day,
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction added successfully!')),
          );

          _formKey.currentState!.reset();
          Navigator.pop(context);
        } catch (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add transaction: $error')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    final CollectionReference transactions = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid)
        .collection('transactions');

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: transactions.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Failed to load transactions. Please try again.'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: Text(
                        'No transactions found. Add your first transaction!',
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.black87,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                final dataDocs = snapshot.data!.docs;
                double totalExpenditure = 0.0;
                Map<String, Map<int, Map<String, List<Widget>>>> groupedTransactions = {};
                Map<String, Map<int, double>> monthlyExpenditure = {};

                for (var doc in dataDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['amount'] == null || data['date'] == null) continue;

                  DateTime date = (data['date'] as Timestamp).toDate();
                  if (date.year != _selectedYear) continue; // Filter by year

                  String monthName = DateFormat('MMMM').format(date);
                  int weekOfMonth = ((date.day - 1) ~/ 7) + 1;
                  String dayKey = DateFormat('yyyy-MM-dd').format(date);
                  Color categoryColor = categoryColors[data['category']] ?? Colors.grey;

                  totalExpenditure += (data['amount'] as num).toDouble();

                  if (!groupedTransactions.containsKey(monthName)) {
                    groupedTransactions[monthName] = {};
                    monthlyExpenditure[monthName] = {};
                  }
                  if (!groupedTransactions[monthName]!.containsKey(weekOfMonth)) {
                    groupedTransactions[monthName]![weekOfMonth] = {};
                  }
                  if (!groupedTransactions[monthName]![weekOfMonth]!.containsKey(dayKey)) {
                    groupedTransactions[monthName]![weekOfMonth]![dayKey] = [];
                  }

                  groupedTransactions[monthName]![weekOfMonth]![dayKey]!.add(
                    Card(
                      color: categoryColor,
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_cart, color: Color(0xFF053F5C)),
                        title: Text(data['category'] ?? 'Unknown'),
                        subtitle: Text(data['description'] ?? 'No description'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "₹${(data['amount'] ?? 0.0).toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.black),
                              onPressed: () async {
                                await transactions.doc(doc.id).delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                  monthlyExpenditure.putIfAbsent(monthName, () => {});
                  monthlyExpenditure[monthName]!.putIfAbsent(weekOfMonth, () => 0.0);
                  monthlyExpenditure[monthName]![weekOfMonth] =
                      (monthlyExpenditure[monthName]![weekOfMonth] ?? 0) + (data['amount'] as num).toDouble();
                }

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      // Display overall expenditure for the selected year
                      Card(
                        elevation: 8,
                        color: Colors.white.withAlpha((0.8 * 255).toInt()),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1.0, horizontal: 1.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: List.generate(15, (index) {
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
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: Text(
                                    year.toString(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(thickness: 1),
                      for (var month in groupedTransactions.keys)
                        ExpansionTile(
                          title: Text(
                            '$month (₹${monthlyExpenditure[month]?.values.fold(0.0, (prev, elem) => prev + elem).toStringAsFixed(2)})',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          children: [
                            for (var week in groupedTransactions[month]!.keys.toList()..sort())
                              ExpansionTile(
                                title: Text(
                                  'Week $week (₹${monthlyExpenditure[month]?[week]?.toStringAsFixed(2) ?? '0.00'})',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                children: [
                                  for (var day in groupedTransactions[month]![week]!.keys.toList()..sort())
                                    ExpansionTile(
                                      title: Text(
                                        day,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      children: groupedTransactions[month]![week]![day]!,
                                    ),
                                ],
                              ),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (ctx) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          items: _categories
                              .map(
                                (category) => DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          )
                              .toList(),
                          onChanged: (value) => setState(() {
                            _selectedCategory = value;
                          }),
                          decoration: InputDecoration(
                            labelText: 'Category', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                            filled: true,
                            fillColor: const Color(0xFF429EBD).withAlpha((0.8 * 255).toInt()),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                            ),
                          ),
                          validator: (value) =>
                          value == null ? 'Please select a category' : null,
                        ),
                        const SizedBox(height: 10),
                        // Amount Input
                        TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Amount', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                            filled: true,
                            fillColor: const Color(0xFF429EBD).withAlpha((0.8 * 255).toInt()),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid positive number';
                            }
                            return null;
                          },
                          onSaved: (value) => _amount = double.parse(value!),
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Description', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                            filled: true,
                            fillColor: const Color(0xFF429EBD).withAlpha((0.8 * 255).toInt()),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                            ),
                          ),
                          onSaved: (value) => _description = value,
                          style: const TextStyle(color: Colors.black),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              _selectedDate == null
                                  ? 'Select Date'
                                  : '${_selectedDate!.toLocal()}'.split(' ')[0],
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.calendar_today, color: Color(0xFF1E5C78)
                              ),
                              onPressed: () => _selectDate(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _addTransaction,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            backgroundColor: const Color(0xFF053F5C),
                          ),
                          child: const Text(
                            '   Add Transaction   ',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        backgroundColor: const Color(0xFF053F5C),
        child: const Icon(Icons.add,color: Colors.white),
      ),
    );
  }
}

final Map<String, Color> categoryColors = {
  'Groceries': const Color(0xFFECB762),
  'Transportation': const Color(0xFFA5CCA9),
  'Entertainment': const Color(0xFFF4BAB0),
  'Rent': const Color(0xFFB2967D),
  'Dining Out': const Color(0xFFF47F7D),
};