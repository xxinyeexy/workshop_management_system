import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../sidebar.dart';

class UserProfileEditForm extends StatefulWidget {
  final String currentName;
  final String currentPhone;
  final String currentBankAccount;
  final String currentAccountNumber;
  final String currentWorkshopName;
  final String currentWorkshopAddress;
  final String userRole;
  final String userName;
  final String userPosition;

  const UserProfileEditForm({
    super.key,
    required this.currentName,
    required this.currentPhone,
    required this.currentBankAccount,
    required this.currentAccountNumber,
    required this.currentWorkshopName,
    required this.currentWorkshopAddress,
    required this.userRole,
    required this.userName,
    required this.userPosition,
  });

  @override
  State<UserProfileEditForm> createState() => _UserProfileEditFormState();
}

class _UserProfileEditFormState extends State<UserProfileEditForm> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  late String phone;
  late String bankAccount;
  late String accountNumber;
  late String workshopName;
  late String workshopAddress;

  bool get isForeman => widget.userRole.toLowerCase() == 'foreman';

  @override
  void initState() {
    super.initState();
    name = widget.currentName;
    phone = widget.currentPhone;
    bankAccount = widget.currentBankAccount;
    accountNumber = widget.currentAccountNumber;
    workshopName = widget.currentWorkshopName;
    workshopAddress = widget.currentWorkshopAddress;
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final updateData = {
        'fullName': name,
        'phone': phone,
      };

      if (isForeman) {
        updateData['bankAccount'] = bankAccount;
        updateData['accountNumber'] = accountNumber;
      } else {
        updateData['workshopName'] = workshopName;
        updateData['workshopAddress'] = workshopAddress;
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updateData);
      Navigator.pop(context, true);
    }
  }

  Color get primaryColor => isForeman ? const Color(0xFF2FB668) : const Color(0xFF4260DB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      drawer: SidebarMenu(
        userRole: isForeman ? UserRole.Foreman : UserRole.WorkshopOwner,
        userName: widget.userName,
        userPosition: widget.userPosition,
        selectedTitle: 'Profile',
        onSelectedTitleChanged: (title) {},
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/images/profile_avatar.png'),
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField('Full Name', name, (val) => name = val),
                    _buildTextField('Phone Number', phone, (val) => phone = val),
                    if (isForeman) _buildTextField('Bank Account', bankAccount, (val) => bankAccount = val),
                    if (isForeman) _buildTextField('Account Number', accountNumber, (val) => accountNumber = val),
                    if (!isForeman) _buildTextField('Workshop Name', workshopName, (val) => workshopName = val),
                    if (!isForeman) _buildTextField('Workshop Address', workshopAddress, (val) => workshopAddress = val),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) _saveProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text(
                    "Save Changes",
                    style: TextStyle(fontSize: 16, color: Colors.white), // <- Set font color to white
                  ),
                ),

              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        initialValue: initialValue,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          fillColor: Colors.grey[100],
          filled: true,
        ),
        onChanged: onChanged,
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}
