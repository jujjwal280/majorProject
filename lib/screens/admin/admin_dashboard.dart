import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'admin_feedback_screen.dart';
import 'admin_users_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_analytics_screen.dart';

const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);
const Color cardBlue = Color(0xFF1E5C78);

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader(tp),
          const SizedBox(height: 30),
          _buildOverviewCards(tp),
          const SizedBox(height: 30),
          _buildSectionTitle(tp, 'Control Center'),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 1.1,
            children: [
              _adminCard(
                context,
                tp,
                title: 'Users',
                subtitle: 'Manage all users',
                icon: Icons.people_alt_rounded,
                screen: const AdminUsersScreen(),
              ),
              _adminCard(
                context,
                tp,
                title: 'Feedback',
                subtitle: 'User responses',
                icon: Icons.feedback_rounded,
                screen: const AdminFeedbackScreen(),
              ),
              _adminCard(
                context,
                tp,
                title: 'Notifications',
                subtitle: 'Send announcements',
                icon: Icons.notifications_active_rounded,
                screen: const AdminNotificationsScreen(),
              ),
              _adminCard(
                context,
                tp,
                title: 'Analytics',
                subtitle: 'App insights',
                icon: Icons.analytics_rounded,
                screen: const AdminAnalyticsScreen(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeProvider tp) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryDark, cardBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  color: accentOrange),
              SizedBox(width: 10),
              Text(
                'ADMIN CONTROL CENTER',
                style: TextStyle(
                  color: accentOrange,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              )
            ],
          ),
          SizedBox(height: 15),
          Text(
            'MoneyMinder System Core',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Manage users, analytics, feedback, alerts and AI systems.',
            style: TextStyle(
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(ThemeProvider tp) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            tp,
            title: 'Users',
            value: '1.2K',
            icon: Icons.people_rounded,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _statCard(
            tp,
            title: 'System',
            value: 'Healthy',
            icon: Icons.health_and_safety_rounded,
          ),
        ),
      ],
    );
  }

  Widget _statCard(ThemeProvider tp, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentOrange),
          const SizedBox(height: 15),
          Text(
            value,
            style: TextStyle(
              color: tp.textColor,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: tp.subTextColor,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeProvider tp, String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: tp.subTextColor,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        fontSize: 11,
      ),
    );
  }

  Widget _adminCard(BuildContext context,
      ThemeProvider tp, {
        required String title,
        required String subtitle,
        required IconData icon,
        required Widget screen,
      }) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tp.cardColor,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: tp.isDarkMode
                  ? Colors.black26
                  : Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentOrange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: accentOrange),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                color: tp.textColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: TextStyle(
                color: tp.subTextColor,
                fontSize: 12,
              ),
            )
          ],
        ),
      ),
    );
  }
}