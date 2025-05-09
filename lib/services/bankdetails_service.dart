import 'dart:convert';
import 'package:http/http.dart' as http;

class BankDetails {
  final int id;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String branchName;
  final String? swiftCode;
  final String? description;
  final int isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdByName;

  BankDetails({
    required this.id,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.branchName,
    this.swiftCode,
    this.description,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
    this.createdByName,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      id: json['id'] ?? 0,
      bankName: json['bankName'] ?? '',
      accountHolderName: json['accountHolderName'] ?? '',
      accountNumber: json['accountNumber'] ?? '',
      branchName: json['branchName'] ?? '',
      swiftCode: json['swiftCode'],
      description: json['description'],
      isActive: json['isActive'] ?? 1,
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdByName: json['createdByName'],
    );
  }
}

class BankDetailsService {
  final String baseUrl;

  BankDetailsService({required this.baseUrl});

  // Get active bank details for deposits
  Future<Map<String, dynamic>> getActiveBankDetails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/bank-details'),
      );
      print('Response: ${response.body} @ ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final List<dynamic> bankDetailsList = data['bankDetails'];
        final List<BankDetails> bankDetails =
            bankDetailsList.map((item) => BankDetails.fromJson(item)).toList();

        return {
          'success': true,
          'bankDetails': bankDetails,
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to load bank details',
        };
      }
    } catch (e) {
      print('Error getting active bank details: $e');
      return {
        'success': false,
        'message': 'Error getting active bank details: $e',
      };
    }
  }

  // Get specific bank details by ID
  Future<Map<String, dynamic>> getBankDetailsById(int bankDetailsId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/bank-details/$bankDetailsId'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final BankDetails bankDetails =
            BankDetails.fromJson(data['bankDetails']);

        return {
          'success': true,
          'bankDetails': bankDetails,
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to load bank details',
        };
      }
    } catch (e) {
      print('Error getting bank details: $e');
      return {
        'success': false,
        'message': 'Error getting bank details: $e',
      };
    }
  }
}
