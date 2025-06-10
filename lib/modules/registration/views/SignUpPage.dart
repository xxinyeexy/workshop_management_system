import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workshop_management_system/modules/registration/views/LoginPage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isWorkshopOwner = true;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final workshopAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        isWorkshopOwner = _tabController.index == 0;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    fullNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    workshopAddressController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    );
  }

  void registerUser() async {
    final fullName = fullNameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();
    final address = workshopAddressController.text.trim();
    final role = isWorkshopOwner ? "workshop_owner" : "foreman";

    // Validation
    if (fullName.isEmpty || email.isEmpty || phone.isEmpty || password.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields")),
      );
      return;
    }

    if (password != confirmPassword) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    if (isWorkshopOwner && address.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Workshop address is required")),
      );
      return;
    }

    try {
      // Create user account
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCred.user!.uid;

      // Create user document
      Map<String, dynamic> userData = {
        'uid': uid, // Add uid field for easier querying
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'createdAt': Timestamp.now(),
        'isActive': true, // Add status field
      };

      if (isWorkshopOwner) {
        userData['address'] = address;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(userData);

      // Create initial rating profile with blank template
      await FirebaseFirestore.instance
          .collection('rating_profiles')
          .doc(uid)
          .set({
        'uid': uid,
        'fullName': fullName,
        'role': role,
        'averageRating': 0.0,
        'totalRatings': 0,
        'starDistribution': {
          '5': 0,
          '4': 0,
          '3': 0,
          '2': 0,
          '1': 0,
        },
        'createdAt': Timestamp.now(),
        'lastUpdated': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Successfully registered as ${role.replaceAll('_', ' ')}!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registration failed: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          'Create Account',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [Tab(text: "Workshop Owner"), Tab(text: "Foreman")],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm(isWorkshopOwner: true),
          _buildForm(isWorkshopOwner: false),
        ],
      ),
    );
  }

  Widget _buildForm({required bool isWorkshopOwner}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha((0.15 * 255).toInt()),
                spreadRadius: 2,
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: fullNameController,
                decoration: _inputDecoration("Full Name"),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: _inputDecoration("Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: _inputDecoration("Phone Number"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: _inputDecoration("Password"),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                decoration: _inputDecoration("Confirm Password"),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              if (isWorkshopOwner)
                Column(
                  children: [
                    TextField(
                      controller: workshopAddressController,
                      decoration: _inputDecoration("Workshop Address"),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isWorkshopOwner ? const Color(0xFF3D5AFE) : Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: registerUser,
                  child: const Text(
                    "Create Account",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account?"),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "Login",
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}