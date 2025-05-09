import 'package:flutter/material.dart';
import 'package:investment_plan_app/services/referral_service.dart';

import '../services/user_service.dart';
import '../widgets/AppTheme.dart';

class ReferralProfitHistoryScreen extends StatefulWidget {
  const ReferralProfitHistoryScreen({super.key});

  @override
  _ReferralProfitHistoryScreenState createState() =>
      _ReferralProfitHistoryScreenState();
}

class _ReferralProfitHistoryScreenState
    extends State<ReferralProfitHistoryScreen> {
  bool _isLoading = true;
  String _errorMessage = '';
  List<ReferralCommission> _commissions = [];
  List<CommissionSummaryItem> _summaryItems = [];

  final ReferralService _referralService = ReferralService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  @override
  void initState() {
    super.initState();
    _loadCommissionHistory();
  }

  Future<void> _loadCommissionHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userId = await UserApiService.getUserId();
      if (userId == null || userId <= 0) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid user ID';
        });
        return;
      }

      final response = await _referralService.getUserCommissions(userId);

      if (response['success']) {
        setState(() {
          _commissions = response['commissions'];
          _summaryItems = response['summary'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Failed to load commission history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading commission history: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.backgroundColor, // Set background color explicitly
      appBar: AppBar(
        title: const Text(
          'Referral Profit History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0, // Remove shadow
        iconTheme: const IconThemeData(
          color: Colors.white, // This changes the back button color
        ),
      ),
      body: Stack(
        children: [
          // Add background
          AppTheme.appBackground(),

          // Content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage.isNotEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ))
                  : _buildCommissionHistory(),
        ],
      ),
    );
  }

  Widget _buildCommissionHistory() {
    return Column(
      children: [
        // Summary section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.withOpacity(0.7),
                Colors.deepPurple.withOpacity(0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Commission Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              // Group summary by type and display totals
              ..._buildSummarySection(),
            ],
          ),
        ),

        // List of commissions
        Expanded(
          child: _commissions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 48,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No commission history found',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 20),
                  itemCount: _commissions.length,
                  itemBuilder: (context, index) {
                    final commission = _commissions[index];
                    return _buildCommissionItem(commission);
                  },
                ),
        ),
      ],
    );
  }

  List<Widget> _buildSummarySection() {
    // Group summary items by type
    Map<String, double> typeTotal = {};
    Map<int, double> levelTotal = {};

    for (var item in _summaryItems) {
      // Sum by type
      if (typeTotal.containsKey(item.type)) {
        typeTotal[item.type] = typeTotal[item.type]! + item.total;
      } else {
        typeTotal[item.type] = item.total;
      }

      // Sum by level
      if (levelTotal.containsKey(item.level)) {
        levelTotal[item.level] = levelTotal[item.level]! + item.total;
      } else {
        levelTotal[item.level] = item.total;
      }
    }

    List<Widget> widgets = [];

    // Add type totals
    widgets.add(const Text('By Commission Type:',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)));

    typeTotal.forEach((type, total) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${type.toUpperCase()} Commissions:',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'LKR ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    });

    widgets.add(const Divider(color: Colors.white30));

    // Add level totals
    widgets.add(const Text('By Referral Level:',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)));

    final sortedLevels = levelTotal.keys.toList()..sort();

    for (var level in sortedLevels) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level:',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'LKR ${levelTotal[level]!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildCommissionItem(ReferralCommission commission) {
    // Format date
    final formattedDate =
        '${commission.date.day.toString().padLeft(2, '0')}/${commission.date.month.toString().padLeft(2, '0')}/${commission.date.year}';

    // Determine color based on commission type
    Color typeColor = commission.type == 'investment'
        ? Colors.green.withOpacity(0.7)
        : Colors.blue.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blueGrey.withOpacity(0.2),
            Colors.black.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formattedDate,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  commission.type.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'From: ${commission.referredUsername}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.show_chart,
                          size: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Level ${commission.level} • ${(commission.rate).toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'LKR ${commission.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'Base: LKR ${commission.baseAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
