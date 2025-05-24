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
      // Fix: Convert integer to boolean
      isPayed: (json['isPayed'] ?? 0) ==
          1, // or json['is_payed'] if that's the actual field name
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

class CommissionSummaryItem {
  final String type;
  final int level;
  final double total;

  CommissionSummaryItem({
    required this.type,
    required this.level,
    required this.total,
  });

  factory CommissionSummaryItem.fromJson(Map<String, dynamic> json) {
    return CommissionSummaryItem(
      type: json['type'] ?? '',
      level: json['level'] ?? 0,
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
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

  Future<Map<String, dynamic>> getUserCommissions(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/commissions'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if data has the expected structure
        if (data['commissions'] == null || data['summary'] == null) {
          return {
            'success': false,
            'message': 'Invalid commission data structure',
          };
        }

        final List<ReferralCommission> commissions =
            (data['commissions'] as List)
                .map((item) => ReferralCommission.fromJson(item))
                .toList();

        final List<CommissionSummaryItem> summary = (data['summary'] as List)
            .map((item) => CommissionSummaryItem.fromJson(item))
            .toList();

        return {
          'success': true,
          'commissions': commissions,
          'summary': summary,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load commissions: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error parsing commissions: $e');
      return {
        'success': false,
        'message': 'Error parsing commission data: $e',
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
        final data = json.decode(response.body);
        print('refferela ${data['directReferrals']}');
        // Add validation
        if (data['directReferrals'] == null ||
            data['levelCounts'] == null ||
            data['commissions'] == null) {
          return {
            'success': false,
            'message': 'Invalid referral data structure',
          };
        }

        final List<Referral> directReferrals = (data['directReferrals'] as List)
            .map((item) => Referral.fromJson(item))
            .toList();

        final List<LevelCount> levelCounts = (data['levelCounts'] as List)
            .map((item) => LevelCount.fromJson(item))
            .toList();

        final TotalCommissions commissions =
            TotalCommissions.fromJson(data['commissions'] ?? {});

        return {
          'success': true,
          'directReferrals': directReferrals,
          'levelCounts': levelCounts,
          'commissions': commissions,
          'totalReferralsCount': data['totalReferralsCount']
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to load referrals: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error parsing referrals: $e');
      return {
        'success': false,
        'message': 'Error parsing referral data: $e',
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

  Future<Map<String, dynamic>> getUserReferralLevels(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/referral-levels'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        return {
          'success': true,
          'data': {
            'userId': data['userId'],
            'totalReferrals': data['totalReferrals'],
            'levelCounts': data['levelCounts'],
            'levelBreakdown': data['levelBreakdown'],
            'maxLevel': data['maxLevel'],
          },
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch referral levels',
        };
      }
    } catch (e) {
      print('Error fetching user referral levels: $e');
      return {
        'success': false,
        'message': 'Error fetching user referral levels: $e',
      };
    }
  }
}
