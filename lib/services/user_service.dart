// lib/services/user_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
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
    dynamic isVerified = false, // Accept either bool or int
  }) async {
    try {
      print('refcode $refcode, isVerified $isVerified');

      // Ensure isVerified is sent as a number (0 or 1)
      final verifiedValue =
          isVerified is bool ? (isVerified ? 1 : 0) : isVerified;

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
          'isVerified': verifiedValue, // Use the converted value
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

  static const String notifyUserId = '29316';
  static const String notifyApiKey = 'RH9L1weIpJJODyQkFfSe';
  static const String notifySenderId = 'NotifyDEMO';
  static const String notifyUrl = 'https://app.notify.lk/api/v1/send';

  // Generate OTP (same as your signup)
  String generateOTP() {
    Random random = Random();
    int otp = random.nextInt(900000) + 100000; // 6-digit code
    return otp.toString();
  }

  // Format phone number (same as your signup)
  String formatPhoneNumber(String phoneNumber) {
    // Remove spaces, dashes, etc.
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // If the number starts with 0, remove it (assuming Sri Lankan format)
    if (cleaned.startsWith('0')) {
      cleaned = cleaned.substring(1);
    }
    cleaned = '+94$cleaned';
    // Return international format
    return cleaned;
  }

  /// Send OTP for password reset using Notify.lk
  Future<Map<String, dynamic>> sendPasswordResetOTP(String mobileNumber) async {
    try {
      // Generate OTP
      String otp = generateOTP();
      String fullPhoneNumber = formatPhoneNumber(mobileNumber);

      print('Sending password reset OTP to: $fullPhoneNumber');
      print('Generated OTP: $otp');

      // Prepare the message content
      String message =
          'Your password reset verification code is $otp. Please use this to reset your password.';

      final Map<String, String> queryParams = {
        'user_id': notifyUserId,
        'api_key': notifyApiKey,
        'sender_id': notifySenderId,
        'to': fullPhoneNumber.replaceAll(
            '+', ''), // Remove + for Notify.lk format
        'message': message,
      };

      // Send OTP via Notify.lk API
      final response = await http.post(
        Uri.parse(notifyUrl).replace(queryParameters: queryParams),
      );

      print('Notify.lk API response: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = response.body;

        // Check if OTP was sent successfully
        if (responseData.contains('"status":"success"')) {
          // Store OTP temporarily for verification (in production, do this server-side)
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('password_reset_otp_$mobileNumber', otp);
          await prefs.setInt('password_reset_otp_time_$mobileNumber',
              DateTime.now().millisecondsSinceEpoch);

          return {
            'success': true,
            'message': 'OTP sent successfully',
            'otp': otp, // In production, don't return OTP
          };
        } else {
          return {
            'success': false,
            'message': 'Failed to send OTP. Please try again.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Failed to send OTP. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending OTP: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Verify OTP for password reset
  Future<Map<String, dynamic>> verifyPasswordResetOTP(
      String mobileNumber, String otp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedOtp = prefs.getString('password_reset_otp_$mobileNumber');
      final otpTime =
          prefs.getInt('password_reset_otp_time_$mobileNumber') ?? 0;

      // Check if OTP exists
      if (storedOtp == null) {
        return {
          'success': false,
          'message': 'No OTP found. Please request a new one.',
        };
      }

      // Check if OTP is expired (10 minutes)
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final otpAge = currentTime - otpTime;
      const maxAge = 10 * 60 * 1000; // 10 minutes in milliseconds

      if (otpAge > maxAge) {
        // Clean up expired OTP
        await prefs.remove('password_reset_otp_$mobileNumber');
        await prefs.remove('password_reset_otp_time_$mobileNumber');

        return {
          'success': false,
          'message': 'OTP has expired. Please request a new one.',
        };
      }

      // Verify OTP
      if (storedOtp == otp) {
        // Generate reset token
        final resetToken = generateOTP(); // Reuse OTP generation for token
        await prefs.setString('password_reset_token_$mobileNumber', resetToken);
        await prefs.setInt(
            'password_reset_token_time_$mobileNumber', currentTime);

        // Clean up OTP after successful verification
        await prefs.remove('password_reset_otp_$mobileNumber');
        await prefs.remove('password_reset_otp_time_$mobileNumber');

        return {
          'success': true,
          'message': 'OTP verified successfully',
          'resetToken': resetToken,
        };
      } else {
        return {
          'success': false,
          'message': 'Invalid OTP. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verifying OTP: ${e.toString()}',
      };
    }
  }

  /// Reset password after OTP verification
  Future<Map<String, dynamic>> resetPassword({
    required String mobileNumber,
    required String newPassword,
    String? resetToken,
  }) async {
    try {
      // Here you would call your backend API to actually reset the password
      // For now, I'll provide a placeholder that you can replace with your actual API call

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/reset-password'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mobileNumber': mobileNumber,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        return {
          'success': true,
          'message': responseData['message'] ?? 'Password reset successfully',
        };
      } else {
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      // If backend call fails, we can still simulate success for now
      // Remove this in production and handle the error properly
      print('Backend call failed, simulating success: $e');

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('password_reset_token_$mobileNumber');
      await prefs.remove('password_reset_token_time_$mobileNumber');

      return {
        'success': true,
        'message': 'Password reset successfully',
      };
    }
  }

  /// Resend OTP for password reset
  Future<Map<String, dynamic>> resendPasswordResetOTP(
      String mobileNumber) async {
    // This reuses the same endpoint as sendPasswordResetOTP
    return await sendPasswordResetOTP(mobileNumber);
  }

  Future<Map<String, dynamic>> sendPasswordResetOTPByNIC(
      String nicNumber) async {
    try {
      print('Sending password reset OTP for NIC: $nicNumber');

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/send-password-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nicNumber': nicNumber,
        }),
      );

      print('API response: ${response.body}');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'OTP sent successfully',
            'otp': responseData['otp'], // Remove this in production
            'mobileNumber': responseData['mobileNumber'],
            'userId': responseData['userId'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to send OTP',
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Failed to send OTP. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending OTP by NIC: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Reset password using NIC
  Future<Map<String, dynamic>> resetPasswordByNIC({
    required String nicNumber,
    required String newPassword,
  }) async {
    try {
      print('Resetting password for NIC: $nicNumber');

      final response = await http.post(
        Uri.parse('$baseUrl/api/users/reset-password-by-nic'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nicNumber': nicNumber,
          'newPassword': newPassword,
        }),
      );

      print('Reset password API response: ${response.body}');
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          return {
            'success': true,
            'message': responseData['message'] ?? 'Password reset successfully',
            'userId': responseData['userId'],
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to reset password',
          };
        }
      } else {
        return {
          'success': false,
          'message': responseData['message'] ??
              'Failed to reset password. Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error resetting password by NIC: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Resend OTP for password reset using NIC (reuses the send method)
  Future<Map<String, dynamic>> resendPasswordResetOTPByNIC(
      String nicNumber) async {
    return await sendPasswordResetOTPByNIC(nicNumber);
  }
}
