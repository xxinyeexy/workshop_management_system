import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshop_management_system/modules/registration/views/LoginPage.dart';

class UserProfilePage extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userPosition;

  const UserProfilePage({
    super.key,
    required this.userRole,
    required this.userName,
    required this.userPosition,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>(debugLabel: 'profile_form');

  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _workshopNameCtrl = TextEditingController();
  final _workshopAddressCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();

  bool _loading = true;
  String _role = '';
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _workshopNameCtrl.dispose();
    _workshopAddressCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _uid = user.uid;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!snap.exists) return;

      final data = snap.data()!;
      _fullNameCtrl.text = data['fullName'] ?? '';
      _emailCtrl.text = data['email'] ?? '';
      _phoneCtrl.text = data['phoneNumber'] ?? '';
      _role = (data['role'] ?? '').toString().toLowerCase();

      if (_role == 'workshop_owner') {
        _workshopNameCtrl.text = data['workshopName'] ?? '';
        _workshopAddressCtrl.text = data['workshopAddress'] ?? '';
      } else if (_role == 'foreman') {
        _bankNameCtrl.text = data['bankName'] ?? '';
        _accountNumberCtrl.text = data['accountNumber'] ?? '';
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _uid == null) return;

    setState(() => _loading = true);

    final update = {
      'fullName': _fullNameCtrl.text.trim(),
      'phoneNumber': _phoneCtrl.text.trim(),
      'role': _role,
    };

    if (_role == 'workshop_owner') {
      update['workshopName'] = _workshopNameCtrl.text.trim();
      update['workshopAddress'] = _workshopAddressCtrl.text.trim();
    } else if (_role == 'foreman') {
      update['bankName'] = _bankNameCtrl.text.trim();
      update['accountNumber'] = _accountNumberCtrl.text.trim();
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .set(update, SetOptions(merge: true));

    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey.shade200,
        ),
        validator: (v) =>
            v == null || v.isEmpty ? '$label cannot be empty' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        _role == 'foreman' ? const Color(0xFF2FB668) : const Color(0xFF4260DB);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.person, size: 56),
                    ),
                    const SizedBox(height: 20),

                    _field(controller: _fullNameCtrl, label: 'Full Name'),
                    _field(
                      controller: _emailCtrl,
                      label: 'Email',
                      enabled: false,
                      type: TextInputType.emailAddress,
                    ),
                    _field(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      type: TextInputType.phone,
                    ),

                    if (_role == 'workshop_owner') ...[
                      _field(
                        controller: _workshopNameCtrl,
                        label: 'Workshop Name',
                      ),
                      _field(
                        controller: _workshopAddressCtrl,
                        label: 'Workshop Address',
                      ),
                    ],

                    if (_role == 'foreman') ...[
                      _field(
                        controller: _bankNameCtrl,
                        label: 'Bank Name',
                      ),
                      _field(
                        controller: _accountNumberCtrl,
                        label: 'Account Number',
                        type: TextInputType.number,
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                        ),
                        onPressed: _saveProfile,
                        child: const Text('Save Changes'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Log Out'),
                        onPressed: _logout,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
