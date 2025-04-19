import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:investment_plan_app/screens/SetPinNavigator.dart';

import '../screens/ProfileScreen.dart';

class AppTheme {
  static const Color backgroundColor = Color(0xFF1E1A4D);
  static const Color textFieldColor = Color(0x44FFFFFF);
  static const Color buttonStartColor = Color(0xFF00CCF1);
  static const Color buttonEndColor = Color(0xFF8200DB);
  static const Color primaryColor = Color(0xFF2F0D68);
  static const Color inactiveColor = Color(0xFF9CA3AF);

  static const Color secondaryColor =
      Color(0xFF03DAC6); // Replace with your secondary color
  static const Color slideContainerColor = Color(0xFF1E88E5);

  static TextStyle textStyleTitle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle textStyleSubtitle = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  static TextStyle textStyleAmount = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle textStyleBold = const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle textStyleLarge = const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle textStyleSmall = const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  static BoxDecoration highlightedContainer() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    );
  }

  static BoxDecoration cardContainer() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(10),
    );
  }

  static Widget pendingTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Text(
        'Pending',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static BottomNavigationBar bottomNavigationBar(
      BuildContext context, int currentIndex,
      {String? username}) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return; // Prevent unnecessary navigation
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(
                context, '/home'); // Replace with actual route
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/deposit');
            break;
          case 2:
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SetPinNavigator()),
            );
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/history');
            break;
          case 4:
            // Pass the username directly to AccountPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AccountPage(username: username),
              ),
            );
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      selectedItemColor: buttonStartColor,
      unselectedItemColor: inactiveColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet), label: 'Deposit'),
        BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz), label: 'Withdraw'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }

  static Widget appBackground() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          child: Stack(
            children: [
              SvgPicture.asset(
                'assets/Vector_1.svg',
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 80, sigmaY: 80), // Blur effect
                  child: Container(
                    color: Colors
                        .transparent, // Ensures only the vector is blurred
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 50,
          right: 0,
          child: Stack(
            children: [
              SvgPicture.asset(
                'assets/Vector_2.svg',
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 80, sigmaY: 80), // Blur effect
                  child: Container(
                    color: Colors
                        .transparent, // Ensures only the vector is blurred
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 100,
          left: 0,
          child: Stack(
            children: [
              SvgPicture.asset(
                'assets/Vector_3.svg',
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 80, sigmaY: 80), // Blur effect
                  child: Container(
                    color: Colors
                        .transparent, // Ensures only the vector is blurred
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Stack(
            children: [
              SvgPicture.asset(
                'assets/Vector_4.svg',
                fit: BoxFit.cover,
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter:
                      ImageFilter.blur(sigmaX: 80, sigmaY: 80), // Blur effect
                  child: Container(
                    color: Colors
                        .transparent, // Ensures only the vector is blurred
                  ),
                ),
              ),
            ],
          ),
        ),
        // Positioned(
        //   top: 50,
        //   right: 0,
        //   child: SvgPicture.asset('assets/Vector_2.svg', fit: BoxFit.cover),
        // ),
        // Positioned(
        //   bottom: 100,
        //   left: 0,
        //   child: SvgPicture.asset('assets/Vector_3.svg', fit: BoxFit.cover),
        // ),
        // Positioned(
        //   bottom: 0,
        //   right: 0,
        //   child: SvgPicture.asset('assets/Vector_4.svg', fit: BoxFit.cover),
        // ),
      ],
    );
  }

  // Button style with transparency and rounded corners
  static ButtonStyle buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      minimumSize: const Size(200, 50),
    );
  }

  // Button decoration with gradient
  static BoxDecoration buttonDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [buttonStartColor, buttonEndColor],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(15),
    );
  }

  // Card decoration
  static BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(15),
    );
  }

  // BoxDecoration for general containers
  static BoxDecoration boxDecoration() {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.3)),
    );
  }

  // BoxDecoration for upload box with dotted border
  static BoxDecoration uploadBoxDecoration() {
    return BoxDecoration(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.white.withOpacity(0.5),
        width: 1.5,
        style: BorderStyle.solid,
      ),
    );
  }

  // Regular text style
  static TextStyle textStyleRegular = TextStyle(
    fontSize: 16,
    color: Colors.white.withOpacity(0.8),
    fontWeight: FontWeight.w400,
  );
}
