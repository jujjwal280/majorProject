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

  Future<bool> _isAdmin() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        IdTokenResult idTokenResult = await user.getIdTokenResult(true);
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
                  final userName = feedback['userName'] ?? 'Unknown User';

                  return Card(
                    elevation: 8,
                    color: const Color(0xFFF5F5F5),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'User Name: $userName',
                                  style: const TextStyle(
                                      fontSize: 12
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatTimestamp(timestamp),
                                style: const TextStyle(
                                    fontSize: 12
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            feedbackText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[900],
                            ),
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
