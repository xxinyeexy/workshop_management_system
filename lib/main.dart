import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:workshop_management_system/modules/registration/views/LoginPage.dart';
import 'package:workshop_management_system/modules/registration/views/Welcome.dart';
// import 'package:workshop_management_system/modules/schedule/views/schedule.dart';
// import 'package:workshop_management_system/modules/rating/views/FindForemanWorkshopPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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