import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:workshop_management_system/modules/registration/views/LoginPage.dart';
import 'package:workshop_management_system/modules/registration/views/Welcome.dart';
// import 'package:workshop_management_system/modules/schedule/views/schedule.dart';
// import 'package:workshop_management_system/modules/rating/views/FindForemanWorkshopPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
   // ✅ Stripe initialization with your publishable key
  Stripe.publishableKey = 'pk_test_51RZCzaQKjzsbUKGZX3XkE0SPRjYe2B9svT1LuJ6M3mGdTIWbuigxjY5qhSge8AwTtOhuKKH7YfhYG1godG78Tmlb003wBTV1ex'; // Replace with your actual key
  await Stripe.instance.applySettings();


  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WorkshopPro',
      debugShowCheckedModeBanner: false,
      home: const WelcomeScreen(),
    );
  }
}