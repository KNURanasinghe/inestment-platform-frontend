import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../widgets/AppTheme.dart';

class ProfitHistoryDialog extends StatefulWidget {
  final int userId;

  const ProfitHistoryDialog({super.key, required this.userId});

  @override
  _ProfitHistoryDialogState createState() => _ProfitHistoryDialogState();
}

class _ProfitHistoryDialogState extends State<ProfitHistoryDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _errorMessage = '';

  // Data for tabs
  List<dynamic> _todayUnclaimedProfits = [];
  List<dynamic> _claimedProfitHistory = [];
  double _todayTotalProfit = 0.0;

  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchProfitData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfitData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch today's unclaimed profits
      final todayResponse = await http.get(
        Uri.parse(
            'http://151.106.125.212:5021/api/users/${widget.userId}/today-profits'),
        headers: {'Content-Type': 'application/json'},
      );

      // Fetch claimed profit history
      final historyResponse = await http.get(
        Uri.parse(
            'http://151.106.125.212:5021/api/users/${widget.userId}/profit-history'),
        headers: {'Content-Type': 'application/json'},
      );

      if (todayResponse.statusCode == 200 &&
          historyResponse.statusCode == 200) {
        final todayData = json.decode(todayResponse.body);
        final historyData = json.decode(historyResponse.body);

        setState(() {
          _todayUnclaimedProfits = todayData['profits'] ?? [];
          // Ensure totalProfit is properly converted to double
          _todayTotalProfit =
              double.tryParse(todayData['totalProfit'].toString()) ?? 0.0;
          _claimedProfitHistory = historyData['profitHistory'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load profit data. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      print('Error fetching profit data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Profit History',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.blue,
                tabs: const [
                  Tab(text: 'Today\'s Unclaimed'),
                  Tab(text: 'Claimed History'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : _errorMessage.isNotEmpty
                        ? _buildErrorMessage()
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildUnclaimedProfitsTab(),
                              _buildClaimedHistoryTab(),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
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
            onPressed: _fetchProfitData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnclaimedProfitsTab() {
    if (_todayUnclaimedProfits.isEmpty) {
      return const Center(
        child: Text(
          'No unclaimed profits available today',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    final formatter = NumberFormat.currency(symbol: 'LKR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Today\'s Total Profit:',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              Text(
                formatter.format(_todayTotalProfit),
                style: const TextStyle(
                    color: Colors.green,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _todayUnclaimedProfits.length,
            itemBuilder: (context, index) {
              final profit = _todayUnclaimedProfits[index];
              return _buildProfitItem(
                transactionId: profit['transactionId'] ?? '',
                date: profit['profitDate'] ?? '',
                // Safely parse the profit amount
                amount: double.tryParse(
                        profit['dailyProfit']?.toString() ?? '0.0') ??
                    0.0,
                isUnclaimed: true,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // Add logic to claim profits
              _claimTodayProfits();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Claim All Profits',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClaimedHistoryTab() {
    if (_claimedProfitHistory.isEmpty) {
      return const Center(
        child: Text(
          'No claimed profit history found',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: _claimedProfitHistory.length,
      itemBuilder: (context, index) {
        final profit = _claimedProfitHistory[index];
        return _buildProfitItem(
          transactionId: profit['transactionId'] ?? '',
          date: profit['date'] ?? '',
          // Safely parse the profit amount
          amount: double.tryParse(profit['amount']?.toString() ?? '0.0') ?? 0.0,
          isUnclaimed: false,
          claimedAt: profit['claimedAt'],
        );
      },
    );
  }

  // Format time string to Sri Lankan time (same as in TransactionHistoryPage)
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

  // Function to format datetime string to Sri Lankan time
  String formatSriLankanDateTime(String dateTimeString) {
    if (dateTimeString.isEmpty) {
      return "Unknown";
    }

    try {
      // Parse the datetime string
      final datetime = DateTime.parse(dateTimeString);

      // Add Sri Lankan offset (UTC+5:30)
      final sriLankanTime = datetime.add(const Duration(hours: 5, minutes: 30));

      // Format date and time
      final date = DateFormat('yyyy-MM-dd').format(sriLankanTime);
      final time = DateFormat('h:mm a').format(sriLankanTime);

      return "$date at $time";
    } catch (e) {
      print('Error parsing datetime string "$dateTimeString": $e');
      return dateTimeString; // Return original if parsing fails
    }
  }

  Widget _buildProfitItem({
    required String transactionId,
    required String date,
    required double amount,
    required bool isUnclaimed,
    String? claimedAt,
  }) {
    final formatter = NumberFormat.currency(symbol: 'LKR');

    String formattedDateTime;
    if (isUnclaimed) {
      // For unclaimed profits, just show the date
      formattedDateTime = date;
    } else if (claimedAt != null && claimedAt.isNotEmpty) {
      // For claimed profits, show the date and time in Sri Lankan format
      formattedDateTime = formatSriLankanDateTime(claimedAt);
    } else {
      formattedDateTime = date;
    }

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUnclaimed ? 'Investment Profit' : 'Claimed Profit',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: $transactionId',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Date: $formattedDateTime',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          Text(
            formatter.format(amount),
            style: TextStyle(
              color: isUnclaimed ? Colors.amber : Colors.green,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claimTodayProfits() async {
    if (_todayUnclaimedProfits.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
            'http://151.106.125.212:5021/api/users/${widget.userId}/claim-profits'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        // Refresh the data
        await _fetchProfitData();
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profits claimed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
          final responseData = json.decode(response.body);
          _errorMessage = responseData['message'] ?? 'Failed to claim profits';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
      print('Error claiming profits: $e');
    }
  }
}
