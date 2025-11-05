import 'package:app_admin_panel/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart'; // UYU NI UMURONGO MUSHASHA

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // UYU NI WO MURONGO WA KABIRI MUSHASHA KANDI UHAMPAYE
  await initializeDateFormatting('fr_FR', null); 

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
      debugShowCheckedModeBanner: false,
      title: 'Jembe Talk Admin',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const AuthGate(),
    );
  }
}