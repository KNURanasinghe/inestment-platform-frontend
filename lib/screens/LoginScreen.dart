import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:investment_plan_app/screens/WelcomeScreen.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart'; // Import AppTheme
import 'package:investment_plan_app/screens/home_screen.dart';

import '../services/user_service.dart'; // Import HomeScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  bool _obscureText = true; // Password visibility state
  bool _isLoading = false;
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final UserApiService _apiService = UserApiService(
    baseUrl:
        'http://151.106.125.212:5021', // Replace with your actual backend URL
  );

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.loginUser(
        nicNumber: _nicController.text.trim(),
        password: _passwordController.text,
      );

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        // Login successful, navigate to HomeScreen

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        print('Login failed: ${result['message']}');
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error during login: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _nicController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background vectors
          AppTheme.appBackground(),

          // Content
          SizedBox(
            width: width,
            height: height,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 8,
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),
                            const Text(
                              'Hello,',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Welcome back',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 110),

                            // NIC Number input
                            TextField(
                              style: const TextStyle(color: Colors.white),
                              controller: _nicController,
                              cursorColor: Colors.white,
                              decoration: InputDecoration(
                                hintText: 'NIC Number',
                                hintStyle: const TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: AppTheme.textFieldColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons
                                      .credit_card_outlined, // Identity card icon
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Password input with visibility toggle
                            TextField(
                              style: const TextStyle(color: Colors.white),
                              controller: _passwordController,
                              cursorColor: Colors.white,
                              obscureText:
                                  _obscureText, // Toggle password visibility
                              decoration: InputDecoration(
                                hintText: 'Password',
                                hintStyle: const TextStyle(color: Colors.white),
                                filled: true,
                                fillColor: AppTheme.textFieldColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock, // Lock icon
                                  color: Colors.white,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureText =
                                          !_obscureText; // Toggle visibility
                                    });
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),

                            // Remember me checkbox
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: rememberMe,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      rememberMe = value!;
                                    });
                                  },
                                  activeColor: Colors.white,
                                ),
                                const Text(
                                  'Remember me',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),

                            // Gradient Login button
                            Container(
                              width: width,
                              decoration: AppTheme.buttonDecoration(),
                              child: ElevatedButton(
                                style: AppTheme.buttonStyle(),
                                onPressed: _isLoading ? null : _login,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Text(
                                        'Log In',
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 18),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        width: width,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                // Navigate to Sign-Up Screen
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: const Text.rich(
                                TextSpan(
                                  text: "Don't have an account?  ",
                                  style: TextStyle(color: Colors.white),
                                  children: [
                                    TextSpan(
                                      text: "Sign up",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
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
