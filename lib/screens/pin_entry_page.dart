// ignore_for_file: unused_import, must_be_immutable

import 'package:flutter/material.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/pending_withdrawals_page.dart';
import 'package:investment_plan_app/services/withdrawal_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinEntryPage extends StatefulWidget {
  String? name;
  String? bankName;
  String? accountNumber;
  String? branchName;
  double? amount;
  String? setPin;
  String? password;
  final String?
      mode; // Add a mode parameter: 'withdrawal', 'setPin', or 'changePassword'

  PinEntryPage({
    super.key,
    this.name,
    this.bankName,
    this.accountNumber,
    this.branchName,
    this.amount,
    this.setPin,
    this.password,
    this.mode = 'withdrawal', // Default to withdrawal mode
  });

  @override
  _PinEntryPageState createState() => _PinEntryPageState();
}

class _PinEntryPageState extends State<PinEntryPage> {
  String enteredPin = "";
  bool _isLoading = false;
  String? _errorMessage;

  // For password change
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Services
  final WithdrawalService _withdrawalService = WithdrawalService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  final UserApiService _userService = UserApiService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  @override
  void initState() {
    super.initState();
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

  void _onNumberTap(String number) {
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += number;
      });
    }
  }

  void _onBackspace() {
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
      });
    }
  }

  // Method to set or update PIN
  Future<void> _updatePin() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = await UserApiService.getUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID not found';
        });

        if (mounted) {
          _showCustomSnackBar(context, "User ID not found", false);
        }
        return;
      }

      // Update PIN in database
      final result = await _userService.updateUserPin(userId, enteredPin);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (!mounted) return;

        _showCustomSnackBar(context, "PIN has been set successfully", true);

        // Add a slight delay before navigation
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context); // Go back to previous screen
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });

        if (mounted) {
          _showCustomSnackBar(
              context, result['message'] ?? "Failed to update PIN", false);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error updating PIN: ${e.toString()}';
      });

      if (mounted) {
        _showCustomSnackBar(
            context, 'Error updating PIN: ${e.toString()}', false);
      }
      print('Error updating PIN: $e');
    }
  }

  // Method to change password
  Future<void> _changePassword() async {
    try {
      // Validate password inputs
      if (_newPasswordController.text.isEmpty ||
          _currentPasswordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        setState(() {
          _errorMessage = 'All fields are required';
        });

        _showCustomSnackBar(context, "All fields are required", false);
        return;
      }

      if (_newPasswordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'New passwords do not match';
        });

        _showCustomSnackBar(context, "New passwords do not match", false);
        return;
      }

      if (_newPasswordController.text.length < 6) {
        setState(() {
          _errorMessage = 'Password must be at least 6 characters';
        });

        _showCustomSnackBar(
            context, "Password must be at least 6 characters", false);
        return;
      }

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final userId = await UserApiService.getUserId();
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID not found';
        });

        if (mounted) {
          _showCustomSnackBar(context, "User ID not found", false);
        }
        return;
      }

      // Update password in database
      final result = await _userService.updateUserPassword(
          userId, _currentPasswordController.text, _newPasswordController.text);

      setState(() {
        _isLoading = false;
      });

      if (result['success']) {
        if (!mounted) return;

        _showCustomSnackBar(
            context, "Password has been changed successfully", true);

        // Add a slight delay before navigation
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.pop(context); // Go back to previous screen
          }
        });
      } else {
        setState(() {
          _errorMessage = result['message'];
        });

        if (mounted) {
          _showCustomSnackBar(
              context, result['message'] ?? "Failed to change password", false);
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error changing password: ${e.toString()}';
      });

      if (mounted) {
        _showCustomSnackBar(
            context, 'Error changing password: ${e.toString()}', false);
      }
      print('Error changing password: $e');
    }
  }

  Future<void> _submitWithdrawal() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get bank details
      final accountHolderName = widget.name ?? widget.name;
      final bankName = widget.bankName ?? widget.bankName;
      final accountNumber = widget.accountNumber ?? widget.accountNumber;
      final branchName = widget.branchName ?? widget.branchName;
      const paymentMethod = 'Wire Transfer';
      final amount = widget.amount;
      final userId = await UserApiService.getUserId();

      if (userId == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID not found';
        });

        if (mounted) {
          _showCustomSnackBar(context, "User ID not found", false);
        }
        return;
      }

      // Call the withdrawal service
      final response = await _withdrawalService.createWithdrawal(
        userId: userId,
        amount: amount!,
        accountHolderName: accountHolderName!,
        bankName: bankName!,
        accountNumber: accountNumber!,
        branchName: branchName!,
        paymentMethod: paymentMethod,
      );

      setState(() {
        _isLoading = false;
      });

      if (!mounted) return;

      _showCustomSnackBar(
          context, "Withdrawal request submitted successfully", true);

      // Add a slight delay before navigation
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        // Navigate to the pending withdrawals page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PendingWithdrawalsPage(),
          ),
        );
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error submitting withdrawal: ${e.toString()}';
      });

      if (mounted) {
        _showCustomSnackBar(
            context, 'Error submitting withdrawal: ${e.toString()}', false);
      }
      print('Error submitting withdrawal: $e');
    }
  }

  Future<void> _onSubmit() async {
    // For PIN settings, we use a 4-digit PIN
    if (widget.mode == 'setPin') {
      if (enteredPin.length == 4) {
        await _updatePin();
      } else {
        setState(() {
          _errorMessage = 'Please enter a 4-digit PIN';
        });

        _showCustomSnackBar(context, "Please enter a 4-digit PIN", false);
      }
    }
    // For withdrawals, we verify the existing PIN against the database
    else if (widget.mode == 'withdrawal') {
      if (enteredPin.length == 4) {
        try {
          setState(() {
            _isLoading = true;
          });

          // Get the current user's ID
          final userId = await UserApiService.getUserId();
          if (userId == null) {
            throw Exception('User ID not found');
          }

          // Fetch user profile to get the stored PIN
          final profileResponse = await _userService.getUserProfile(userId);
          print('Profile Response: $profileResponse');
          if (profileResponse['success']) {
            final userData = profileResponse['userData'];
            final storedPin =
                userData['pin']; // Assuming pin is returned in the profile data
            print('Stored PIN: $storedPin');
            // Compare entered PIN with stored PIN
            if (enteredPin == storedPin) {
              await _submitWithdrawal();
            } else {
              setState(() {
                _errorMessage = 'Incorrect PIN, please try again';
                enteredPin = ""; // Clear the entered PIN
              });

              _showCustomSnackBar(
                  context, "Incorrect PIN, please try again", false);
            }
          } else {
            throw Exception(profileResponse['message'] ??
                'Failed to retrieve user profile');
          }
        } catch (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Error verifying PIN: ${e.toString()}';
          });

          _showCustomSnackBar(
              context, "Error verifying PIN: ${e.toString()}", false);
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showCustomSnackBar(context, "Please enter a 4-digit PIN", false);
      }
    }
  }

  Widget _buildPinIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < enteredPin.length ? Colors.white : Colors.white30,
          ),
        );
      }),
    );
  }

  Widget _buildNumberButton(String number) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _onNumberTap(number),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordChangeForm() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          TextField(
            controller: _currentPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Current Password',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _newPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'New Password',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Confirm New Password',
              hintStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Updating Password...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      )
                    : const Text(
                        'Change Password',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String pageTitle = "Enter PIN";
    String pageSubtitle = "Enter your PIN to confirm withdrawal";

    if (widget.mode == 'setPin') {
      pageTitle = "Set PIN";
      pageSubtitle = "Create a 4-digit PIN for withdrawals";
    } else if (widget.mode == 'changePassword') {
      pageTitle = "Change Password";
      pageSubtitle = "Update your login password";
    }

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
      ),
      body: Stack(
        children: [
          AppTheme.appBackground(),
          widget.mode == 'changePassword'
              ? SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock, color: Colors.white, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        pageTitle,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        pageSubtitle,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),

                      // Error message display (removed in favor of SnackBar)
                      _buildPasswordChangeForm(),
                    ],
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text(
                      pageTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      pageSubtitle,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    _buildPinIndicator(),
                    const SizedBox(height: 40),
                    if (_isLoading)
                      const Column(
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 20),
                          Text(
                            "Processing...",
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton("1"),
                                _buildNumberButton("2"),
                                _buildNumberButton("3"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton("4"),
                                _buildNumberButton("5"),
                                _buildNumberButton("6"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton("7"),
                                _buildNumberButton("8"),
                                _buildNumberButton("9"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                  onTap: _isLoading ? null : _onBackspace,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.backspace,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                _buildNumberButton("0"),
                                GestureDetector(
                                  onTap: _isLoading ? null : _onSubmit,
                                  child: Container(
                                    width: 70,
                                    height: 70,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.blue, Colors.purple],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 2),
    );
  }
}
