import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

// Unified Brand Constants
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);

// 1. DATA MODEL (Fixed: "Type not found" error)
class AppNotification {
  final String message;
  final String url;
  final Timestamp? createdAt;

  AppNotification({required this.message, required this.url, this.createdAt});

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      message: data['message'] ?? 'No message content',
      url: data['url'] ?? '',
      createdAt: data['createdAt'] as Timestamp?,
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // 2. FETCH LOGIC (Fixed: "Method not defined" error)
  Future<void> _fetchNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .get();

      final notifications = snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 3. URL LOGIC (Fixed: "Method not defined" error)
  void _launchURL(String url) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Connected Theme Fix
      body: RefreshIndicator(
        color: accentOrange,
        onRefresh: _fetchNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: accentOrange))
            : ListView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 10),
            _buildHeader(tp),
            const SizedBox(height: 30),

            if (_notifications.isEmpty)
              _buildEmptyState()
            else
              ..._notifications.map((note) => _buildNotificationCard(note, tp)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeProvider tp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.notifications_active_outlined, color: accentOrange, size: 20),
            SizedBox(width: 8),
            Text(
                "NOTIFICATIONS",
                style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Recent Activity",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor),
        ),
      ],
    );
  }

  Widget _buildNotificationCard(AppNotification note, ThemeProvider tp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: tp.isDarkMode ? Colors.black26 : primaryDark.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 6,
              decoration: const BoxDecoration(
                color: accentOrange,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note.message,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tp.textColor,
                          fontSize: 16,
                          height: 1.3
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            "MoneyMinder System",
                            style: TextStyle(color: tp.subTextColor, fontSize: 11, fontWeight: FontWeight.bold)
                        ),
                        if (note.url.isNotEmpty)
                          _buildDetailsButton(note.url, tp),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsButton(String url, ThemeProvider tp) {
    return GestureDetector(
      onTap: () => _launchURL(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: tp.isDarkMode ? accentOrange : primaryDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(
                "DETAILS",
                style: TextStyle(color: tp.isDarkMode ? primaryDark : Colors.white, fontSize: 10, fontWeight: FontWeight.w900)
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_outward_rounded, color: tp.isDarkMode ? primaryDark : Colors.white, size: 12),
          ],
        ),
      ),
    );
  }

  // 4. EMPTY STATE HELPER (Fixed: "Method not defined" error)
  Widget _buildEmptyState() {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Icon(Icons.notifications_none_rounded, size: 60, color: Colors.grey.withOpacity(0.3)),
        const SizedBox(height: 16),
        const Text(
            "All caught up!",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}