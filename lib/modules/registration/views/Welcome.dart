import 'package:flutter/material.dart';
import 'package:workshop_management_system/modules/registration/views/LoginPage.dart';
import 'package:workshop_management_system/modules/registration/views/SignUpPage.dart';


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/logo.png", height: 120), // Replace with your logo
              const Text("WorkshopPro", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Text("Workshop Management System", style: TextStyle(fontSize: 16)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text("Login"),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: const Text("Register"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
