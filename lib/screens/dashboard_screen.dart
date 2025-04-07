import 'package:flutter/material.dart';
import 'package:flip_card/flip_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:start1/screens/transactions_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  double monthExpenses = 0;
  double predictedExpense= 0;
  String currentMonth = "";
  String nextMonth = "";
  Map<String, double> categoryExpenses = {};
  String? _username;
  String? _account_number;
  String? _bank_name;
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
            _account_number = userDoc['account_number'] ?? 'Account Number';
            _bank_name = userDoc['bank_name'] ?? 'Bank Name';
          });
        }
      } catch (e) {
        print("Error fetching user details: $e");
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
        print('Error fetching predicted expense: $e');
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

        // Get current month and year
        DateTime now = DateTime.now();
        int currentMonth = now.month;
        int currentYear = now.year;

        for (var doc in dataDocs) {
          final data = doc.data() as Map<String, dynamic>;

          if (data['amount'] != null && data['category'] != null && data['date'] != null) {
            final category = data['category'];
            final amount = data['amount'].toDouble();
            final Timestamp timestamp = data['date'];  // Firestore stores date as Timestamp
            DateTime transactionDate = timestamp.toDate();

            // Check if the transaction is in the current month and year
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
        print("Error fetching expenses: $e");
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

  void _onItemTapped(int index) {
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

  void _transactions() async {
    setState(() {
      isTransaction = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, '/transactions');
    setState(() {
      isTransaction = false;
    });
  }

  void _profile() async {
    setState(() {
      isProfile = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, '/profile');
    setState(() {
      isProfile = false;
    });
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
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
      default:
        return HomeScreen(
          username: _username,
          monthExpenses: monthExpenses,
          categoryExpenses: categoryExpenses,
          flipCardKey: _flipCardKey,
          currentMonth: currentMonth,
        );
    }
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode
          ? ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
      )
          : ThemeData.light().copyWith(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white,
      ),
      home:Scaffold(
        appBar: AppBar(
          title: const Text("Dashboard", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color(0xFF053F5C),
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu_rounded, size: 28),
                onPressed: () {
                  Scaffold.of(context).openDrawer(); // Open the drawer
                },
              );
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, size: 28), // Logout icon
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
                      // Cancel button
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
              icon: Icon(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: _toggleDarkMode,
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,  // Removes default padding
            children: [
              // Custom header
              const SizedBox(height: 25),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: const BoxDecoration(
                  color: Color(0xFF1E5C78),  // Gradient from dark blue to light blue
                ),
                child: IntrinsicHeight(  // Adjusts height according to content
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 20,  // Larger avatar size
                        backgroundColor: Colors.white,
                        child: Icon(Icons.account_circle, size: 40, color: Color(0xFF053F5C)),
                      ),
                      const SizedBox(width: 15),  // Space between avatar and text
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
                              _account_number ?? 'Phone Number',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              _bank_name ?? 'Phone Number',
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
                leading: const Icon(Icons.payment),
                title: Row(
                  children: [
                    const Text(
                      'Transactions',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isTransaction) // Check if loading is true
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: CircularProgressIndicator(color: Color(0xFF053F5C)),
                      ),
                  ],
                ),
                onTap: _transactions,
              ),
              const Divider(thickness: 1,),
              ListTile(
                leading: const Icon(Icons.person),
                title: Row(
                  children: [
                    const Text(
                      'Profile',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isProfile) // Check if loading is true
                      const Padding(
                        padding: EdgeInsets.only(left: 10),
                        child: CircularProgressIndicator(color: Color(0xFF053F5C)),
                      ),
                  ],
                ),
                onTap: _profile,
              ),
              const Divider(thickness: 1),
            ],
          ),
        ),
        body: _getScreen(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
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
                color: _selectedIndex == 0 ? const Color(0xFFF27F0C) : Colors.white,  // Change color based on selection
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.bar_chart_rounded,
                color: _selectedIndex == 1 ? const Color(0xFFF27F0C) : Colors.white,  // Change color based on selection
              ),
              label: 'Future Insights',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.notifications_none_outlined,
                color: _selectedIndex == 2 ? const Color(0xFFF27F0C) : Colors.white,  // Change color based on selection
              ),
              label: 'Notifications',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String? username;
  final double monthExpenses;
  final Map<String, double> categoryExpenses;
  final GlobalKey<FlipCardState> flipCardKey;
  final String currentMonth;

  HomeScreen({
    super.key,
    this.username,
    required this.monthExpenses,
    required this.categoryExpenses,
    required this.flipCardKey,
    required this.currentMonth,
  });


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
        children: [
          const SizedBox(height: 5),
          if (username != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'Hey, $username!',
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
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text(
                      "$currentMonth Expenditure",
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF053F5C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "₹${monthExpenses.toStringAsFixed(2)}",
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
          categoryExpenses.isEmpty
              ? const Center(
            child: Text(
              "No data available",
              style: TextStyle(color: Color(0xFF1E5C78)),
            ),
          )
              : FlipCard(
            key: flipCardKey,
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
                            sections: categoryExpenses.entries.map((entry) {
                              double percentage = (entry.value / monthExpenses) * 100;
                              return PieChartSectionData(
                                color: categoryColors[entry.key] ?? Colors.grey,
                                value: entry.value,
                                title: "${percentage.toStringAsFixed(1)}%",
                                radius: 45,
                                titleStyle: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              );
                            }).toList(),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                          onPressed: () {
                            flipCardKey.currentState?.toggleCard();
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
                flipCardKey.currentState?.toggleCard();
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Category-wise Expenditure",
                          style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Container(
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
                                        "${entry.key}",
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
          Column(
            children: categoryExpenses.entries.map((entry) {
              return Card(
                color: categoryColors[entry.key] ?? Colors.grey, // Use the category color for each entry
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.shopping_cart, color: Color(0xFF053F5C)),
                  title: Text(
                    "${entry.key}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF053F5C),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "₹${entry.value.toStringAsFixed(2)}", // Show the category amount here as well
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
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

class FutureInsightScreen extends StatelessWidget {
  final String? username;
  final double? predictedExpense; // Nullable
  final String? nextMonth;        // Nullable

  const FutureInsightScreen({
    super.key,
    this.username,
    required this.predictedExpense,
    required this.nextMonth,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ListView(
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
          const SizedBox(height: 5),

          predictedExpense == null || nextMonth == null
              ? const Center(
            child: Text(
              "Prediction unavailable.\nAdd more transactions.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1E5C78),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
              : Card(
            elevation: 8,
            color: const Color(0xFFF5F5F5),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Text(
                      "$nextMonth Expenditure",
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF053F5C),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "₹${predictedExpense!.toStringAsFixed(2)}",
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
        ],
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

  void _launchURL(BuildContext context, String url) async {
    if (await canLaunch(url)) {
      await launch(url);
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