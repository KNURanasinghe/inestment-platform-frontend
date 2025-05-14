// lib/screens/signup_screen.dart
// ignore_for_file: unused_local_variable

import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/otp_verification.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool agreeToTerms = false;
  bool _obscureText = true;
  bool _isLoading = false;
  String? _deviceId;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _refController = TextEditingController();

  // Form key for validation_refController
  final _formKey = GlobalKey<FormState>();

  // Create instance of API service
  final UserApiService _apiService = UserApiService(
    baseUrl: 'http://151.106.125.212:5021', // Your backend URL
  );
// Format phone number for API
  String formatPhoneNumber(String phoneNumber) {
    // Remove spaces, dashes, etc.
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If the number starts with 0, remove it (assuming Sri Lankan format)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    cleaned = '+94$cleaned';
    // Return international format
    return cleaned;
  }

  // Generate OTP
  String generateOTP() {
    Random random = Random();
    int otp = random.nextInt(900000) + 100000; // 4-digit code between 1000-9999
    return otp.toString();
  }

  // Custom SnackBar method
  void _showCustomSnackBar(
      BuildContext context, String message, bool isSuccess) {
    // Get the ScaffoldMessengerState
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Clear any existing SnackBars
    scaffoldMessenger.clearSnackBars();

    // Show the SnackBar with the gradient wrapper
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSuccess
                  ? [
                      const Color(0xFF4776E6),
                      const Color(0xFF8E54E9)
                    ] // Success gradient - blue to purple
                  : [
                      const Color(0xFFFF416C),
                      const Color(0xFFFF4B2B)
                    ], // Error gradient - red to orange
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // Function to handle registration
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!agreeToTerms) {
      _showCustomSnackBar(
          context, 'Please agree to the Privacy & Policy', false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String formattedPhone =
          formatPhoneNumber(_phoneController.text).toString();
      print('Attempting to register user with the following details:');
      print('Name: ${_nameController.text}');
      print('Email: ${_emailController.text}');
      print('NIC: ${_nicController.text}');
      print('Username: ${_usernameController.text}');

      // Generate and send OTP
      String otp = generateOTP();
      String fullPhoneNumber = formatPhoneNumber(_phoneController.text);

      // Log for debugging
      print('Phone number: $fullPhoneNumber');
      print('Generated OTP: $otp');

      // Notify.lk API credentials
      const String userId = '29316';
      const String apiKey = 'RH9L1weIpJJODyQkFfSe';
      const String senderId = 'NotifyDEMO';

      // Notify.lk API endpoint
      const String url = 'https://app.notify.lk/api/v1/send';

      // Prepare the message content
      String message =
          'Your verification code is $otp. Please use this to verify your account.';
      print(message);

      final Map<String, String> queryParams = {
        'user_id': userId,
        'api_key': apiKey,
        'sender_id': senderId,
        'to': fullPhoneNumber.replaceAll(
            '+', ''), // Ensure the phone number is in 947XXXXXXXX format
        'message': message,
      };

      try {
        // Send OTP via Notify.lk API
        final notifyResponse = await http.post(
          Uri.parse(url).replace(queryParameters: queryParams),
        );

        // Log response for debugging
        print('Notify.lk API response: ${notifyResponse.body}');

        if (notifyResponse.statusCode == 200) {
          final notifyData = notifyResponse.body;

          // Check if OTP was sent successfully
          if (notifyData.contains('"status":"success"')) {
            setState(() {
              _isLoading = false;
            });

            // Navigate to OTP verification screen with all user data
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => OtpVerificationScreen(
                      email: _emailController.text,
                      phoneNumber: _phoneController.text,
                      // Pass all the user registration data
                      name: _nameController.text,
                      nicNumber: _nicController.text,
                      username: _usernameController.text,
                      password: _passwordController.text,
                      deviceId: _deviceId,
                      address: _addressController.text,
                      country: _countryController.text,
                      refcode: _refController.text,
                      otp: otp)),
            );
          } else {
            setState(() {
              _isLoading = false;
              _showCustomSnackBar(context,
                  'Failed to send verification code. Please try again.', false);
            });
          }
        } else {
          setState(() {
            _isLoading = false;
            _showCustomSnackBar(
                context,
                'Failed to send verification code. Status: ${notifyResponse.statusCode}',
                false);
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
          _showCustomSnackBar(context,
              'Error sending verification code: ${e.toString()}', false);
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      print('Error during registration: $e');

      _showCustomSnackBar(context, 'Error: ${e.toString()}', false);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeOneSignal();
  }

  Future<void> _initializeOneSignal() async {
    // Get the device state
    final deviceId = OneSignal.User.pushSubscription.id;
    setState(() {
      _deviceId = deviceId;
    });
  }

  @override
  void dispose() {
    // Dispose controllers when the widget is removed
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nicController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _countryController.dispose();
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
          AppTheme.appBackground(),
          SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 50),
                      const Text(
                        'Hello,',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 50),
                      TextFormField(
                        controller: _nameController,
                        cursorColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Name',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                          errorStyle: const TextStyle(color: Colors.amber),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        cursorColor: Colors.white,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Email',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.mail,
                            color: Colors.white,
                          ),
                          errorStyle: const TextStyle(color: Colors.amber),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _phoneController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Phone Number',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Colors.white,
                          ),
                          errorStyle: const TextStyle(color: Colors.amber),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                            return 'Please enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _nicController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'NIC Number',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.credit_card_outlined,
                            color: Colors.white,
                          ),
                          errorStyle: const TextStyle(color: Colors.amber),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your NIC number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _usernameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Username',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.account_circle,
                            color: Colors.white,
                          ),
                          errorStyle: const TextStyle(color: Colors.amber),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a username';
                          }
                          if (value.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.white),
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.lock,
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
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          errorStyle: const TextStyle(color: Colors.amber),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _addressController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Address',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.home,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _countryController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Country',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.language,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        cursorColor: Colors.white,
                        controller: _refController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'referral code',
                          hintStyle: const TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: AppTheme.textFieldColor,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none),
                          prefixIcon: const Icon(
                            Icons.credit_card_outlined,
                            color: Colors.white,
                          ),
                          errorStyle: const TextStyle(color: Colors.amber),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.all(2.5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  agreeToTerms = !agreeToTerms;
                                });
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.white),
                                  color: agreeToTerms
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                                child: agreeToTerms
                                    ? const Icon(
                                        Icons.check,
                                        size: 18,
                                        color: Colors.green,
                                      )
                                    : null,
                              ),
                            ),
                            const Text(
                              'I agree with Privacy & Policy',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        width: width,
                        decoration: AppTheme.buttonDecoration(),
                        child: ElevatedButton(
                          style: AppTheme.buttonStyle(),
                          onPressed: _isLoading ? null : _registerUser,
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Creating Account...',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18),
                                    ),
                                  ],
                                )
                              : const Text('Sign Up',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/login'),
                          child: const Text.rich(
                            TextSpan(
                              text: "Already have an account?  ",
                              style: TextStyle(color: Colors.white),
                              children: [
                                TextSpan(
                                  text: "Log in",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
