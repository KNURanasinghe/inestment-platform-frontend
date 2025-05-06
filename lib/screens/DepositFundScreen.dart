import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/PaymentDetailsScreen.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/BankDetailsScreen.dart';

import '../services/coin_service.dart';

class DepositFundScreen extends StatefulWidget {
  final String? depositType;
  const DepositFundScreen({super.key, this.depositType});

  @override
  _DepositFundScreenState createState() => _DepositFundScreenState();
}

class _DepositFundScreenState extends State<DepositFundScreen> {
  final TextEditingController _amountController = TextEditingController();
  double serviceFee = 0;
  double totalAmount = 0;
  String? _errorMessage;

  // Min-max amount constraints based on deposit type
  late double _minAmount;
  late double _maxAmount;
  double _coinValue = 0.0;
  bool _isLoadingCoinValue = true;
  double coinBalance = 0;

  final CoinService _coinService = CoinService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  @override
  void initState() {
    super.initState();
    _getCoinValue();
    // Set amount constraints based on deposit type
    if (widget.depositType == 'investment') {
      _minAmount = 10000;
      _maxAmount = 1000000;
    } else {
      // Default to 'buy_coin' constraints
      _minAmount = 5000;
      _maxAmount = 1000000;
    }
  }

  Future<void> _getCoinValue() async {
    final response = await _coinService.getCurrentCoinValue();
    if (response['success']) {
      setState(() {
        _coinValue = response['coinValue'].lkrValue;
        _isLoadingCoinValue = false;
      });
      print('Coin value loaded: $_coinValue');
    } else {
      setState(() {
        _isLoadingCoinValue = true;
      });
    }
  }

  void _calculateFees() async {
    // Clear previous error
    setState(() {
      _errorMessage = null;
    });

    // Parse amount
    double amount = double.tryParse(_amountController.text) ?? 0;

    // Validate amount based on deposit type
    if (amount > 0) {
      if (amount < _minAmount) {
        setState(() {
          _errorMessage =
              'Minimum deposit amount is \$${_minAmount.toStringAsFixed(0)}';
        });
      } else if (amount > _maxAmount) {
        setState(() {
          _errorMessage =
              'Maximum deposit amount is \$${_maxAmount.toStringAsFixed(0)}';
        });
      }
    }

    setState(() {
      serviceFee = amount * 0.1;
      totalAmount = amount + serviceFee;
      coinBalance = amount / _coinValue;
    });
  }

  // Show custom styled snackbar
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
        title: Text('Deposit Funds', style: AppTheme.textStyleLarge),
        centerTitle: true,
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),

                  // Display the deposit type
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8200DB).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF8200DB).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      widget.depositType == 'investment'
                          ? 'Investment Deposit'
                          : 'Coin Deposit',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Display amount restrictions
                  Container(
                    width: width,
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
                        Expanded(
                          child: Text(
                            'Deposit amount must be between \$${_minAmount.toStringAsFixed(0)} and \$${_maxAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.blue[100],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
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
                              hintText: ' Enter amount',
                              hintStyle: const TextStyle(color: Colors.white60),
                              filled: true,
                              fillColor: AppTheme.textFieldColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.attach_money,
                                color: Colors.white60,
                              ),
                            ),
                            onChanged: (value) => _calculateFees(),
                          ),
                        ),
                        if (_amountController.text.isNotEmpty &&
                            widget.depositType != 'investment') ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              '${coinBalance.toStringAsFixed(2)} coins available',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
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
                            Text(
                                '\$${_amountController.text.isEmpty ? "0.00" : double.parse(_amountController.text).toStringAsFixed(2)}',
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
                  const SizedBox(height: 30),
                  Container(
                    width: width,
                    decoration: AppTheme.buttonDecoration(),
                    child: ElevatedButton(
                      style: AppTheme.buttonStyle(),
                      onPressed: () {
                        // Validate amount
                        if (_amountController.text.isEmpty) {
                          _showCustomSnackBar(
                              context, 'Please enter an amount', false);
                          return;
                        }

                        double amount =
                            double.tryParse(_amountController.text) ?? 0;

                        if (amount < _minAmount) {
                          _showCustomSnackBar(
                              context,
                              'Minimum deposit amount is \$${_minAmount.toStringAsFixed(0)}',
                              false);
                          return;
                        }

                        if (amount > _maxAmount) {
                          _showCustomSnackBar(
                              context,
                              'Maximum deposit amount is \$${_maxAmount.toStringAsFixed(0)}',
                              false);
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PaymentDetailsScreen(
                                    // Pass the total amount to the next screen if needed
                                    purpose: widget.depositType,
                                    totalAmount: totalAmount,
                                  )),
                        );
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
          ),
        ],
      ),
      bottomNavigationBar:
          AppTheme.bottomNavigationBar(context, 1), // '1' is the current index
    );
  }
}
