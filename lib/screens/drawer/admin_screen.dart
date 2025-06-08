
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<bool> _isAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['isAdmin'] == true;
    } catch (e) {
      debugPrint('Error checking admin: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<bool>(
        future: _isAdmin(),
        builder: (context, adminSnapshot) {
          if (adminSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (adminSnapshot.hasError || !(adminSnapshot.data ?? false)) {
            return const Center(child: Text('You are not authorized to view feedback.'));
          }

          // Admin is authorized, show feedback list
          return FeedbackList();
        },
      ),
    );
  }
}

class FeedbackList extends StatelessWidget {
  FeedbackList({super.key});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    return DateFormat('yyyy-MM-dd • hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error fetching feedback'));
        }

        final feedbacks = snapshot.data?.docs ?? [];
        if (feedbacks.isEmpty) {
          return const Center(child: Text('No feedbacks available.'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hello Admin 👋',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ExpansionTile(
                  title: Text(
                    'Feedbacks (${feedbacks.length})',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  children: feedbacks.map((doc) {
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final feedbackText = data['feedback'] ?? 'No feedback';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final userName = data['userName'] ?? 'Unknown User';

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      elevation: 3,
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'User: $userName',
                                style: const TextStyle(fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatTimestamp(timestamp),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_rounded,
                                color: Colors.red,
                                size: 28,
                              ),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text(
                                        'Are you sure you want to delete?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
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
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: const Text(
                                            '  Delete   ',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    await FirebaseFirestore.instance
                                        .collection('feedback')
                                        .doc(doc.id)
                                        .delete();
                                  }
                                }
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Text(
                              feedbackText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[900],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
