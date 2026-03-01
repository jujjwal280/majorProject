import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart'; // Ensure correct path

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  // Controllers
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // State
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  // Design System Colors
  final Color primaryDark = const Color(0xFF053F5C);
  final Color accentOrange = const Color(0xFFF27F0C);

  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    _fadeController.forward();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      _showStatusSnackbar('Welcome back to Dhanrakshak!', accentOrange);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      _showStatusSnackbar(e.message ?? 'Login failed', accentOrange);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> forgotPassword() async {
    if (emailController.text.isEmpty) {
      _showStatusSnackbar('Enter email to reset password', Colors.orange);
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text.trim());
      _showStatusSnackbar('Reset link sent to your email!', Colors.blue);
    } catch (e) {
      _showStatusSnackbar('Error sending reset link', accentOrange);
    }
  }

  void _showStatusSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: tp.scaffoldBg, // Dynamic Background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Creative Header (Remains dark for brand identity)
            _buildHeader(),

            // 2. Form Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        tp: tp,
                        controller: emailController,
                        hint: "Email Address",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 18),
                      _buildTextField(
                        tp: tp,
                        controller: passwordController,
                        hint: "Password",
                        icon: Icons.lock_outline_rounded,
                        isPassword: true,
                      ),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: forgotPassword,
                          child: Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: tp.isDarkMode ? accentOrange : primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      _buildLoginButton(),

                      const SizedBox(height: 40),

                      // 3. Social Login Section
                      _buildSocialDivider(tp),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialIcon(tp, Icons.g_mobiledata_rounded),
                          const SizedBox(width: 20),
                          _socialIcon(tp, Icons.apple_rounded),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // 4. Redirect Link
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: tp.subTextColor, fontSize: 16),
                            children: [
                              TextSpan(
                                text: "Create Account",
                                style: TextStyle(
                                  color: tp.isDarkMode ? accentOrange : primaryDark,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          height: 250,
          decoration: BoxDecoration(
            color: primaryDark,
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(80)),
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [primaryDark, const Color(0xFF1E5C78)],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  "Your secure wealth vault is ready.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required ThemeProvider tp,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tp.cardColor, // Swaps white/dark-gray
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: tp.isDarkMode ? Colors.black26 : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        style: TextStyle(color: tp.textColor, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: tp.subTextColor.withOpacity(0.5), fontSize: 14),
          prefixIcon: Icon(icon, color: tp.isDarkMode ? accentOrange : primaryDark),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: tp.subTextColor),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        ),
        validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(colors: [primaryDark, const Color(0xFF1E5C78)]),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text(
          "SECURE LOGIN",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildSocialDivider(ThemeProvider tp) {
    return Row(
      children: [
        Expanded(child: Divider(color: tp.subTextColor.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Text("OR CONNECT WITH",
              style: TextStyle(color: tp.subTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
        Expanded(child: Divider(color: tp.subTextColor.withOpacity(0.2))),
      ],
    );
  }

  Widget _socialIcon(ThemeProvider tp, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: tp.subTextColor.withOpacity(0.1)),
        color: tp.cardColor,
      ),
      child: Icon(icon, color: tp.textColor, size: 30),
    );
  }
}