// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'dart:async' show TimeoutException, Timer;

import 'package:flutter/material.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/services/coin_service.dart';
import 'package:investment_plan_app/services/investment_service.dart';
import 'package:investment_plan_app/services/referral_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;
  double _userCoinCount = 0.0;
  double _userCoinValueLKR = 0.0;
  bool _isLoadingUserCoins = true;
  String _userCoinsError = '';

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

  // Services
  final UserApiService _userApiService = UserApiService(
    baseUrl: 'http://145.223.21.62:5021',
  );

  final CoinService _coinService = CoinService(
    baseUrl: 'http://145.223.21.62:5021',
  );

  final InvestmentService _investmentService = InvestmentService(
    baseUrl: 'http://145.223.21.62:5021',
  );

  final ReferralService _referralService = ReferralService(
    baseUrl: 'http://145.223.21.62:5021',
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadAllData() async {
    await _loadUserData();
    if (_userId > 0) {
      await Future.wait([
        _loadCoinValue(),
        _loadInvestmentProfits(),
        _loadReferrals(),
      ]);
      await _loadUserCoins();
      _calculateTotalIncome();

      // Force refresh the UI
      if (mounted) {
        setState(() {
          // Just to trigger a rebuild
        });
      }
    }
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

  Future<void> _loadReferrals() async {
    setState(() {
      _isLoadingReferrals = true;
      _referralsError = '';
    });

    try {
      // Get referral data from the API
      final response = await _referralService.getUserReferrals(_userId);

      if (response['success']) {
        final directReferrals = response['directReferrals'];
        final commissions = response['commissions'];

        setState(() {
          _directReferrals = directReferrals;
          _referralIncome = commissions.coin; // Get income from coin referrals
          _isLoadingReferrals = false;
        });
        print(
            'Referrals loaded: ${_directReferrals.length}, Referral income: $_referralIncome');
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

  void _calculateTotalIncome() {
    setState(() {
      _totalIncome = _investmentProfit + _referralIncome;
    });
    print('Total income calculated: $_totalIncome');
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
      // Add a timeout to prevent indefinite loading
      final response = await _coinService
          .getUserCoins(_userId)
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw TimeoutException('Connection timed out. Please try again.');
      });

      if (response['success']) {
        setState(() {
          _userCoinCount = response['coinData'].coinCount ?? 0.0;
          _userCoinValueLKR = _userCoinCount * _coinValue;
          _isLoadingUserCoins = false;
        });
      } else {
        setState(() {
          _userCoinsError = response['message'] ?? 'Failed to load user coins';
          _isLoadingUserCoins = false;
        });
      }
    } catch (e) {
      setState(() {
        _userCoinsError = e is TimeoutException
            ? 'Connection timed out'
            : 'Error loading user coins';
        _isLoadingUserCoins = false;
      });
      print('Error loading user coins: $e');
    }
  }

  // Build dot indicator widget
  Widget _buildDotIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? Colors.white
            : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  // Define the reusable container widget for auto-scrolling
  Widget _buildAutoScrollContainer(int index) {
    return Container(
      width: 150, // Fixed width for each container
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
          'Item ${index + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _userCoinInfoWidget() {
    // Directly return the content without checking loading state
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'T E T H E R',
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
            const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
            const SizedBox(width: 8),
            Text(
              '${_userCoinCount.toStringAsFixed(2)} Coins',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Value: LKR ${_userCoinValueLKR.toStringAsFixed(2)}',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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
            GestureDetector(
              onTap: () {
                // Navigate to profile screen
              },
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.purple.withOpacity(0.5),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                ),
              ),
            ),
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
      body: RefreshIndicator(
        onRefresh: _refreshData,
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
                                horizontal: 20.0, vertical: 10.0),
                            child: Container(
                              height: 120,
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

                          // Slidable containers with PageView
                          Column(
                            children: [
                              SizedBox(
                                height: 200,
                                width: width,
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (int page) {
                                    setState(() {
                                      _currentPage = page;
                                    });
                                  },
                                  children: [
                                    // First slide - Coin information
                                    Container(
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
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _userCoinInfoWidget(),
                                      ),
                                    ),

                                    // Second slide - Editable text
                                    Container(
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
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: TextField(
                                          controller: _textControllers[0],
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 3,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: 'Enter slide text',
                                            hintStyle: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              slideTexts[0] = value;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Dot indicators for pagination
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    2,
                                    (index) => _buildDotIndicator(index),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Golden tape profit container
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
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
                                          Icons.trending_up,
                                          color: Color(0xFF8B4513),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Flexible(
                                          child: const Text(
                                            'Today\'s Profit',
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
                                  Text(
                                    '\$${(_totalIncome * 0.05).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Color(0xFF8B4513),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Total income container
                          Container(
                            height: 150,
                            decoration: const BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage('assets/total_bg.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Your Total Income',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '\$${_totalIncome.toStringAsFixed(2)}',
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
                          ),
                          const SizedBox(height: 20),

                          // Golden tape upcoming store container
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10.0, horizontal: 16.0),
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
                          const SizedBox(height: 20),

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
                                            'Current Coin Rate',
                                            '1 Coin = LKR${_coinValue.toStringAsFixed(2)}',
                                            width),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Parallel Containers for profits
                          Padding(
                            padding: const EdgeInsets.only(left: 20, right: 20),
                            child: Row(
                              children: [
                                // Investment profit container
                                Expanded(
                                  child: Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      border:
                                          Border.all(color: Colors.grey[300]!),
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
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Investment Profit',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '\$${_investmentProfit.toStringAsFixed(2)}',
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
                                      border:
                                          Border.all(color: Colors.grey[300]!),
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
                                          const Icon(Icons.people,
                                              color: Colors.white, size: 16),
                                          Expanded(
                                            child: Center(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                    'Coin Referral',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '\$${_referralIncome.toStringAsFixed(2)}',
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
                            padding: const EdgeInsets.only(left: 20, right: 20),
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
                                              child: CircularProgressIndicator(
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
                                          style: TextStyle(color: Colors.white),
                                        ),
                                      ),
                                    )
                                  else if (_referralsError.isNotEmpty)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Text(
                                          'Unable to load referrals: $_referralsError',
                                          style:
                                              TextStyle(color: Colors.red[300]),
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
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 0),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "Investment: \$${referral.totalInvestment?.toStringAsFixed(2) ?? '0.00'}",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                "Coins: \$${referral.totalCoinPurchase?.toStringAsFixed(2) ?? '0.00'}",
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
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
}
