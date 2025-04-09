import 'dart:convert';
import 'package:http/http.dart' as http;

class Withdrawal {
  final int? id;
  final String transactionId;
  final int userId;
  final double amount;
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String branchName;
  final String paymentMethod;
  final bool isPending;
  final DateTime createdAt;
  final String? username;

  Withdrawal({
    this.id,
    required this.transactionId,
    required this.userId,
    required this.amount,
    required this.accountHolderName,
    required this.bankName,
    required this.accountNumber,
    required this.branchName,
    required this.paymentMethod,
    required this.isPending,
    required this.createdAt,
    this.username,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    // Print json for debugging
    print('Parsing withdrawal: $json');

    return Withdrawal(
      id: json['id'],
      transactionId: json['transaction_id'] ?? '',
      userId: json['user_id'] ?? 0,
      amount: _parseAmount(json['amount']),
      accountHolderName: json['account_holder_name'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      branchName: json['branch_name'] ?? '',
      paymentMethod: json['payment_method'] ?? '',
      isPending: json['is_pending'] == 1 || json['is_pending'] == true,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      username: json['username'],
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'user_id': userId,
      'amount': amount,
      'account_holder_name': accountHolderName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'branch_name': branchName,
      'payment_method': paymentMethod,
      'is_pending': isPending,
      'created_at': createdAt.toIso8601String(),
      'username': username,
    };
  }
}

class WithdrawalResponse {
  final String message;
  final int? withdrawalId;
  final String? transactionId;

  WithdrawalResponse({
    required this.message,
    this.withdrawalId,
    this.transactionId,
  });

  factory WithdrawalResponse.fromJson(Map<String, dynamic> json) {
    return WithdrawalResponse(
      message: json['message'] ?? 'Operation completed',
      withdrawalId: json['withdrawalId'],
      transactionId: json['transactionId'],
    );
  }
}

class WithdrawalService {
  final String baseUrl;

  WithdrawalService({required this.baseUrl});

  // Create a new withdrawal request
  Future<WithdrawalResponse> createWithdrawal({
    required int userId,
    required double amount,
    required String accountHolderName,
    required String bankName,
    required String accountNumber,
    required String branchName,
    required String paymentMethod,
  }) async {
    try {
      print('Creating withdrawal: userId=$userId, amount=$amount');
      final uri = Uri.parse('$baseUrl/api/withdrawals');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'amount': amount,
          'accountHolderName': accountHolderName,
          'bankName': bankName,
          'accountNumber': accountNumber,
          'branchName': branchName,
          'paymentMethod': paymentMethod,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return WithdrawalResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create withdrawal: ${response.body}');
      }
    } catch (e) {
      print('Error creating withdrawal: $e');
      throw Exception('Error creating withdrawal: $e');
    }
  }

  // Get all withdrawals
  Future<List<Withdrawal>> getAllWithdrawals() async {
    try {
      print('Fetching all withdrawals from $baseUrl/api/withdrawals');
      final response = await http.get(
        Uri.parse('$baseUrl/api/withdrawals'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> withdrawalsList = data['withdrawals'];
        return withdrawalsList
            .map((json) => Withdrawal.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load withdrawals: ${response.body}');
      }
    } catch (e) {
      print('Error getting withdrawals: $e');
      throw Exception('Error getting withdrawals: $e');
    }
  }

  // Get pending withdrawals
  Future<List<Withdrawal>> getPendingWithdrawals() async {
    try {
      print(
          'Fetching pending withdrawals from $baseUrl/api/withdrawals/pending');
      final response = await http.get(
        Uri.parse('$baseUrl/api/withdrawals/pending'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> pendingWithdrawalsList = data['pendingWithdrawals'];
        return pendingWithdrawalsList
            .map((json) => Withdrawal.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load pending withdrawals: ${response.body}');
      }
    } catch (e) {
      print('Error getting pending withdrawals: $e');
      throw Exception('Error getting pending withdrawals: $e');
    }
  }

  // Get user withdrawals
  Future<List<Withdrawal>> getUserWithdrawals(int userId) async {
    try {
      final url = '$baseUrl/api/users/$userId/withdrawals';
      print('Fetching user withdrawals from $url');

      final response = await http.get(
        Uri.parse(url),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded data: $data');

        final List<dynamic> userWithdrawalsList = data['userWithdrawals'];
        print('User withdrawals list length: ${userWithdrawalsList.length}');

        final withdrawals = userWithdrawalsList
            .map((item) => Withdrawal.fromJson(item))
            .toList();
        print('Parsed ${withdrawals.length} withdrawals');

        return withdrawals;
      } else {
        throw Exception('Failed to load user withdrawals: ${response.body}');
      }
    } catch (e) {
      print('Error getting user withdrawals: $e');
      throw Exception('Error getting user withdrawals: $e');
    }
  }

  // Get withdrawal by ID
  Future<Withdrawal> getWithdrawalById(int withdrawalId) async {
    try {
      final url = '$baseUrl/api/withdrawals/$withdrawalId';
      print('Fetching withdrawal from $url');

      final response = await http.get(
        Uri.parse(url),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final withdrawalData = data['withdrawal'];
        return Withdrawal.fromJson(withdrawalData);
      } else {
        throw Exception('Failed to load withdrawal: ${response.body}');
      }
    } catch (e) {
      print('Error getting withdrawal: $e');
      throw Exception('Error getting withdrawal: $e');
    }
  }

  // Update withdrawal status
  Future<WithdrawalResponse> updateWithdrawalStatus(
      int withdrawalId, bool isPending) async {
    try {
      print(
          'Updating withdrawal status: id=$withdrawalId, isPending=$isPending');
      final response = await http.patch(
        Uri.parse('$baseUrl/api/withdrawals/$withdrawalId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isPending': isPending}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return WithdrawalResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update withdrawal status: ${response.body}');
      }
    } catch (e) {
      print('Error updating withdrawal status: $e');
      throw Exception('Error updating withdrawal status: $e');
    }
  }

  // Delete withdrawal (admin only)
  Future<WithdrawalResponse> deleteWithdrawal(int withdrawalId) async {
    try {
      print('Deleting withdrawal: id=$withdrawalId');
      final response = await http.delete(
        Uri.parse('$baseUrl/api/withdrawals/$withdrawalId'),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return WithdrawalResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to delete withdrawal: ${response.body}');
      }
    } catch (e) {
      print('Error deleting withdrawal: $e');
      throw Exception('Error deleting withdrawal: $e');
    }
  }
}
