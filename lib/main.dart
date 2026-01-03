import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:workshop_management_system/modules/registration/views/Welcome.dart';
import 'routes/route.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settings');

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
      title: 'WorkshopPro',
      debugShowCheckedModeBanner: false,

      // 🌈 GLOBAL THEME (APPLIED TO ALL PAGES)
      theme: ThemeData(
        // 🔹 ElevatedButton (most important)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // TEXT & ICON color
            textStyle: const TextStyle(
              inherit: true,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // 🔹 Optional: TextButton default style
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),

        // 🔹 Optional: AppBar default text color
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white,
        ),
      ),

      home: const WelcomeScreen(),
      navigatorKey: NavigationService.navigatorKey,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
