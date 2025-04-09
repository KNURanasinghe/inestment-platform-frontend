import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/PaymentDetailsScreen.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/BankDetailsScreen.dart';

class DepositFundScreen extends StatefulWidget {
  const DepositFundScreen({super.key});

  @override
  _DepositFundScreenState createState() => _DepositFundScreenState();
}

class _DepositFundScreenState extends State<DepositFundScreen> {
  final TextEditingController _amountController = TextEditingController();
  double serviceFee = 0;
  double totalAmount = 0;

  void _calculateFees() {
    double amount = double.tryParse(_amountController.text) ?? 0;
    setState(() {
      serviceFee = amount * 0.1;
      totalAmount = amount + serviceFee;
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/user.png'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AppTheme.appBackground(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Deposit Funds', style: AppTheme.textStyleLarge),
                const SizedBox(height: 20),
                Container(
                  decoration: AppTheme.cardDecoration(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Enter Amount',
                        textAlign: TextAlign.left,
                        style:
                            TextStyle(color: Color(0x80FFFFFF), fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: TextField(
                          style: const TextStyle(color: Colors.white),
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: ' 0.00',
                            hintStyle: const TextStyle(color: Colors.white),
                            filled: true,
                            fillColor: AppTheme.textFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (value) => _calculateFees(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: AppTheme.cardDecoration(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Amount', style: AppTheme.textStyleBold),
                          Text('\$${_amountController.text}',
                              style: AppTheme.textStyleBold),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Service Fee (10%)',
                              style: AppTheme.textStyleSmall),
                          Text('\$${serviceFee.toStringAsFixed(2)}',
                              style: AppTheme.textStyleSmall),
                        ],
                      ),
                      const Divider(color: Colors.white),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Amount', style: AppTheme.textStyleBold),
                          Text('\$${totalAmount.toStringAsFixed(2)}',
                              style: AppTheme.textStyleBold),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
                Container(
                  width: width,
                  decoration: AppTheme.buttonDecoration(),
                  child: ElevatedButton(
                    style: AppTheme.buttonStyle(),
                    onPressed: () {
                      if (_amountController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Please enter an amount')),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PaymentDetailsScreen(
                                    // Pass the total amount to the next screen if needed
                                    totalAmount: totalAmount,
                                  )),
                        );
                      }
                    },
                    child: const Text(
                      'Proceed to Payment',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'A 10% service fee will be applied to your deposit amount. This helps us maintain and improve our service.',
                  textAlign: TextAlign.center,
                  style: AppTheme.textStyleSmall,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          AppTheme.bottomNavigationBar(context, 1), // '1' is the current index
    );
  }
}
