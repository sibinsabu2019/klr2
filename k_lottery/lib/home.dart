import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:k_lottery/pdfviewPage.dart';
import 'package:k_lottery/scert.dart';
import 'package:k_lottery/shared_models.dart';

import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Import intl package

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Map<String, String>> entries = [];
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    fetchEntries();
  }

  // Add this method to parse the date
  DateTime parseDate(String dateStr) {
    try {
      final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
      return dateFormat.parse(dateStr);
    } catch (e) {
      print('Error parsing date: $e');
      return DateTime.now(); // Fallback to current date
    }
  }

  Future<void> fetchEntries() async {
    try {
      QuerySnapshot lotteriesSnapshot = await FirebaseFirestore.instance
          .collection('Lotteries')
          .limit(20)
          .get();
      List<Map<String, String>> fetchedEntries = [];

      for (var lotteryDoc in lotteriesSnapshot.docs) {
        var data = lotteryDoc.data() as Map<String, dynamic>?;
        log(data!['lottery_name'].toString());

        if (data != null &&
            data.containsKey('draw_date') &&
            data.containsKey('lottery_name') &&
            data.containsKey('lottery_serial_number')) {
          fetchedEntries.add({
            "date": data['draw_date'] as String,
            "name": data['lottery_name'] as String,
            "SerialNumber": data['lottery_serial_number'] as String,
          });
        } else {
          print('Document ${lotteryDoc.id} is missing required fields.');
        }
      }

      // Sort the entries based on the draw_date
      fetchedEntries.sort((a, b) {
        DateTime dateA = parseDate(a["date"]!);
        DateTime dateB = parseDate(b["date"]!);
        return dateB.compareTo(dateA); // Sort in descending order
      });

      setState(() {
        entries = fetchedEntries;
      });
    } catch (e) {
      print('Error fetching entries: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 6.0,
        top: 6.0,
        right: 6.0,
        bottom: 0.0,
      ),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Two-column layout
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
          childAspectRatio: 2, // Adjust the aspect ratio as needed
        ),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          var entry = entries[index];
          var lotteryinfo = LotteryResultInfo(
            id: entry["SerialNumber"] ?? "",
            lotteryName: entry["name"] ?? "",
            serialNumber: entry["SerialNumber"] ?? "",
            drawDate: entry["date"] ?? "",
          );
          return LotteryEntryCard(
            entry: entry,
            isNew: index == 0, // Mark the first item as news
            lotteryinfo: lotteryinfo,
          );
        },
      ),
    );
  }
}

class LotteryEntryCard extends StatefulWidget {
  final Map<String, String> entry;
  final bool isNew;
  final LotteryResultInfo lotteryinfo;

  const LotteryEntryCard({
    required this.entry,
    required this.isNew,
    required this.lotteryinfo,
  });

  @override
  _LotteryEntryCardState createState() => _LotteryEntryCardState();
}

class _LotteryEntryCardState extends State<LotteryEntryCard> {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  // Load the interstitial ad
  // Load the interstitial ad
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-3940256099942544/1033173712', // Test ad unit ID
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          setState(() {
            _isAdReady = true;
          });
          print('Interstitial Ad Loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Interstitial Ad Failed to Load: $error');
          _isAdReady = false;
        },
      ),
    );
  }

  // Show the interstitial ad
  void _showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          print('Ad Dismissed');
          ad.dispose();
          _loadInterstitialAd(); // Load a new ad after the current one is dismissed
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          print('Failed to show interstitial ad: $error');
          ad.dispose();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        _showInterstitialAd();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (context) => Result(),
            child: ResultPage(
              info: widget.lotteryinfo,
              title:Provider.of<Result>(context, listen: false)
                .Languages[widget.entry["name"]],
            ),
          ),
        ));

        log(Provider.of<Result>(context, listen: false).selectedtittle =
            widget.entry["name"].toString());
        if (Provider.of<Result>(context, listen: false)
                .Languages[widget.entry["name"]] !=
            null) {
          log("not null");
          Provider.of<Result>(context, listen: false).Title(Provider.of<Result>(context, listen: false)
                  .Languages[widget.entry["name"]]);   
              
                  log(Provider.of<Result>(context, listen: false).selectedtittle);
        } else {
          Provider.of<Result>(context, listen: false).selectedtittle =
              widget.entry["name"].toString();
        }
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8.0,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Consumer<Result>(
                    builder: (context, result, child) {
                      // String lotteryName = result.Languages[widget.entry["name"]?.trim()];
                      return LotteryEntryTitle(
                        date: widget.entry["date"] ?? "",
                        serialNo: widget.entry["SerialNumber"] ?? "",
                      );
                    },
                  ),
                  // LotteryEntryTitle(
                  //   date: widget.entry["date"] ?? "",
                  //   serialNo: widget.entry["SerialNumber"] ?? "",
                  // ),
                  SizedBox(height: 8),
                  LotteryEntryDate(
                      title: Provider.of<Result>(context, listen: false)
                                  .Languages[widget.entry["name"]] !=
                              null
                          ? Provider.of<Result>(context, listen: false)
                              .Languages[widget.entry["name"]]
                              .toString()
                          : widget.entry["name"].toString()),
                ],
              ),
            ),
          ),
          if (widget.isNew)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                  ),
                ),
                child: Text(
                  'New',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LotteryEntryTitle extends StatelessWidget {
  final String date;
  final String serialNo;

  const LotteryEntryTitle({required this.date, required this.serialNo});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          date,
          style: TextStyle(
            color: Color.fromARGB(221, 32, 32, 32),
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 36, 46, 178),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            serialNo,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class LotteryEntryDate extends StatelessWidget {
  final String title;

  const LotteryEntryDate({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.blue.shade900,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class LotteryResultData {
  final List<String> prizeInfo;
  final List<String> prizeDetails;

  const LotteryResultData({
    required this.prizeInfo,
    required this.prizeDetails,
  });

  @override
  String toString() {
    return prizeDetails.last;
  }
}
