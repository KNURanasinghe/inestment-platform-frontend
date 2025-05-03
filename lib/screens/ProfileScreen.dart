// ignore_for_file: unused_import, unused_element

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/LoginScreen.dart';
import 'package:investment_plan_app/screens/kyc_verification_dialog.dart';
import 'package:investment_plan_app/screens/pin_entry_page.dart';
import 'package:investment_plan_app/services/kyc_service.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/DepositFundScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

import '../services/user_service.dart';

class AccountPage extends StatefulWidget {
  final String? username;
  const AccountPage({super.key, required this.username});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final KycService _apiService = KycService();

  // KYC status variables
  bool isLoading = true;
  String kycStatus = "pending"; // Options: pending, submitted, verified
  bool isKycVerified = false;
  String refcode = '';
  int userid = 0;
  @override
  void initState() {
    super.initState();
    fetchKYCStatus();
  }

  Future<void> fetchKYCStatus() async {
    final refKey = await UserApiService.getUserRef();
    setState(() {
      isLoading = true;
      refcode = refKey ?? '';
    });

    try {
      // Get user ID from shared preferences

      final userId = await UserApiService.getUserId();

      if (userId != null) {
        final response = await _apiService.getKYCStatus(userId);

        if (response['success']) {
          final data = jsonDecode(response['data']);
          setState(() {
            kycStatus = data['status'];
            isKycVerified = data['isVerified'] ?? false;
            userid = userId;
          });
        }
      }
    } catch (e) {
      print("Error fetching KYC status: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showVerificationDialog(BuildContext context) async {
    // Get user ID from shared preferences

    final userId = await UserApiService.getUserId();

    if (userId == null) {
      _showCustomSnackBar(
          context, "User not authenticated. Please log in again.", false);
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => KYCVerificationDialog(
        userId: userId,
        onVerificationSubmitted: () {
          setState(() {
            kycStatus = "submitted";
          });
          _showCustomSnackBar(
              context, "KYC verification submitted successfully", true);
          fetchKYCStatus(); // Refresh status
        },
      ),
    );
  }

  // Custom SnackBar method
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          AppTheme.appBackground(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView(
              children: [
                _buildProfileSection(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0x1AD9D9D9), // #D9D9D9 with 10% opacity
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Security Settings",
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PinEntryPage(
                                mode: 'setPin',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                                0x1AD9D9D9), // #D9D9D9 with 10% opacity
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock, color: Colors.white),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Set Withdrawal Password",
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PinEntryPage(
                                mode: 'changePassword',
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(
                                0x1AD9D9D9), // #D9D9D9 with 10% opacity
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.security, color: Colors.white),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Change Login Password",
                                      style: TextStyle(color: Colors.white)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildKYOTile(context),
                const SizedBox(height: 20),
                _buildPaymentTile(context),
                const SizedBox(height: 20),
                _buildReferralTile(context),
                const SizedBox(height: 20),
                _buildLogoutButton(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 4),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage("https://via.placeholder.com/150"),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    widget.username ?? "Alexander Mitchell",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  if (isKycVerified)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 1),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 14,
                            ),
                            SizedBox(width: 2),
                            Text(
                              "Verified",
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Text("ID: $userid", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
      onTap: () {},
    );
  }

  Widget _buildKYOTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AD9D9D9), // #D9D9D9 with 10% opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("KYC Verification", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1AD9D9D9), // #D9D9D9 with 10% opacity
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Verification Status",
                        style: TextStyle(color: Colors.white)),
                    if (isLoading)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      )
                    else
                      Row(
                        children: [
                          if (isKycVerified)
                            const Icon(
                              Icons.verified,
                              color: Colors.green,
                              size: 16,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            isKycVerified
                                ? "Verified"
                                : kycStatus == "submitted"
                                    ? "Under Review"
                                    : "Pending",
                            style: TextStyle(
                              color: isKycVerified
                                  ? Colors.green
                                  : kycStatus == "submitted"
                                      ? Colors.amber
                                      : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: isKycVerified
                      ? 1.0
                      : kycStatus == "submitted"
                          ? 0.7
                          : 0.3,
                  backgroundColor: Colors.grey,
                  color: isKycVerified
                      ? Colors.green
                      : kycStatus == "submitted"
                          ? Colors.amber
                          : Colors.blue,
                ),
                const SizedBox(height: 12),
                if (!isKycVerified)
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Colors.blue, // Left color
                            Colors.purple, // Right color
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: kycStatus == "submitted"
                            ? null
                            : () => _showVerificationDialog(context),
                        child: Text(
                          kycStatus == "submitted"
                              ? "Verification Pending"
                              : "Complete Verification",
                          style: const TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AD9D9D9), // #D9D9D9 with 10% opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Payment Methods", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              _showCustomSnackBar(context, "Managing payment methods", true);
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x1AD9D9D9), // #D9D9D9 with 10% opacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.account_balance, color: Colors.white),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bank Account",
                          style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralTile(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AD9D9D9), // #D9D9D9 with 10% opacity
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Referral Program", style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1AD9D9D9), // #D9D9D9 with 10% opacity
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Your Referral Code",
                    style: TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                              0x1AD9D9D9), // #D9D9D9 with 10% opacity
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          refcode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: refcode));
                        _showCustomSnackBar(context,
                            "Referral code copied to clipboard!", true);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                              0x1AD9D9D9), // #D9D9D9 with 10% opacity
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.copy, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Colors.blue, // Left color
              Colors.purple, // Right color
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () {
            _showCustomSnackBar(context, "Logging out...", true);

            Future.delayed(const Duration(milliseconds: 1000), () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove("userId");

              if (context.mounted) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()));
              }
            });
          },
          child: const Text(
            "Log Out",
            style: TextStyle(
                color: Color.fromARGB(255, 250, 250,
                    250)), // Change text color to white for contrast
          ),
        ),
      ),
    );
  }
}
