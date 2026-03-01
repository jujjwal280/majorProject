import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

// Brand Constants
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);

class UserCardScreen extends StatefulWidget {
  const UserCardScreen({super.key});

  @override
  State<UserCardScreen> createState() => _UserCardScreenState();
}

class _UserCardScreenState extends State<UserCardScreen> {
  String? _username;
  String? _email;
  String? _bankName;
  String? _accountNumber;
  DateTime? _createdAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _username = doc.data()?['username'];
          _email = doc.data()?['email'];
          _bankName = doc.data()?['bank_name'];
          _accountNumber = doc.data()?['account_number'];
          _createdAt = (doc.data()?['createdAt'] as Timestamp?)?.toDate();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Access the global theme provider
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // FIX: Set to transparent so HomeScreen's background shows through
      backgroundColor: Colors.transparent,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentOrange))
          : ListView(
        padding: const EdgeInsets.all(24),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 10),
          _buildHeader(tp),
          const SizedBox(height: 30),

          // 1. THE IDENTITY CARD (Shadows and accents adapt to theme)
          _buildIdentityCard(tp),

          const SizedBox(height: 40),

          // 2. ACCOUNT SETTINGS SECTION
          _buildSectionTitle("Account Security", tp),
          _buildMenuTile(Icons.shield_outlined, "Security Settings", "Manage passwords & biometric", tp),
          _buildMenuTile(Icons.account_balance_outlined, "Bank Details", _bankName ?? "Not linked", tp),

          const SizedBox(height: 30),

          // 3. APP SETTINGS SECTION
          _buildSectionTitle("Preferences", tp),
          _buildMenuTile(Icons.notifications_none_rounded, "Notifications", "Custom alerts & reminders", tp),
          _buildMenuTile(Icons.data_exploration_outlined, "Export Data", "Download transaction history (CSV)", tp),

          const SizedBox(height: 50),

          // 4. TEAM SIGNATURE
          _buildTeamFooter(tp),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeProvider tp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.person_pin_rounded, color: accentOrange, size: 20),
            SizedBox(width: 8),
            Text("USER PROFILE", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
            "Member Settings",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor)
        ),
      ],
    );
  }

  Widget _buildIdentityCard(ThemeProvider tp) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, Color(0xFF1E5C78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            // Shadow is stronger in dark mode to provide depth
              color: tp.isDarkMode ? Colors.black.withOpacity(0.5) : primaryDark.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10)
          ),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_rounded, size: 50, color: primaryDark),
          ),
          const SizedBox(height: 20),
          Text(
            _username ?? "Member",
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            _email ?? "User email",
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Member Since", _createdAt != null ? DateFormat('MMM yyyy').format(_createdAt!) : "---"),
              _buildStatItem("Status", "Verified"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeProvider tp) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, left: 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, String subtitle, ThemeProvider tp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
              color: tp.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.03),
              blurRadius: 10
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // FIXED: Changed 'backgroundColor' to 'color'
              color: tp.isDarkMode ? Colors.white.withOpacity(0.05) : primaryDark.withOpacity(0.05),
              shape: BoxShape.circle
          ),
          child: Icon(icon, color: tp.isDarkMode ? accentOrange : primaryDark, size: 22),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: tp.subTextColor)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: tp.subTextColor),
        onTap: () {
          HapticFeedback.lightImpact();
        },
      ),
    );
  }

  Widget _buildTeamFooter(ThemeProvider tp) {
    return Column(
      children: [
        Divider(color: tp.isDarkMode ? Colors.white10 : Colors.black12),
        const SizedBox(height: 20),
        Text("POWERED BY", style: TextStyle(color: tp.subTextColor, fontSize: 10, letterSpacing: 3)),
        const SizedBox(height: 8),
        Text(
          "TEAM DHANRAKSHAK",
          style: TextStyle(
            color: tp.textColor.withOpacity(0.8),
            fontWeight: FontWeight.w900,
            fontSize: 16,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}