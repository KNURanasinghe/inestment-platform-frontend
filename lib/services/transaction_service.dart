import 'dart:convert';
import 'package:http/http.dart' as http;

class Transaction {
  final int id;
  final String transactionId;
  final double amount;
  final DateTime createdAt;
  final String type;
  final String description;
  final String time;
  final String displayAmount;

  Transaction({
    required this.id,
    required this.transactionId,
    required this.amount,
    required this.createdAt,
    required this.type,
    required this.description,
    required this.time,
    required this.displayAmount,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] ?? 0,
      transactionId: json['transaction_id'] ?? '',
      amount: _parseAmount(json['amount']),
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      time: json['time'] ?? '',
      displayAmount: json['display_amount'] ?? '',
    );
  }

  static double _parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is double) return amount;
    if (amount is int) return amount.toDouble();
    if (amount is String) {
      try {
        return double.parse(amount);
      } catch (e) {
        return 0.0;
      }
    }
    return 0.0;
  }
}

class TransactionResponse {
  final Map<String, List<Transaction>> transactions;
  final List<Transaction> allTransactions;
  final double balance;
  final double totalDeposits;
  final double totalWithdrawals;

  TransactionResponse({
    required this.transactions,
    required this.allTransactions,
    required this.balance,
    required this.totalDeposits,
    required this.totalWithdrawals,
  });

  factory TransactionResponse.fromJson(Map<String, dynamic> json) {
    // Process grouped transactions
    Map<String, List<Transaction>> groupedTransactions = {};

    if (json.containsKey('transactions')) {
      final Map<String, dynamic> groups = json['transactions'];

      groups.forEach((key, value) {
        groupedTransactions[key] =
            (value as List).map((item) => Transaction.fromJson(item)).toList();
      });
    }

    // Process all transactions
    List<Transaction> allTxs = [];
    if (json.containsKey('allTransactions')) {
      allTxs = (json['allTransactions'] as List)
          .map((item) => Transaction.fromJson(item))
          .toList();
    }

    return TransactionResponse(
      transactions: groupedTransactions,
      allTransactions: allTxs,
      balance: double.tryParse(json['balance']?.toString() ?? '0') ?? 0.0,
      totalDeposits:
          double.tryParse(json['totalDeposits']?.toString() ?? '0') ?? 0.0,
      totalWithdrawals:
          double.tryParse(json['totalWithdrawals']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class TransactionService {
  final String baseUrl;

  TransactionService({required this.baseUrl});

  // Get user's transaction history
  Future<Map<String, dynamic>> getUserTransactions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/transactions'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final TransactionResponse transactionResponse =
            TransactionResponse.fromJson(data);

        return {
          'success': true,
          'transactions': transactionResponse.transactions,
          'allTransactions': transactionResponse.allTransactions,
          'balance': transactionResponse.balance,
          'totalDeposits': transactionResponse.totalDeposits,
          'totalWithdrawals': transactionResponse.totalWithdrawals,
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to load transactions',
        };
      }
    } catch (e) {
      print('Error getting user transactions: $e');
      return {
        'success': false,
        'message': 'Error getting user transactions: $e',
      };
    }
  }
}
