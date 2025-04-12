import 'dart:io';
import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/DepositScreen.dart';
import 'package:investment_plan_app/screens/home_screen.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/services/deposit_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final double? totalAmount;
  final String? purpose;

  const PaymentDetailsScreen({super.key, this.totalAmount, this.purpose});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final DepositService _depositService = DepositService(
    // Update with your API base URL
    baseUrl: 'http://145.223.21.62:5021',
  );

  final UserApiService _userApiService = UserApiService(
    baseUrl: 'http://145.223.21.62:5021',
  );

  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _userId = 0;
  bool _isPayed = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final uId = await UserApiService.getUserId();

      if (uId != null && uId > 0) {
        setState(() {
          _userId = uId;
        });

        // Fetch user profile to get payment status
        final userProfileResponse =
            await _userApiService.getUserProfile(_userId);
        if (userProfileResponse['success']) {
          setState(() {
            _isPayed = userProfileResponse['userData']['is_payed'] ?? false;
          });
          print('User payment status loaded: $_isPayed');
        }
      } else {
        print('Invalid user ID: $uId');
        _showCustomSnackBar(context, 'Error loading user data', false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      _showCustomSnackBar(
          context, 'Error loading user data: ${e.toString()}', false);
    }
  }

  void _showCustomSnackBar(
      BuildContext context, String message, bool isSuccess) {
    // Get the ScaffoldMessengerState
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Clear any existing SnackBars
    scaffoldMessenger.clearSnackBars();

    // Show the SnackBar with the gradient wrapper
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isSuccess
                  ? [
                      const Color(0xFF4776E6),
                      const Color(0xFF8E54E9)
                    ] // Success gradient - blue to purple
                  : [
                      const Color(0xFFFF416C),
                      const Color(0xFFFF4B2B)
                    ], // Error gradient - red to orange
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                blurRadius: 8,
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(15),
        duration: const Duration(seconds: 3),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: ${e.toString()}';
      });
      print('Error picking image: $e');
      _showCustomSnackBar(context, 'Error selecting image', false);
    }
  }

  Future<void> _updatePaymentStatus() async {
    try {
      // Check if this is the first coin deposit and user is not yet paid
      if (widget.purpose == 'buy_coin' && !_isPayed) {
        print('Updating user payment status to paid');

        // Call API to update payment status
        final updateResponse =
            await _userApiService.updatePaymentStatus(_userId, true);

        if (updateResponse['success']) {
          print('Payment status updated successfully');
          setState(() {
            _isPayed = true;
          });

          // Update the shared preferences or other local storage if needed
          final prefs = await SharedPreferences.getInstance();
          // You might want to store this in shared preferences if you use it elsewhere
          await prefs.setBool('is_payed', true);

          return;
        } else {
          print(
              'Failed to update payment status: ${updateResponse['message']}');
          throw Exception(
              'Failed to update payment status: ${updateResponse['message']}');
        }
      }
    } catch (e) {
      print('Error updating payment status: $e');
      rethrow; // Rethrow to be caught by the calling function
    }
  }

  Future<void> _submitDeposit() async {
    // Validate image is selected
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select a deposit slip image';
      });
      _showCustomSnackBar(context, 'Please select a deposit slip image', false);
      return;
    }

    // Validate amount
    if (widget.totalAmount == null || widget.totalAmount! <= 0) {
      setState(() {
        _errorMessage = 'Invalid amount';
      });
      _showCustomSnackBar(context, 'Invalid amount', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      print('purpose: ${widget.purpose}');

      // Call deposit service to create deposit
      final response = await _depositService.createDeposit(
        userId: _userId,
        amount: widget.totalAmount!,
        imageFile: _selectedImage!,
        purpose: widget.purpose!,
      );

      // If this is a coin deposit and user hasn't paid yet, update payment status
      if (widget.purpose == 'buy_coin' && !_isPayed) {
        await _updatePaymentStatus();
        print('Payment status updated to paid');
      }

      setState(() {
        _isLoading = false;
        _successMessage =
            'Deposit successfully submitted! Transaction ID: ${response.transactionId}';
      });

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.backgroundColor,
          title: const Text("Payment Successful",
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your payment has been successfully processed.",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Text(
                "Transaction ID: ${response.transactionId}",
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Your deposit is in pending status.",
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              if (widget.purpose == 'buy_coin' && !_isPayed) ...[
                const SizedBox(height: 12),
                const Text(
                  "Your account has been upgraded to access investment features.",
                  style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const DepositScreen())); // Go back to deposit screen
              },
              child: const Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        print('error ${e.toString()}');
        _isLoading = false;
        _errorMessage = 'Error submitting deposit: ${e.toString()}';
      });
      print('Error creating deposit: $e');
      _showCustomSnackBar(context, 'Error submitting deposit', false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Payment Details", style: AppTheme.textStyleLarge),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/user.png'),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          AppTheme.appBackground(),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: width,
                    decoration: AppTheme.boxDecoration(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDetailRow("Bank Name", "Your Bank"),
                        _buildDetailRow("Account Holder Name", "John Doe"),
                        _buildDetailRow("Account Number", "123456789"),
                        _buildDetailRow("Routing Number", "987654"),
                        _buildDetailRow("Swift Code", "SWIFT123"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Display payment purpose
                  if (widget.purpose != null) ...[
                    Text("Payment Purpose", style: AppTheme.textStyleBold),
                    Container(
                      width: width,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      decoration: AppTheme.boxDecoration(),
                      child: Text(
                        widget.purpose == 'buy_coin'
                            ? "Buy Coins"
                            : widget.purpose == 'investment'
                                ? "Investment Deposit"
                                : widget.purpose ?? "",
                        style: AppTheme.textStyleRegular,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  Text("Total Payment Amount", style: AppTheme.textStyleBold),
                  Container(
                    width: width,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: AppTheme.boxDecoration(),
                    child: Text(
                        "LKR ${widget.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
                        style: AppTheme.textStyleLarge),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Upload Deposit Slip",
                    style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14),
                  ),
                  const SizedBox(height: 10),

                  // Image picker container
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      width: width,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color.fromARGB(255, 172, 21, 177)
                              .withOpacity(0.5),
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_upload,
                                      color: Colors.white, size: 40),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Click to upload deposit slip",
                                    style: AppTheme.textStyleRegular,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Supported: JPG, PNG, PDF",
                                    style: AppTheme.textStyleSmall.copyWith(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ),

                  // Error message
                  if (_errorMessage != null)
                    Container(
                      width: width,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Success message
                  if (_successMessage != null)
                    Container(
                      width: width,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // First time coin payment note
                  if (widget.purpose == 'buy_coin' && !_isPayed)
                    Container(
                      width: width,
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4776E6).withOpacity(0.2),
                            const Color(0xFF8E54E9).withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF8E54E9).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[300],
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "This is your first coin purchase. Upon successful payment, you'll gain access to investment features.",
                              style: TextStyle(
                                color: Colors.blue[100],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),

                  // Upload button
                  Center(
                    child: Container(
                      width: width,
                      decoration: AppTheme.buttonDecoration(),
                      child: ElevatedButton(
                        style: AppTheme.buttonStyle(),
                        onPressed: _isLoading ? null : _submitDeposit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Upload Slip",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Cancel button
                  Center(
                    child: Container(
                      width: width,
                      decoration: AppTheme.buttonDecoration(),
                      child: ElevatedButton(
                        style: AppTheme.buttonStyle().copyWith(
                          backgroundColor:
                              WidgetStateProperty.all(AppTheme.primaryColor),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 1),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTheme.textStyleBold),
          Text(value, style: AppTheme.textStyleRegular),
        ],
      ),
    );
  }
}

// Add this method to your UserApiService class
/*
Future<Map<String, dynamic>> updatePaymentStatus(int userId, bool isPayed) async {
  try {
    final response = await http.patch(
      Uri.parse('$baseUrl/api/users/$userId/payment-status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'is_payed': isPayed,
      }),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'] ?? 'Payment status updated successfully',
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to update payment status',
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
*/
