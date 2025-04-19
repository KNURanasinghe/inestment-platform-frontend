import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class Deposit {
  final int? id;
  final String transactionId;
  final int userId;
  final double amount;
  final String? imagePath;
  final bool isPending;
  final DateTime createdAt;
  final String? username;
  final String purpose; // New field for purpose

  Deposit({
    this.id,
    required this.transactionId,
    required this.userId,
    required this.amount,
    this.imagePath,
    required this.isPending,
    required this.createdAt,
    this.username,
    this.purpose = 'investment', // Default to investment
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: json['id'],
      transactionId: json['transaction_id'] ?? '',
      userId: json['user_id'] ?? 0,
      amount: _parseAmount(json['amount']),
      imagePath: json['image_path'],
      isPending: json['is_pending'] == 1 || json['is_pending'] == true,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      username: json['username'],
      // Make sure to handle the purpose field properly
      purpose: json['purpose'] != null
          ? json['purpose'].toString().toLowerCase()
          : 'investment',
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
      'image_path': imagePath,
      'is_pending': isPending,
      'created_at': createdAt.toIso8601String(),
      'username': username,
      'purpose': purpose,
    };
  }
}

class DepositResponse {
  final String message;
  final int? depositId;
  final String? transactionId;
  final String? purpose;

  DepositResponse({
    required this.message,
    this.depositId,
    this.transactionId,
    this.purpose,
  });

  factory DepositResponse.fromJson(Map<String, dynamic> json) {
    return DepositResponse(
      message: json['message'] ?? 'Operation completed',
      depositId: json['depositId'],
      transactionId: json['transactionId'],
      purpose: json['purpose'],
    );
  }
}

class DepositService {
  final String baseUrl;

  DepositService({required this.baseUrl});

  // Create a new deposit with purpose
  Future<DepositResponse> createDeposit({
    required int userId,
    required double amount,
    required File imageFile,
    String purpose = 'investment', // Default to investment
  }) async {
    try {
      print(
          'Creating deposit: userId=$userId, amount=$amount, purpose=$purpose');
      final uri = Uri.parse('$baseUrl/api/deposits');

      var request = http.MultipartRequest('POST', uri);

      // Add text fields
      request.fields['userId'] = userId.toString();
      request.fields['amount'] = amount.toString();
      request.fields['purpose'] = purpose;

      // Add file
      String fileName = imageFile.path.split('/').last;
      String fileExtension = fileName.split('.').last.toLowerCase();

      // Determine content type based on file extension
      String contentType;
      if (['jpg', 'jpeg'].contains(fileExtension)) {
        contentType = 'image/jpeg';
      } else if (fileExtension == 'png') {
        contentType = 'image/png';
      } else if (fileExtension == 'pdf') {
        contentType = 'application/pdf';
      } else {
        throw Exception('Unsupported file type: $fileExtension');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      print('Sending deposit request...');
      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (response.statusCode == 201) {
        return DepositResponse.fromJson(json.decode(responseBody));
      } else {
        throw Exception('Failed to create deposit: $responseBody');
      }
    } catch (e) {
      print('Error creating deposit: $e');
      throw Exception('Error creating deposit: $e');
    }
  }

  // Get user deposits with purpose filtering
  Future<List<Deposit>> getUserDeposits(int userId, {String? purpose}) async {
    try {
      final url = '$baseUrl/api/users/$userId/deposits';
      print('Fetching user deposits from $url');

      final response = await http.get(
        Uri.parse(url),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        print('Decoded data: $data');

        final List<dynamic> userDepositsList = data['userDeposits'];
        print('User deposits list length: ${userDepositsList.length}');

        final deposits = userDepositsList
            .map((item) => Deposit.fromJson(item))
            .where((deposit) => purpose == null || deposit.purpose == purpose)
            .toList();

        print('Parsed ${deposits.length} deposits');

        return deposits;
      } else {
        throw Exception('Failed to load user deposits: ${response.body}');
      }
    } catch (e) {
      print('Error getting user deposits: $e');
      throw Exception('Error getting user deposits: $e');
    }
  }

  // Update deposit status
  Future<DepositResponse> updateDepositStatus(
      int depositId, bool isPending) async {
    try {
      print('Updating deposit status: id=$depositId, isPending=$isPending');
      final response = await http.patch(
        Uri.parse('$baseUrl/api/deposits/$depositId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isPending': isPending}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return DepositResponse.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update deposit status: ${response.body}');
      }
    } catch (e) {
      print('Error updating deposit status: $e');
      throw Exception('Error updating deposit status: $e');
    }
  }
}
