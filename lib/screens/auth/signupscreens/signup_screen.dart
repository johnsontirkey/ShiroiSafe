import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wsa4/screens/auth/signupscreens/otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final fullNameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final pinController = TextEditingController();
  final phoneController = TextEditingController();

  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _showPassword = false;
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    fullNameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    pinController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmailPassword() async {
    if (_emailFormKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        await _firestore.collection('users').doc(userCredential.user?.uid).set({
          'fullName': fullNameController.text.trim(),
          'username': usernameController.text.trim(),
          'pin': pinController.text.trim(),
          'role': 'User',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup Successful!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        debugPrint('Signup error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signup failed: ${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _signUpWithPhone() {
    if (_phoneFormKey.currentState!.validate()) {
      String phone = '+91${phoneController.text.trim()}';

      _auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP Sent')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(verificationId: verificationId),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: const Duration(seconds: 60),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF8BBD0), Color(0xFFF06292)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    Image.asset('assets/images/logonew.png', height: 100),
                    const SizedBox(height: 10),
                    const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.black,
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.black38,
                      tabs: const [
                        Tab(text: 'Email & Password'),
                        Tab(text: 'Phone & OTP'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 500,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          Form(
                            key: _emailFormKey,
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: fullNameController,
                                    label: 'Full Name',
                                    icon: Icons.person,
                                    validator: (value) => value!.isEmpty ? 'Enter full name' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: usernameController,
                                    label: 'Username',
                                    icon: Icons.account_circle,
                                    validator: (value) => value!.isEmpty ? 'Enter username' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: pinController,
                                    obscureText: !_showPin,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    validator: (value) => value!.length != 4 ? 'Enter a 4-digit PIN' : null,
                                    decoration: InputDecoration(
                                      labelText: '4-digit PIN',
                                      prefixIcon: const Icon(Icons.pin),
                                      suffixIcon: IconButton(
                                        icon: Icon(_showPin ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () {
                                          setState(() {
                                            _showPin = !_showPin;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.8),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(color: Colors.black38),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(color: Colors.black38),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      counterText: '',
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: emailController,
                                    label: 'Email',
                                    icon: Icons.email,
                                    validator: (value) => value!.isEmpty ? 'Enter email' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: passwordController,
                                    obscureText: !_showPassword,
                                    validator: (value) => value!.length < 6 ? 'Min 6 characters' : null,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock),
                                      suffixIcon: IconButton(
                                        icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                                        onPressed: () {
                                          setState(() {
                                            _showPassword = !_showPassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: Colors.white.withValues(alpha: 0.8),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(color: Colors.black38),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: const BorderSide(color: Colors.black38),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildSubmitButton(
                                    label: 'Sign Up with Email',
                                    onPressed: _signUpWithEmailPassword,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Form(
                            key: _phoneFormKey,
                            child: Column(
                              children: [
                                _buildTextField(
                                  controller: phoneController,
                                  label: 'Phone Number',
                                  icon: Icons.phone,
                                  keyboardType: TextInputType.phone,
                                  validator: (value) => value!.isEmpty ? 'Enter phone number' : null,
                                ),
                                const SizedBox(height: 20),
                                _buildSubmitButton(
                                  label: 'Send OTP',
                                  onPressed: _signUpWithPhone,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        child: const Text(
                          'Already have an account? Login here',
                          style: TextStyle(
                            color: Colors.black87,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.black),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.8),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black38),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.black38),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
