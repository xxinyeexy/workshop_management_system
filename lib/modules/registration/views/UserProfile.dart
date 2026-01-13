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
  final _roleDisplayCtrl = TextEditingController();
  final _operatingHoursCtrl = TextEditingController();
final _specializationCtrl = TextEditingController();
final _experienceCtrl = TextEditingController();
final _primarySkillsCtrl = TextEditingController();
 


  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const Divider(),
        ],
      ),
    );
  }

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
    _roleDisplayCtrl.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _workshopNameCtrl.dispose();
    _workshopAddressCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _operatingHoursCtrl.dispose();
   _specializationCtrl.dispose();
   _experienceCtrl.dispose();
   _primarySkillsCtrl.dispose();

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
      _roleDisplayCtrl.text = _role == 'workshop_owner' ? 'Workshop Owner' : 'Foreman';

      if (_role == 'workshop_owner') {
        _workshopNameCtrl.text = data['workshopName'] ?? '';
        _workshopAddressCtrl.text = data['workshopAddress'] ?? '';
        _operatingHoursCtrl.text = data['operatingHours'] ?? '';
  _specializationCtrl.text = data['specialization'] ?? '';
      } else if (_role == 'foreman') {
        _bankNameCtrl.text = data['bankName'] ?? '';
        _accountNumberCtrl.text = data['accountNumber'] ?? '';
        _experienceCtrl.text = data['experience'] ?? '';
  _primarySkillsCtrl.text = data['primarySkills'] ?? '';
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
      update['operatingHours'] = _operatingHoursCtrl.text.trim();
      update['specialization'] = _specializationCtrl.text.trim();
    } else if (_role == 'foreman') {
      update['bankName'] = _bankNameCtrl.text.trim();
      update['accountNumber'] = _accountNumberCtrl.text.trim();
      update['experience'] = _experienceCtrl.text.trim();
      update['primarySkills'] = _primarySkillsCtrl.text.trim();
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
Widget _sectionCard({
  required String title,
  required List<Widget> children,
  Color? color,
}) {
  return Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? Colors.grey.shade100,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...children,
      ],
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
                  const SizedBox(height: 8),
Text(
  _roleDisplayCtrl.text,
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.grey,
  ),
),
                    const SizedBox(height: 20),
                    _sectionCard(
  title: "Basic Information",
  color: Colors.blue.shade50,
  children: [
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
  ],
),

                    if (_role == 'workshop_owner' || _role == 'foreman')
  _sectionCard(
    title: "Professional Information",
    color: Colors.green.shade50,
    children: [
      if (_role == 'workshop_owner') ...[
        _field(controller: _workshopNameCtrl, label: 'Workshop Name'),
        _field(controller: _workshopAddressCtrl, label: 'Workshop Address'),
        _field(controller: _operatingHoursCtrl, label: 'Operating Hours'),
        _field(controller: _specializationCtrl, label: 'Specialization'),
      ],
      if (_role == 'foreman') ...[
        _field(controller: _bankNameCtrl, label: 'Bank Name'),
        _field(
          controller: _accountNumberCtrl,
          label: 'Account Number',
          type: TextInputType.number,
        ),
        _field(controller: _experienceCtrl, label: 'Experience'),
        _field(controller: _primarySkillsCtrl, label: 'Primary Technical Skills'),
      ],
    ],
  ),
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
