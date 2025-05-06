import 'dart:async';

import 'package:flutter/material.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/DepositFundScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';

import '../services/investment_service.dart';
import '../services/referral_service.dart';
import '../services/withdrawal_service.dart';
import 'ProfitHistoryDialog.dart';

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  _TransactionHistoryPageState createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  int _userId = 0;
  double _balance = 0.0;

  // Transaction data
  Map<String, List<dynamic>> _groupedTransactions = {
    'today': [],
    'yesterday': [],
    'older': []
  };

  final InvestmentService _investmentService =
      InvestmentService(baseUrl: 'http://151.106.125.212:5021');

  final ReferralService _referralService =
      ReferralService(baseUrl: 'http://151.106.125.212:5021');

  // Filter state
  String _currentFilter = 'All';
  bool isPinSet = false;
  bool isLoading = true;
  double _totalIncome = 0.0;
  double _investmentProfit = 0.0;
  double _referralIncome = 0.0;
  double withdrawalAmount = 0.0;
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

      setState(() {});
    } catch (e) {
      print('Error: $e');
      // Handle error, show snackbar, etc.
    }
  }

  Future<void> _loadIncomeData() async {
    try {
      final userId = await UserApiService.getUserId();
      if (userId == null) {
        throw Exception('User ID not found');
      }

      // Load investment profits
      final investmentResponse =
          await _investmentService.getUserInvestments(userId);
      if (investmentResponse['success']) {
        final summary = investmentResponse['summary'];
        _investmentProfit = summary.totalEarned;
      }

      // Load referral income
      final referralResponse = await _referralService.getUserReferrals(userId);
      if (referralResponse['success']) {
        final commissions = referralResponse['commissions'];
        _referralIncome = commissions.coin;
      }

      // Calculate total income
      setState(() {
        _totalIncome = _investmentProfit + _referralIncome;
      });

      print('Total income calculated: $_totalIncome');
    } catch (e) {
      print('Error loading income data: $e');
      rethrow; // Re-throw to be caught by parent
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchTransactions();
  }

  Future<void> _loadUserIdAndFetchTransactions() async {
    try {
      final userId = await UserApiService.getUserId() ?? 0;
      await _loadIncomeData();
      await _fetchUserTotalWithdrawals();

      setState(() {
        _userId = userId;
      });

      await _fetchTransactionHistory();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading user data: $e';
      });
      print('Error loading user data: $e');
    }
  }

  Future<void> _fetchTransactionHistory() async {
    print('Fetching transaction history for user ID: $_userId');
    try {
      final response = await http.get(
        Uri.parse(
            'http://151.106.125.212:5021/api/users/$_userId/transactions'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );
      print('user id: $_userId');
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        setState(() {
          // Parse the balance from response
          final balanceWithCharge =
              double.parse(responseData['balance'] ?? '0.0');

// Calculate original amount by removing 10% charge
          final originalAmount = balanceWithCharge / 1.1;

// Now you can use originalAmount for display purposes
          _balance = originalAmount;
          _groupedTransactions = {
            'today':
                List<dynamic>.from(responseData['transactions']['today'] ?? []),
            'yesterday': List<dynamic>.from(
                responseData['transactions']['yesterday'] ?? []),
            'older':
                List<dynamic>.from(responseData['transactions']['older'] ?? [])
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load transactions. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      Fluttertoast.showToast(
        msg: 'Error fetching transaction history: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      print('Error fetching transaction history: $e');
    }
  }

  List<dynamic> _getFilteredTransactions(List<dynamic> transactions) {
    if (_currentFilter == 'All') {
      return transactions;
    } else if (_currentFilter == 'Income') {
      return transactions.where((tx) => tx['type'] == 'income').toList();
    } else {
      return transactions.where((tx) => tx['type'] == 'expense').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // Updated color to match SignupScreen.dart
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        // title: const Text("Transaction History"),
        // centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.monetization_on, color: Colors.white),
            onPressed: () {
              // Handle notification icon press
              showDialog(
                context: context,
                builder: (context) => ProfitHistoryDialog(userId: _userId),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          AppTheme.appBackground(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceSection(),
                const SizedBox(height: 20),
                _buildTransactionTabs(),
                const SizedBox(height: 20),
                _buildSearchField(),
                const SizedBox(height: 20),
                Expanded(child: _buildTransactionList()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 3),
    );
  }

  Widget _buildBalanceSection() {
    final formatter = NumberFormat.currency(symbol: '\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Total Balance",
            style: TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 8),
        Text(formatter.format(_totalIncome - withdrawalAmount),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransactionTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _buildTab("All", isSelected: _currentFilter == "All"),
            _buildTab("Income", isSelected: _currentFilter == "Income"),
            _buildTab("Expense", isSelected: _currentFilter == "Expense"),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            setState(() {
              _isLoading = true;
            });
            _fetchTransactionHistory();
          },
        ),
      ],
    );
  }

  Widget _buildTab(String title, {bool isSelected = false}) {
    return TextButton(
      onPressed: () {
        setState(() {
          _currentFilter = title;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.grey,
      ),
      child: Text(title, style: const TextStyle(fontSize: 14)),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: "Search transactions...",
        hintStyle: const TextStyle(
          color: Colors.white,
        ),
        filled: true,
        fillColor: const Color(0x1AD9D9D9), // #D9D9D9 with 10% opacity
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        prefixIcon: const Icon(Icons.search, color: Colors.white),
      ),
    );
  }

  Widget _buildTransactionList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = '';
                });
                _fetchTransactionHistory();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Check if there are any transactions
    bool hasToday =
        _getFilteredTransactions(_groupedTransactions['today'] ?? [])
            .isNotEmpty;
    bool hasYesterday =
        _getFilteredTransactions(_groupedTransactions['yesterday'] ?? [])
            .isNotEmpty;
    bool hasOlder =
        _getFilteredTransactions(_groupedTransactions['older'] ?? [])
            .isNotEmpty;

    if (!hasToday && !hasYesterday && !hasOlder) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            const Text(
              'No transactions found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            if (_currentFilter != 'All') ...[
              const SizedBox(height: 8),
              Text(
                'Try changing the filter',
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
              ),
            ],
          ],
        ),
      );
    }

    return ListView(
      children: [
        if (hasToday) ...[
          _buildTransactionSection(
            "Today",
            _getFilteredTransactions(_groupedTransactions['today'] ?? [])
                .map((tx) => _buildTransactionItem(
                      tx['description'],
                      getFormattedTime(tx['time']), // Format time
                      _getDisplayAmountWithoutCharge(
                          tx['display_amount'], tx['type']),
                      tx['type'] == 'income', // Remove 10%
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (hasYesterday) ...[
          _buildTransactionSection(
            "Yesterday",
            _getFilteredTransactions(_groupedTransactions['yesterday'] ?? [])
                .map((tx) => _buildTransactionItem(
                      tx['description'],
                      getFormattedTime(tx['time']), // Format time
                      _getDisplayAmountWithoutCharge(
                          tx['display_amount'], tx['type']), // Remove 10%
                      tx['type'] == 'income',
                    ))
                .toList(),
          ),
          const SizedBox(height: 20),
        ],
        if (hasOlder) ...[
          _buildTransactionSection(
            "Older",
            _getFilteredTransactions(_groupedTransactions['older'] ?? [])
                .map((tx) => _buildTransactionItem(
                      tx['description'],
                      getFormattedTime(tx['time']), // Format time
                      _getDisplayAmountWithoutCharge(
                          tx['display_amount'], tx['type']), // Remove 10%
                      tx['type'] == 'income',
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  String getFormattedTime(String timeString) {
    if (timeString.isEmpty) {
      return "Unknown time";
    }

    try {
      // Parse the time string (assuming format "7:09 AM")
      final timeFormat = DateFormat('h:mm a');
      final timeOnly = timeFormat.parse(timeString);

      // Get current date in local timezone
      final now = DateTime.now();

      // Combine with current date and add Sri Lanka offset
      final sriLankanTime = DateTime(
        now.year,
        now.month,
        now.day,
        timeOnly.hour,
        timeOnly.minute,
      ).add(const Duration(hours: 5, minutes: 30));

      // Format for display
      return DateFormat('h:mm a').format(sriLankanTime);
    } catch (e) {
      print('Error parsing time string "$timeString": $e');
      return timeString; // Return original if parsing fails
    }
  }

// Helper function to remove 10% charge from amount
  // Helper function to apply different deduction rates based on transaction type
  String _getDisplayAmountWithoutCharge(String amountWithCharge, String type) {
    try {
      final amount =
          double.parse(amountWithCharge.replaceAll(RegExp(r'[+\-]'), ''));
      double adjustedAmount;

      if (type == 'expense') {
        // For withdrawals: deduct 3% fee
        adjustedAmount = amount * 0.97;
      } else if (type == 'income') {
        // For deposits: deduct 10% fee
        adjustedAmount = amount / 1.1;
      } else {
        // Fallback for any other types
        adjustedAmount = amount;
      }

      return adjustedAmount.toStringAsFixed(2); // Format to 2 decimal places
    } catch (e) {
      return amountWithCharge; // Return original if parsing fails
    }
  }

  Widget _buildTransactionSection(String title, List<Widget> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
        ),
        ...transactions,
      ],
    );
  }

  Widget _buildTransactionItem(
      String description, String time, String amount, bool isIncome) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1A00CCF1), // #00CCF1 with 10% opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isIncome ? Colors.green : Colors.red,
                child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(description,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
                  Text(time,
                      style: const TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ],
          ),
          Text(amount,
              style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red, fontSize: 16)),
        ],
      ),
    );
  }

// Widget _buildBottomNavigationBar() {
//   return BottomNavigationBar(
//     backgroundColor: const Color(0xFF2C1A49),
//     unselectedItemColor: Colors.grey,
//     selectedItemColor: Colors.white,
//     items: const [
//       BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
//       BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Deposit"),
//       BottomNavigationBarItem(icon: Icon(Icons.money_off), label: "Withdraw"),
//       BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
//       BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
//     ],
//   );
}
