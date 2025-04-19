import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinValue {
  final int id;
  final double lkrValue;
  final DateTime updatedAt;
  final String updatedByName;

  CoinValue({
    required this.id,
    required this.lkrValue,
    required this.updatedAt,
    required this.updatedByName,
  });

  factory CoinValue.fromJson(Map<String, dynamic> json) {
    return CoinValue(
      id: json['id'],
      lkrValue: _parseAmount(json['lkrValue']),
      updatedAt: DateTime.parse(json['updatedAt']),
      updatedByName: json['updatedByName'] ?? '',
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

class CoinBalance {
  final int id;
  final int userId;
  final double balance;
  final DateTime? updatedAt;

  CoinBalance({
    required this.id,
    required this.userId,
    required this.balance,
    this.updatedAt,
  });

  factory CoinBalance.fromJson(Map<String, dynamic> json) {
    return CoinBalance(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      balance: CoinValue._parseAmount(json['balance']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

class UserInvestmentSummary {
  final double investmentsTotal;
  final double coinPurchasesTotal;
  final double totalDeposits;
  final double pendingInvestments;
  final double pendingCoinPurchases;
  final int pendingDepositsCount;
  final double currentCoinBalance;

  UserInvestmentSummary({
    required this.investmentsTotal,
    required this.coinPurchasesTotal,
    required this.totalDeposits,
    required this.pendingInvestments,
    required this.pendingCoinPurchases,
    required this.pendingDepositsCount,
    required this.currentCoinBalance,
  });

  factory UserInvestmentSummary.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] ?? {};
    final investments = summary['investments'] ?? {};
    final coinPurchases = summary['coinPurchases'] ?? {};

    return UserInvestmentSummary(
      investmentsTotal: CoinValue._parseAmount(investments['total']),
      coinPurchasesTotal: CoinValue._parseAmount(coinPurchases['total']),
      totalDeposits: CoinValue._parseAmount(summary['totalDeposits']),
      pendingInvestments: CoinValue._parseAmount(investments['pending']),
      pendingCoinPurchases: CoinValue._parseAmount(coinPurchases['pending']),
      pendingDepositsCount: summary['pendingDeposits'] ?? 0,
      currentCoinBalance: CoinValue._parseAmount(summary['currentCoinBalance']),
    );
  }
}

class CoinService {
  final String baseUrl;

  CoinService({required this.baseUrl});

  // Get current coin value
  Future<Map<String, dynamic>> getCurrentCoinValue() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/coin-values/current'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final CoinValue coinValue = CoinValue.fromJson(data['coinValue']);

        return {
          'success': true,
          'coinValue': coinValue,
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get current coin value',
        };
      }
    } catch (e) {
      print('Error getting current coin value: $e');
      return {
        'success': false,
        'message': 'Error getting current coin value: $e',
      };
    }
  }

  // Get coin value history
  Future<Map<String, dynamic>> getCoinValueHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/coin-values/history'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final List<dynamic> coinValuesList = data['coinValues'];
        final List<CoinValue> coinValues =
            coinValuesList.map((item) => CoinValue.fromJson(item)).toList();

        return {
          'success': true,
          'coinValues': coinValues,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get coin value history',
        };
      }
    } catch (e) {
      print('Error getting coin value history: $e');
      return {
        'success': false,
        'message': 'Error getting coin value history: $e',
      };
    }
  }

  // Get user coin balance
  Future<Map<String, dynamic>> getUserCoinBalance(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/coins'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final CoinBalance coinBalance = CoinBalance.fromJson(data);
        print('coin balance ${coinBalance.balance}');
        print('user id ${coinBalance.userId}');
        return {
          'success': true,
          'balance': coinBalance.balance,
          'userId': coinBalance.userId,
          'updatedAt': coinBalance.updatedAt,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get user coin balance',
        };
      }
    } catch (e) {
      print('Error getting user coin balance: $e');
      return {
        'success': false,
        'message': 'Error getting user coin balance: $e',
      };
    }
  }

  // Get user investment summary - for total coin and investment deposits
  Future<Map<String, dynamic>> getUserInvestmentSummary(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/investment-summary'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final UserInvestmentSummary summary =
            UserInvestmentSummary.fromJson(data);

        return {
          'success': true,
          'summary': summary,
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get investment summary',
        };
      }
    } catch (e) {
      print('Error getting investment summary: $e');
      return {
        'success': false,
        'message': 'Error getting investment summary: $e',
      };
    }
  }

  // Transfer coins to another user
  Future<Map<String, dynamic>> transferCoins({
    required int senderId,
    required String receiverUsername,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/coins/transfer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': senderId,
          'receiverUsername': receiverUsername,
          'amount': amount,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return {
          'success': true,
          'message': data['message'],
          'amount': CoinValue._parseAmount(data['amount']),
          'receiverUsername': data['receiverUsername'],
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to transfer coins',
        };
      }
    } catch (e) {
      print('Error transferring coins: $e');
      return {
        'success': false,
        'message': 'Error transferring coins: $e',
      };
    }
  }
}
