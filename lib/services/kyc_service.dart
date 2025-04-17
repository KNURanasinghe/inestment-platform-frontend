// Add these methods to your ApiService class

// In api_service.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class KycService {
  // Your existing code and API base URL
  final String baseUrl = 'http://145.223.21.62:5021/api';

  // Submit KYC verification
  Future<Map<String, dynamic>> submitKYCVerification(int userId,
      String verificationType, File frontImage, File? backImage) async {
    try {
      var request = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/users/$userId/kyc-verification'));

      // Add verification type
      request.fields['verificationType'] = verificationType;

      // Add front image
      var frontStream = http.ByteStream(frontImage.openRead());
      var frontLength = await frontImage.length();
      var frontMultipartFile = http.MultipartFile(
        'frontImage',
        frontStream,
        frontLength,
        filename: 'front_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(frontMultipartFile);

      // Add back image if provided (for NIC)
      if (backImage != null) {
        var backStream = http.ByteStream(backImage.openRead());
        var backLength = await backImage.length();
        var backMultipartFile = http.MultipartFile(
          'backImage',
          backStream,
          backLength,
          filename: 'back_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(backMultipartFile);
      }

      // Send the request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message':
              'Failed to submit KYC verification: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error submitting KYC verification: $e',
      };
    }
  }

  // Get KYC verification status
  Future<Map<String, dynamic>> getKYCStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/kyc-status'),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.body,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to get KYC status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error getting KYC status: $e',
      };
    }
  }
}
