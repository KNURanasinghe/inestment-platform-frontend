import 'dart:convert';
import 'package:http/http.dart' as http;

class Investment {
  final int id;
  final int depositId;
  final String transactionId;
  final double amount;
  final double interestRate;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final int daysRemaining;
  final int daysActive;
  final int totalProfitDays;
  final int claimedDays;
  final double? totalClaimedProfit;
  final double? totalProfit;

  Investment({
    required this.id,
    required this.depositId,
    required this.transactionId,
    required this.amount,
    required this.interestRate,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.daysRemaining,
    required this.daysActive,
    required this.totalProfitDays,
    required this.claimedDays,
    this.totalClaimedProfit,
    this.totalProfit,
  });

  factory Investment.fromJson(Map<String, dynamic> json) {
    return Investment(
      id: json['id'],
      depositId: json['depositId'],
      transactionId: json['transactionId'] ?? '',
      amount: _parseAmount(json['amount']),
      interestRate: _parseAmount(json['interestRate']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      status: json['status'] ?? 'active',
      daysRemaining: json['daysRemaining'] ?? 0,
      daysActive: json['daysActive'] ?? 0,
      totalProfitDays: json['totalProfitDays'] ?? 0,
      claimedDays: json['claimedDays'] ?? 0,
      totalClaimedProfit: _parseAmount(json['totalClaimedProfit']),
      totalProfit: _parseAmount(json['totalProfit']),
    );
  }

  // Helper method to parse amount that could be a string, int, double or null
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

class InvestmentProfit {
  final int id;
  final DateTime date;
  final double amount;
  final bool claimed;
  final DateTime? claimedAt;

  InvestmentProfit({
    required this.id,
    required this.date,
    required this.amount,
    required this.claimed,
    this.claimedAt,
  });

  factory InvestmentProfit.fromJson(Map<String, dynamic> json) {
    return InvestmentProfit(
      id: json['id'],
      date: DateTime.parse(json['date']),
      amount: Investment._parseAmount(json['amount']),
      claimed: json['claimed'] ?? false,
      claimedAt:
          json['claimedAt'] != null ? DateTime.parse(json['claimedAt']) : null,
    );
  }
}

class InvestmentSummary {
  final double totalInvested;
  final double totalEarned;
  final int activeInvestments;
  final int completedInvestments;
  final int totalInvestments;

  InvestmentSummary({
    required this.totalInvested,
    required this.totalEarned,
    required this.activeInvestments,
    required this.completedInvestments,
    required this.totalInvestments,
  });

  factory InvestmentSummary.fromJson(Map<String, dynamic> json) {
    return InvestmentSummary(
      totalInvested: Investment._parseAmount(json['totalInvested']),
      totalEarned: Investment._parseAmount(json['totalEarned']),
      activeInvestments: json['activeInvestments'] ?? 0,
      completedInvestments: json['completedInvestments'] ?? 0,
      totalInvestments: json['totalInvestments'] ?? 0,
    );
  }
}

class InvestmentService {
  final String baseUrl;

  InvestmentService({required this.baseUrl});

  // Get all user investments
  Future<Map<String, dynamic>> getUserInvestments(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/investments'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final List<dynamic> investmentsList = data['investments'];
        final List<Investment> investments =
            investmentsList.map((item) => Investment.fromJson(item)).toList();

        final InvestmentSummary summary =
            InvestmentSummary.fromJson(data['summary']);

        return {
          'success': true,
          'investments': investments,
          'summary': summary,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load investments: ${response.body}',
        };
      }
    } catch (e) {
      print('Error getting user investments: $e');
      return {
        'success': false,
        'message': 'Error getting user investments: $e',
      };
    }
  }

  // Get specific investment details
  Future<Map<String, dynamic>> getInvestmentDetails(int investmentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/investments/$investmentId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final Investment investment = Investment.fromJson(data['investment']);

        final List<dynamic> profitHistoryList = data['profitHistory'];
        final List<InvestmentProfit> profitHistory = profitHistoryList
            .map((item) => InvestmentProfit.fromJson(item))
            .toList();

        return {
          'success': true,
          'investment': investment,
          'profitHistory': profitHistory,
          'summary': data['summary'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load investment details: ${response.body}',
        };
      }
    } catch (e) {
      print('Error getting investment details: $e');
      return {
        'success': false,
        'message': 'Error getting investment details: $e',
      };
    }
  }

  // Get today's available profits
  Future<Map<String, dynamic>> getTodayProfits(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/today-profits'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return {
          'success': true,
          'date': data['date'],
          'profits': data['profits'],
          'totalProfit': Investment._parseAmount(data['totalProfit']),
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load today\'s profits: ${response.body}',
        };
      }
    } catch (e) {
      print('Error getting today\'s profits: $e');
      return {
        'success': false,
        'message': 'Error getting today\'s profits: $e',
      };
    }
  }

  // Claim today's profits
  Future<Map<String, dynamic>> claimTodayProfits(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/$userId/claim-profits'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return {
          'success': true,
          'message': data['message'],
          'date': data['date'],
          'totalProfit': Investment._parseAmount(data['totalProfit']),
          'count': data['count'],
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to claim profits',
        };
      }
    } catch (e) {
      print('Error claiming profits: $e');
      return {
        'success': false,
        'message': 'Error claiming profits: $e',
      };
    }
  }

  // Get profit history
  Future<Map<String, dynamic>> getProfitHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/profit-history'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final List<dynamic> profitHistoryList = data['profitHistory'];
        final List<InvestmentProfit> profitHistory = profitHistoryList
            .map((item) => InvestmentProfit.fromJson(item))
            .toList();

        return {
          'success': true,
          'profitHistory': profitHistory,
          'count': data['count'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load profit history: ${response.body}',
        };
      }
    } catch (e) {
      print('Error getting profit history: $e');
      return {
        'success': false,
        'message': 'Error getting profit history: $e',
      };
    }
  }
}
