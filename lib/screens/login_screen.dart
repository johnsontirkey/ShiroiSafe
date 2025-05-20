import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wsa4/screens/animations/bubble_painter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wsa4/screens/auth/signupscreens/signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String selectedRole = 'User';

  final emailPhoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;

  late List<Offset> bubbles;
  late Timer bubbleTimer;
  final int numBubbles = 20;
  final double bubbleRadius = 20;
  final Random random = Random();

  final GoogleSignIn googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    bubbles = List.generate(
      numBubbles,
      (_) => Offset(random.nextDouble() * 400, random.nextDouble() * 800),
    );
    bubbleTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        bubbles = bubbles
            .map((bubble) => Offset(
                  bubble.dx,
                  bubble.dy - 1 > 0 ? bubble.dy - 1 : 800,
                ))
            .toList();
      });
    });
  }

  @override
  void dispose() {
    emailPhoneController.dispose();
    passwordController.dispose();
    bubbleTimer.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailPhoneController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = credential.user;
        if (user == null) throw Exception("User not found after login");

        // Get user role from Firestore
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

        String role = 'User'; // default
        if (userDoc.exists && userDoc.data() != null) {
          role = userDoc.data()!['role'] ?? 'User';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login successful"),
            backgroundColor: Colors.green,
          ),
        );

        if (role == 'Admin') {
          Navigator.pushReplacementNamed(context, '/adminhome');
        } else {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'user-not-found'
                  ? "No user found for that email."
                  : e.code == 'wrong-password'
                      ? "Wrong password provided."
                      : "Login failed: ${e.message}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _googleSignIn() async {
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled sign in

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = authResult.user;
      if (user == null) throw Exception("Google sign-in failed: No user");

      // Get role from Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

      String role = 'User'; // default
      if (userDoc.exists && userDoc.data() != null) {
        role = userDoc.data()!['role'] ?? 'User';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Google login successful"),
          backgroundColor: Colors.green,
        ),
      );

      if (role == 'Admin') {
        Navigator.pushReplacementNamed(context, '/adminhome');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Google sign-in failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetPassword() async {
    String email = emailPhoneController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid email to reset password."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset email sent."),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.bold),
      prefixIcon: Icon(icon, color: Colors.black),
      filled: true,
      fillColor: Colors.white.withAlpha(230),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black38, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.black38, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF8BBD0), Color(0xFFF06292)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          CustomPaint(
            painter: BubblePainter(bubbles, bubbleRadius),
            size: MediaQuery.of(context).size,
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: MediaQuery.of(context).size.height * 0.05),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('assets/images/logonew.png', height: MediaQuery.of(context).size.height * 0.15),
                    const SizedBox(height: 10),
                    const Text(
                      'Welcome',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(height: 10),
                    const Text('Select Role',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 10),
                    ToggleButtons(
                      isSelected: [selectedRole == 'User', selectedRole == 'Admin'],
                      borderRadius: BorderRadius.circular(12),
                      selectedColor: Colors.black,
                      fillColor: Colors.pink.shade400,
                      color: Colors.white70,
                      children: const [
                        Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('User')),
                        Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Admin')),
                      ],
                      onPressed: (int index) {
                        setState(() {
                          selectedRole = index == 0 ? 'User' : 'Admin';
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: emailPhoneController,
                      style: const TextStyle(color: Colors.black),
                      decoration: _inputDecoration('Email or Phone', Icons.person),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter email or phone' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.bold),
                        prefixIcon: const Icon(Icons.lock, color: Colors.black),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withAlpha(230),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black38, width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.black38, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      validator: (value) =>
                          value == null || value.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _login,
                        child: const Text('Login', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _googleSignIn,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/icongoogle.png', width: 30, height: 30),
                            const SizedBox(width: 10),
                            const Text('Sign in with Google', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account yet? ",
                            style: TextStyle(fontSize: 16, color: Colors.black54)),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                            );
                          },
                          child: const Text(
                            'Signup now',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
