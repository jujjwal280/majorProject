import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:intl/intl.dart';

// Brand Constants
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  Future<bool> _isAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      return doc.data()?['isAdmin'] == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access Global Theme
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      // FIX #1: Set to transparent to inherit HomeScreen's background
      backgroundColor: Colors.transparent,
      body: FutureBuilder<bool>(
        future: _isAdmin(),
        builder: (context, adminSnapshot) {
          if (adminSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: accentOrange));
          }
          if (adminSnapshot.hasError || !(adminSnapshot.data ?? false)) {
            return _buildAccessDenied(tp);
          }

          return FeedbackHub(tp: tp);
        },
      ),
    );
  }

  Widget _buildAccessDenied(ThemeProvider tp) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.gpp_maybe_rounded, size: 80, color : accentOrange),
          const SizedBox(height: 20),
          Text("Access Restricted",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: tp.textColor)),
          Text("Admin credentials required.", style: TextStyle(color: tp.subTextColor)),
        ],
      ),
    );
  }
}

class FeedbackHub extends StatelessWidget {
  final ThemeProvider tp;
  const FeedbackHub({super.key, required this.tp});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('feedback').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: accentOrange));

        final feedbacks = snapshot.data!.docs;

        return ListView(
          padding: const EdgeInsets.all(24.0),
          physics: const BouncingScrollPhysics(),
          children: [
            const SizedBox(height: 10),
            _buildHeader(),
            const SizedBox(height: 30),

            // 1. ANALYTICS CARDS (Theme Aware)
            _buildStatCards(feedbacks.length),
            const SizedBox(height: 35),

            _buildSectionLabel("User Feedback Log"),
            const SizedBox(height: 15),

            // 2. FEEDBACK TILES
            if (feedbacks.isEmpty)
              Center(child: Text("No feedback received yet.", style: TextStyle(color: tp.subTextColor)))
            else
              ...feedbacks.map((doc) => _buildFeedbackTile(context, doc)),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: accentOrange, size: 18),
            const SizedBox(width: 8),
            const Text("ADMIN COMMAND", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        Text("System Oversight",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor)),
      ],
    );
  }

  Widget _buildStatCards(int total) {
    return Row(
      children: [
        _statItem("Total Input", total.toString(), Icons.forum_rounded),
        const SizedBox(width: 15),
        _statItem("System Status", "Healthy", Icons.check_circle_outline_rounded),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: tp.cardColor,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: tp.isDarkMode ? Colors.black26 : primaryDark.withOpacity(0.04),
                blurRadius: 15, offset: const Offset(0, 8)
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REMOVED 'const' here to fix the error
            Icon(icon, color: accentOrange, size: 20),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: tp.textColor)),
            Text(label, style: TextStyle(color: tp.subTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackTile(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timestamp = data['timestamp'] as Timestamp?;
    final rating = data['rating'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: tp.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: accentOrange,
        collapsedIconColor: tp.subTextColor,
        leading: CircleAvatar(
          backgroundColor: tp.isDarkMode ? Colors.white10 : primaryDark.withOpacity(0.05),
          child: Text(data['userName']?[0] ?? '?', style: TextStyle(color: tp.textColor, fontWeight: FontWeight.bold)),
        ),
        title: Text(data['userName'] ?? 'Anonymous', style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor)),
        subtitle: Text(timestamp != null ? DateFormat('MMM d • h:mm a').format(timestamp.toDate()) : 'Recent', style: TextStyle(fontSize: 11, color: tp.subTextColor)),
        trailing: _buildRatingBadge(rating),
        childrenPadding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: tp.isDarkMode ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FEFF),
                borderRadius: BorderRadius.circular(15)
            ),
            child: Text(
              data['feedback'] ?? 'No text provided.',
              style: TextStyle(color: tp.textColor, fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _showDeleteConfirm(context, doc.id),
                icon: const Icon(Icons.delete_outline_rounded, color: accentOrange, size: 18),
                label: const Text("PURGE", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildRatingBadge(int rating) {
    if (rating == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: rating >= 4 ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: rating >= 4 ? primaryDark : Color(0xFF11698E)),
          const SizedBox(width: 4),
          Text(rating.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: rating >= 4 ? primaryDark : Color(0xFF11698E))),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String docId) {
    HapticFeedback.heavyImpact();

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
                  color: tp.cardColor, // Dynamic color
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: accentOrange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_sweep_rounded,
                        color: accentOrange,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text(
                      "Delete Feedback?",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: tp.textColor, // Dynamic color
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "This will permanently erase this feedback. Continue?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: tp.subTextColor, // Dynamic color
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),

                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text("CANCEL", style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              gradient: const LinearGradient(
                                colors: [primaryDark, Color(0xFF11698E)],
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('feedback').doc(docId).delete();
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildSectionLabel(String title) {
    return Text(title.toUpperCase(),
        style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5));
  }
}