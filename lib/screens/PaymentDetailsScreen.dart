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

  const PaymentDetailsScreen({super.key, this.totalAmount});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  final DepositService _depositService = DepositService(
    // Update with your API base URL
    baseUrl: 'http://145.223.21.62:5021', //TODO: Update with your API base URL
  );

  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _userId =
      1; // Default user ID, you might want to get this from SharedPreferences

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    try {
      final uId = await UserApiService.getUserId();
      setState(() {
        _userId = uId ?? 0; // Default to 1 if not found
      });
    } catch (e) {
      print('Error loading user ID: $e');
      // Continue with default user ID
    }
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
    }
  }

  Future<void> _submitDeposit() async {
    // Validate image is selected
    if (_selectedImage == null) {
      setState(() {
        _errorMessage = 'Please select a deposit slip image';
      });
      return;
    }

    // Validate amount
    if (widget.totalAmount == null || widget.totalAmount! <= 0) {
      setState(() {
        _errorMessage = 'Invalid amount';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // Call deposit service to create deposit
      final response = await _depositService.createDeposit(
        userId: _userId,
        amount: widget.totalAmount!,
        imageFile: _selectedImage!,
      );

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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const DepositScreen())); // Go back to previous screen
              },
              child: const Text("OK", style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error submitting deposit: ${e.toString()}';
      });
      print('Error creating deposit: $e');
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

                  const SizedBox(height: 40),
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
