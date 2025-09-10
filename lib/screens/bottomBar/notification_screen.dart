import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

// A simple data model class to represent a notification.
// This makes the code cleaner and safer than using raw Maps.
class AppNotification {
  final String message;
  final String url;

  AppNotification({required this.message, required this.url});

  // A factory constructor to create an AppNotification from a Firestore document.
  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      message: data['message'] ?? 'No message content',
      url: data['url'] ?? '',
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // A state variable to hold the list of notifications fetched from Firestore.
  List<AppNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch the notifications when the screen is first loaded.
    _fetchNotifications();
  }

  /// Fetches notification documents from the top-level 'notifications' collection in Firestore.
  Future<void> _fetchNotifications() async {
    // Set loading to true when refetching data
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('createdAt', descending: true) // Show newest notifications first
          .get();

      // Convert the Firestore documents into a list of AppNotification objects.
      final notifications = snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList();

      // Update the state to rebuild the UI with the new data.
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching notifications: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackbar("Failed to load notifications.");
      }
    }
  }

  void _launchURL(String url) async {
    if (url.isEmpty) {
      _showSnackbar("No link available.");
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnackbar("Could not open the link.");
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while data is being fetched.
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show a message if no notifications are found.
    if (_notifications.isEmpty) {
      return const Center(
        child: Text(
          "No notifications yet.",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Build the list of notification cards from the fetched data.
    return RefreshIndicator(
      onRefresh: _fetchNotifications, // Allow user to pull-to-refresh
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notification_important_rounded, color: Color(0xFFF27F0C), size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          notification.message,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchURL(notification.url),
                      icon: const Icon(Icons.open_in_new_rounded, color: Colors.white),
                      label: const Text('Open', style: TextStyle(fontSize: 14, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF053F5C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

