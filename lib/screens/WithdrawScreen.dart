import 'package:flutter/material.dart';
import 'Bank_Account_Details.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';

class WithdrawPage extends StatelessWidget {
  const WithdrawPage({super.key});

  // Create a custom SnackBar with gradient and proper styling
  void _showCustomSnackBar(
      BuildContext context, String message, bool isSuccess) {
    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(15),
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );

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
                    ] // Success gradient
                  : [
                      const Color(0xFFFF416C),
                      const Color(0xFFFF4B2B)
                    ], // Error gradient
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
    TextEditingController amount = TextEditingController();
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          AppTheme.appBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                const Align(
                  alignment: Alignment.topRight,
                  child: CircleAvatar(
                    backgroundImage: AssetImage('assets/profile.jpg'),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Current Balance",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  "\$12,458.90",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 60),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Enter Withdrawal Amount",
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: amount,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          prefixText: "\$",
                          prefixStyle: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Available for withdrawal: \$10,000.00\nDaily limit: \$5,000.00",
                        style: TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                GestureDetector(
                  onTap: () {
                    // Navigate to Bank Account Details Page
                    if (amount.text.isEmpty) {
                      // Show error message with custom SnackBar
                      _showCustomSnackBar(
                          context, "Please enter an amount to withdraw", false);
                    } else if (double.tryParse(amount.text) == null) {
                      _showCustomSnackBar(
                          context, "Please enter a valid amount", false);
                    } else if (double.parse(amount.text) <= 0) {
                      _showCustomSnackBar(
                          context, "Amount must be greater than zero", false);
                    } else if (double.parse(amount.text) > 10000) {
                      _showCustomSnackBar(
                          context, "Amount exceeds available balance", false);
                    } else if (double.parse(amount.text) > 5000) {
                      _showCustomSnackBar(context,
                          "Amount exceeds daily withdrawal limit", false);
                    } else {
                      // Show success message before navigating
                      _showCustomSnackBar(
                          context, "Processing withdrawal request...", true);

                      // Navigate after a brief delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BankDetailsPage(
                                    amount: double.parse(amount.text),
                                  )),
                        );
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
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
                        "Next",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "🔒 Your transaction is secured and encrypted",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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
