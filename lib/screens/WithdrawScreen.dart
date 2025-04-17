import 'package:flutter/material.dart';
import 'Bank_Account_Details.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';

class WithdrawPage extends StatefulWidget {
  const WithdrawPage({super.key});

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController amount = TextEditingController();
  double serviceFee = 0;
  double finalAmount = 0;

  // Create a custom SnackBar with gradient and proper styling
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

  // Calculate the service fee and final amount
  void _calculateFees() {
    double enteredAmount = double.tryParse(amount.text) ?? 0;
    setState(() {
      serviceFee = enteredAmount * 0.03; // 3% fee
      finalAmount = enteredAmount - serviceFee;
    });
  }

  @override
  void initState() {
    super.initState();
    // Add listener to automatically update fee calculation when amount changes
    amount.addListener(_calculateFees);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    amount.removeListener(_calculateFees);
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   title: const Text(
      //     "Withdraw Funds",
      //     style: TextStyle(color: Colors.white, fontSize: 20),
      //   ),
      //   centerTitle: true,
      //   iconTheme: const IconThemeData(color: Colors.white),
      // ),
      body: Stack(
        children: [
          AppTheme.appBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
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
                    "LKR12,458.90",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Information container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[300],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Minimum withdrawal: LKR7,000\nMaximum withdrawal: LKR1,000,000\nA 3% service fee will be deducted from your withdrawal amount',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
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
                            prefixText: "LKR",
                            prefixStyle: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Fee calculation container (similar to DepositFundScreen)
                  Container(
                    width: double.infinity,
                    decoration: AppTheme.cardDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Amount', style: AppTheme.textStyleBold),
                            Text(
                                'LKR${amount.text.isEmpty ? "0.00" : double.parse(amount.text).toStringAsFixed(2)}',
                                style: AppTheme.textStyleBold),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Service Fee (3%)',
                                style: AppTheme.textStyleSmall),
                            Text('LKR${serviceFee.toStringAsFixed(2)}',
                                style: AppTheme.textStyleSmall),
                          ],
                        ),
                        const Divider(color: Colors.white),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('You Receive', style: AppTheme.textStyleBold),
                            Text('LKR${finalAmount.toStringAsFixed(2)}',
                                style: AppTheme.textStyleBold),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {
                      // Navigate to Bank Account Details Page
                      if (amount.text.isEmpty) {
                        // Show error message with custom SnackBar
                        _showCustomSnackBar(context,
                            "Please enter an amount to withdraw", false);
                      } else if (double.tryParse(amount.text) == null) {
                        _showCustomSnackBar(
                            context, "Please enter a valid amount", false);
                      } else if (double.parse(amount.text) <= 0) {
                        _showCustomSnackBar(
                            context, "Amount must be greater than zero", false);
                      } else if (double.parse(amount.text) < 7000) {
                        _showCustomSnackBar(context,
                            "Minimum withdrawal amount is LKR7,000", false);
                      } else if (double.parse(amount.text) > 1000000) {
                        _showCustomSnackBar(context,
                            "Maximum withdrawal amount is LKR1,000,000", false);
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
                                      amount:
                                          finalAmount, // Pass the final amount after fee deduction
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
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 2),
    );
  }
}
