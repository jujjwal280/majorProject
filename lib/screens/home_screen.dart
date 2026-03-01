import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flip_card/flip_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'bottomBar/insight_screen.dart';
import 'bottomBar/notification_screen.dart';
import 'drawer/admin_screen.dart';
import 'drawer/feedback_screen.dart';
import 'drawer/profile_screen.dart';
import 'drawer/transactions_screen.dart';
import 'drawer/usercard_screen.dart';

// --- Global Design Constants ---
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);
const Color cardBlue = Color(0xFF1E5C78);
const Color bgLight = Color(0xFFF8FEFF);

// UPDATED: Category Colors as per your instruction
final Map<String, Color> categoryColors = {
  'Groceries': const Color(0xFFECB762),
  'Transportation': const Color(0xFFA5CCA9),
  'Entertainment': const Color(0xFFF4BAB0),
  'Rent': const Color(0xFFB2967D),
  'Dining Out': const Color(0xFFF47F7D),
  'Other': Colors.grey,
};

// HELPER: Category Icons for a "Major Project" look
final Map<String, IconData> categoryIcons = {
  'Groceries': Icons.shopping_cart_rounded,
  'Transportation': Icons.directions_bus_rounded,
  'Entertainment': Icons.movie_creation_rounded,
  'Rent': Icons.home_work_rounded,
  'Dining Out': Icons.restaurant_rounded,
  'Other': Icons.miscellaneous_services_rounded,
};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Logic Variables (700+ lines context preserved)
  bool isAdmin = false;
  int _selectedIndex = 0;
  double monthExpenses = 0;
  double predictedExpense = 0;
  String currentMonth = "";
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
  }

  // --- PRESERVED CORE LOGIC ---
  void _fetchUserDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          setState(() {
            _username = userDoc['username'] ?? 'User Name';
            _accountNumber = userDoc['account_number'] ?? 'XXXX XXXX XXXX';
            _bankName = userDoc['bank_name'] ?? 'Bank Name';
            isAdmin = userDoc['isAdmin'] ?? false;
          });
        }
      } catch (e) {
        if (kDebugMode) print("User fetch error: $e");
      }
    }
  }

  void _fetchExpenses() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DateTime now = DateTime.now();
        DateTime startOfMonth = DateTime(now.year, now.month, 1);
        DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);

        final QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).collection('transactions')
            .where('date', isGreaterThanOrEqualTo: startOfMonth)
            .where('date', isLessThan: endOfMonth)
            .get();

        Map<String, double> tempCategoryExpenses = {};
        double total = 0;

        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['amount'] != null && data['category'] != null) {
            final amount = (data['amount'] as num).toDouble();
            total += amount;
            tempCategoryExpenses.update(data['category'], (v) => v + amount, ifAbsent: () => amount);
          }
        }
        setState(() {
          monthExpenses = total;
          categoryExpenses = tempCategoryExpenses;
        });
      } catch (e) {
        if (kDebugMode) print("Expense fetch error: $e");
      }
    }
  }

  void _fetchPredictedExpense() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).collection('prediction').doc('next_month').get();
        if (snapshot.exists) {
          setState(() => predictedExpense = (snapshot.data()?['predicted_expense'] ?? 0.0).toDouble());
        }
      } catch (e) {
        if (kDebugMode) print('Prediction fetch error: $e');
      }
    }
  }

  String _getCurrentMonth() => ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][DateTime.now().month - 1];

  @override
  Widget build(BuildContext context) {
    // 1. Listen to the provider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // 2. Dynamic background color
      backgroundColor: themeProvider.isDarkMode ? const Color(0xFF121212) : bgLight,
      appBar: _buildConnectedAppBar(themeProvider),
      drawer: _buildModernDrawer(themeProvider),
      // Pass themeProvider down to screens if necessary,
      // though they can also call Provider.of themselves.
      body: _getScreen(_selectedIndex),
      bottomNavigationBar: _buildBottomNav(themeProvider),
    );
  }

  AppBar _buildConnectedAppBar(ThemeProvider tp) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      title: const Text("MONEYMINDER",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white)),
      backgroundColor: primaryDark,
      leading: Builder(builder: (context) => IconButton(
          icon: const Icon(Icons.notes_rounded, color: Colors.white),
          onPressed: () => Scaffold.of(context).openDrawer())),
      actions: [
        // THEME TOGGLE BUTTON
        IconButton(
            icon: Icon(
                tp.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: Colors.white
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              tp.toggleTheme(); // This triggers notifyListeners() in your Provider
            }
        ),
        IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => _showLogoutDialog()
        ),
      ],
    );
  }

  Widget _buildModernDrawer(ThemeProvider tp) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.75,
      backgroundColor: tp.isDarkMode ? const Color(0xFF0A0A0A) : bgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: Column(
        children: [
          // 1. CREATIVE HEADER
          _drawerHeader(tp),

          const SizedBox(height: 20),

          // 2. SCROLLABLE MENU ITEMS
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    _drawerTile(Icons.grid_view_rounded, 'Dashboard', 0, tp),
                    _drawerTile(Icons.receipt_long_rounded, 'Transactions', 3, tp),
                    _drawerTile(Icons.person_3_rounded, 'Profile Vault', 4, tp),
                    _drawerTile(Icons.credit_card_rounded, 'My Digital ID', 7, tp),
                    _drawerTile(Icons.chat_bubble_outline_rounded, 'Help & Feedback', 5, tp),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                      child: Divider(color: Colors.black12, thickness: 1),
                    ),

                    if (isAdmin)
                      _drawerTile(Icons.admin_panel_settings_rounded, 'Admin Console', 6, tp),
                  ],
                ),
              ),
            ),
          ),

          // 3. LOGOUT & FOOTER
          _drawerFooter(),
        ],
      ),
    );
  }

  Widget _drawerHeader(ThemeProvider tp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 60, 20, 30),
      decoration: const BoxDecoration(
        color: primaryDark,
        borderRadius: BorderRadius.only(
          bottomRight: Radius.circular(60),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _selectedIndex = 7);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: accentOrange,
                    shape: BoxShape.circle,
                  ),
                  child: const CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person_rounded,
                      size: 35,
                      color: primaryDark,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 15),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _username ?? 'Authorized User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _bankName ?? 'RBI',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      _accountNumber ?? 'ID: DHAN-001',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: accentOrange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentOrange.withOpacity(0.5),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: accentOrange,
                    ),
                    SizedBox(width: 6),
                    Text(
                      "SECURE",
                      style: TextStyle(
                        color: accentOrange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // Vault Status Badge

        ],
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, int index, ThemeProvider tp) {
    bool isSelected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          decoration: BoxDecoration(
            color: isSelected ? accentOrange.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? accentOrange : (tp.isDarkMode ? Colors.white70 : primaryDark.withOpacity(0.7)),
                size: 24,
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  color: isSelected ? accentOrange : (tp.isDarkMode ? Colors.white : primaryDark),
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(color: accentOrange, shape: BoxShape.circle),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerFooter() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          child: InkWell(
            onTap: () => _showLogoutDialog(),
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, color: accentOrange, size: 22),
                const SizedBox(width: 15),
                Text(
                  "Log Out",
                  style: TextStyle(color: accentOrange.withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          color: primaryDark.withOpacity(0.05),
          child: Column(
            children: [
              const Text(
                "DHANRAKSHAK",
                style: TextStyle(color: primaryDark, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 3),
              ),
              Text(
                "v1.0.5 Powered by AI",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 9),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Add 'ThemeProvider tp' inside the parentheses
  Widget _buildBottomNav(ThemeProvider tp) {
    return Container(
      decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30)
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex > 2 ? 0 : _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          // Use the provider to change colors dynamically
          backgroundColor: tp.isDarkMode ? const Color(0xFF1A1A1A) : primaryDark,
          selectedItemColor: accentOrange,
          unselectedItemColor: tp.isDarkMode ? Colors.white38 : Colors.white54,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: 'Insights'),
            BottomNavigationBarItem(icon: Icon(Icons.notifications_rounded), label: 'Alerts'),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    // Access the theme provider before opening the dialog
    final tp = Provider.of<ThemeProvider>(context, listen: false);

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
                  // Dynamic background: White in light mode, surfaceDark in dark mode
                  color: tp.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: tp.isDarkMode ? Colors.black54 : primaryDark.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Creative Exit Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.power_settings_new_rounded,
                        color: accentOrange,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Themed Typography
                    Text(
                      "Secure Logout",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        // Dynamic text color from Provider
                        color: tp.textColor,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Are you sure you want to end your secure session?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        // Dynamic sub-text color from Provider
                        color: tp.subTextColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // 3. Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              "STAY",
                              style: TextStyle(
                                // Using subTextColor so it looks like a secondary action
                                color: tp.subTextColor,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: LinearGradient(
                                // Optional: Shift gradient colors slightly for dark mode
                                colors: tp.isDarkMode
                                    ? [accentOrange, const Color(0xFFD46A00)]
                                    : [primaryDark, const Color(0xFF11698E)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _logout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: const Text(
                                "LOGOUT",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
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

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
      // Index 0: The Main Dashboard we just refined
        return DashboardScreen(
          username: _username,
          monthExpenses: monthExpenses,
          categoryExpenses: categoryExpenses,
          flipCardKey: _flipCardKey,
          currentMonth: currentMonth,
        );
      case 1:
      // Index 1: The AI Future Insight Screen we refined earlier
        return const FutureInsightScreen();
      case 2:
      // Index 2: The Notification Screen (Ensure you have this file imported)
        return const NotificationScreen();
      case 3:
      // Index 3: Transactions (Usually called from Drawer or a deeper tap)
        return TransactionsScreen(
          onTransactionChanged: _fetchExpenses,
        );
      case 4:
        return const ProfileScreen();
      case 5:
        return const FeedbackScreen();
      case 6:
        return const AdminScreen();
      case 7:
        return const UserCardScreen();
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
}

class DashboardScreen extends StatefulWidget {
  final String? username;
  final double monthExpenses;
  final Map<String, double> categoryExpenses;
  final GlobalKey<FlipCardState> flipCardKey;
  final String currentMonth;

  const DashboardScreen({super.key, this.username, required this.monthExpenses, required this.categoryExpenses, required this.flipCardKey, required this.currentMonth});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),

      children: [
        if (widget.username != null)
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.air_rounded, color: accentOrange, size: 20),
              const SizedBox(width: 8),
              Text("WELCOME BACK "+ '${widget.username}!', style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ],
          ),

        const SizedBox(height: 25),

        // --- THE DIGITAL WALLET CARD ---
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [primaryDark, cardBlue], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: primaryDark.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("${widget.currentMonth} Overview", style: const TextStyle(color: Colors.white70, fontSize: 16)),
                  const Icon(Icons.auto_graph_rounded, color: accentOrange),
                ],
              ),
              const SizedBox(height: 12),
              Text("₹ ${widget.monthExpenses.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(value: 0.6, backgroundColor: Colors.white10, color: accentOrange, minHeight: 6),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // --- FLIP CHART SECTION (Updated for Donut) ---
        widget.categoryExpenses.isEmpty
            ? const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No transactions yet.")))
            : FlipCard(
          key: widget.flipCardKey,
          front: _chartContainer(child: _buildDonutChart()),
          back: _chartContainer(child: _buildLegend()),
        ),

        const SizedBox(height: 20),
        const Text("Spending Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDark)),
        const SizedBox(height: 15),

        // --- UPDATED CATEGORY TILES ---
        ...widget.categoryExpenses.entries.map((entry) => _categoryTile(entry.key, entry.value)),
      ],
    );
  }

  Widget _chartContainer({required Widget child}) {
    return Container(
      height: 280,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: primaryDark, borderRadius: BorderRadius.circular(30)),
      child: Stack(
        children: [
          Center(child: child),
          Positioned(right: 15, top: 15, child: IconButton(icon: const Icon(Icons.info_outline, color: accentOrange), onPressed: () => widget.flipCardKey.currentState?.toggleCard())),
        ],
      ),
    );
  }

  Widget _buildDonutChart() {
    return PieChart(
      PieChartData(
        centerSpaceRadius: 60,
        sectionsSpace: 5,
        sections: widget.categoryExpenses.entries.toList().asMap().entries.map((entry) {
          final isTouched = entry.key == touchedIndex;
          final mapEntry = entry.value;

          // Calculate percentage for the title
          final double percentage = widget.monthExpenses > 0
              ? (mapEntry.value / widget.monthExpenses) * 100
              : 0;

          return PieChartSectionData(
            color: categoryColors[mapEntry.key] ?? Colors.grey,
            value: mapEntry.value,
            // Show percentage string (e.g., "15.5%")
            title: '${percentage.toStringAsFixed(1)}%',
            radius: isTouched ? 45 : 35, // Increased radius to fit text better
            titleStyle: TextStyle(
              fontSize: isTouched ? 14 : 11,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
            titlePositionPercentageOffset: 0.55, // Centers the text in the segment
          );
        }).toList(),
        pieTouchData: PieTouchData(touchCallback: (event, response) {
          setState(() => touchedIndex = response?.touchedSection?.touchedSectionIndex);
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Wrap(
        spacing: 15, runSpacing: 15,
        children: categoryColors.entries.map((e) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(radius: 6, backgroundColor: e.value),
            const SizedBox(width: 8),
            Text(e.key, style: const TextStyle(color: Colors.white, fontSize: 13)),
          ],
        )).toList(),
      ),
    );
  }

  Widget _categoryTile(String category, double amount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: categoryColors[category] ?? Colors.grey, width: 6)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: (categoryColors[category] ?? Colors.grey).withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(categoryIcons[category] ?? Icons.category_rounded, size: 20, color: categoryColors[category] ?? Colors.grey),
              ),
              const SizedBox(width: 15),
              Text(category, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryDark, fontSize: 16)),
            ],
          ),
          Text("₹ ${amount.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, color: accentOrange)),
        ],
      ),
    );
  }
}