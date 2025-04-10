import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/ProfileScreen.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/WithdrawScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetPinNavigator extends StatefulWidget {
  const SetPinNavigator({super.key});

  @override
  State<SetPinNavigator> createState() => _SetPinNavigatorState();
}

class _SetPinNavigatorState extends State<SetPinNavigator> {
  bool isPinSet = false;

  @override
  void initState() {
    super.initState();
    checkPinStatus();
  }

  Future<void> checkPinStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isPinSet = prefs.getString('withdrawal_pin') != null;
    });
  }

  void _showCustomSnackBar(BuildContext context, String message, bool isSuccess) {
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isPinSet) ...[  // Show PIN setup prompt if PIN is not set
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
                          builder: (context) => const AccountPage(),
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
                ] else ...[  // Show withdrawal page if PIN is set
                  const WithdrawPage(),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 2),
    );
  }
}
