// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:async' show TimeoutException, Timer;

import 'package:flutter/material.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/services/coin_service.dart';
import 'package:investment_plan_app/services/investment_service.dart';
import 'package:investment_plan_app/services/referral_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../services/deposit_service.dart';
import '../services/withdrawal_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _walletCurrentPage = 0;
  final int _currentIndex = 0;
  double _userCoinCount = 0.0;
  double _userCoinValueLKR = 0.0;
  bool _isLoadingUserCoins = true;
  String _userCoinsError = '';
  bool _isLoadingProfile = true; // Add this line
  bool _isLoadingInvestments = true; // Add this line

  @override
  bool get wantKeepAlive => true;
  late final ScrollController _scrollController;

  // Add a page controller to control the PageView
  final PageController _pageController = PageController();

  // Add a PageController for the auto-scrolling PageView
  final PageController _autoScrollController = PageController();

  // Add a Timer for auto-scrolling
  Timer? _autoScrollTimer;

  // Current page for auto-scrolling
  int _autoScrollPage = 0;

  // Add a variable to track the current page index for the slide indicators
  int _currentPage = 0;

  String username = "User";
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  int _userId = 0;
  double _coinValue = 0.0;
  bool _isLoadingCoinValue = true;
  String _coinValueError = '';

  // Income and profit variables
  double _totalIncome = 0.0;
  double _investmentProfit = 0.0;
  double _referralIncome = 0.0;

  // Referrals
  List<dynamic> _directReferrals = [];
  bool _isLoadingReferrals = true;
  String _referralsError = '';

// Add these variables to your _HomeScreenState class
  bool _hasTodayProfit = false;
  double _todayProfitAmount = 0.0;
  bool _isLoadingTodayProfit = true;
  bool _isClaimingProfit = false;

  // Add these variables to your _HomeScreenState class
  double _totalDepositAmount = 0.0;
  double _totalInvestmentDeposits = 0.0;
  double _totalCoinDeposits = 0.0;
  bool _isLoadingDeposits = true;
  List<Deposit> _userDeposits = [];
  final bool _isDropdownOpen = false;

  double withdrawalAmount = 0.0;
  int _totalReferralsCount = 0;

  String? profileImageUrl;

  // Services
  final UserApiService _userApiService = UserApiService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  final CoinService _coinService = CoinService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  final InvestmentService _investmentService = InvestmentService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  final ReferralService _referralService = ReferralService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  // Slidable container text contents (reduced to 1)
  final List<String> slideTexts = [
    'Track your earnings and referrals easily',
  ];

  // Text editing controllers for the slidable text inputs (reduced to 1)
  final List<TextEditingController> _textControllers = [
    TextEditingController(text: 'Track your earnings and referrals easily'),
  ];

  @override
  void dispose() {
    // Dispose all text controllers
    for (var controller in _textControllers) {
      controller.dispose();
    }
    // Dispose the page controllers
    _pageController.dispose();
    _autoScrollController.dispose();
    // Cancel the auto-scroll timer
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // Initialize with default values to prevent loading indicators
    _userCoinCount = 0.0;
    _userCoinValueLKR = 0.0;
    _isLoadingUserCoins = false;

    _loadAllData();

    // Add listener to page controller to update current page index
    _pageController.addListener(() {
      int page = _pageController.page?.round() ?? 0;
      if (_currentPage != page) {
        setState(() {
          _currentPage = page;
        });
      }
    });

    // Start auto-scrolling after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScrolling();
    });
  }

  Future<void> fetchProfileImage() async {
    final userId = await UserApiService.getUserId();

    if (userId != null) {
      final imageUrl = await _userApiService.getProfileImageUrl(userId);
      setState(() {
        profileImageUrl = imageUrl;
        print('image url ${'http://151.106.125.212:5021'}/uploads/$imageUrl');
      });
    }
  }

// Example usage in a Flutter widget
  Future<void> _fetchUserTotalWithdrawals() async {
    try {
      final withdrawalService =
          WithdrawalService(baseUrl: 'http://151.106.125.212:5021');
      final userId = await UserApiService.getUserId();

      // Get all withdrawals total
      final totalAmount =
          await withdrawalService.getUserTotalWithdrawals(userId!);
      print('Total withdrawals: $totalAmount');
      setState(() {
        withdrawalAmount = totalAmount;
      });
      // Get only pending withdrawals total
      final pendingAmount = await withdrawalService
          .getUserTotalWithdrawals(userId, status: 'pending');
      print('Pending withdrawals: $pendingAmount');

      // Get only approved withdrawals total
      final approvedAmount = await withdrawalService
          .getUserTotalWithdrawals(userId, status: 'approved');
      print('Approved withdrawals: $approvedAmount');
    } catch (e) {
      print('Error: $e');
      // Handle error, show snackbar, etc.
    }
  }

  // Start auto-scrolling
  void _startAutoScrolling() {
    // Cancel any existing timer to prevent duplicates
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_autoScrollController.hasClients && mounted) {
        print('Auto-scrolling to page: ${(_autoScrollPage + 1) % 10}');
        _autoScrollController.animateToPage(
          (_autoScrollPage + 1) % 10,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        print('PageView not mounted or widget disposed');
      }
    });
  }

  Widget _buildWalletSection() {
    return Column(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: 200,
            aspectRatio: 16 / 9,
            viewportFraction: 0.9,
            initialPage: 0,
            enableInfiniteScroll: true,
            reverse: false,
            autoPlay: true,
            autoPlayInterval: Duration(seconds: 5),
            autoPlayAnimationDuration: Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            enlargeCenterPage: true,
            enlargeFactor: 0.3,
            onPageChanged: (index, reason) {
              setState(() {
                _walletCurrentPage = index;
              });
            },
            scrollDirection: Axis.horizontal,
          ),
          items: [
            _userCoinInfoWidget(),
            _buildInvestmentWalletSlide(),
          ],
        ),
        // Dot indicators
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (index) => _buildWalletDotIndicator(index),
            ),
          ),
        ),
      ],
    );
  }

  // Coin value modification
  void updateCoinValue(double newValue) {
    if (mounted) {
      setState(() {
        _coinValue = newValue;
        _userCoinValueLKR = _userCoinCount * newValue;
      });
      _calculateTotalIncome();
    }
  }

// Investment profit adjustment
  void adjustInvestmentProfit(double adjustment) {
    if (mounted) {
      setState(() {
        _investmentProfit += adjustment;
        _totalIncome = _investmentProfit + _referralIncome;
      });
    }
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    try {
      // Load critical user data first
      await _loadUserData();

      if (_userId <= 0) return;

      // Parallel loading with error isolation
      final results = await Future.wait([
        _loadCoinValue().catchError((e) => print("Coin error: $e")),
        _loadInvestmentProfits().catchError((e) => print("Invest error: $e")),
        _loadReferrals().catchError((e) => print("Referral error: $e")),
        _loadUserCoins().catchError(
            (e) => print("User coins error: $e")), // Always load user coins
        _loadInvestmentSummary().catchError(
            (e) => print("Investment summary error: $e")), // Add this line
      ], eagerError: false);

      // Serial loading for dependent operations
      await _loadTodayProfit();
      await _loadUserDeposits();
      await _fetchUserTotalWithdrawals();
      await fetchProfileImage();

      _calculateTotalIncome();

      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
          _isLoadingCoinValue = false;
          _isLoadingInvestments = false;
        });
      }
    } catch (e) {
      print("Global load error: $e");
    }
  }

// Create a method to format date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
        _userDeposits = approvedDeposits;
        _totalDepositAmount = totalAmount;
        _totalInvestmentDeposits = investmentAmount;
        _totalCoinDeposits = coinAmount;
        _isLoadingDeposits = false;
      });

      print('Loaded user deposits: ${approvedDeposits.length}');
      print('Total deposit amount: $_totalDepositAmount');
      print('Investment deposits: $_totalInvestmentDeposits');
      print('Coin deposits: $_totalCoinDeposits');
    } catch (e) {
      setState(() {
        _isLoadingDeposits = false;
      });
      print('Error loading user deposits: $e');
    }
  }

// Add this method to check for today's unclaimed profits
  Future<void> _loadTodayProfit() async {
    setState(() {
      _isLoadingTodayProfit = true;
    });

    try {
      final response = await _investmentService.getTodayProfits(_userId);

      if (response['success']) {
        final totalProfit = response['totalProfit'] ?? 0.0;
        final count = response['count'] ?? 0;

        setState(() {
          _hasTodayProfit = totalProfit > 0 && count > 0;
          _todayProfitAmount = totalProfit;
          _isLoadingTodayProfit = false;
          print('has today profit $_hasTodayProfit');
        });

        print(
            'Today\'s profit loaded: $_todayProfitAmount, Available: $_hasTodayProfit');
      } else {
        setState(() {
          _hasTodayProfit = false;
          _todayProfitAmount = 0.0;
          _isLoadingTodayProfit = false;
        });
        print('No profits available today or error: ${response['message']}');
      }
    } catch (e) {
      setState(() {
        _hasTodayProfit = false;
        _todayProfitAmount = 0.0;
        _isLoadingTodayProfit = false;
      });
      print('Error loading today\'s profit: $e');
    }
  }

// Modify the _claimTodayProfit method to update all relevant values
  Future<void> _claimTodayProfit() async {
    if (_isClaimingProfit) return; // Prevent double-clicking

    double maxIncomeLimit = _totalDepositAmount * 3;
    if (_totalIncome >= maxIncomeLimit) {
      // Show message explaining why claim is disabled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot claim profits: Maximum income limit reached (3x investment amount). Please make additional deposits to increase your earning potential.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return; // Exit without claiming
    }

    setState(() {
      _isClaimingProfit = true;
    });

    try {
      final response = await _investmentService.claimTodayProfits(_userId);

      if (response['success']) {
        final claimedAmount = response['totalProfit'] ?? 0.0;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Successfully claimed ${claimedAmount.toStringAsFixed(2)} LKR'),
            backgroundColor: Colors.green,
          ),
        );

        // Update investment profit and total income, but not coin balance
        setState(() {
          _investmentProfit +=
              claimedAmount; // Add claimed amount to investment profit
          _totalIncome =
              _investmentProfit + _referralIncome; // Recalculate total income
          _hasTodayProfit = false;
          _todayProfitAmount = 0.0;
        });

        // Important: DO NOT call _loadUserCoins() here as it would refresh the coin balance
        // Only refresh the investment profits data
        // await _loadTodayProfit();
        // await _loadInvestmentProfits();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to claim profit'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error claiming profit: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error claiming today\'s profit: $e');
    } finally {
      setState(() {
        _isClaimingProfit = false;
      });
    }
  }

  // Add this as a new method in the _HomeScreenState class

  Widget _buildIncomeLimitMessage() {
    // Compare total income with investment wallet amount
    double maxIncomeLimit = (_totalDepositAmount / 1.1) * 3;
    bool hasReachedMaxLimit = _totalIncome >= maxIncomeLimit;

    // Calculate remaining earnings allowed
    double remainingEarnings = maxIncomeLimit - _totalIncome;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasReachedMaxLimit
                ? [
                    Colors.red.withOpacity(0.7),
                    Colors.redAccent.withOpacity(0.5)
                  ]
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
                  ? 'You have reached the maximum income limit of 3x your investment amount. Please make additional deposits to increase your earning potential.'
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
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LKR 0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
                Text(
                  'LKR ${maxIncomeLimit.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// Create a widget for today's profit container
  // Modified _buildTodayProfitContainer method to disable claim button when limit reached
  Widget _buildTodayProfitContainer() {
    // Check if user has reached maximum income limit
    bool hasReachedMaxLimit = false;
    if (!_isLoadingDeposits && _totalDepositAmount > 0) {
      double maxIncomeLimit = _totalDepositAmount * 3;
      hasReachedMaxLimit = _totalIncome >= maxIncomeLimit;
    }

    if (_isLoadingTodayProfit) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700).withOpacity(0.8),
                const Color(0xFFF5DEB3).withOpacity(0.9),
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
          child: Center(
            child: SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
          ),
        ),
      );
    }

    if (!_hasTodayProfit) {
      // Return nothing if no profit is available
      return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: hasReachedMaxLimit
                ? [
                    Colors.grey.withOpacity(0.7),
                    Colors.grey.withOpacity(0.5),
                  ]
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasReachedMaxLimit
                            ? Icons.warning_amber
                            : Icons.monetization_on,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          hasReachedMaxLimit
                              ? 'Profit Available (Max Limit Reached)'
                              : 'Today\'s Profit Available!',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LKR ${_todayProfitAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasReachedMaxLimit
                    ? null // Disable the button if max limit reached
                    : (_isClaimingProfit ? null : _claimTodayProfit),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      hasReachedMaxLimit ? Colors.grey : Colors.red,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: hasReachedMaxLimit
                      ? Colors.grey.withOpacity(0.5)
                      : Colors.red.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isClaimingProfit
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        hasReachedMaxLimit ? 'MAX LIMIT REACHED' : 'CLAIM NOW',
                      ),
              ),
            ),
            if (hasReachedMaxLimit)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Make additional deposits to increase your earning limit',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user ID
      final userId = await UserApiService.getUserId();
      if (userId != null && userId > 0) {
        _userId = userId;

        // Load user profile
        final userProfileResponse =
            await _userApiService.getUserProfile(_userId);
        if (userProfileResponse['success']) {
          setState(() {
            _userData = userProfileResponse['userData'];
            username = _userData?['name'] ?? 'User';
            _isLoading = false;
          });
          print('User data loaded: $_userData');
        } else {
          setState(() {
            _isLoading = false;
          });
          print(
              'Failed to load user profile: ${userProfileResponse['message']}');
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Invalid user ID: $userId');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadCoinValue() async {
    setState(() {
      _isLoadingCoinValue = true;
      _coinValueError = '';
    });

    try {
      final response = await _coinService.getCurrentCoinValue();

      if (response['success']) {
        setState(() {
          _coinValue = response['coinValue'].lkrValue;
          _isLoadingCoinValue = false;
        });
        print('Coin value loaded: $_coinValue');
      } else {
        setState(() {
          _coinValueError = response['message'] ?? 'Failed to load coin value';
          _isLoadingCoinValue = false;
        });
        print('Failed to load coin value: $_coinValueError');
      }
    } catch (e) {
      setState(() {
        _coinValueError = 'Error loading coin value';
        _isLoadingCoinValue = false;
      });
      print('Error loading coin value: $e');
    }
  }

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

  // First, modify your _loadReferrals method in the _HomeScreenState class
  Future<void> _loadReferrals() async {
    setState(() {
      _isLoadingReferrals = true;
      _referralsError = '';
    });

    try {
      // Get referral data from the API
      final response = await _referralService.getUserReferrals(_userId);
      print('response home $response');

      if (response['success']) {
        final directReferrals = response['directReferrals'];
        final commissions = response['commissions'];

        // Extract totalReferralsCount from the response
        final totalReferralsCount = response['totalReferralsCount'] ?? 0;

        setState(() {
          _directReferrals = directReferrals;
          // Correctly set the referral income to the coin commission only
          // The issue is here - you're adding coin to itself (doubling it)
          _referralIncome = commissions.coin +
              commissions.investment; // Sum of coin + investment commissions
          _isLoadingReferrals = false;
          _totalReferralsCount = totalReferralsCount; // Update the total count
        });
        print(
            'Referrals loaded: ${_directReferrals.length}, Referral income: $_referralIncome, Total referrals: $_totalReferralsCount');

        // Optionally log the individual components
        print(
            'Referral coin income: ${commissions.coin}, Referral investment income: ${commissions.investment}');
      } else {
        setState(() {
          _referralsError = response['message'] ?? 'Failed to load referrals';
          _isLoadingReferrals = false;
        });
        print('Failed to load referrals: $_referralsError');
      }
    } catch (e) {
      setState(() {
        _referralsError = 'Error loading referrals';
        _isLoadingReferrals = false;
      });
      print('Error loading referrals: $e');
    }
  }

  // Modify the _calculateTotalIncome to make it more robust
  void _calculateTotalIncome() {
    setState(() {
      _totalIncome = _investmentProfit + _referralIncome;
    });
    print('Total income recalculated: $_totalIncome');
  }

  Future<void> _refreshData() async {
    await _loadAllData();
  }

  Future<void> _loadUserCoins() async {
    setState(() {
      _isLoadingUserCoins = true;
      _userCoinsError = '';
    });

    try {
      // First try to get the coin balance directly from the API
      final response = await _coinService.getUserCoinBalance(_userId);

      if (response['success']) {
        setState(() {
          _userCoinCount = response['balance'] ?? 0.0;
          _userCoinValueLKR = _userCoinCount * _coinValue;
          _isLoadingUserCoins = false;
        });
        print('User coin balance loaded: $_userCoinCount');
      } else {
        // If direct method fails, try to get from investment summary
        if (_investmentSummary != null) {
          setState(() {
            _userCoinCount = _investmentSummary!.currentCoinBalance;
            _userCoinValueLKR = _userCoinCount * _coinValue;
            _isLoadingUserCoins = false;
          });
          print('User coin balance loaded from summary: $_userCoinCount');
        } else {
          setState(() {
            _userCoinsError =
                response['message'] ?? 'Failed to load user coins';
            _isLoadingUserCoins = false;
          });
          print('Failed to load user coins: $_userCoinsError');
        }
      }
    } catch (e) {
      setState(() {
        _userCoinsError = 'Error loading user coins';
        _isLoadingUserCoins = false;
      });
      print('Error loading user coins: $e');
    }
  }

  // Add investment summary object
  UserInvestmentSummary? _investmentSummary;

  Future<void> _loadInvestmentSummary() async {
    try {
      final response = await _coinService.getUserInvestmentSummary(_userId);

      if (response['success']) {
        setState(() {
          _investmentSummary = response['summary'];
          // Update coin count if not already set
          if (_userCoinCount <= 0) {
            _userCoinCount = _investmentSummary!.currentCoinBalance;
            _userCoinValueLKR = _userCoinCount * _coinValue;
          }
        });
        print('Investment summary loaded');
      } else {
        print('Failed to load investment summary: ${response['message']}');
      }
    } catch (e) {
      print('Error loading investment summary: $e');
    }
  }

  // Build dot indicator widget
  Widget _buildWalletDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: _walletCurrentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // Define the reusable container widget for auto-scrolling
  Widget _buildAutoScrollContainer(int index) {
    return Container(
      width: 180, // Fixed width for each container
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red[900]!.withOpacity(0.8), // Deep red
            Color(0xFFFFD700).withOpacity(0.9), // Golden yellow
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          'Today TEC 1 Coin = LKR ${_coinValue.toStringAsFixed(2)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  _userCoinInfoWidget() {
    print(
        'Value: LKR  $_userCoinCount * $_coinValue ${(_userCoinCount * _coinValue).toStringAsFixed(2)}');
    return Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.withOpacity(0.6),
              Colors.blue.withOpacity(0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'T E C WALLET',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                    height: 45,
                    width: 45,
                    child: Image.asset('assets/coin.png')),
                const SizedBox(width: 8),
                _isLoadingUserCoins
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ))
                    : Text(
                        '${_userCoinCount.toInt()} Coins',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ],
            ),
            const SizedBox(height: 8),
            _isLoadingUserCoins || _isLoadingCoinValue
                ? Text(
                    'Loading value...',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  )
                : Text(
                    'Value: LKR ${(_userCoinCount * _coinValue).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    super.build(context); // Call super.build to maintain state

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          // mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to profile screen
              },
              child: profileImageUrl != null
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(profileImageUrl!))
                  : CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.purple.withOpacity(0.5),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
            ),
            SizedBox(
              width: 10,
            ),
            _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text('Hello $username',
                    style: const TextStyle(fontSize: 20, color: Colors.white)),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is OverscrollNotification) {
            _autoScrollTimer?.cancel();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: () => _loadAllData(forceRefresh: true),
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    AppTheme.appBackground(),
                    SizedBox(
                      width: width,
                      height: height,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            // Auto-scrolling horizontal containers
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0, vertical: 2.0),
                              child: SizedBox(
                                height: 70,
                                child: GestureDetector(
                                  onPanDown: (_) {
                                    print(
                                        'User interaction: Pausing auto-scroll');
                                    _autoScrollTimer?.cancel();
                                  },
                                  onPanEnd: (_) {
                                    print(
                                        'User interaction ended: Resuming auto-scroll');
                                    _startAutoScrolling();
                                  },
                                  child: PageView.builder(
                                    controller: _autoScrollController,
                                    itemCount: 10,
                                    itemBuilder: (context, index) {
                                      return _buildAutoScrollContainer(index);
                                    },
                                    onPageChanged: (index) {
                                      setState(() {
                                        _autoScrollPage = index;
                                        print('Page changed to: $index');
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),

                            _buildWalletSection(),
                            // // Golden tape profit container

                            // Add today's profit container (will only show when profit is available)
                            _buildTodayProfitContainer(),
                            _hasTodayProfit
                                ? const SizedBox(height: 12)
                                : SizedBox.shrink(),
                            // Total income container
                            Row(
                              // mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                SizedBox(
                                  width: 10,
                                ),
                                Container(
                                  height: 120,
                                  width: 120,
                                  decoration: const BoxDecoration(
                                    image: DecorationImage(
                                      image: AssetImage('assets/btc.png'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                // SizedBox(
                                //   width: 10,
                                // ),
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Your Total Gain',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'LKR${_totalIncome.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Investment + Referral Income',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

// Income limit message
                            _isLoadingDeposits || _totalDepositAmount <= 0
                                ? SizedBox
                                    .shrink() // Don't show if still loading or no deposits
                                : _buildIncomeLimitMessage(),

                            const SizedBox(height: 20),

                            // Golden tape upcoming store container

                            // Current rate container
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 20, right: 20, top: 0, bottom: 20),
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  gradient: LinearGradient(
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                    colors: [
                                      Colors.indigo.withOpacity(0.1),
                                      Colors.deepPurple.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: _isLoadingCoinValue
                                      ? _loadingCoinValueWidget(width)
                                      : _coinValueError.isNotEmpty
                                          ? _errorCoinValueWidget(
                                              width, _coinValueError)
                                          : _infoWidget2(
                                              'Current Balance',
                                              'LKR ${(_investmentProfit + _referralIncome - withdrawalAmount).toStringAsFixed(2)}',
                                              width),
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Parallel Containers for profits
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: Row(
                                children: [
                                  // Investment profit container
                                  Expanded(
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.withOpacity(0.4),
                                            Colors.white.withOpacity(0.3),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.show_chart,
                                                color: Colors.white, size: 16),
                                            Expanded(
                                              child: Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      //7135184230
                                                      'Investment Gain',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'LKR${_investmentProfit.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  // Referral income container
                                  Expanded(
                                    child: Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.withOpacity(0.4),
                                            Colors.white.withOpacity(0.3),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.people,
                                                    color: Colors.white,
                                                    size: 16),
                                                const Spacer(),
                                                _isLoadingReferrals
                                                    ? SizedBox(
                                                        width: 14,
                                                        height: 14,
                                                        child:
                                                            CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : Text(
                                                        '$_totalReferralsCount', // Display the total referrals count
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                              ],
                                            ),
                                            Expanded(
                                              child: Center(
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Text(
                                                      'Invite and Earn',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'LKR${_referralIncome.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Level 1 Referrals Container
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 20, right: 20),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Level 1 Referrals',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20),
                                        ),
                                        _isLoadingReferrals
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Text(
                                                '${_directReferrals.length} users',
                                                style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16),
                                              ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Referral list
                                    if (_isLoadingReferrals)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: Text(
                                            'Loading your referrals...',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      )
                                    else if (_referralsError.isNotEmpty)
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(20.0),
                                          child: Text(
                                            'Unable to load referrals: $_referralsError',
                                            style: TextStyle(
                                                color: Colors.red[300]),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    else if (_directReferrals.isEmpty)
                                      const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(20.0),
                                          child: Column(
                                            children: [
                                              Icon(
                                                Icons.people_outline,
                                                color: Colors.white,
                                                size: 48,
                                              ),
                                              SizedBox(height: 16),
                                              Text(
                                                'You don\'t have any referrals yet.\nInvite friends to earn commissions!',
                                                style: TextStyle(
                                                    color: Colors.white),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _directReferrals.length,
                                        itemBuilder: (context, index) {
                                          final referral =
                                              _directReferrals[index];
                                          return _buildReferralTile(referral);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 30.0, horizontal: 16.0),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFFFD700).withOpacity(0.8),
                                      const Color(0xFFF5DEB3).withOpacity(0.9),
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
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.store,
                                            color: Color(0xFF8B4513),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: const Text(
                                              'Upcoming Store',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Color(0xFF8B4513),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Coming Soon',
                                      style: TextStyle(
                                        color: Color(0xFF8B4513),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar:
          AppTheme.bottomNavigationBar(context, 0, username: username),
    );
  }

  Widget _buildReferralTile(dynamic referral) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                referral.name.toString().isNotEmpty
                    ? referral.name.toString().substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.name ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  referral.username ?? '',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Column(
          //   crossAxisAlignment: CrossAxisAlignment.end,
          //   children: [
          //     Text(
          //       "Investment: LKR${referral.totalInvestment?.toStringAsFixed(2) ?? '0.00'}",
          //       style: const TextStyle(color: Colors.white, fontSize: 12),
          //     ),
          //     const SizedBox(height: 4),
          //     Text(
          //       "Coins: LKR${referral.totalCoinPurchase?.toStringAsFixed(2) ?? '0.00'}",
          //       style: const TextStyle(color: Colors.white, fontSize: 12),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _loadingCoinValueWidget(double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: width,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Text(
            'Current Coin Rate',
            style: AppTheme.textStyleTitle.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCoinValueWidget(double width, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: width,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Text(
            'Current Coin Rate',
            style: AppTheme.textStyleTitle.copyWith(color: Colors.white),
          ),
          Text(
            'Unable to load',
            style: AppTheme.textStyleAmount.copyWith(color: Colors.red[300]),
          ),
        ],
      ),
    );
  }

  Widget _infoWidget2(String title, String amount, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: width,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Text(title,
              style: AppTheme.textStyleTitle.copyWith(color: Colors.white)),
          Text(amount,
              style: AppTheme.textStyleAmount.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildInvestmentWalletSlide() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.withOpacity(0.6),
            Colors.blue.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'INVESTMENT WALLET',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                  height: 45,
                  width: 45,
                  child: Image.asset('assets/icons8-wallet-96.png')),
              const SizedBox(width: 6),
              _isLoadingDeposits
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'LKR ${(_totalDepositAmount / 1.1).toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              print("DROPDOWN TAPPED: User tapped on deposit history dropdown");
              // Instead of just toggling a boolean, show a dialog when clicked
              if (!_isLoadingDeposits) {
                _showDepositHistoryDialog(context);
              }
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border:
                    Border.all(color: Colors.white.withOpacity(0.3), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Deposit History',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// Create a new method to show deposit history in a dialog
  void _showDepositHistoryDialog(BuildContext context) {
    print("DIALOG OPENED: About to show deposit history dialog");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.6,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.withOpacity(0.9),
                  Colors.purple.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Deposit History',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white30),
                _buildDepositHistoryContent(),
              ],
            ),
          ),
        );
      },
    );
  }

// Content for the deposit history dialog
// Content for the deposit history dialog
  Widget _buildDepositHistoryContent() {
    if (_userDeposits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            'No deposits found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Amount',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Type',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // List
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _userDeposits.length,
              itemBuilder: (context, index) {
                final deposit = _userDeposits[index];
                // Force debug print here
                print(
                    'Displaying deposit: ID=${deposit.id}, Purpose=${deposit.purpose}, Amount=${deposit.amount}');

                // Determine display text and color based on purpose
                String displayType;
                Color typeColor;

                if (deposit.purpose == 'investment') {
                  displayType = 'Investment';
                  typeColor = Colors.green.withOpacity(0.3);
                } else if (deposit.purpose == 'buy_coin') {
                  displayType = 'Coin Purchase';
                  typeColor = Colors.blue.withOpacity(0.3);
                } else {
                  // Fallback for any other value
                  displayType = deposit.purpose ?? 'Unknown';
                  typeColor = Colors.orange.withOpacity(0.3);
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: index < _userDeposits.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(deposit.createdAt),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'LKR ${(deposit.amount / 1.1).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            displayType,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Summary footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Investment Deposits:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'LKR ${(_totalInvestmentDeposits / 1.1).toStringAsFixed(2)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Coin Deposits:',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'LKR ${(_totalCoinDeposits / 1.1).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Deposits:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'LKR ${(_totalDepositAmount / 1.1).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
