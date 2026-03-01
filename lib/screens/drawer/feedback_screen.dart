import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

// Unified Brand Constants
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackController = TextEditingController();
  String? _username;
  int _selectedRating = 3;
  bool _isSending = false;

  final List<IconData> _ratingIcons = [
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_satisfied_rounded,
    Icons.sentiment_very_satisfied_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _username = userDoc['username'] ?? 'User';
        });
      }
    }
  }

  Future<void> _submitFeedback() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSending = true);
    HapticFeedback.mediumImpact();

    final feedback = _feedbackController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('feedback').add({
          'feedback': feedback,
          'rating': _selectedRating + 1,
          'userName': _username,
          'email': user.email,
          'timestamp': FieldValue.serverTimestamp(),
        });

        _feedbackController.clear();
        _showSuccessDialog();
      } catch (e) {
        _showStatusSnackbar("Failed to transmit data.", isError: true);
      } finally {
        if (mounted) setState(() => _isSending = false);
      }
    }
  }

  void _showSuccessDialog() {
    final tp = Provider.of<ThemeProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tp.cardColor, // Adapts to theme
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: accentOrange, size: 60),
            const SizedBox(height: 20),
            Text("Received!", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: tp.textColor)),
            const SizedBox(height: 10),
            Text("Thanks for helping us secure your future, $_username.", textAlign: TextAlign.center, style: TextStyle(color: tp.subTextColor)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () => Navigator.pop(context),
              child: const Text("OKAY", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }

  void _showStatusSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: isError ? accentOrange : primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Inherits global background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _buildHeader(tp),
              const SizedBox(height: 40),

              Text("How is your experience?", style: TextStyle(fontWeight: FontWeight.bold, color: tp.subTextColor, fontSize: 13, letterSpacing: 1)),
              const SizedBox(height: 15),
              _buildRatingBar(tp),

              const SizedBox(height: 40),

              Text("Share your thoughts", style: TextStyle(fontWeight: FontWeight.bold, color: tp.subTextColor, fontSize: 13, letterSpacing: 1)),
              const SizedBox(height: 15),
              _buildFeedbackInput(tp),

              const SizedBox(height: 40),

              _buildSubmitButton(),

              const SizedBox(height: 50),
              _buildTeamSignature(tp),
            ],
          ),
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
            Icon(Icons.forum_rounded, color: accentOrange, size: 18),
            SizedBox(width: 8),
            Text("SUPPORT CENTER", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Improve Vault",
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor),
        ),
        Text("Your feedback fuels our innovation, $_username.", style: TextStyle(color: tp.subTextColor, fontSize: 14)),
      ],
    );
  }

  Widget _buildRatingBar(ThemeProvider tp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (index) {
        bool isSelected = _selectedRating == index;
        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            setState(() => _selectedRating = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? accentOrange : tp.cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? accentOrange.withOpacity(0.3) : Colors.black.withOpacity(tp.isDarkMode ? 0.2 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Icon(
              _ratingIcons[index],
              color: isSelected ? Colors.white : tp.subTextColor,
              size: 30,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFeedbackInput(ThemeProvider tp) {
    return Container(
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(tp.isDarkMode ? 0.2 : 0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: TextFormField(
        controller: _feedbackController,
        maxLines: 6,
        style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor),
        decoration: InputDecoration(
          hintText: "What could we do better?",
          hintStyle: TextStyle(color: tp.subTextColor.withOpacity(0.5), fontSize: 15),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (v) => (v == null || v.isEmpty) ? "Please write something" : null,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [primaryDark, Color(0xFF1E5C78)]),
        boxShadow: [BoxShadow(color: primaryDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton.icon(
        onPressed: _isSending ? null : _submitFeedback,
        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        label: const Text("TRANSMIT FEEDBACK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildTeamSignature(ThemeProvider tp) {
    return Center(
      child: Column(
        children: [
          Text("DHANRAKSHAK SECURE SYSTEMS", style: TextStyle(color: tp.subTextColor, fontSize: 9, letterSpacing: 3, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("v1.0.2-stable", style: TextStyle(color: tp.subTextColor.withOpacity(0.5), fontSize: 10)),
        ],
      ),
    );
  }
}