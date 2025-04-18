// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:investment_plan_app/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
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

  // Initialize OneSignal
  OneSignal.initialize('0d5f52a7-45de-4bcd-8987-b8b9dedc7509');
  await OneSignal.Notifications.requestPermission(true);

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
      home: HomeScreen(),

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
