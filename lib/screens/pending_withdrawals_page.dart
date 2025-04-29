// ignore_for_file: unused_import, unused_field

import 'package:flutter/material.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/services/withdrawal_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingWithdrawalsPage extends StatefulWidget {
  const PendingWithdrawalsPage({super.key});

  @override
  _PendingWithdrawalsPageState createState() => _PendingWithdrawalsPageState();
}

class _PendingWithdrawalsPageState extends State<PendingWithdrawalsPage> {
  final WithdrawalService _withdrawalService = WithdrawalService(
    baseUrl: 'http://151.106.125.212:5021', // Update with your server URL
  );

  List<Withdrawal>? _pendingWithdrawals;
  double _totalPendingAmount = 0.0;
  bool _isLoading = true;
  String? _errorMessage;
  int? _userId; // Default user ID
  String _filterType = "All"; // Default filter
  String _sortBy = "Date"; // Default sort

  @override
  void initState() {
    super.initState();
    _loadPendingWithdrawals();
  }

  Future<void> _loadPendingWithdrawals() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get user ID from preferences if available
      final userid = await UserApiService.getUserId();
      if (userid != null) {
        _userId = userid;
      }

      // Get all pending withdrawals - for admin view
      final withdrawals = await _withdrawalService.getUserWithdrawals(userid!);

      // Calculate total pending amount
      double total = 0.0;
      for (var withdrawal in withdrawals) {
        total += withdrawal.amount;
      }

      setState(() {
        _pendingWithdrawals = withdrawals;
        _totalPendingAmount = total;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading withdrawals: ${e.toString()}';
      });
      print('Error loading withdrawals: $e');
    }
  }

  // Format date for display
  String _formatDate(DateTime date) {
    final DateFormat formatter = DateFormat('MMM dd, yyyy • hh:mm a');
    return formatter.format(date);
  }

  // Format currency for display
  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '\$',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Pending Withdrawals",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadPendingWithdrawals,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 15),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/profile.jpg'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AppTheme.appBackground(),
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          // Total Pending Card with gradient
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1A4D), Color(0xFF8200DB)],
                                begin: Alignment.bottomCenter,
                                end: Alignment(0.01, 1.4),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Pending',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(_totalPendingAmount),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_pendingWithdrawals?.length ?? 0} Transactions',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Text(
                                      'Last 7 days',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),
                          // Filter and Sort Row
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                PopupMenuButton<String>(
                                  onSelected: (String value) {
                                    setState(() {
                                      _filterType = value;
                                    });
                                  },
                                  color: AppTheme.backgroundColor,
                                  child: const FilterButton(
                                    icon: Icons.filter_list,
                                    text: "Filter",
                                  ),
                                  itemBuilder: (BuildContext context) =>
                                      <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'All',
                                      child: Text('All',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Bank Transfer',
                                      child: Text('Bank Transfer',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                    const PopupMenuItem<String>(
                                      value: 'Wire Transfer',
                                      child: Text('Wire Transfer',
                                          style:
                                              TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    PopupMenuButton<String>(
                                      onSelected: (String value) {
                                        setState(() {
                                          _sortBy = value;
                                        });
                                      },
                                      color: AppTheme.backgroundColor,
                                      child: const FilterButton(
                                        icon: Icons.sort,
                                        text: "Sort",
                                      ),
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(
                                          value: 'Date',
                                          child: Text('Date',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                        const PopupMenuItem<String>(
                                          value: 'Amount',
                                          child: Text('Amount',
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(Icons.search,
                                        color: Colors.white60),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: _pendingWithdrawals == null ||
                                    _pendingWithdrawals!.isEmpty
                                ? const Center(
                                    child: Text(
                                      'No pending withdrawals found',
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: _pendingWithdrawals!.length,
                                    itemBuilder: (context, index) {
                                      final withdrawal =
                                          _pendingWithdrawals![index];

                                      // Apply filtering
                                      if (_filterType != "All" &&
                                          withdrawal.paymentMethod !=
                                              _filterType) {
                                        return const SizedBox.shrink();
                                      }

                                      return TransactionTile(
                                        withdrawal.paymentMethod,
                                        "${withdrawal.bankName} ••••${withdrawal.accountNumber.substring(withdrawal.accountNumber.length > 4 ? withdrawal.accountNumber.length - 4 : 0)}",
                                        _formatDate(withdrawal.createdAt),
                                        _formatCurrency(withdrawal.amount),
                                        withdrawalId: withdrawal.id ?? 0,
                                        onApprove: () async {
                                          try {
                                            await _withdrawalService
                                                .updateWithdrawalStatus(
                                              withdrawal.id ?? 0,
                                              false, // set isPending to false (approve)
                                            );
                                            // Reload the data
                                            _loadPendingWithdrawals();

                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Withdrawal approved successfully'),
                                                backgroundColor: Colors.green,
                                              ),
                                            );
                                          } catch (e) {
                                            if (!mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Error: ${e.toString()}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 10),
                          // Process All Withdrawals Button
                          GestureDetector(
                            onTap: () async {
                              try {
                                setState(() {
                                  _isLoading = true;
                                });

                                // Process all pending withdrawals
                                if (_pendingWithdrawals != null) {
                                  for (var withdrawal in _pendingWithdrawals!) {
                                    if (withdrawal.id != null) {
                                      await _withdrawalService
                                          .updateWithdrawalStatus(
                                        withdrawal.id!,
                                        false, // set isPending to false (approve)
                                      );
                                    }
                                  }
                                }

                                // Reload the data
                                await _loadPendingWithdrawals();

                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'All withdrawals processed successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                setState(() {
                                  _isLoading = false;
                                  _errorMessage = 'Error: ${e.toString()}';
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF00CCF1),
                                    Color(0xFF8200DB)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  "Process All Withdrawals",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 2),
    );
  }
}

// Transaction Tile
class TransactionTile extends StatelessWidget {
  final String type, bank, date, amount;
  final int withdrawalId;
  final Function()? onApprove;

  const TransactionTile(
    this.type,
    this.bank,
    this.date,
    this.amount, {
    super.key,
    this.withdrawalId = 0,
    this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF00CCF1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(bank,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(date,
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      "Pending",
                      style: TextStyle(color: Colors.white, fontSize: 12),
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

// Filter & Sort Button
class FilterButton extends StatelessWidget {
  final IconData icon;
  final String text;

  const FilterButton({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 5),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
