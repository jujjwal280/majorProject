import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    final date = timestamp.toDate();
    return DateFormat('yyyy-MM-dd • hh:mm a').format(date);
  }

  // Method to check if the user is an admin
  Future<bool> _isAdmin() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        IdTokenResult idTokenResult = await user.getIdTokenResult(true);
        // Check if the 'admin' claim is true
        return idTokenResult.claims?['admin'] == true;
      }
    } catch (e) {
      print("Error getting admin status: $e");
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Feedback'),
        backgroundColor: const Color(0xFF1E5C78),
      ),
      body: FutureBuilder<bool>(
        future: _isAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching admin status'));
          }

          bool isAdmin = snapshot.data ?? false;

          if (!isAdmin) {
            return const Center(child: Text('You are not authorized to view feedback.'));
          }

          // If the user is an admin, fetch feedback
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

              return ListView.builder(
                itemCount: feedbacks.length,
                padding: const EdgeInsets.all(10),
                itemBuilder: (context, index) {
                  final feedback = feedbacks[index];
                  final feedbackText = feedback['feedback'] ?? 'No feedback';
                  final timestamp = feedback['timestamp'];
                  final userId = feedback['userId'] ?? 'Unknown User';

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            feedbackText,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'User ID: $userId',
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatTimestamp(timestamp),
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
