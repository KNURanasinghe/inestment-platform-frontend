import 'package:flutter/material.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';
import 'pin_entry_page.dart'; // Import the PIN entry page

class BankDetailsPage extends StatefulWidget {
  double? amount; // Amount to be deposited, if needed
  BankDetailsPage({super.key, this.amount});

  @override
  _BankDetailsPageState createState() => _BankDetailsPageState();
}

class _BankDetailsPageState extends State<BankDetailsPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController bankController = TextEditingController();
  TextEditingController accountNumberController = TextEditingController();
  TextEditingController branchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.pop(context); // Go back to the previous page
            },
          ),
          title: const Text("Bank Account Details",
              style: TextStyle(color: Colors.white, fontSize: 20)),
          centerTitle: true,
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 15),
              child: CircleAvatar(
                backgroundImage:
                    AssetImage('assets/profile.jpg'), // Add user profile image
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            AppTheme.appBackground(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    buildTextField("Account Holder Name", "Enter your name",
                        nameController),
                    const SizedBox(height: 20),
                    buildTextField(
                        "Bank Name", "Enter bank name", bankController),
                    const SizedBox(height: 20),
                    buildTextField("Account Number", "Enter account number",
                        accountNumberController),
                    const SizedBox(height: 20),
                    buildTextField(
                        "Branch Name", "Enter branch name", branchController),
                    const SizedBox(height: 60),
                    GestureDetector(
                      onTap: () {
                        // Navigate to PIN Entry Page when "Next" is clicked
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PinEntryPage(
                                    accountNumber: accountNumberController.text,
                                    bankName: bankController.text,
                                    name: nameController.text,
                                    branchName: branchController.text,
                                    amount: widget.amount,
                                  )),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            "Next",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        // bottomNavigationBar: BottomNavigationBar(
        //   backgroundColor: Color(0xFF1D153A),
        //   selectedItemColor: Colors.blue,
        //   unselectedItemColor: Colors.white54,
        //   items: [
        //     BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        //     BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "Deposit"),
        //     BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: "Withdraw"),
        //     BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        //     BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        //   ],
        // ),
        bottomNavigationBar: AppTheme.bottomNavigationBar(context, 2));
  }

  Widget buildTextField(
      String label, String hint, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }
}
