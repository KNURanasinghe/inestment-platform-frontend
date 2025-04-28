import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/home_screen.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/DepositFundScreen.dart';
import 'package:investment_plan_app/services/deposit_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final DepositService _depositService = DepositService(
    // Update this URL based on your server location
    baseUrl: 'http://151.106.125.212:5021', // For Android emulator
    // Use 'http://localhost:3000' for iOS simulator
  );

  final UserApiService _userApiService = UserApiService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  List<Deposit>? _pendingDeposits;
  double _totalPendingAmount = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  int _userId = 0;
  bool _isPayed = false; // User payment status
  String? _selectedCardType; // To track which card is selected

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user ID
      final userId = await UserApiService.getUserId() as int;
      if (userId > 0) {
        _userId = userId;

        // Load user profile to check payment status
        final userProfileResponse =
            await _userApiService.getUserProfile(_userId);
        if (userProfileResponse['success']) {
          // Extract isPayed status from user data
          _isPayed = userProfileResponse['userData']['isPayed'] ?? false;
          print('User payment status: $_isPayed');
        }

        // Load pending deposits
        await _loadPendingDeposits();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID not found';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user data: ${e.toString()}';
      });
    }
  }

  Future<void> _loadPendingDeposits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print('Loading pending deposits...');
    try {
      // Get user's pending deposits
      final deposits = await _depositService.getUserDeposits(_userId);
      print('user id: $_userId');
      print('deposits: $deposits');
      // Filter only pending deposits
      final pendingDeposits =
          deposits.where((deposit) => deposit.isPending).toList();

      // Calculate total pending amount
      double total = 0.0;
      for (var deposit in pendingDeposits) {
        total += deposit.amount;
      }

      setState(() {
        _pendingDeposits = pendingDeposits;
        _totalPendingAmount = total;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading deposits: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading deposits: ${e.toString()}';
      });
    }
  }

  // Format date string
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
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

  // Handle card selection and navigate to deposit fund screen
  void _onCardSelected(String cardType) {
    if (cardType == 'investment' && !_isPayed) {
      // Show message that investment deposit is only available after payment
      _showCustomSnackBar(context,
          'Investment deposit is only available after initial payment', false);
      return;
    }

    setState(() {
      _selectedCardType = cardType;
    });

    // If selected from button, navigate immediately
    // Otherwise, add a small delay for visual feedback of selection
    if (_selectedCardType == cardType) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DepositFundScreen(
            depositType: cardType,
          ),
        ),
      ).then((_) {
        _loadPendingDeposits();
        _showCustomSnackBar(context, 'Deposit info updated', true);
      });
    } else {
      // Just select the card but don't navigate
      _showCustomSnackBar(context, '$cardType selected', true);
    }
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
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadUserData,
          ),
          const Padding(
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
          SizedBox(
            width: width,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Pending Amount Card
                  Container(
                    width: width,
                    decoration: BoxDecoration(
                      gradient: SweepGradient(
                        colors: [
                          const Color(0xFF1E1A4D).withOpacity(0.3),
                          const Color(0xFF311568).withOpacity(0.3),
                          const Color(0xFF8200DB).withOpacity(0.3),
                        ],
                        stops: const [0.29, 0.39, 0.63],
                        center: Alignment.center,
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Pending',
                                style: AppTheme.textStyleBold),
                            const SizedBox(height: 8),
                            Text('\$${_totalPendingAmount.toStringAsFixed(2)}',
                                style: AppTheme.textStyleLarge),
                          ],
                        ),
                        Image.asset(
                          'assets/pending.png',
                          width: 90,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section title for deposit types
                  Text('Select Deposit Type',
                      style: AppTheme.textStyleBold.copyWith(fontSize: 18)),
                  const SizedBox(height: 10),

                  // Deposit Type Cards
                  Row(
                    children: [
                      // Investment Deposit Card
                      // Investment Deposit Card
                      Expanded(
                        child: GestureDetector(
                          onTap: _isPayed
                              ? () => _onCardSelected('investment')
                              : null, // Disable if not paid
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: SweepGradient(
                                colors: [
                                  const Color(0xFF1E1A4D)
                                      .withOpacity(_isPayed ? 0.3 : 0.1),
                                  const Color(0xFF311568)
                                      .withOpacity(_isPayed ? 0.3 : 0.1),
                                  const Color(0xFF8200DB)
                                      .withOpacity(_isPayed ? 0.3 : 0.1),
                                ],
                                stops: const [0.29, 0.39, 0.63],
                                center: Alignment.center,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: _selectedCardType == 'investment'
                                  ? Border.all(color: Colors.purple, width: 3)
                                  : null,
                              boxShadow: _selectedCardType == 'investment'
                                  ? [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Investment Deposit',
                                        style: AppTheme.textStyleBold.copyWith(
                                          color: _isPayed
                                              ? Colors.white
                                              : Colors.grey,
                                        ),
                                      ),
                                    ),
                                    if (_selectedCardType == 'investment')
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.purple,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (!_isPayed)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Locked',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                if (_selectedCardType == 'investment')
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.purple,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Selected',
                                          style: TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Coin Deposit Card
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _onCardSelected('buy_coin'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              gradient: SweepGradient(
                                colors: [
                                  const Color(0xFF1E1A4D).withOpacity(0.3),
                                  const Color(0xFF311568).withOpacity(0.3),
                                  const Color(0xFF8200DB).withOpacity(0.3),
                                ],
                                stops: const [0.29, 0.39, 0.63],
                                center: Alignment.center,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              border: _selectedCardType == 'buy_coin'
                                  ? Border.all(color: Colors.purple, width: 3)
                                  : null,
                              boxShadow: _selectedCardType == 'buy_coin'
                                  ? [
                                      BoxShadow(
                                        color: Colors.purple.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Coin deposit',
                                      style: AppTheme.textStyleBold,
                                    ),
                                    if (_selectedCardType == 'buy_coin')
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.purple,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                                if (_selectedCardType == 'buy_coin')
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.purple,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Selected',
                                          style: TextStyle(
                                            color: Colors.purple,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Deposit List
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[300]),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : _pendingDeposits == null ||
                                    _pendingDeposits!.isEmpty
                                ? Center(
                                    child: Text(
                                      'No pending deposits',
                                      style: AppTheme.textStyleBold,
                                    ),
                                  )
                                : RefreshIndicator(
                                    onRefresh: _loadPendingDeposits,
                                    color: AppTheme.primaryColor,
                                    backgroundColor: AppTheme.backgroundColor,
                                    child: ListView.builder(
                                      itemCount: _pendingDeposits!.length,
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final deposit =
                                            _pendingDeposits![index];
                                        return Container(
                                          width: width,
                                          decoration: AppTheme.cardDecoration(),
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 8),
                                          padding: const EdgeInsets.all(16),
                                          child: Stack(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          '\$${deposit.amount.toStringAsFixed(2)}',
                                                          style: AppTheme
                                                              .textStyleBold),
                                                      Text(
                                                          _formatDateTime(
                                                              deposit
                                                                  .createdAt),
                                                          style: AppTheme
                                                              .textStyleSmall),
                                                      const SizedBox(
                                                          height: 10),
                                                      Text(
                                                          'ID: ${deposit.transactionId}',
                                                          style: AppTheme
                                                              .textStyleSmall),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 16,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            30),
                                                  ),
                                                  child: const Text(
                                                    "Pending",
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                  ),

                  const SizedBox(height: 20),

                  // Make Deposit Button
                  Center(
                    child: Container(
                      width: width,
                      decoration: AppTheme.buttonDecoration(),
                      child: ElevatedButton(
                        style: AppTheme.buttonStyle(),
                        onPressed: _selectedCardType != null
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DepositFundScreen(
                                      depositType: _selectedCardType!,
                                    ),
                                  ),
                                ).then((_) {
                                  _loadPendingDeposits();
                                  _showCustomSnackBar(
                                      context, 'Deposit info updated', true);
                                })
                            : () {
                                _showCustomSnackBar(
                                    context,
                                    'Please select a deposit type first',
                                    false);
                              },
                        child: const Text(
                          'Make Deposit',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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

// You'll need to modify your DepositFundScreen to accept the depositType parameter
// Here's a minimal example of how to modify the constructor:

/*
class DepositFundScreen extends StatefulWidget {
  final String depositType; // 'investment' or 'coin'
  
  const DepositFundScreen({
    Key? key, 
    required this.depositType,
  }) : super(key: key);

  @override
  State<DepositFundScreen> createState() => _DepositFundScreenState();
}
*/
