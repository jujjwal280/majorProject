import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:start1/main.dart';
import 'package:start1/screens/drawer/profile_screen.dart';
import 'package:start1/screens/drawer/transactions_screen.dart';
import '../providers/theme_provider.dart';
import 'bottomBar/insight_screen.dart';
import 'bottomBar/notification_screen.dart';
import 'drawer/admin_screen.dart';
import 'drawer/feedback_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isAdmin = false;
  int _selectedIndex = 0;
  double monthExpenses = 0;
  double predictedExpense= 0;
  String currentMonth = "";
  String nextMonth = "";
  Map<String, double> categoryExpenses = {};
  String? _username;
  String? _accountNumber;
  String? _bankName;
  bool isLogout = false;
  final GlobalKey<FlipCardState> _flipCardKey = GlobalKey<FlipCardState>();


  @override

  void initState() {
    super.initState();
    _fetchExpenses();
    _fetchUserDetails();
    _fetchPredictedExpense();
    currentMonth = _getCurrentMonth();
    nextMonth = _getNextMonth();
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
            _username = userDoc['username'] ?? 'User Name';
            _accountNumber = userDoc['account_number'] ?? 'Account Number';
            _bankName = userDoc['bank_name'] ?? 'Bank Name';
            isAdmin = userDoc['isAdmin'] ?? false;
          });
        }
      } catch (e) {
        if (kDebugMode) {
          showSnackbar("Error fetching user details: $e");
        }
      }
    }
  }

  void _fetchPredictedExpense() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final DocumentReference predictionDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('prediction')
          .doc('next_month');

      try {
        final DocumentSnapshot snapshot = await predictionDoc.get();

        if (snapshot.exists) {
          final data = snapshot.data() as Map<String, dynamic>;
          final double predicted = data['predicted_expense']?.toDouble() ?? 0.0;

          setState(() {
            predictedExpense = predicted;
          });
        }
      } catch (e) {
        if (kDebugMode) {
          showSnackbar('Error fetching predicted expense: $e');
        }
      }
    }
  }

  void _fetchExpenses() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final CollectionReference transactions = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions');

      try {
        DateTime now = DateTime.now();
        // First day of the current month
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        // First day of the next month
        DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

        // 🔥 Optimized Firestore query: only fetch this month’s documents
        final QuerySnapshot snapshot = await transactions
            .where('date', isGreaterThanOrEqualTo: startOfMonth)
            .where('date', isLessThan: endOfMonth)
            .get();

        final dataDocs = snapshot.docs;

        Map<String, double> tempCategoryExpenses = {};
        double total = 0;

        for (var doc in dataDocs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['amount'] != null && data['category'] != null) {
            final category = data['category'];
            final amount = (data['amount'] as num).toDouble();

            total += amount;
            tempCategoryExpenses.update(category, (value) => value + amount, ifAbsent: () => amount);
          }
        }

        setState(() {
          monthExpenses = total;
          categoryExpenses = tempCategoryExpenses;
          currentMonth = _getCurrentMonth();
        });
      } catch (e) {
        if (kDebugMode) {
          showSnackbar("Error fetching expenses: $e");
        }
      }
    }
  }

  void showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _getCurrentMonth() {
    DateTime now = DateTime.now();
    return _monthName(now.month);
  }

  String _getNextMonth() {
    DateTime now = DateTime.now();
    return _monthName(now.month + 1);
  }

  String _monthName(int month) {
    List<String> months = [
      "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December"
    ];
    return months[month - 1];
  }

  void _onBottomTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    setState(() {
      isLogout = true;
    });
    // --- FIX #3: Removed the old widget.onThemeToggle line ---
    await Future.delayed(const Duration(seconds: 1));
    await FirebaseAuth.instance.signOut();
    // Ensure the context is still valid before navigating
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onDrawerTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return DashboardScreen(
          username: _username,
          monthExpenses: monthExpenses,
          categoryExpenses: categoryExpenses,
          flipCardKey: _flipCardKey,
          currentMonth: currentMonth,
        );
      case 1:
        return FutureInsightScreen();
      case 2:
        return NotificationScreen();
      case 3:
        return TransactionsScreen(
          onTransactionChanged: _fetchExpenses,
        );
      case 4:
        return const ProfileScreen();
      case 5:
        return const FeedbackScreen();
      case 6:
        return const AdminScreen();
      default:
        return DashboardScreen(
          username: _username,
          monthExpenses: monthExpenses,
          categoryExpenses: categoryExpenses,
          flipCardKey: _flipCardKey,
          currentMonth: currentMonth,
        );
    }
  }

  String _getAppBarTitle(int index) {
    switch (index) {
      case 0:
        return "Dashboard";
      case 1:
        return "Future Insight";
      case 2:
        return "Notifications";
      case 3:
        return "Transaction";
      case 4:
        return "Profile";
      case 5:
        return "Feedback";
      case 6:
        return "Admin";
      default:
        return "Dashboard";
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(_selectedIndex), style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF053F5C),
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu_rounded, size: 28),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: [
            // This is the LOGOUT button
            IconButton(
              icon: const Icon(Icons.logout, size: 28, color: Colors.white),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Are you sure you want to log out?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel', style: TextStyle(fontSize: 18, color: Colors.black)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF053F5C),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _logout,
                        child: isLogout
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('LogOut', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
            // This is the THEME TOGGLE button
            IconButton(
              icon: Icon(
                themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Colors.white,
              ),
              // --- FIX #2: Corrected the onPressed syntax ---
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Custom header
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E5C78),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.account_circle, size: 40, color: Color(0xFF053F5C)),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _username ?? 'User Name',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              _accountNumber ?? 'Account Number',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _bankName ?? 'Bank Name',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(thickness: 1),
              ListTile(
                leading: const Icon(Icons.dashboard_rounded, color: Color(0xFF053F5C)),
                title: Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                ),
                selected: _selectedIndex == 0,
                selectedTileColor: const Color(0xFFF27F0C),
                onTap: () => _onDrawerTap(0),
              ),
              const Divider(thickness: 1),
              ListTile(
                leading: const Icon(Icons.payment_rounded, color: Color(0xFF053F5C)),
                title: Text(
                  'Transactions',
                  style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                ),
                selected: _selectedIndex == 3,
                selectedTileColor: const Color(0xFFF27F0C),
                onTap: () => _onDrawerTap(3),
              ),
              const Divider(thickness: 1,),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF053F5C)),
                title: Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                ),
                selected: _selectedIndex == 4,
                selectedTileColor: const Color(0xFFF27F0C),
                onTap: () => _onDrawerTap(4),
              ),
              const Divider(thickness: 1),
              ListTile(
                leading: const Icon(Icons.feedback_rounded, color: Color(0xFF053F5C)),
                title: Text(
                  'Feedback',
                  style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                ),
                selected: _selectedIndex == 5,
                selectedTileColor: const Color(0xFFF27F0C),
                onTap: () => _onDrawerTap(5),
              ),
              const Divider(thickness: 1),
              if (isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF053F5C)),
                  title: Text(
                    'Admin',
                    style: TextStyle(fontWeight: FontWeight.bold, color: themeProvider.isDarkMode ? Colors.white : Colors.black),
                  ),
                  selected: _selectedIndex == 6,
                  selectedTileColor: const Color(0xFFF27F0C),
                  onTap: () => _onDrawerTap(6),
                ),
              const Divider(thickness: 1),
            ],
          ),
        ),
        body: _getScreen(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex > 2 ? 0 : _selectedIndex,
          onTap: _onBottomTap,
          backgroundColor: const Color(0xFF053F5C),
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.white,
          selectedLabelStyle: const  TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(
              icon: Icon(
                Icons.dashboard_rounded,
                color: _selectedIndex == 0 ? const Color(0xFFF27F0C) : Colors.white,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.bar_chart_rounded,
                color: _selectedIndex == 1 ? const Color(0xFFF27F0C) : Colors.white,
              ),
              label: 'Future Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: _selectedIndex == 2 ? const Color(0xFFF27F0C) : Colors.white,
              ),
              label: 'Notifications',
            ),
          ],
        ),
      );
  }
}

class DashboardScreen extends StatefulWidget {
  final String? username;
  final double monthExpenses;
  final Map<String, double> categoryExpenses;
  final GlobalKey<FlipCardState> flipCardKey;
  final String currentMonth;

  const DashboardScreen({
    super.key,
    this.username,
    required this.monthExpenses,
    required this.categoryExpenses,
    required this.flipCardKey,
    required this.currentMonth,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          if (widget.username != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Hey, ${widget.username}!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          Card(
            elevation: 8,
            color: Colors.white.withAlpha(230),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text(
                      "${widget.currentMonth} Expenditure",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF053F5C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "₹${widget.monthExpenses.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[900],
                    ),
                  ),
                ],
              ),
            ),
          ),
          widget.categoryExpenses.isEmpty
              ? const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: Text(
                "No data available",
                style: TextStyle(color: Color(0xFF1E5C78), fontSize: 16),
              ),
            ),
          )
              : FlipCard(
            key: widget.flipCardKey,
            direction: FlipDirection.HORIZONTAL,
            front: GestureDetector(
              onTap: () {},
              child: Card(
                elevation: 4,
                color: const Color(0xFF1E5C78),
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: widget.categoryExpenses.entries.toList().asMap().entries.map((entry) {
                              int index = entry.key;
                              final mapEntry = entry.value;
                              double percentage = (mapEntry.value / widget.monthExpenses) * 100;
                              bool isTouched = index == touchedIndex;

                              return PieChartSectionData(
                                color: categoryColors[mapEntry.key] ?? Colors.grey,
                                value: mapEntry.value,
                                title: "${percentage.toStringAsFixed(1)}%",
                                radius: isTouched ? 55 : 45,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4,
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions || pieTouchResponse?.touchedSection == null) {
                                    touchedIndex = null;
                                  } else {
                                    touchedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                          onPressed: () {
                            widget.flipCardKey.currentState?.toggleCard();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            back: GestureDetector(
              onTap: () {
                widget.flipCardKey.currentState?.toggleCard();
              },
              child: Card(
                elevation: 4,
                color: const Color(0xFF1E5C78),
                margin: const EdgeInsets.all(16.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Category-wise Expenditure",
                          style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 160,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categoryColors.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        color: entry.value,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        entry.key,
                                        style: const TextStyle(color: Colors.white, fontSize: 17),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Column(
            children: widget.categoryExpenses.entries.map((entry) {
              return Card(
                color: categoryColors[entry.key] ?? Colors.grey,
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.shopping_cart_rounded, color: Color(0xFF053F5C)),
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF053F5C),
                    ),
                  ),
                  trailing: Text(
                    "₹${entry.value.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }
}
