import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Ibi bizadufasha gufata ibyo umukoresha yanditse
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Function yo kwinjira
  Future<void> signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Niba hari ikibazo kibaye, tuzakibona hano
      print("Ibyabaye byatunguye: ${e.message}");
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imeri canke ijambobanga si vyo! Subiramwo neza.'))
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Jembe Talk Admin',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Aho gushyira imeri
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),

              // Aho gushyira ijambobanga
              TextField(
                controller: _passwordController,
                obscureText: true, // Guhisha ijambobanga
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              // Buto yo kwinjira
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: signIn,
                  child: const Text('Injira'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}