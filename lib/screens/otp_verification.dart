// ignore_for_file: unused_import

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final String? phoneNumber;
  final String?
      mode; // 'registration', 'passwordReset', 'emailVerification', etc.

  // Add new parameters needed for registration
  final String? name;
  final String? nicNumber;
  final String? username;
  final String? password;
  final String? deviceId;
  final String? address;
  final String? country;
  final String? refcode;
  final String otp;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.phoneNumber,
    this.mode = 'registration',
    required this.otp,
    // New parameters for registration
    this.name,
    this.nicNumber,
    this.username,
    this.password,
    this.deviceId,
    this.address,
    this.country,
    this.refcode,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    6,
    (index) => FocusNode(),
  );

  bool _isLoading = false;
  String? _errorMessage;
  bool _isResending = false;
  int _resendTimer = 60;
  Timer? _timer;

  final UserApiService _userService = UserApiService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();

    // Dispose controllers and focus nodes
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }

    super.dispose();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _restartResendTimer() {
    setState(() {
      _resendTimer = 60;
    });
    _startResendTimer();
  }

  Future<void> _resendOTP() async {
    if (_resendTimer > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      // Replace with your actual resend OTP API call
      // final result = await _userService.resendOTP(widget.email);

      // if (result['success']) {
      //   if (mounted) {
      //     _showCustomSnackBar(
      //         context, "OTP has been resent successfully", true);
      //     _restartResendTimer();
      //   }
      // } else {
      //   setState(() {
      //     _errorMessage = result['message'];
      //   });

      //   if (mounted) {
      //     _showCustomSnackBar(
      //         context, result['message'] ?? "Failed to resend OTP", false);
      //   }
      // }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error resending OTP: ${e.toString()}';
      });

      if (mounted) {
        _showCustomSnackBar(
            context, 'Error resending OTP: ${e.toString()}', false);
      }
    } finally {
      setState(() {
        _isResending = false;
      });
    }
  }

  Future<void> _verifyOTP() async {
    // Collect OTP from all text fields
    final otp = _controllers.map((controller) => controller.text).join();

    // Validate OTP
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP';
      });
      _showCustomSnackBar(
          context, "Please enter the complete 6-digit OTP", false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if entered OTP matches the expected OTP
      if (widget.otp == otp) {
        if (widget.mode == 'registration') {
          // Now that OTP is verified, register the user
          try {
            final registerResult = await _userService.registerUser(
              name: widget.name ?? '',
              email: widget.email,
              nicNumber: widget.nicNumber ?? '',
              username: widget.username ?? '',
              password: widget.password ?? '',
              phoneNumber: widget.phoneNumber ?? '',
              deviceId: widget.deviceId ?? '',
              address: widget.address ?? '',
              country: widget.country ?? '',
              refcode: widget.refcode ?? '',
              isVerified:
                  1, // Send 1 instead of true to match backend expectation
            );

            setState(() {
              _isLoading = false;
            });

            if (registerResult['success']) {
              if (!mounted) return;

              _showCustomSnackBar(context, "Registration successful", true);

              // Add a slight delay before navigation
              Future.delayed(const Duration(milliseconds: 1500), () {
                if (mounted) {
                  // Navigate to home screen after successful registration
                  Navigator.pushReplacementNamed(context, '/home');
                }
              });
            } else {
              if (!mounted) return;

              _showCustomSnackBar(context,
                  registerResult['message'] ?? "Registration failed", false);
            }
          } catch (e) {
            setState(() {
              print(e.toString());
              _isLoading = false;
              _errorMessage = 'Error registering user: ${e.toString()}';
            });

            if (mounted) {
              _showCustomSnackBar(
                  context, 'Error registering user: ${e.toString()}', false);
            }
          }
        } else if (widget.mode == 'passwordReset') {
          // Handle password reset
          setState(() {
            _isLoading = false;
          });

          _showCustomSnackBar(context, "OTP verification successful", true);

          // Navigate to reset password screen
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/reset-password');
            }
          });
        } else {
          // Default success behavior
          setState(() {
            _isLoading = false;
          });

          _showCustomSnackBar(context, "OTP verification successful", true);

          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pop(context);
            }
          });
        }
      } else {
        // OTP doesn't match
        setState(() {
          _isLoading = false;
          _errorMessage = "Invalid OTP";
        });

        if (mounted) {
          _showCustomSnackBar(context, "Invalid OTP", false);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error verifying OTP: ${e.toString()}';
      });

      if (mounted) {
        _showCustomSnackBar(
            context, 'Error verifying OTP: ${e.toString()}', false);
      }
    }
  }

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

  String maskMobileNumber(String mobileNumber) {
    // Remove any non-digit characters (spaces, dashes, etc.)
    final cleanNumber = mobileNumber.replaceAll(RegExp(r'\D'), '');

    // Check if we have a valid number to mask
    if (cleanNumber.length < 4) {
      return mobileNumber; // Return original if too short to mask properly
    }

    // Keep first 2 digits and last 2 digits visible, mask the rest
    final firstVisible = cleanNumber.substring(0, 2);
    final lastVisible = cleanNumber.substring(cleanNumber.length - 2);

    // Create asterisks for the middle part
    final maskedPart = '*' * (cleanNumber.length - 4);

    return '$firstVisible$maskedPart$lastVisible';
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = "OTP Verification";
    String pageSubtitle = widget.mode == 'registration'
        ? "Please enter the 6-digit code sent to your phone number"
        : widget.mode == 'passwordReset'
            ? "Enter the verification code to reset your password"
            : "Enter the verification code to verify your account";

    final String maskedEmail =
        widget.email.replaceRange(2, widget.email.indexOf('@'), '***');

    final String maskedPhone = maskMobileNumber(widget.phoneNumber!);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(pageTitle, style: AppTheme.textStyleLarge),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          AppTheme.appBackground(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user,
                      color: Colors.white, size: 60),
                  const SizedBox(height: 20),
                  Text(
                    pageSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Code sent to: $maskedPhone",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                      (index) => SizedBox(
                        width: 45,
                        height: 55,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 20),
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            }
                            if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }

                            // Auto-verify if all fields are filled
                            if (index == 5 && value.isNotEmpty) {
                              bool allFilled = true;
                              for (var controller in _controllers) {
                                if (controller.text.isEmpty) {
                                  allFilled = false;
                                  break;
                                }
                              }
                              if (allFilled) {
                                // Automatically trigger verification
                                FocusScope.of(context).unfocus();
                                Future.delayed(
                                    const Duration(milliseconds: 300), () {
                                  _verifyOTP();
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Verify Button
                  _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.blue, Colors.purple],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _verifyOTP,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: const Text(
                              'Verify OTP',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                  const SizedBox(height: 30),

                  // Resend OTP Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Didn't receive the code? ",
                        style: TextStyle(color: Colors.white70),
                      ),
                      _resendTimer > 0
                          ? Text(
                              "Resend in $_resendTimer seconds",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : GestureDetector(
                              onTap: _isResending ? null : _resendOTP,
                              child: _isResending
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Colors.blue, Colors.purple],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Text(
                                        "Resend OTP",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // bottomNavigationBar: AppTheme.bottomNavigationBar(context, 0),
    );
  }
}
