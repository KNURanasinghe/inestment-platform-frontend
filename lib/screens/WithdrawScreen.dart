import 'package:flutter/material.dart';
import '../services/deposit_service.dart';
import '../services/user_service.dart';
import '../services/investment_service.dart'; // Add this import
import '../services/referral_service.dart'; // Add this import
import 'Bank_Account_Details.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';

import 'pending_withdrawals_page.dart';

class WithdrawPage extends StatefulWidget {
  final double balance; // Add this parameter

  const WithdrawPage({
    super.key,
    this.balance = 0.0, // Default value if not provided
  });

  @override
  State<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends State<WithdrawPage> {
  final TextEditingController amount = TextEditingController();
  double serviceFee = 0;
  double finalAmount = 0;

  final UserApiService _userApiService = UserApiService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  // Add these services
  final InvestmentService _investmentService = InvestmentService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  final ReferralService _referralService = ReferralService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  String? profileImageUrl;
  double _totalDepositAmount = 0.0;
  int _userId = 0; // Changed from final to regular variable
  bool _isLoadingDeposits = true;

  // Add these variables for income tracking
  double _totalIncome = 0.0;
  double _investmentProfit = 0.0;
  double _referralIncome = 0.0;
  bool _isLoadingIncome = true;
  bool hasReachedMaxLimit = false;

  Future<void> _loadUserData() async {
    try {
      // Get user ID
      final userId = await UserApiService.getUserId();
      if (userId != null && userId > 0) {
        setState(() {
          _userId = userId;
        });

        // Load deposits and income data
        await Future.wait([
          _loadUserDeposits(),
          _loadInvestmentProfits(),
          _loadReferrals(),
        ]);

        // Calculate total income and check limits
        _calculateTotalIncome();
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadUserDeposits() async {
    if (_userId <= 0) return;

    setState(() {
      _isLoadingDeposits = true;
    });

    try {
      // Create deposit service
      final depositService =
          DepositService(baseUrl: 'http://151.106.125.212:5021');

      // Get all user deposits that are not pending
      final deposits = await depositService.getUserDeposits(_userId);
      print('ALL user deposits received: ${deposits.length}');

      // Debug purpose values
      for (var deposit in deposits) {
        print(
            'Deposit ID: ${deposit.id}, Purpose: "${deposit.purpose}", Amount: ${deposit.amount}');
      }

      final approvedDeposits =
          deposits.where((deposit) => !deposit.isPending).toList();
      print('APPROVED user deposits: ${approvedDeposits.length}');

      // Calculate total deposit amount
      double totalAmount = 0.0;
      double investmentAmount = 0.0;
      double coinAmount = 0.0;

      for (var deposit in approvedDeposits) {
        totalAmount += deposit.amount;
        if (deposit.purpose == 'investment') {
          investmentAmount += deposit.amount;
          print('Added to investment: ${deposit.amount}');
        } else if (deposit.purpose == 'buy_coin') {
          coinAmount += deposit.amount;
          print('Added to coin: ${deposit.amount}');
        } else {
          print('UNKNOWN purpose: ${deposit.purpose}');
        }
      }

      setState(() {
        _totalDepositAmount = totalAmount;
        _isLoadingDeposits = false;
      });

      print('Total deposit amount: $_totalDepositAmount');
    } catch (e) {
      setState(() {
        _isLoadingDeposits = false;
      });
      print('Error loading user deposits: $e');
    }
  }

  // Add method to load investment profits (from HomeScreen)
  Future<void> _loadInvestmentProfits() async {
    try {
      // Get investment profits from the API
      final response = await _investmentService.getUserInvestments(_userId);

      if (response['success']) {
        final summary = response['summary'];
        setState(() {
          _investmentProfit = summary.totalEarned;
        });
        print('Investment profit loaded: $_investmentProfit');
      } else {
        print('Failed to load investment profits: ${response['message']}');
      }
    } catch (e) {
      print('Error loading investment profits: $e');
    }
  }

  // Add method to load referrals (from HomeScreen)
  Future<void> _loadReferrals() async {
    try {
      // Get referral data from the API
      final response = await _referralService.getUserReferrals(_userId);

      if (response['success']) {
        final commissions = response['commissions'];
        setState(() {
          _referralIncome = commissions.coin + commissions.investment;
        });
        print('Referral income loaded: $_referralIncome');
      } else {
        print('Failed to load referrals');
      }
    } catch (e) {
      print('Error loading referrals: $e');
    }
  }

  // Calculate total income and check limit
  void _calculateTotalIncome() {
    setState(() {
      _totalIncome = _investmentProfit + _referralIncome;

      // Calculate max income limit and check if reached
      double maxIncomeLimit = (_totalDepositAmount / 1.1) * 3;
      hasReachedMaxLimit = _totalIncome >= maxIncomeLimit;

      _isLoadingIncome = false;
    });
    print(
        'Total income calculated: $_totalIncome, Max limit reached: $hasReachedMaxLimit');
  }

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
    _loadUserData(); // Load user data including deposits and income
    // Add listener to automatically update fee calculation when amount changes
    amount.addListener(_calculateFees);
    fetchProfileImage();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    amount.removeListener(_calculateFees);
    amount.dispose();
    super.dispose();
  }

  Future<void> fetchProfileImage() async {
    final userId = await UserApiService.getUserId();
    //String? profileImageUrl;
    if (userId != null) {
      final imageUrl = await _userApiService.getProfileImageUrl(userId);
      setState(() {
        profileImageUrl = imageUrl;
        print('image url $imageUrl');
      });
    }
  }

  // Add method to build the income limit message widget
  Widget _buildIncomeLimitMessage() {
    // Calculate max income limit and remaining earnings
    double maxIncomeLimit = (_totalDepositAmount / 1.1) * 3;
    double remainingEarnings = maxIncomeLimit - _totalIncome;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasReachedMaxLimit
              ? [Colors.red.withOpacity(0.7), Colors.redAccent.withOpacity(0.5)]
              : [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.3),
                ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasReachedMaxLimit ? Icons.warning_amber : Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasReachedMaxLimit
                    ? 'Maximum Income Limit Reached'
                    : 'Income Limit',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasReachedMaxLimit
                ? 'You have reached the maximum income limit of 3x your investment amount. Please make additional deposits to increase your withdrawal potential.'
                : 'You can earn up to LKR ${remainingEarnings.toStringAsFixed(2)} more before reaching your maximum income limit of 3x your investment amount.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _totalIncome / maxIncomeLimit,
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              hasReachedMaxLimit ? Colors.red[300]! : Colors.white,
            ),
          ),
        ],
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Align(
                    alignment: Alignment.topRight,
                    child: profileImageUrl != null
                        ? CircleAvatar(
                            backgroundImage: NetworkImage('$profileImageUrl'),
                          )
                        : const CircleAvatar(
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Current Balance",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "LKR${widget.balance.toStringAsFixed(2)}", // Use the balance parameter here
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Show income limit message if data is loaded
                  if (!_isLoadingIncome && !_isLoadingDeposits)
                    _buildIncomeLimitMessage(),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PendingWithdrawalsPage()));
                    },
                    child: Container(
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Pending withdrawals',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_outlined,
                            color: Colors.blue[300],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                            'Minimum withdrawal: LKR4,000\nMaximum withdrawal: LKR1,000,000\nA 3% service fee will be deducted from your withdrawal amount',
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
                          enabled:
                              !hasReachedMaxLimit, // Disable textfield if limit reached
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
                    onTap: hasReachedMaxLimit
                        ? () {
                            // Show notice when max limit is reached
                            _showCustomSnackBar(
                                context,
                                "You have reached the maximum income limit. Please make additional deposits to enable withdrawals.",
                                false);
                          }
                        : () {
                            // Validate withdrawal amount
                            if (amount.text.isEmpty) {
                              _showCustomSnackBar(context,
                                  "Please enter an amount to withdraw", false);
                            } else if (double.tryParse(amount.text) == null) {
                              _showCustomSnackBar(context,
                                  "Please enter a valid amount", false);
                            } else if (double.parse(amount.text) <= 0) {
                              _showCustomSnackBar(context,
                                  "Amount must be greater than zero", false);
                            } else if (double.parse(amount.text) < 4000) {
                              _showCustomSnackBar(
                                  context,
                                  "Minimum withdrawal amount is LKR4,000",
                                  false);
                            } else if (double.parse(amount.text) > 1000000) {
                              _showCustomSnackBar(
                                  context,
                                  "Maximum withdrawal amount is LKR1,000,000",
                                  false);
                            } else if (double.parse(amount.text) >
                                widget.balance) {
                              // Add a new validation for insufficient balance
                              _showCustomSnackBar(
                                  context,
                                  "Insufficient balance for this withdrawal",
                                  false);
                            } else {
                              // Show success message before navigating
                              _showCustomSnackBar(context,
                                  "Processing withdrawal request...", true);

                              // Navigate after a brief delay
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => BankDetailsPage(
                                            amount: double.tryParse(
                                                    amount.text) ??
                                                0, // Pass the final amount after fee deduction
                                          )),
                                );
                              });
                            }
                          },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: hasReachedMaxLimit
                              ? [
                                  Colors.grey,
                                  Colors.grey.shade600
                                ] // Grey gradient when disabled
                              : [
                                  Colors.blue,
                                  Colors.purple
                                ], // Normal gradient when enabled
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          hasReachedMaxLimit ? "Withdrawals Disabled" : "Next",
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  if (hasReachedMaxLimit)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Text(
                        "Make additional deposits to enable withdrawals",
                        style: TextStyle(
                          color: Colors.red[300],
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
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
