import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyCareApp());
}

class MyCareApp extends StatelessWidget {
  const MyCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MyCare',
      theme: ThemeData(
        fontFamily: 'Cairo',
      ),
      home: const LoginScreen(),
    );
  }
}