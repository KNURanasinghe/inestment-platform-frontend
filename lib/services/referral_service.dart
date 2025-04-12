import 'dart:convert';
import 'package:http/http.dart' as http;

class Referral {
  final int id;
  final String name;
  final String username;
  final String email;
  final bool isPayed;
  final DateTime joinedAt;
  final double totalInvestment;
  final double totalCoinPurchase;

  Referral({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.isPayed,
    required this.joinedAt,
    required this.totalInvestment,
    required this.totalCoinPurchase,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      isPayed: json['isPayed'] ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'])
          : DateTime.now(),
      totalInvestment: _parseAmount(json['totalInvestment']),
      totalCoinPurchase: _parseAmount(json['totalCoinPurchase']),
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

class LevelCount {
  final int level;
  final int count;

  LevelCount({
    required this.level,
    required this.count,
  });

  factory LevelCount.fromJson(Map<String, dynamic> json) {
    return LevelCount(
      level: json['level'] ?? 0,
      count: json['count'] ?? 0,
    );
  }
}

class ReferralCommission {
  final int id;
  final String type;
  final int level;
  final double baseAmount;
  final double rate;
  final double amount;
  final DateTime date;
  final String referredUsername;

  ReferralCommission({
    required this.id,
    required this.type,
    required this.level,
    required this.baseAmount,
    required this.rate,
    required this.amount,
    required this.date,
    required this.referredUsername,
  });

  factory ReferralCommission.fromJson(Map<String, dynamic> json) {
    return ReferralCommission(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      level: json['level'] ?? 0,
      baseAmount: Referral._parseAmount(json['baseAmount']),
      rate: Referral._parseAmount(json['rate']),
      amount: Referral._parseAmount(json['amount']),
      date:
          json['date'] != null ? DateTime.parse(json['date']) : DateTime.now(),
      referredUsername: json['referredUsername'] ?? '',
    );
  }
}

class CommissionSummary {
  final String type;
  final int level;
  final double total;

  CommissionSummary({
    required this.type,
    required this.level,
    required this.total,
  });

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    return CommissionSummary(
      type: json['type'] ?? '',
      level: json['level'] ?? 0,
      total: Referral._parseAmount(json['total']),
    );
  }
}

class TotalCommissions {
  final double investment;
  final double coin;
  final double total;

  TotalCommissions({
    required this.investment,
    required this.coin,
    required this.total,
  });

  factory TotalCommissions.fromJson(Map<String, dynamic> json) {
    return TotalCommissions(
      investment: Referral._parseAmount(json['investment']),
      coin: Referral._parseAmount(json['coin']),
      total: Referral._parseAmount(json['total']),
    );
  }
}

class ReferralService {
  final String baseUrl;

  ReferralService({required this.baseUrl});

  // Get user's referral code
  Future<Map<String, dynamic>> getUserReferralCode(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/ref-code'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return {
          'success': true,
          'userId': data['userId'],
          'refCode': data['refCode'],
          'refLink': data['refLink'],
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get referral code',
        };
      }
    } catch (e) {
      print('Error getting referral code: $e');
      return {
        'success': false,
        'message': 'Error getting referral code: $e',
      };
    }
  }

  // Get user's referrals (people they've referred)
  Future<Map<String, dynamic>> getUserReferrals(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/referrals'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final List<dynamic> directReferralsList = data['directReferrals'];
        final List<Referral> directReferrals =
            directReferralsList.map((item) => Referral.fromJson(item)).toList();

        final List<dynamic> levelCountsList = data['levelCounts'];
        final List<LevelCount> levelCounts =
            levelCountsList.map((item) => LevelCount.fromJson(item)).toList();

        final TotalCommissions commissions =
            TotalCommissions.fromJson(data['commissions']);

        return {
          'success': true,
          'directReferrals': directReferrals,
          'levelCounts': levelCounts,
          'commissions': commissions,
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get referrals',
        };
      }
    } catch (e) {
      print('Error getting referrals: $e');
      return {
        'success': false,
        'message': 'Error getting referrals: $e',
      };
    }
  }

  // Get user's referral commission history
  Future<Map<String, dynamic>> getCommissionHistory(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/commissions'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final List<dynamic> commissionsList = data['commissions'];
        final List<ReferralCommission> commissions = commissionsList
            .map((item) => ReferralCommission.fromJson(item))
            .toList();

        final List<dynamic> summaryList = data['summary'];
        final List<CommissionSummary> summary = summaryList
            .map((item) => CommissionSummary.fromJson(item))
            .toList();

        return {
          'success': true,
          'commissions': commissions,
          'summary': summary,
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get commission history',
        };
      }
    } catch (e) {
      print('Error getting commission history: $e');
      return {
        'success': false,
        'message': 'Error getting commission history: $e',
      };
    }
  }

  // Look up user by referral code
  Future<Map<String, dynamic>> lookupUserByReferralCode(String refCode) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/ref/$refCode'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return {
          'success': true,
          'user': data['user'],
        };
      } else {
        final Map<String, dynamic> data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'No user found with this referral code',
        };
      }
    } catch (e) {
      print('Error looking up user by referral code: $e');
      return {
        'success': false,
        'message': 'Error looking up user by referral code: $e',
      };
    }
  }
}
