import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // 🔥 1. Iyi variable niyo igena niba password igaragara cyangwa ihishwe
  bool _isObscured = true;

  // Function yo kwinjira
  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      debugPrint("Ivyabaye vyatunguye: ${e.message}");
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email canke ijambobanga si vyo! Subiramwo neza.'))
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13), // Nashyizemo ibara ryirabura ngo bihure n'izindi paje
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                const Text(
                  'Jembe Talk Admin',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 40),

                // Aho gushira email
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.white54),
                  ),
                ),
                const SizedBox(height: 20),

                // Aho gushira ijambobanga
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscured, // 🔥 2. Hano koresha variable ya _isObscured
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: const OutlineInputBorder(),
                    enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                    focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.amber)),
                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                    
                    // 🔥 3. KAKAMENYETSO K'IJISHO (SUFFIX ICON)
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () {
                        // Iyo ukanzeho, bihindura isura (State)
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Buto yo kwinjira
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: signIn,
                    child: const Text('Injira', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}