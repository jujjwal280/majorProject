import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For better date formatting

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // A key to identify and validate the form
  final _formKey = GlobalKey<FormState>();

  // Controllers to manage the text in each form field
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _branchAddressController = TextEditingController();

  // Variables to hold the selected values from dropdowns
  String? _selectedGender;
  String? _selectedBank;

  // Options for the dropdown menus
  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bankOptions = [
    'Axis Bank', 'Bank of Baroda', 'HDFC Bank', 'ICICI Bank', 'Indusland Bank',
    'Kotak Mahindra Bank', 'Punjab National Bank', 'State Bank of India', 'Union Bank of India'
  ];

  // State flags to manage the UI based on data loading/saving
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Fetch user data as soon as the widget is initialized
    _fetchUserProfile();
  }

  @override
  void dispose() {
    // Clean up controllers to free up resources when the widget is removed
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

  /// Fetches user profile data from Firestore and updates the UI.
  Future<void> _fetchUserProfile() async {
    // Ensure the widget is still in the tree before updating state
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackbar("No user is signed in.", isError: true);
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      if (doc.exists && mounted) {
        final data = doc.data()!;
        // Populate controllers and state variables with fetched data
        _usernameController.text = data['username'] ?? '';
        _emailController.text = user.email ?? '';
        _phoneNumberController.text = data['phone_number'] ?? '';
        _dobController.text = data['dob'] ?? '';
        _addressController.text = data['address'] ?? '';
        _ageController.text = (data['age'] ?? 0).toString();
        _accountNumberController.text = data['account_number'] ?? '';
        _ifscCodeController.text = data['ifsc_code'] ?? '';
        _branchAddressController.text = data['branch_address'] ?? '';

        // Safely set dropdown values
        _selectedGender = _genderOptions.contains(data['sex']) ? data['sex'] : null;
        _selectedBank = _bankOptions.contains(data['bank_name']) ? data['bank_name'] : null;

      }
    } catch (e) {
      _showSnackbar("Failed to load profile data.", isError: true);
      _hasError = true;
    } finally {
      // Ensure loading is turned off regardless of success or failure
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Validates the form and updates the user profile in Firestore.
  void _updateUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'username': _usernameController.text,
          'email': _emailController.text,
          'phone_number': _phoneNumberController.text,
          'dob': _dobController.text,
          'sex': _selectedGender,
          'address': _addressController.text,
          'bank_name': _selectedBank,
          'account_number': _accountNumberController.text,
          'age': int.tryParse(_ageController.text) ?? 0,
          'ifsc_code': _ifscCodeController.text,
          'branch_address': _branchAddressController.text,
        });

        // Show a success message deferred after frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully")),
          );
        });
      } catch (e) {
        if (kDebugMode) {
          _showSnackbar("Error updating user profile: $e");
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update profile")),
          );
        });
      }
    }

    // Also delay navigation after frame so context is safe
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  /// Displays a date picker and updates the date of birth field.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        // Format the date to a more readable string
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  /// Helper to show a SnackBar with a message.
  void _showSnackbar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Failed to load profile.', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _fetchUserProfile,
              child: const Text('Retry'),
            )
          ],
        ),
      )
          : _buildProfileForm(),
    );
  }

  /// Builds the main form widget with all the input fields.
  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        children: [
          // --- HEADER SECTION ---
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: const Color(0xFF9FE7F5).withOpacity(0.5),
                  child: const Icon(Icons.person, size: 50, color: Color(0xFF1E5C78)),
                ),
                const SizedBox(height: 12),
                Text(
                  _usernameController.text.isNotEmpty ? _usernameController.text : "User Profile",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  _emailController.text,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- PERSONAL DETAILS CARD ---
          _buildSectionCard(
            title: 'Personal Details',
            icon: Icons.person_outline,
            children: [
              TextFormField(controller: _usernameController, decoration: _buildInputDecoration(labelText: 'Username'), validator: (v) => v!.isEmpty ? 'Username cannot be empty' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _emailController, readOnly: true, decoration: _buildInputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextFormField(controller: _phoneNumberController, keyboardType: TextInputType.phone, decoration: _buildInputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 12),
              TextFormField(controller: _dobController, readOnly: true, onTap: () => _selectDate(context), decoration: _buildInputDecoration(labelText: 'Date of Birth')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(value: _selectedGender, items: _genderOptions.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _selectedGender = v), decoration: _buildInputDecoration(labelText: 'Gender')),
              const SizedBox(height: 12),
              TextFormField(controller: _ageController, keyboardType: TextInputType.number, decoration: _buildInputDecoration(labelText: 'Age')),
              const SizedBox(height: 12),
              TextFormField(controller: _addressController, decoration: _buildInputDecoration(labelText: 'Address')),
            ],
          ),
          const SizedBox(height: 20),

          // --- BANK DETAILS CARD ---
          _buildSectionCard(
            title: 'Bank Details',
            icon: Icons.account_balance,
            children: [
              DropdownButtonFormField<String>(value: _selectedBank, items: _bankOptions.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(), onChanged: (v) => setState(() => _selectedBank = v), decoration: _buildInputDecoration(labelText: 'Bank Name')),
              const SizedBox(height: 12),
              TextFormField(controller: _accountNumberController, keyboardType: TextInputType.number, decoration: _buildInputDecoration(labelText: 'Account Number')),
              const SizedBox(height: 12),
              TextFormField(controller: _ifscCodeController, decoration: _buildInputDecoration(labelText: 'IFSC Code')),
              const SizedBox(height: 12),
              TextFormField(controller: _branchAddressController, decoration: _buildInputDecoration(labelText: 'Branch Address')),
            ],
          ),
          const SizedBox(height: 30),

          // --- SAVE BUTTON ---
          ElevatedButton(
            onPressed: _isSaving ? null : _updateUserProfile,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              backgroundColor: const Color(0xFF053F5C),
            ),
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : const Text('Save Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// Helper method for consistent section styling
  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF053F5C)),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 20, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  /// Helper method for consistent InputDecoration styling
  InputDecoration _buildInputDecoration({required String labelText}) {
    return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
    focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),),
    enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    borderSide: const BorderSide(color: Color(0xFF429EBD), width: 1.5),),
    border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(15),
    ),
    );
  }
}