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
  bool isDashboard = false;
  bool isProfile = false;
  bool isTransaction = false;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  String? _selectedGender;
  String? _selectedBank;
  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _bankOptions = [
    'Axis Bank',
    'Bank of Baroda',
    'HDFC Bank',
    'ICICI Bank',
    'Indusland Bank',
    'Kotak Mahindra Bank',
    'Punjab National Bank',
    'Punjab Sindh Bank'
    'State Bank of India',
    'Union Bank of India'
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _fetchUserProfile() async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Safely access the user.uid
      if (kDebugMode) {
        print("User UID: ${user.uid}");
      }

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

            // Initialize the controllers with fetched data
            _usernameController.text = _username ?? '';
            _emailController.text = _email ?? '';
            _phoneNumberController.text = _phoneNumber ?? '';
            _dobController.text = _dob ?? '';
            _addressController.text = _address ?? '';
            _ageController.text = (_age ?? 0).toString();
            _accountNumberController.text = _accountNumber ?? '';
            _selectedGender = _gender;
            _selectedBank = _bankName;
          });
        } else {
          if (kDebugMode) {
            print("User document does not exist");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("Error fetching user profile: $e");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load profile data")),
        );
      }
    } else {
      if (kDebugMode) {
        print("No user is signed in.");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No user is signed in")),
      );
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
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
      } catch (e) {
        if (kDebugMode) {
          print("Error updating user profile: $e");
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to update profile")),
        );
      }
    }
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  void _dashboard() async {
    setState(() {
      isDashboard = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, '/dashboard');
    setState(() {
      isTransaction = false;
    });
  }

  void _transactions() async {
    setState(() {
      isTransaction = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, '/transactions');
    setState(() {
      isTransaction = false;
    });
  }

  void _profile() async {
    setState(() {
      isProfile = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    Navigator.pushReplacementNamed(context, '/profile');
    setState(() {
      isProfile = false;
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
      appBar: AppBar(title: const Text("Profile", style: TextStyle(color: Colors.white)),
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, size: 28),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        backgroundColor: const Color(0xFF053F5C),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Custom header
            const SizedBox(height: 25),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              decoration: const BoxDecoration(
                color: Color(0xFF1E5C78),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.account_circle, size: 40, color: Color(0xFF053F5C)),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _username ?? 'User Name',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _accountNumber ?? 'Phone Number',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _bankName ?? 'Phone Number',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(thickness: 1),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: Row(
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isDashboard)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: CircularProgressIndicator(color: Color(0xFF053F5C)),
                    ),
                ],
              ),
              onTap: _dashboard,
            ),
            const Divider(thickness: 1),
            ListTile(
              leading: const Icon(Icons.payment),
              title: Row(
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isTransaction)
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: CircularProgressIndicator(color: Color(0xFF053F5C)),
                    ),
                ],
              ),
              onTap: _transactions,
            ),
            const Divider(thickness: 1,),
            ListTile(
              leading: const Icon(Icons.person),
              title: Row(
                children: [
                  const Text(
                    'Profile',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (isProfile) // Check if loading is true
                    const Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: CircularProgressIndicator(color: Color(0xFF053F5C)),
                    ),
                ],
              ),
              onTap: _profile,
            ),
            const Divider(thickness: 1),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_username != null) ...[
                Text('Update your Profile $_username', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
              ],
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                  filled: true,fillColor: const Color(0xFF429EBD).withAlpha((0.2 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                  filled: true,
                  fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                  filled: true,
                  fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dobController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: InputDecoration(
                  labelText: 'Date of Birth (DD/MM/YYYY)', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                  filled: true,
                  fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
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
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _ageController,
                decoration: InputDecoration(
                  labelText: 'Age', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                  filled: true,
                  fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Address', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                  filled: true,
                  fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                  labelText: 'Bank Name', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                  filled: true,
                  fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _accountNumberController,
                decoration: InputDecoration(
                  labelText: 'Account Number', labelStyle: const TextStyle(color: Color(0xFF053F5C),),
                  filled: true,
                  fillColor: const Color(0xFF9FE7F5).withAlpha((0.2 * 255).toInt()),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF1E5C78), width: 2,),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFF429EBD), width: 2,),
                  ),
                ),
              ),
              const SizedBox(height: 60),
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
