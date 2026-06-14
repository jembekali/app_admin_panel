// lib/main.dart

import 'package:app_admin_panel/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Wizere ko iyi file ihari (yaremwe na FlutterFire CLI)
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // 1. Tangiza Flutter Engine
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Tegura uburyo bwo kwerekana amatariki (Localisation)
  // Ibi bifasha mu kwerekana amatariki neza mu Gifaransa/Ikirundi (urugero: 14 Février 2026)
  await initializeDateFormatting('fr_FR', null); 

  // 3. Initialize Firebase ukoresheje configuration nshya ya Jembe Talk Pro
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
      title: 'Jembe Talk Admin Panel',
      
      // IYI NI YO THEME IHUYE NA YA SHUSHO Y'UMUKARA TWAKOZE (Premium Dark Mode)
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF0F0F13), // Umubara w'umukara wo kuri foto
        
        // Gutunganya imiterere y'ama-Buttons muri App yose
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        
        // Gutunganya imiterere ya AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E26),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // URWINJIRIRO RWA APP (Security Gate)
      // AuthGate ni yo izagena niba ubona LoginScreen cyangwa MainScreen
      home: const AuthGate(),
    );
  }
}