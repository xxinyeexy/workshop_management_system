import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../sidebar.dart';
import 'UserProfileEditForm.dart';

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
  String fullName = '';
  String email = '';
  String phone = '';
  String bankAccount = '';
  String accountNumber = '';
  String workshopName = '';
  String workshopAddress = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null) {
        setState(() {
          fullName = data['fullName'] ?? '';
          email = data['email'] ?? '';
          phone = data['phone'] ?? '';
          bankAccount = data['bankAccount'] ?? '';
          accountNumber = data['accountNumber'] ?? '';
          workshopName = data['workshopName'] ?? '';
          workshopAddress = data['workshopAddress'] ?? '';
          isLoading = false;
        });
      }
    }
  }

  Color get primaryColor {
    return widget.userRole.toLowerCase() == 'foreman'
        ? const Color(0xFF2FB668)
        : const Color(0xFF4260DB);
  }

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
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserProfileEditForm(
                    currentName: fullName,
                    currentPhone: phone,
                    currentBankAccount: bankAccount,
                    currentAccountNumber: accountNumber,
                    currentWorkshopName: workshopName,
                    currentWorkshopAddress: workshopAddress,
                    userRole: widget.userRole,
                    userName: widget.userName,
                    userPosition: widget.userPosition,
                  ),
                ),
              );
              if (result == true) {
                _fetchUserData();
              }
            },
          ),
        ],
      ),
      drawer: SidebarMenu(
        userRole: widget.userRole.toLowerCase() == 'foreman'
            ? UserRole.Foreman
            : UserRole.WorkshopOwner,
        userName: widget.userName,
        userPosition: widget.userPosition,
        selectedTitle: 'Profile',
        onSelectedTitleChanged: (title) {},
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/images/profile_avatar.png'),
                    ),
                    const SizedBox(height: 20),
                    Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(widget.userPosition, style: const TextStyle(color: Colors.grey)),
                    const Divider(height: 30),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text("Email"),
                      subtitle: Text(email),
                    ),
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: const Text("Phone Number"),
                      subtitle: Text(phone),
                    ),
                    if (widget.userRole.toLowerCase() == 'foreman') ...[
                      ListTile(
                        leading: const Icon(Icons.account_balance),
                        title: const Text("Bank Account"),
                        subtitle: Text(bankAccount),
                      ),
                      ListTile(
                        leading: const Icon(Icons.confirmation_number),
                        title: const Text("Account Number"),
                        subtitle: Text(accountNumber),
                      ),
                    ] else ...[
                      ListTile(
                        leading: const Icon(Icons.business),
                        title: const Text("Workshop Name"),
                        subtitle: Text(workshopName),
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: const Text("Workshop Address"),
                        subtitle: Text(workshopAddress),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
