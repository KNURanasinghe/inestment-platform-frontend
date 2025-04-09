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
    baseUrl: 'http://145.223.21.62:5021', // For Android emulator
    // Use 'http://localhost:3000' for iOS simulator
  );

  List<Deposit>? _pendingDeposits;
  double _totalPendingAmount = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingDeposits();
  }

  Future<void> _loadPendingDeposits() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    print('Loading pending deposits...');
    try {
      final userId = await UserApiService.getUserId() as int;
      if (userId > 0) {
        _userId = userId;
      } else {
        // Handle the case where userId is not found in shared preferences
        setState(() {
          _isLoading = false;
          _errorMessage = 'User ID not found';
        });
        return;
      }
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
            onPressed: _loadPendingDeposits,
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
                  const SizedBox(height: 40),

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
                                                  // deposit.imagePath != null
                                                  //     ? GestureDetector(
                                                  //         onTap: () {
                                                  //           // Show payment proof image
                                                  //           showDialog(
                                                  //             context: context,
                                                  //             builder: (ctx) =>
                                                  //                 Dialog(
                                                  //               backgroundColor:
                                                  //                   Colors
                                                  //                       .transparent,
                                                  //               child: Column(
                                                  //                 mainAxisSize:
                                                  //                     MainAxisSize
                                                  //                         .min,
                                                  //                 children: [
                                                  //                   AppBar(
                                                  //                     backgroundColor:
                                                  //                         AppTheme
                                                  //                             .backgroundColor,
                                                  //                     title: const Text(
                                                  //                         'Payment Proof'),
                                                  //                     leading:
                                                  //                         IconButton(
                                                  //                       icon: const Icon(
                                                  //                           Icons.close),
                                                  //                       onPressed:
                                                  //                           () =>
                                                  //                               Navigator.pop(ctx),
                                                  //                     ),
                                                  //                   ),
                                                  //                   ClipRRect(
                                                  //                     borderRadius:
                                                  //                         const BorderRadius
                                                  //                             .only(
                                                  //                       bottomLeft:
                                                  //                           Radius.circular(10),
                                                  //                       bottomRight:
                                                  //                           Radius.circular(10),
                                                  //                     ),
                                                  //                     child: Image
                                                  //                         .network(
                                                  //                       '${_depositService.baseUrl}/${deposit.imagePath}',
                                                  //                       loadingBuilder: (context,
                                                  //                           child,
                                                  //                           loadingProgress) {
                                                  //                         if (loadingProgress ==
                                                  //                             null)
                                                  //                           return child;
                                                  //                         return Container(
                                                  //                           color:
                                                  //                               AppTheme.backgroundColor,
                                                  //                           height:
                                                  //                               300,
                                                  //                           width:
                                                  //                               double.infinity,
                                                  //                           child:
                                                  //                               Center(
                                                  //                             child: CircularProgressIndicator(
                                                  //                               value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null,
                                                  //                               color: AppTheme.primaryColor,
                                                  //                             ),
                                                  //                           ),
                                                  //                         );
                                                  //                       },
                                                  //                       errorBuilder: (context,
                                                  //                           error,
                                                  //                           stackTrace) {
                                                  //                         return Container(
                                                  //                           color:
                                                  //                               AppTheme.backgroundColor,
                                                  //                           height:
                                                  //                               100,
                                                  //                           width:
                                                  //                               double.infinity,
                                                  //                           alignment:
                                                  //                               Alignment.center,
                                                  //                           child:
                                                  //                               const Text(
                                                  //                             'Error loading image',
                                                  //                             style: TextStyle(color: Colors.white),
                                                  //                           ),
                                                  //                         );
                                                  //                       },
                                                  //                     ),
                                                  //                   ),
                                                  //                 ],
                                                  //               ),
                                                  //             ),
                                                  //           );
                                                  //         },
                                                  //         child: const Icon(
                                                  //           Icons.image,
                                                  //           color:
                                                  //               Colors.white70,
                                                  //           size: 28,
                                                  //         ),
                                                  //       )
                                                  //     : const SizedBox(),
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
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const DepositFundScreen()),
                        ).then((_) =>
                            _loadPendingDeposits()), // Reload after returning
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
