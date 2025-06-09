import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _username;
  String? _email;
  String? _phoneNumber;
  String? _dob;
  String? _gender;
  String? _address;
  String? _bankName;
  String? _accountNumber;
  int? _age;
  String? _ifscCode;
  String? _branchAddress;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  final TextEditingController _branchAddressController = TextEditingController();

  String? _selectedBank;
  String? _selectedGender;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bankOptions = [
    'Axis Bank',
    'Bank of Baroda',
    'HDFC Bank',
    'ICICI Bank',
    'Indusland Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
    'Punjab Sindh Bank',
    'State Bank of India',
    'Union Bank of India'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserProfile();
    });
  }

  void showSnackbar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  void _fetchUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _username = userDoc['username'];
            _email = user.email;
            _phoneNumber = userDoc['phone_number'] ?? '';
            _dob = userDoc['dob'] ?? '';
            _gender = userDoc['sex'] ?? '';
            _address = userDoc['address'] ?? '';
            _bankName = userDoc['bank_name'] ?? '';
            _accountNumber = userDoc['account_number'] ?? '';
            _age = userDoc['age'] ?? 0;
            _ifscCode = userDoc['ifsc_code'] ?? '';
            _branchAddress = userDoc['branch_address'] ?? '';

            _usernameController.text = _username ?? '';
            _emailController.text = _email ?? '';
            _phoneNumberController.text = _phoneNumber ?? '';
            _dobController.text = _dob ?? '';
            _addressController.text = _address ?? '';
            _ageController.text = (_age ?? 0).toString();
            _accountNumberController.text = _accountNumber ?? '';
            _selectedGender = _genderOptions.contains(userDoc['sex']) ? userDoc['sex'] : null;
            _selectedBank = _bankOptions.contains(userDoc['bank_name']) ? userDoc['bank_name'] : null;
            _ifscCodeController.text = _ifscCode ?? 'null';
            _branchAddressController.text = _branchAddress ?? 'null';
          });
        } else {
          if (kDebugMode) {
            showSnackbar("User document does not exist");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          showSnackbar("Error fetching user profile: $e");
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load profile data")),
          );
        });
      }
    } else {
      if (kDebugMode) {
        showSnackbar("No user is signed in.");
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No user is signed in")),
        );
      });
    }
  }

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
          showSnackbar("Error updating user profile: $e");
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

  Future<void> _selectDate(BuildContext context) async {
    DateTime currentDate = DateTime.now();
    DateTime initialDate = DateTime.now();
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime(currentDate.year + 1);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null && picked != initialDate) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_username != null) ...[
                Text('Update your Profile $_username', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
              ],
              const Divider(thickness: 1),
              ExpansionTile(
                title: const Text(
                  'Personal Details :',
                  style: TextStyle(fontSize: 20),
                ),
                children: [
                  const SizedBox(height: 5),
                  TextField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneNumberController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _dobController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: InputDecoration(
                      labelText: 'Date of Birth (DD/MM/YYYY)',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    items: _genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: 'Age',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: 'Address',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 1),
              ExpansionTile(
                title: const Text(
                  'Bank Details :',
                  style: TextStyle(fontSize: 20),
                ),
                children: [
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: _selectedBank,
                    items: _bankOptions.map((String bank) {
                      return DropdownMenuItem<String>(
                        value: bank,
                        child: Text(bank),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedBank = newValue;
                      });
                    },
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _accountNumberController,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ifscCodeController,
                    decoration: InputDecoration(
                      labelText: 'IFSC Code',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _branchAddressController,
                    decoration: InputDecoration(
                      labelText: 'Branch Address',
                      filled: true,
                      fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(thickness: 1),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  onPressed: _updateUserProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    backgroundColor: const Color(0xFF053F5C),
                  ),
                  child: const Text(
                    '   Save Profile   ',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
