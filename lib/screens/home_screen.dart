import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:start1/screens/profile_screen.dart';
import 'package:start1/screens/transactions_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  double monthExpenses = 0;
  double predictedExpense= 0;
  String currentMonth = "";
  String nextMonth = "";
  Map<String, double> categoryExpenses = {};
  String? _username;
  String? _accountNumber;
  String? _bankName;
  bool isDashboard = false;
  bool isProfile = false;
  bool isTransaction = false;
  bool isLogout = false;
  bool isDarkMode = false;
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
          });
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching user details: $e");
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
          print('Error fetching predicted expense: $e');
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
        final QuerySnapshot snapshot = await transactions.get();
        final dataDocs = snapshot.docs;

        Map<String, double> tempCategoryExpenses = {};
        double total = 0;

        DateTime now = DateTime.now();
        int currentMonth = now.month;
        int currentYear = now.year;

        for (var doc in dataDocs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['amount'] != null && data['category'] != null && data['date'] != null) {
            final category = data['category'];
            final amount = data['amount'].toDouble();
            final Timestamp timestamp = data['date'];
            DateTime transactionDate = timestamp.toDate();

            if (transactionDate.month == currentMonth && transactionDate.year == currentYear) {
              total += amount;
              tempCategoryExpenses.update(category, (value) => value + amount, ifAbsent: () => amount);
            }
          }
        }

        setState(() {
          monthExpenses = total;
          categoryExpenses = tempCategoryExpenses;
          currentMonth = _getCurrentMonth() as int;
        });
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching expenses: $e");
        }
      }
    }
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
    await Future.delayed(const Duration(seconds: 1));
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
    setState(() {
      isLogout = false;
    });
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
        return FutureInsightScreen(
          username: _username,
          predictedExpense: predictedExpense,
          nextMonth: nextMonth,
        );
      case 2:
        return NotificationScreen();
      case 3:
        return const TransactionsScreen();
      case 4:
        return const ProfileScreen();
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
      default:
        return "Dashboard";
    }
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(_selectedIndex), style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF053F5C),
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu_rounded, size: 28, color: Colors.black,),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.logout,
                size: 28,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          backgroundColor: const Color(0xFF053F5C),
                        ),
                        onPressed: _logout,
                        child: isLogout
                            ? const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: CircularProgressIndicator(color: Color(0xFF053F5C)),
                        )
                            : const Text(
                          '  LogOut   ',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: Icon(
                isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: _toggleDarkMode,
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
                              _accountNumber ?? 'Phone Number',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _bankName ?? 'Phone Number',
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
                leading: const Icon(Icons.dashboard_rounded),
                title: const Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                selected: _selectedIndex == 0,
                selectedTileColor: const Color(0xFFF27F0C),
                onTap: () => _onDrawerTap(0),
              ),
              const Divider(thickness: 1),
              ListTile(
                leading: const Icon(Icons.payment),
                title: const Text(
                  'Transactions',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                selected: _selectedIndex == 3,
                selectedTileColor: const Color(0xFFF27F0C),
                onTap: () => _onDrawerTap(3),
              ),
              const Divider(thickness: 1,),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text(
                  'Profile',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                selected: _selectedIndex == 4,
                selectedTileColor: const Color(0xFFF27F0C),
                onTap: () => _onDrawerTap(4),
              ),
              const Divider(thickness: 1),
            ],
          ),
        ),
        body: _getScreen(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex > 2 ? 0 : _selectedIndex,
          onTap: _onBottomTap,
          backgroundColor: const Color(0xFF1E5C78),
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
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
            color: const Color(0xFFF5F5F5),
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
                  const SizedBox(height: 5),
                  Text(
                    "₹${widget.monthExpenses.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontSize: 30,
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
                  leading: const Icon(Icons.shopping_cart, color: Color(0xFF053F5C)),
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

class FutureInsightScreen extends StatefulWidget {
  final String? username;
  final double? predictedExpense;
  final String? nextMonth;

  const FutureInsightScreen({
    super.key,
    this.username,
    required this.predictedExpense,
    required this.nextMonth,
  });

  @override
  State<FutureInsightScreen> createState() => _FutureInsightScreenState();
}

class _FutureInsightScreenState extends State<FutureInsightScreen> {
  double? predictedExpense;
  String? nextMonth;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    predictedExpense = widget.predictedExpense;
    nextMonth = widget.nextMonth;
    loadPredictedExpense();
  }

  Future<void> loadPredictedExpense() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    double? storedExpense = prefs.getDouble('predictedExpense');
    if (storedExpense != null) {
      setState(() {
        predictedExpense = storedExpense;
      });
    }
  }

  Future<void> triggerPredictionAPI() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (kDebugMode) {
        print("❌ No user logged in.");
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final url = Uri.parse(
      'https://ae60f539-d299-4b88-af7e-d19af12b951d-00-3b1kce09qe2qk.sisko.replit.dev/predict',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'uid': user.uid}), // ✅ Send UID in body
      );

      if (response.statusCode == 200) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('prediction')
            .doc('next_month')
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          final newPredictedExpense = data['predicted_expense']?.toDouble();

          // Update state with the new predicted expense
          setState(() {
            predictedExpense = newPredictedExpense;
          });

          // Save the updated expense value to SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          prefs.setDouble('predictedExpense', predictedExpense ?? 0.0);
        }
      } else {
        if (kDebugMode) {
          print("❌ Prediction API failed: ${response.body}");
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print("🔥 Error calling prediction API: $e");
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        color: const Color(0xFF053F5C),
        onRefresh: triggerPredictionAPI,
        child: ListView(
          padding: const EdgeInsets.all(10.0),
          children: [
            const SizedBox(height: 5),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Predicted Value!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Card(
              elevation: 8,
              color: const Color(0xFFF5F5F5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: Text(
                        "$nextMonth's Expenditure",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF053F5C),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    predictedExpense != null
                        ? Text(
                      "₹${predictedExpense!.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                      ),
                    )
                        : Text(
                      "Not enough data to predict 💤",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.red[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Push down to refresh",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
              ),
            ),
            const SizedBox(height: 450),
            Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                "📝 To get your predicted expense, make sure you’ve added transactions for at least 2 months.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  final List<Map<String, String>> notifications = [
    {
      "message": "Updates are available! Update your app to access more functionality.",
      "url": "https://drive.google.com/drive/folders/1GJ07mHcpegXa4DPTPsu2kH72vDwaBnyA?usp=sharing",
    },
    {
      "message": "Check out us on our website!",
      "url": "https://example.com/features",
    },
  ];

  NotificationScreen({super.key});

  void _launchURL(BuildContext context, String url) async {
    if (await canLaunchUrl(url as Uri)) {
      launchUrl;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not open the link. Please try again."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notification_important_rounded,
                      color: Color(0xFFF27F0C),
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notification["message"] ?? "",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchURL(context, notification["url"] ?? ""),
                    icon: const Icon(Icons.download_rounded, color: Colors.redAccent),
                    label: const Text(
                      ' Open  ',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: const Color(0xFF053F5C),
                        minimumSize: const Size(100, 40)
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
