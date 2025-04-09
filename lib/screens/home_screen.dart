import 'package:flutter/material.dart';
import 'package:investment_plan_app/widgets/AppTheme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final int _currentIndex = 0;

  final String username = "John Doe";
  final double totalIncome = 1500.00;
  final List<String> imageUrls = [
    'assets/home_bg.png',
    'assets/home_bg.png',
    'assets/home_bg.png',
  ];

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      // Apply global background color
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hello $username',
                style: const TextStyle(fontSize: 20, color: Colors.white)),
            const CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage('assets/user_profile.jpg'),
            ),
          ],
        ),
        backgroundColor: AppTheme.backgroundColor, // Fixed undefined color
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                AppTheme.appBackground(),
                SizedBox(
                  width: width,
                  height: height,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          width: width,
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return Image.asset(imageUrls[index],
                                  fit: BoxFit.scaleDown);
                            },
                          ),
                        ),

                        //Total income container
                        Container(
                          height: 150,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/total_bg.png'),
                              // Replace with your image path
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Your Total Income',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                      ),
                                    ),
                                    Text(
                                      '\$12,500', // Replace with user's income
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

//current rate container
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 0, bottom: 20),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.indigo.withOpacity(0.1),
                                  // 0% - Light Blue
                                  Colors.deepPurple.withOpacity(0.1),
                                  // 100% - Dark Purple
                                ],
                              ),
                              borderRadius: BorderRadius.circular(
                                  15), // Optional: Add rounded corners
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _infoWidget2(
                                  'Current Rate', '\$1 BTC = \$45,000', width),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

//Parallel Containers

                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(0.4),
                                        Colors.white.withOpacity(0.3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.show_chart,
                                            color: Colors.white),
                                        Expanded(
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text('Total Profit',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20)),
                                                Text('\$5,000',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 120,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.withOpacity(0.4),
                                        Colors.white.withOpacity(0.3),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.people, color: Colors.white),
                                        Expanded(
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text('Referral Income',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20)),
                                                Text('\$2,500',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                // Replace with referral income
                                              ],
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
                        ),

                        const SizedBox(height: 30),

// Recent transactions container
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recent transactions',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(Icons.arrow_upward, color: Colors.red),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('Sent BTC',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18)),
                                            SizedBox(width: 120),
                                            Text('-0.245 BTC',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        ),
                                        Text('2023-10-27, 10:30 AM',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20),
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward,
                                        color: Colors.green),
                                    SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text('Received ETH',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18)),
                                            SizedBox(width: 80),
                                            Text('+1.567 ETH',
                                                style: TextStyle(
                                                    color: Colors.green)),
                                          ],
                                        ),
                                        Text('2023-10-27, 11:45 AM',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppTheme.bottomNavigationBar(context, 0),
    );
  }

  Widget _infoWidget(String title, String amount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade800, Colors.grey.shade600],
          // Gradient gray colors
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius:
            BorderRadius.circular(12), // Optional: Smooth rounded corners
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AppTheme.textStyleTitle.copyWith(color: Colors.white),
          ),
          Text(
            amount,
            style: AppTheme.textStyleAmount.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // Widget _infoWidget(String title, String amount) {
  //   return Container(
  //     padding: EdgeInsets.all(16),
  //     decoration: AppTheme.cardDecoration(),
  //     child: Column(
  //       children: [
  //         Text(title,
  //             style: AppTheme.textStyleTitle.copyWith(color: Colors.white)),
  //         Text(amount,
  //             style: AppTheme.textStyleAmount.copyWith(color: Colors.white)),
  //       ],
  //     ),
  //   );
  // }

  Widget _infoWidget2(String title, String amount, double width) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: width,
      decoration: AppTheme.cardDecoration(),
      child: Column(
        children: [
          Text(title,
              style: AppTheme.textStyleTitle.copyWith(color: Colors.white)),
          Text(amount,
              style: AppTheme.textStyleAmount.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
