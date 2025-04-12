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

  final List<String> imageUrls = [
    'assets/home_bg.png',
    'assets/home_bg.png',
    'assets/home_bg.png',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await _loadUserData();
    if (_userId > 0) {
      await Future.wait([
        _loadCoinValue(),
        _loadInvestmentProfits(),
        _loadReferrals(),
      ]);
      _calculateTotalIncome();
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // Apply global background color
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
              child: const CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage('assets/user_profile.jpg'),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0, // No shadow
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
                          SizedBox(
                            height: 200,
                            width: width,
                            child: PageView.builder(
                              itemCount: imageUrls.length,
                              itemBuilder: (context, index) {
                                return Image.asset(imageUrls[index],
                                    fit: BoxFit.scaleDown);
                              },
                            ),
                          ),

                          //Total income container
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Your Total Income',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),
                                      Text(
                                        '\$${_totalIncome.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Investment + Referral Income',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          //current rate container
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

                          //Parallel Containers for profits
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
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.show_chart,
                                              color: Colors.white),
                                          Expanded(
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text(
                                                      'Investment Profit',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20)),
                                                  Text(
                                                      '\$${_investmentProfit.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold)),
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
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.people,
                                              color: Colors.white),
                                          Expanded(
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Text('Coin Referral',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20)),
                                                  Text(
                                                      '\$${_referralIncome.toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold)),
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
                'Investment: \$${referral.totalInvestment?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Coins: \$${referral.totalCoinPurchase?.toStringAsFixed(2) ?? '0.00'}',
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
