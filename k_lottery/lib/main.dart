import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:k_lottery/demobarcode.dart';
import 'package:k_lottery/scert.dart';
import 'package:k_lottery/search_page.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'home.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (context) => Result()),
  ], child: const MyApp(),));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainWidget(),
    );
  }
}

class MainWidget extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<MainWidget> {
  int _selectedIndex = 0;
  String appVersion = 'Version: 1.0.0';
  String _selectedLanguage = 'English'; // Default language
  bool isLoading = false;

  final List<Widget> _pages = [
    Home(),
    SearchPage(),
    // ScannerPage(),
    DemoScanner(),
  ];

  @override
  void initState() {
    super.initState();
    Provider.of<Result>(context, listen: false).FetchLang("english");
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
   void shareApp() {
    Share.share('Check out the K-Lottery app: https://play.google.com/store/apps/details?id=com.example.klottery');
  }

  // Open the privacy policy page in a browser
  void openPrivacyPolicy() async {
    final url = 'https://www.example.com/privacy-policy'; // Replace with your actual Privacy Policy URL
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

void showRateDialog(BuildContext context) {
  int _rating = 0; // Initialize rating to 0

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text("Rate Us"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Please rate your experience:"),
                SizedBox(height: 10),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _rating = index + 1; // Update rating when pressed
                        });
                        print("Rated: $_rating star(s)"); // Print the rating in the console
                      },
                    );
                  }),
                )
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cancel button
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context); // Continue button
                  // Open Play Store link
                  final url = 'https://play.google.com/store/apps/details?id=com.example.klottery';
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                },
                child: Text("Continue"),
              ),
            ],
          );
        },
      );
    },
  );
}
  void _selectLanguage(String language) async {
    setState(() {
      isLoading = true;
    });
    log(isLoading.toString());
    await Provider.of<Result>(context, listen: false).FetchLang(language);

    setState(() {
      _selectedLanguage = language;
      isLoading = false;
    });
  }

  // Disclaimer text
  String disclaimerText = '''
    **K-Lottery Disclaimer**

    Welcome to K-Lottery, your go-to lottery app for exciting games and rewards! Before using our application, please carefully review the following terms and conditions. By accessing and using the K-Lottery app, you agree to comply with and be bound by the following legal disclaimers.

    **1. No Guarantee of Winning:**
    The games provided in the K-Lottery app are purely based on chance. There is no guarantee of winning, and users should play for entertainment purposes only. The lottery results are random, and winning is dependent on luck.

    **2. Responsible Gambling:**
    K-Lottery encourages responsible gaming. We do not promote excessive or problematic gambling behavior. Please play responsibly and within your financial limits. If you feel you are experiencing issues with gambling, we advise seeking professional assistance.

    **3. Age Restriction:**
    The K-Lottery app is only for users who are 18 years of age or older. By using this app, you confirm that you are legally allowed to participate in lottery games according to the laws of your jurisdiction.

    **4. Fairness and Transparency:**
    K-Lottery ensures that all lottery games are conducted fairly and transparently. However, we do not guarantee that the platform or services will be free from errors, interruptions, or delays.

    **5. Personal Data and Privacy:**
    Your privacy is important to us. We collect and process your personal information in accordance with our Privacy Policy. Please read our Privacy Policy to understand how we handle your data. We will never share your personal information with third parties without your consent, except as required by law.

    **6. No Liability for Losses:**
    K-Lottery and its developers are not liable for any financial or emotional losses resulting from participation in the lottery or other related activities. You accept full responsibility for your actions while using the app.

    **7. Third-Party Ads and Links:**
    The app may contain third-party advertisements and links to external websites. We are not responsible for the content, privacy practices, or services offered by these third-party sites.

    **8. Updates to Disclaimer:**
    K-Lottery reserves the right to update or modify this disclaimer at any time. Any changes will be reflected here, and your continued use of the app indicates your acceptance of these updated terms.

    **Contact Us:**
    If you have any questions or concerns about this disclaimer, please contact us at support@klotteryapp.com.

    Thank you for using K-Lottery. Enjoy the game responsibly!
  ''';

  // Show disclaimer in a modal bottom sheet
  void showDisclaimer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Disclaimer',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  disclaimerText,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20),
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      textStyle: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> _titles = [
      'K-Lottery',
      'Search',
      'Scanner',
      'Profile',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'K-Lottery' : _titles[_selectedIndex],
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 20, 28, 137),
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            onSelected: _selectLanguage,
            icon: Icon(Icons.language, color: Colors.white),
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'english',
                  child: Text('English'),
                ),
                PopupMenuItem(
                  value: 'malayalam',
                  child: Text('Malayalam'),
                ),
                PopupMenuItem(
                  value: 'tamil',
                  child: Text('Tamil'),
                ),
                PopupMenuItem(
                  value: 'hindi',
                  child: Text('Hindi'),
                ),
              ];
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 20, 28, 137),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'K-Lottery Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    appVersion,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.update),
              title: Text('Update'),
               onTap: () async {
                  Navigator.pop(context); // Continue button
                  // Open Play Store link
                  final url = 'https://play.google.com/store/apps/details?id=com.example.klottery';
                  if (await canLaunch(url)) {
                    await launch(url);
                  }
                },
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('Disclaimer'),
              onTap: () {
                Navigator.pop(context);
                showDisclaimer(context); // Show disclaimer
              },
            ),
            ListTile(
              leading: Icon(Icons.star_rate),
              title: Text('Rate Us'),
              onTap: () {
                Navigator.pop(context);
                showRateDialog(context);
                // Add functionality here for "Rate Us"
              },
            ),
            ListTile(
              leading: Icon(Icons.privacy_tip),
              title: Text('Privacy Policy'),
              onTap: () {
                Navigator.pop(context);
                openPrivacyPolicy();
                // Add functionality here for "Privacy Policy"
              },
              
            ),
             ListTile(
              leading: Icon(Icons.share),
              title: Text('Share '),
              onTap: () {
                Navigator.pop(context);
                shareApp();
                // Add functionality here for "Privacy Policy"
              },
              
            ),
          ],
        ),
      ),
      body: isLoading == false ? _pages[_selectedIndex] : Center(child: CircularProgressIndicator()),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_2_outlined),
            label: 'Scanner',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.grey,
        unselectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}
