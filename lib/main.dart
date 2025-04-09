import 'package:flutter/material.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/LoginScreen.dart';
import 'screens/SignUpScreen.dart';
import 'screens/home_screen.dart';
import 'screens/DepositScreen.dart';
import 'screens/DepositFundScreen.dart';
import 'screens/WithdrawScreen.dart';
import 'screens/HistoryScreen.dart';
import 'screens/ProfileScreen.dart';
import 'screens/BankDetailsScreen.dart';
import 'screens/PaymentDetailsScreen.dart';
import 'screens/Bank_Account_Details.dart';
import 'screens/pending_withdrawals_page.dart';
import 'screens/pin_entry_page.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Check login status before building the app
  bool isLoggedIn = await checkLoginStatus();
  runApp(MyApp(
    isLoggedIn: isLoggedIn,
  ));
}

Future<bool> checkLoginStatus() async {
  final userId = await UserApiService.getUserId();
  final bool islog;
  if (userId != null) {
    islog = true;
  } else {
    islog = false;
  }
  print('userid $islog');
  return islog;
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes debug banner
      title: 'Investment Plan App',
      theme: ThemeData(
        primaryColor: const Color(0xFF2F0D68), // Sets primary color
      ),
      initialRoute: isLoggedIn ? '/login' : '/signup', // Set the initial screen
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/deposit': (context) => const DepositScreen(),
        '/withdraw': (context) => const WithdrawPage(),
        '/history': (context) => const TransactionHistoryPage(),
        '/profile': (context) => const AccountPage(),
        '/depositfund': (context) => const DepositFundScreen(),
        '/bankdetails': (context) => const BankDetailsScreen(),
        '/paymentdetails': (context) => const BankDetailsScreen(),
        '/pendingwithdrawals': (context) => const PendingWithdrawalsPage(),
        '/pinentrypage': (context) => PinEntryPage(),
        '/bank_account_details': (context) => BankDetailsPage(),
      },
    );
  }
}
