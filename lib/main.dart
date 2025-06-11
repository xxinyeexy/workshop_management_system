import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'routes/route.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manage Inventory Module',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // Use the NavigationService's navigator key
      navigatorKey: NavigationService.navigatorKey,
      
      // Set initial route
      initialRoute: AppRoutes.inventory,
      
      // Use the route generator
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}