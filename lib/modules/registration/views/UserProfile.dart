import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshop_management_system/modules/sidebar.dart'; // Import SidebarMenu

class UserProfilePage extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userPosition;
  final ValueChanged<String>? onSelectedTitleChanged;
  final String? originalUserRole;

  const UserProfilePage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userPosition,
    this.onSelectedTitleChanged,
    this.originalUserRole,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _workshopNameController = TextEditingController();
  final TextEditingController _workshopAddressController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();

  String _userRole = '';
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _workshopNameController.dispose();
    _workshopAddressController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() {
      _isLoading = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle no user logged in
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _userId = user.uid;

    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        _fullNameController.text = data?['fullName'] ?? '';
        _emailController.text = data?['email'] ?? '';
        _phoneNumberController.text = data?['phoneNumber'] ?? '';
        _userRole = data?['role'] ?? '';
        print('DEBUG: Fetched user role: $_userRole');

        if (_userRole.toLowerCase() == 'workshop_owner') {
          _workshopNameController.text = data?['workshopName'] ?? '';
          _workshopAddressController.text = data?['workshopAddress'] ?? '';
          print('DEBUG: Fetched workshopName: ${_workshopNameController.text}');
          print(
            'DEBUG: Fetched workshopAddress: ${_workshopAddressController.text}',
          );
        } else if (_userRole.toLowerCase() == 'foreman') {
          _bankNameController.text = data?['bankName'] ?? '';
          _accountNumberController.text = data?['accountNumber'] ?? '';
        }
      } else {
        // Populate with FirebaseAuth email if no Firestore doc
        _emailController.text = user.email ?? '';
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching user data: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId);

      final Map<String, dynamic> updateData = {
        'fullName': _fullNameController.text,
        'email': _emailController.text,
        'phoneNumber': _phoneNumberController.text,
        'role': _userRole, // Ensure role is saved
      };

      if (_userRole.toLowerCase() == 'workshop_owner') {
        updateData['workshopName'] = _workshopNameController.text;
        updateData['workshopAddress'] = _workshopAddressController.text;
      } else if (_userRole.toLowerCase() == 'foreman') {
        updateData['bankName'] = _bankNameController.text;
        updateData['accountNumber'] = _accountNumberController.text;
      }

      await userRef.set(updateData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: enabled,
        decoration: InputDecoration(
          labelText: labelText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[100],
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$labelText cannot be empty';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        widget.userRole.toLowerCase().contains('foreman')
            ? const Color(0xFF2FB668) // Green for foreman
            : const Color(0xFF4260DB); // Blue for workshop owner or default

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Profile",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  print('DEBUG: Sidebar button pressed!');
                  Scaffold.of(context).openDrawer();
                },
              ),
        ),
        automaticallyImplyLeading:
            false, // Keep this false as we're providing a custom leading
      ),
      drawer: SidebarMenu(
        // Add the drawer here
        userRole: UserRole.values.firstWhere(
          (e) =>
              e.toString().split('.').last.toLowerCase() ==
              widget.userRole.toLowerCase().replaceAll(' ', ''),
          orElse:
              () => UserRole.WorkshopOwner, // Provide a default or handle error
        ),
        userName: widget.userName,
        userPosition: widget.userPosition,
        selectedTitle: 'Profile',
        onSelectedTitleChanged: widget.onSelectedTitleChanged,
        originalUserRole: widget.originalUserRole,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Icon/Avatar Placeholder
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.grey[300],
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      _buildTextField(
                        controller: _fullNameController,
                        labelText: 'Full Name',
                      ),
                      _buildTextField(
                        controller: _emailController,
                        labelText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        enabled: false, // Email is typically not editable
                      ),
                      _buildTextField(
                        controller: _phoneNumberController,
                        labelText: 'Phone Number',
                        keyboardType: TextInputType.phone,
                      ),
                      if (_userRole.toLowerCase() == 'workshop_owner') ...[
                        _buildTextField(
                          controller: _workshopNameController,
                          labelText: 'Workshop Name',
                        ),
                        _buildTextField(
                          controller: _workshopAddressController,
                          labelText: 'Workshop Address',
                          keyboardType: TextInputType.streetAddress,
                        ),
                      ],
                      if (_userRole.toLowerCase() == 'foreman') ...[
                        _buildTextField(
                          controller: _bankNameController,
                          labelText: 'Bank Account',
                        ),
                        _buildTextField(
                          controller: _accountNumberController,
                          labelText: 'Account Number',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor, // Use role-based color
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
