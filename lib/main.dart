// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:investment_plan_app/screens/otp_verification.dart';
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
  OneSignal.initialize('f60a232e-f993-4322-bd2b-fa1bbbfc59c6');
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
      home: const LoginScreen(),

      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/home': (context) => const HomeScreen(),
        '/deposit': (context) => const DepositScreen(),
        '/withdraw': (context) => const WithdrawPage(),
        '/history': (context) => const TransactionHistoryPage(),
        '/profile': (context) => const AccountPage(
              username: '',
            ),
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

//TODO code with 10 sec session time out

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:investment_plan_app/services/user_service.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'screens/LoginScreen.dart';
// import 'screens/SignUpScreen.dart';
// import 'screens/home_screen.dart';
// import 'screens/DepositScreen.dart';
// import 'screens/DepositFundScreen.dart';
// import 'screens/WithdrawScreen.dart';
// import 'screens/HistoryScreen.dart';
// import 'screens/ProfileScreen.dart';
// import 'screens/BankDetailsScreen.dart';
// import 'screens/PaymentDetailsScreen.dart';
// import 'screens/Bank_Account_Details.dart';
// import 'screens/pending_withdrawals_page.dart';
// import 'screens/pin_entry_page.dart';

// // For testing, you can reduce the timeout duration
// // 3 minutes = 180000 milliseconds
// // For testing: 10 seconds = 10000 milliseconds
// const int SESSION_TIMEOUT_MS = 10000; // Set to 10 seconds for testing

// class AppSession {
//   static DateTime? backgroundTime;
  
//   static void setBackgroundTime() {
//     backgroundTime = DateTime.now();
//     print('App went to background at: $backgroundTime');
//   }
  
//   static Duration getBackgroundDuration() {
//     if (backgroundTime == null) {
//       return Duration.zero;
//     }
    
//     Duration elapsed = DateTime.now().difference(backgroundTime!);
//     print('App was in background for: ${elapsed.inSeconds} seconds');
//     return elapsed;
//   }
// }

// void main() async {
//   // Ensure Flutter is initialized
//   WidgetsFlutterBinding.ensureInitialized();

//   // Initialize OneSignal
//   OneSignal.initialize('0d5f52a7-45de-4bcd-8987-b8b9dedc7509');
//   await OneSignal.Notifications.requestPermission(true);

//   // Check login status before building the app
//   bool isLoggedIn = await checkLoginStatus();
  
//   runApp(MyApp(
//     isLoggedIn: isLoggedIn,
//   ));
// }

// Future<bool> checkLoginStatus() async {
//   final userId = await UserApiService.getUserId();
//   final bool islog;
//   if (userId != null) {
//     islog = true;
//   } else {
//     islog = false;
//   }
//   print('userid $islog');
//   return islog;
// }

// class MyApp extends StatefulWidget {
//   final bool isLoggedIn;
//   const MyApp({super.key, required this.isLoggedIn});

//   @override
//   _MyAppState createState() => _MyAppState();
// }

// class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
//   final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//   }
  
//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
    
//     if (state == AppLifecycleState.paused) {
//       // App is going to background
//       AppSession.setBackgroundTime();
//     } else if (state == AppLifecycleState.resumed) {
//       // App is coming back to foreground
//       _checkSessionTimeout();
//     }
//   }
  
//   Future<void> _checkSessionTimeout() async {
//     print('Checking session timeout...');
//     Duration backgroundDuration = AppSession.getBackgroundDuration();
    
//     print('Background duration: ${backgroundDuration.inMilliseconds}ms, Timeout threshold: ${SESSION_TIMEOUT_MS}ms');
    
//     if (backgroundDuration.inMilliseconds >= SESSION_TIMEOUT_MS) {
//       print('SESSION TIMEOUT DETECTED! Redirecting to login...');
      
//       // Only show timeout if user is logged in
//       final userId = await UserApiService.getUserId();
//       print('Current user ID: $userId');
      
//       if (userId != null) {
//         print('User was logged in, showing timeout dialog');
        
//         // Ensure we can safely show a dialog
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (navigatorKey.currentContext != null) {
//             showDialog(
//               context: navigatorKey.currentContext!,
//               barrierDismissible: false,
//               builder: (context) => AlertDialog(
//                 title: const Text('Session Expired'),
//                 content: const Text('Your session has expired due to inactivity. Please log in again.'),
//                 actions: [
//                   TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                       // Navigate to login and clear all previous routes
//                       Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
//                     },
//                     child: const Text('OK'),
//                   ),
//                 ],
//               ),
//             );
//           } else {
//             print('ERROR: Navigator context is null, cannot show dialog');
//             // Fallback - try to navigate directly
//             navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
//           }
//         });
//       } else {
//         print('User was not logged in, no need to show timeout');
//       }
//     } else {
//       print('Session still valid, no timeout needed');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     print('Building MyApp with isLoggedIn: ${widget.isLoggedIn}');
    
//     return MaterialApp(
//       navigatorKey: navigatorKey,
//       debugShowCheckedModeBanner: false,
//       title: 'Investment Plan App',
//       theme: ThemeData(
//         primaryColor: const Color(0xFF2F0D68),
//       ),
//       // Important: If this is wrong, users won't be directed to the correct initial screen
//       home: widget.isLoggedIn ? const HomeScreen() : const SignUpScreen(),
//       routes: {
//         '/login': (context) => const LoginScreen(),
//         '/signup': (context) => const SignUpScreen(),
//         '/home': (context) => const HomeScreen(),
//         '/deposit': (context) => const DepositScreen(),
//         '/withdraw': (context) => const WithdrawPage(),
//         '/history': (context) => const TransactionHistoryPage(),
//         '/profile': (context) => const AccountPage(username: ''),
//         '/depositfund': (context) => const DepositFundScreen(),
//         '/bankdetails': (context) => const BankDetailsScreen(),
//         '/paymentdetails': (context) => const BankDetailsScreen(),
//         '/pendingwithdrawals': (context) => const PendingWithdrawalsPage(),
//         '/pinentrypage': (context) => PinEntryPage(),
//         '/bank_account_details': (context) => BankDetailsPage(),
//       },
//     );
//   }
// }