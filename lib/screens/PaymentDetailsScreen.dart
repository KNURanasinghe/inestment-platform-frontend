// ignore_for_file: unused_import

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/DepositScreen.dart';
import 'package:investment_plan_app/screens/home_screen.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/services/deposit_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/bankdetails_service.dart';

class PaymentDetailsScreen extends StatefulWidget {
  final double? totalAmount;
  final String? purpose;

  const PaymentDetailsScreen({super.key, this.totalAmount, this.purpose});

  @override
  State<PaymentDetailsScreen> createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen>
    with SingleTickerProviderStateMixin {
  final DepositService _depositService = DepositService(
    // Update with your API base URL
    baseUrl: 'http://151.106.125.212:5021',
  );

  final UserApiService _userApiService = UserApiService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  final BankDetailsService _bankDetailsService = BankDetailsService(
    baseUrl: 'http://151.106.125.212:5021',
  );

  late TabController _tabController;
  File? _selectedImage;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  int _userId = 0;
  bool _isPayed = false;

  BankDetails? firstBankDetail;
  String? bankQrCodeUrl;
  String? usdtQrCodeUrl;

  // Assume USDT wallet holder name comes from the same bank details
  String usdtHolderName = "T.E.C Dynamic Works (Pvt) Ltd";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _getBankDetails();
    _loadUserData();
    _getQrCodes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Add method to get QR codes from your database
  Future<void> _getQrCodes() async {
    try {
      // This is a placeholder. Replace with your actual API call
      // For example:
      // final qrResponse = await _bankDetailsService.getQrCodes();
      // if (qrResponse['success']) {
      //   setState(() {
      //     bankQrCodeUrl = qrResponse['bankQrUrl'];
      //     usdtQrCodeUrl = qrResponse['usdtQrUrl'];
      //   });
      // }

      // For now, let's assume these are the URLs (replace with your actual API endpoints)
      setState(() {
        bankQrCodeUrl = 'http://151.106.125.212:5021/api/qrcodes/bank_qr.png';
        usdtQrCodeUrl = 'http://151.106.125.212:5021/api/qrcodes/usdt_qr.png';
      });
    } catch (e) {
      print('Error getting QR codes: $e');
    }
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

  Future<void> _getBankDetails() async {
    try {
      final bankDetailsResponse =
          await _bankDetailsService.getActiveBankDetails();
      if (bankDetailsResponse['success']) {
        // Get the list of bank details
        final List<BankDetails> bankDetailsList =
            bankDetailsResponse['bankDetails'];

        // Check if the list is not empty
        if (bankDetailsList.isNotEmpty) {
          // Access the first bank detail
          setState(() {
            firstBankDetail = bankDetailsList[0];
          });
          print('Bank details loaded successfully. ID: ${firstBankDetail!.id}');

          // You can now access other properties of the first bank detail
          print('Bank Name: ${firstBankDetail!.bankName}');
          print('Account Holder: ${firstBankDetail!.accountHolderName}');

          // Or if you need to work with all bank details
          for (var bankDetail in bankDetailsList) {
            print('Bank ID: ${bankDetail.id}, Name: ${bankDetail.bankName}');
          }
        } else {
          print('No bank details found');
        }
      } else {
        // Handle error response
        print('Error loading bank details: ${bankDetailsResponse['message']}');
      }
    } catch (e) {
      print('Error loading bank details: $e');
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(
              icon: Icon(Icons.account_balance),
              text: "Bank Transfer",
            ),
            Tab(
              icon: Icon(Icons.currency_bitcoin),
              text: "USDT Transfer",
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          AppTheme.appBackground(),
          firstBankDetail == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Bank Transfer Tab
                    _buildBankTransferTab(width),

                    // USDT Transfer Tab
                    _buildUsdtTransferTab(width),
                  ],
                ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 1),
    );
  }

  Widget _buildBankTransferTab(double width) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bank Details Container
            Container(
              width: width,
              decoration: AppTheme.boxDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Bank Name", firstBankDetail!.bankName),
                  _buildDetailRow("Account Holder Name",
                      firstBankDetail!.accountHolderName),
                  _buildDetailRow(
                      "Account Number", firstBankDetail!.accountNumber),
                  _buildDetailRow("Branch Name", firstBankDetail!.branchName),
                  _buildDetailRow(
                      "Swift Code", firstBankDetail!.swiftCode ?? "N/A"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QR Code Container for Bank
            Container(
              width: width,
              decoration: AppTheme.boxDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Scan QR Code for Bank Transfer",
                      style: AppTheme.textStyleBold,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: bankQrCodeUrl != null
                          ? Image.network(
                              bankQrCodeUrl!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.error,
                                        color: Colors.red, size: 50),
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.white,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text("QR Code not available"),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Scan to get bank details for transfer",
                    style: AppTheme.textStyleSmall.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Rest of your Bank Transfer tab content
            _buildCommonPaymentDetails(width),
          ],
        ),
      ),
    );
  }

  Widget _buildUsdtTransferTab(double width) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // USDT Details Container
            Container(
              width: width,
              decoration: AppTheme.boxDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow("Account Holder Name", usdtHolderName),
                  _buildDetailRow("USDT Network", "TRC20 (Tron)"),
                  // You might want to add the wallet address if available
                ],
              ),
            ),

            const SizedBox(height: 20),

            // QR Code Container for USDT
            Container(
              width: width,
              decoration: AppTheme.boxDecoration(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text("Scan QR Code for USDT Transfer",
                      style: AppTheme.textStyleBold,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: usdtQrCodeUrl != null
                          ? Image.network(
                              usdtQrCodeUrl!,
                              width: 200,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(Icons.error,
                                        color: Colors.red, size: 50),
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.white,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: 200,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Text("QR Code not available"),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Scan to send USDT to our wallet",
                    style: AppTheme.textStyleSmall.copyWith(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.orange[300], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Important: Only send USDT through TRC20 network to avoid loss of funds",
                            style: TextStyle(
                                color: Colors.orange[100], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Rest of your USDT Transfer tab content
            _buildCommonPaymentDetails(width),
          ],
        ),
      ),
    );
  }

  // Common payment details section to be used in both tabs
  Widget _buildCommonPaymentDetails(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: Text("LKR ${widget.totalAmount?.toStringAsFixed(2) ?? '0.00'}",
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
                color: const Color.fromARGB(255, 172, 21, 177).withOpacity(0.5),
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
                      style: TextStyle(color: Colors.white, fontSize: 18),
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
                backgroundColor: WidgetStateProperty.all(AppTheme.primaryColor),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.textStyleBold),
          Text(value, style: AppTheme.textStyleRegular),
        ],
      ),
    );
  }
}
