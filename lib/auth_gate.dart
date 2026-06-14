// lib/auth_gate.dart

import 'package:app_admin_panel/main_screen.dart';
import 'package:app_admin_panel/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // 1. Igenzura niba hari uwinjiye mu buryo bwa Firebase Auth
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // Mu gihe Firebase ikirimo kugenzura (Loading)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F0F13),
            body: Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        // 2. NIBA NTA MUNTU WINJIYE: Mujyane kuri Login Screen
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 3. NIBA WINJIYE: Fungura Dashboard (MainScreen)
        return const MainScreen(); 
      },
    );
  }
}