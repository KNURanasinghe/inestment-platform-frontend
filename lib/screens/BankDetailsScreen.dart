import 'package:flutter/material.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'package:investment_plan_app/screens/DepositFundScreen.dart';
import 'package:investment_plan_app/screens/PaymentDetailsScreen.dart';

class BankDetailsScreen extends StatefulWidget {
  const BankDetailsScreen({super.key});

  @override
  _BankDetailsScreenState createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _holderNameController = TextEditingController();
  final TextEditingController _branchCodeController = TextEditingController();
  final TextEditingController _depositAmountController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Bank Account Details", style: AppTheme.textStyleLarge),
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
          SizedBox(
            width: width,
            height: height,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bank Name',
                      style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14),
                    ),
                    _buildTextField("Enter bank name", _bankNameController),
                    const Text(
                      'Account Number',
                      style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14),
                    ),
                    _buildTextField(
                        "Enter account number", _accountNumberController),
                    const Text(
                      'Account Holder Name',
                      style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14),
                    ),
                    _buildTextField(
                        "Enter account holder name", _holderNameController),
                    const Text(
                      'Branch Code',
                      style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14),
                    ),
                    _buildTextField("Enter branch code", _branchCodeController),
                    const Text(
                      'Deposit Amount',
                      style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14),
                    ),
                    _buildTextField(
                        "Enter deposit amount", _depositAmountController),
                    const SizedBox(height: 20),
                    const Text(
                      "Upload Deposit Slip",
                      style: TextStyle(color: Color(0x80FFFFFF), fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: const Color.fromARGB(255, 172, 21, 177)
                              .withOpacity(0.5),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload, color: Colors.white),
                            const SizedBox(height: 8),
                            Text(
                              "Click to upload or drag and drop",
                              style: AppTheme.textStyleSmall,
                            ),
                            Text(
                              "Supported: JPG, PNG, PDF",
                              style: AppTheme.textStyleSmall.copyWith(
                                color: Colors.grey,
                                fontSize: 12, // Decreased font size
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: width,
                        decoration: AppTheme.buttonDecoration(),
                        child: ElevatedButton(
                          style: AppTheme.buttonStyle(),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const PaymentDetailsScreen()),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 1),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppTheme.textFieldColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
