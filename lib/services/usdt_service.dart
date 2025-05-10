import 'dart:convert';
import 'package:http/http.dart' as http;

class UsdtRate {
  final int? id;
  final double buyRate;
  final double sellRate;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? updatedByName;

  UsdtRate({
    this.id,
    required this.buyRate,
    required this.sellRate,
    this.isActive,
    this.createdAt,
    this.updatedAt,
    this.updatedByName,
  });

  factory UsdtRate.fromJson(Map<String, dynamic> json) {
    return UsdtRate(
      id: json['id'],
      buyRate: double.parse(json['buyRate'].toString()),
      sellRate: double.parse(json['sellRate'].toString()),
      isActive: json['isActive'],
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      updatedByName: json['updatedByName'],
    );
  }
}

class UsdtRateService {
  final String baseUrl;

  UsdtRateService({required this.baseUrl});

  // Get current USDT rate (public)
  Future<Map<String, dynamic>> getCurrentRate() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/api/usdt-rate'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> rateData = data['rate'];

        return {
          'success': true,
          'rate': UsdtRate(
            buyRate: double.parse(rateData['buyRate'].toString()),
            sellRate: double.parse(rateData['sellRate'].toString()),
            updatedAt: rateData['lastUpdated'] != null
                ? DateTime.parse(rateData['lastUpdated'])
                : null,
          ),
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'No active USDT rate found',
        };
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to load USDT rate',
        };
      }
    } catch (e) {
      print('Error getting USDT rate: $e');
      return {
        'success': false,
        'message': 'Error getting USDT rate: $e',
      };
    }
  }
}
