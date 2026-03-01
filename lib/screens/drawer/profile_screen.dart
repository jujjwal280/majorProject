import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

// Brand Constants
const Color primaryDark = Color(0xFF053F5C);
const Color accentOrange = Color(0xFFF27F0C);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _branchAddressController = TextEditingController();

  String? _selectedGender;
  String? _selectedBank;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bankOptions = [
    'Axis Bank', 'Bank of Baroda', 'HDFC Bank', 'ICICI Bank', 'Indusland Bank',
    'Kotak Mahindra Bank', 'Punjab National Bank', 'State Bank of India', 'Union Bank of India'
  ];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _branchAddressController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneNumberController.text = data['phone_number'] ?? '';
          _dobController.text = data['dob'] ?? '';
          _addressController.text = data['address'] ?? '';
          _ageController.text = (data['age'] ?? '').toString();
          _accountNumberController.text = data['account_number'] ?? '';
          _ifscCodeController.text = data['ifsc_code'] ?? '';
          _branchAddressController.text = data['branch_address'] ?? '';
          _selectedGender = _genderOptions.contains(data['sex']) ? data['sex'] : null;
          _selectedBank = _bankOptions.contains(data['bank_name']) ? data['bank_name'] : null;
        });
      }
    } catch (e) {
      _showStatusSnackbar("Vault sync failed.", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _updateUserProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _usernameController.text.trim(),
          'phone_number': _phoneNumberController.text.trim(),
          'dob': _dobController.text,
          'sex': _selectedGender,
          'address': _addressController.text.trim(),
          'bank_name': _selectedBank,
          'account_number': _accountNumberController.text.trim(),
          'age': int.tryParse(_ageController.text) ?? 0,
          'ifsc_code': _ifscCodeController.text.trim(),
          'branch_address': _branchAddressController.text.trim(),
        });

        _showStatusSnackbar("Identity secured successfully!");
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        });
      } catch (e) {
        _showStatusSnackbar("Vault update failed.", isError: true);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showStatusSnackbar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: isError ? primaryDark : const Color(0xFF11698E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Fix: Inherits dark/light bg from Home
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accentOrange))
          : _buildProfileContent(tp),
    );
  }

  Widget _buildProfileContent(ThemeProvider tp) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 10),
          _buildHeader(tp),
          const SizedBox(height: 30),

          // CLICKABLE AVATAR
          _buildClickableAvatar(tp),
          const SizedBox(height: 40),

          // PERSONAL DETAILS
          _buildSectionLabel(tp, "Personal Identity"),
          _buildVaultCard(tp, [
            _buildTextField(tp, _usernameController, "Username", Icons.person_outline),
            _buildTextField(tp, _emailController, "Vault Email", Icons.alternate_email, enabled: false),
            _buildTextField(tp, _phoneNumberController, "Phone Number", Icons.phone_android_rounded, type: TextInputType.phone),
            _buildTextField(tp, _dobController, "Date of Birth", Icons.calendar_today_rounded, readOnly: true, onTap: () => _selectDate(context)),
            _buildDropdown(tp, "Gender", Icons.face_rounded, _genderOptions, _selectedGender, (v) => setState(() => _selectedGender = v)),
            _buildTextField(tp, _ageController, "Age", Icons.cake_outlined, type: TextInputType.number),
            _buildTextField(tp, _addressController, "Residential Address", Icons.location_on_outlined),
          ]),

          const SizedBox(height: 30),

          // FINANCIAL VAULT
          _buildSectionLabel(tp, "Bank Connection"),
          _buildVaultCard(tp, [
            _buildDropdown(tp, "Primary Bank", Icons.account_balance_rounded, _bankOptions, _selectedBank, (v) => setState(() => _selectedBank = v)),
            _buildTextField(tp, _accountNumberController, "Account Number", Icons.numbers_rounded, type: TextInputType.number),
            _buildTextField(tp, _ifscCodeController, "IFSC Code", Icons.qr_code_rounded),
            _buildTextField(tp, _branchAddressController, "Branch Details", Icons.map_rounded),
          ]),

          const SizedBox(height: 40),

          _buildSaveButton(),
          const SizedBox(height: 50),
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
            Icon(Icons.security_rounded, color: accentOrange, size: 16),
            SizedBox(width: 8),
            Text("VAULT ACCESS", style: TextStyle(color: accentOrange, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 8),
        Text("Edit Identity", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: tp.textColor)),
      ],
    );
  }

  Widget _buildClickableAvatar(ThemeProvider tp) {
    return Center(
      child: InkWell(
        onTap: () => _showStatusSnackbar("Upload feature coming soon!"),
        borderRadius: BorderRadius.circular(60),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: accentOrange, width: 2)),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: primaryDark,
                child: Text(
                  _usernameController.text.isNotEmpty ? _usernameController.text[0].toUpperCase() : "?",
                  style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w900),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: accentOrange, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVaultCard(ThemeProvider tp, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tp.cardColor,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(tp.isDarkMode ? 0.2 : 0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSectionLabel(ThemeProvider tp, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 15),
      child: Text(title.toUpperCase(), style: TextStyle(color: tp.subTextColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
    );
  }

  Widget _buildTextField(ThemeProvider tp, TextEditingController ctrl, String label, IconData icon, {bool enabled = true, bool readOnly = false, VoidCallback? onTap, TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: type,
        style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor),
        decoration: _inputDecor(tp, label, icon),
        validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
      ),
    );
  }

  Widget _buildDropdown(ThemeProvider tp, String label, IconData icon, List<String> options, String? value, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        dropdownColor: tp.cardColor,
        value: value,
        items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: TextStyle(color: tp.textColor)))).toList(),
        onChanged: onChanged,
        style: TextStyle(fontWeight: FontWeight.bold, color: tp.textColor),
        decoration: _inputDecor(tp, label, icon),
      ),
    );
  }

  InputDecoration _inputDecor(ThemeProvider tp, String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: tp.subTextColor.withOpacity(0.5), fontSize: 12),
      prefixIcon: Icon(icon, color: tp.isDarkMode ? accentOrange : primaryDark, size: 20),
      filled: true,
      fillColor: tp.isDarkMode ? Colors.white.withOpacity(0.03) : const Color(0xFFF8FEFF),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: accentOrange, width: 1.5)),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [primaryDark, Color(0xFF1E5C78)]),
        boxShadow: [BoxShadow(color: primaryDark.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _updateUserProfile,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: _isSaving
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text("SAVE SECURE DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryDark, onPrimary: Colors.white, onSurface: primaryDark),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dobController.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }
}