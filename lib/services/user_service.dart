// lib/services/user_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class UserApiService {
  // Base URL of your backend API
  final String baseUrl;

  UserApiService({required this.baseUrl});
  static const String USER_ID_KEY = 'user_id';
  static const String USER_REF_KEY = 'ref_code';
  static const String USER_DATA_KEY = 'user_data';
  static const String IS_LOGGED_IN_KEY = 'is_logged_in';

  static Future<bool> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(USER_ID_KEY, userId);
  }

  static Future<bool> saveUserRef(String refcode) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(USER_REF_KEY, refcode);
  }

  // Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(USER_ID_KEY);
  }

  static Future<String?> getUserRef() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(USER_REF_KEY);
  }

  // Register a new user
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String email,
    required String nicNumber,
    required String username,
    required String password,
    required String phoneNumber,
    required String deviceId,
    String? address,
    String? country,
    String? refcode,
  }) async {
    try {
      print('refcode $refcode');
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'nic_number': nicNumber,
          'username': username,
          'password': password,
          'phone_number': phoneNumber,
          'device_id': deviceId,
          'address': address,
          'country': country,
          'referrerCode': refcode,
        }),
      );

      final responseData = jsonDecode(response.body);
      print('Response data: $responseData');
      if (response.statusCode == 201) {
        print('Registration successful: ${responseData['refCode']}');
        // Save user ID to shared preferences
        await saveUserId(responseData['userId']);
        await saveUserRef(responseData['refCode']);
        return {
          'success': true,
          'message': responseData['message'],
          'userId': responseData['userId'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Registration failed',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('Network error during registration: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Login user
  // Update the loginUser method in user_service.dart
  Future<Map<String, dynamic>> loginUser({
    required String nicNumber,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nic_number': nicNumber,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);
      print('Response data : $responseData');
      if (response.statusCode == 200) {
        // Save user ID to shared preferences
        final userData = responseData['userData'];
        await saveUserId(responseData['userId']);
        await saveUserRef(userData['ref_code']);
        // Set logged in status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(IS_LOGGED_IN_KEY, true);

        // Optionally save user data
        if (responseData['userData'] != null) {
          await prefs.setString(
              USER_DATA_KEY, jsonEncode(responseData['userData']));
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Login successful',
          'userId': responseData['userId'],
          'userData': responseData['userData'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user profile
  Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);
      print('Response data: $responseData');
      print('Response pin code: ${responseData['pin']}');
      if (response.statusCode == 200) {
        return {
          'success': true,
          'userData': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get user data',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile(
    int userId, {
    String? name,
    String? email,
    String? address,
    String? country,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};

      if (name != null) updateData['name'] = name;
      if (email != null) updateData['email'] = email;
      if (address != null) updateData['address'] = address;
      if (country != null) updateData['country'] = country;

      final response = await http.put(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Profile updated successfully',
          'userData': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Add this method to your UserApiService class
  Future<Map<String, dynamic>> updatePaymentStatus(
      int userId, bool isPayed) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/users/$userId/payment-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'isPayed': isPayed,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Payment status updated successfully',
        };
      } else {
        return {
          'success': false,
          'message':
              responseData['message'] ?? 'Failed to update payment status',
        };
      }
    } catch (e) {
      print('Network error updating payment status: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user deposits
  Future<Map<String, dynamic>> getUserDeposits(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/deposits'),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'deposits': responseData['userDeposits'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get deposits',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get user withdrawals
  Future<Map<String, dynamic>> getUserWithdrawals(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/withdrawals'),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'withdrawals': responseData['userWithdrawals'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to get withdrawals',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserPin(int userId, String pin) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/users/$userId/pin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pin': pin,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'PIN updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update PIN',
          'errors': responseData['errors'],
        };
      }
    } catch (e) {
      print('Network error updating PIN: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

// Update user password
  Future<Map<String, dynamic>> updateUserPassword(
      int userId, String currentPassword, String newPassword) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/users/$userId/password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password updated successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to update password',
        };
      }
    } catch (e) {
      print('Network error updating password: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  // Reset user password (admin or forgot password functionality)
  Future<Map<String, dynamic>> resetUserPassword(
      int userId, String newPassword) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/api/users/$userId/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'newPassword': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      print('Network error resetting password: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
  // user_service.dart - Add these methods to your existing UserApiService class

  // Upload profile image
  Future<Map<String, dynamic>> uploadPaymentImage(int userId, File file) async {
    try {
      // Create a multipart request
      final url = Uri.parse('$baseUrl/api/users/$userId/profile-image');
      final request = http.MultipartRequest('POST', url);
      print('Uploading file: ${file.path}');
      print('request $request');
      // Get file extension
      final fileExtension = path.extension(file.path).toLowerCase();
      String contentType;

      switch (fileExtension) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.pdf':
          contentType = 'application/pdf';
          break;
        default:
          throw Exception(
              'Unsupported file type. Please upload JPG, PNG, or PDF files only.');
      }

      // Add file to request
      final multipartFile = await http.MultipartFile.fromPath(
        'image', // Changed from 'image' to 'file' to be more generic
        file.path,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Response data: $data');
        return {
          'success': true,
          'message': data['message'] ?? 'Payment proof uploaded successfully',
          'fileUrl': data['fileUrl'] // If the API returns the uploaded file URL
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to upload file: ${response.body}',
        };
      }
    } catch (e) {
      print('Error uploading payment proof: ${e.toString()}');
      Fluttertoast.showToast(
        msg: 'Error uploading payment proof: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Get user payment status
  Future<bool> getPaymentStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/payment-status'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['isPayed'] ?? false;
      } else {
        throw Exception('Failed to get payment status: ${response.body}');
      }
    } catch (e) {
      print('Error getting payment status: ${e.toString()}');
      return false;
    }
  }

  // Add this to your UserApiService class in user_service.dart
  Future<Map<String, dynamic>> uploadProfileImage(
      int userId, File imageFile) async {
    try {
      // Create a multipart request
      final url = Uri.parse('$baseUrl/api/users/$userId/profile-image');
      final request = http.MultipartRequest('POST', url);

      // Get file extension
      final fileExtension = path.extension(imageFile.path).toLowerCase();
      String contentType;

      switch (fileExtension) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        default:
          contentType = 'image/jpeg'; // Default to jpeg
      }

      // Add file to request
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      // Get the response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Profile image uploaded successfully',
          'imagePath': data['imagePath']
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to upload image: ${response.body}',
        };
      }
    } catch (e) {
      print('Error uploading profile image: ${e.toString()}');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

// Add this method to get the profile image URL
  Future<String?> getProfileImageUrl(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId/profile'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('profile response $data');
        return data['user']['profileImageUrl'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching profile image: ${e.toString()}');
      return null;
    }
  }
}
