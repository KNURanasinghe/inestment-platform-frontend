// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/ProfileScreen.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/WithdrawScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetPinNavigator extends StatefulWidget {
  const SetPinNavigator({super.key});

  @override
  State<SetPinNavigator> createState() => _SetPinNavigatorState();
}

class _SetPinNavigatorState extends State<SetPinNavigator> {
  final UserApiService _userService =
      UserApiService(baseUrl: 'http://151.106.125.212:5021');
  bool isPinSet = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    checkPinStatus();
  }

  Future<void> checkPinStatus() async {
    try {
      final userid = await UserApiService.getUserId();
      final userdata = await _userService.getUserProfile(userid!);
      final data = userdata['userData'];
      print('User data: $data');

      setState(() {
        isPinSet = data['hasPin'] ?? false;
        isLoading = false;
        print('User has PIN: $isPinSet');
      });

      // If PIN is set, navigate to WithdrawPage
      if (isPinSet) {
        // Use a short delay to ensure the state has been updated
        Future.delayed(Duration.zero, () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const WithdrawPage(),
            ),
          );
        });
      }
    } catch (e) {
      print('Error checking PIN status: $e');
      setState(() {
        isLoading = false;
      });
      _showCustomSnackBar(context, "Failed to load user data", false);
    }
  }

  void _showCustomSnackBar(
      BuildContext context, String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSuccess
                  ? [const Color(0xFF4776E6), const Color(0xFF8E54E9)]
                  : [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          AppTheme.appBackground(),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Only show PIN setup prompt (PIN is not set)
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Please set the Withdrawal PIN first",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountPage(
                            username: '',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.purple],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          "Set PIN",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 2),
    );
  }
}
