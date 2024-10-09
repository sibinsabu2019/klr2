import 'package:flutter/material.dart';
import 'package:k_lottery/scert.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart'; // Import the share_plus package
import 'package:provider/provider.dart';
import 'package:k_lottery/shared_models.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultPage extends StatefulWidget {
  final LotteryResultInfo info;
  final String title;
  const ResultPage({super.key, required this.info, required this.title});

  @override
  _ResultPageState createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late ScrollController _scrollController;
  late TextEditingController _searchController;
  late String _searchText;
  late Map<String, GlobalKey> _itemKeyMap;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _searchText = "";
    _itemKeyMap = {};

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toUpperCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_dataLoaded) {
        Provider.of<Result>(context, listen: false)
            .reloadData(widget.info.serialNumber);
        setState(() {
          _dataLoaded = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Share Content Function
  // Share Content Function
void _shareContent()async {
  final result = Provider.of<Result>(context, listen: false).data;
  
  if (result != null) {
    // Create a well-formatted string for sharing
    StringBuffer shareText = StringBuffer();

     String appLink ='https://play.google.com/store/apps/details?id=com.example.klottery';
    // Add title
    shareText.writeln('Kerala Lottery Results\n');
     
         shareText.writeln('Download the KLottery App now: $appLink\n',);
    // Add Prize Details and corresponding Prize Info
    shareText.writeln('Prize Details:');
    for (int i = 0; i < result.prizeDetails.length; i++) {
      // Get the prize detail
      final prizeDetail = result.prizeDetails[i];
      
      // Get the corresponding prize info
      final prizeInfo = result.prizeInfo.length > i ? result.prizeInfo[i] : '';

      // Add both to the share text
      shareText.writeln('$prizeDetail\n$prizeInfo\n');
    }

    // Share the formatted text
    Share.share(
      shareText.toString(),
      subject: 'Kerala Lottery Results',
    );
  } else {
    Share.share(
      'Download KLottery App now',
      subject: 'Kerala Lottery Result',
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 20, 28, 137),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.0,
          ),
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: TextButton(
              style: ButtonStyle(
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                shape: MaterialStateProperty.all<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                backgroundColor: MaterialStateProperty.all<Color>(
                  Color.fromARGB(255, 0, 120, 215),
                ),
              ),
              onPressed: _shareContent, // Assign share functionality here
              child: Icon(
                Icons.share,
                size: 20.0,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<Result>(
              builder: (context, result, child) {
                if (result.isLoading) {
                  return Center(child: CircularProgressIndicator());
                }
                final data = result.data;
                if (data == null) {
                  return Center(child: Text("No data available"));
                }

                return ListView(
                  controller: _scrollController,
                  children: data.prizeDetails.map((e) {
                    final key = GlobalKey();
                    _itemKeyMap[e] = key;

                    return ResultTile(
                      key: key,
                      heading: e,
                      detailedResult: data
                          .prizeInfo[data.prizeDetails.indexOf(e)],
                      searchText: _searchText,
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ResultTile extends StatelessWidget {
  final String heading;
  final String detailedResult;
  final String searchText;

  const ResultTile(
      {super.key, required this.heading, required this.detailedResult, required this.searchText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color(0xFFFFE0B2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                heading,
                style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 18.0,
                    color: Colors.black,
                  ),
                  children: _highlightSearchText(detailedResult, searchText),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TextSpan> _highlightSearchText(String text, String searchText) {
    if (searchText.isEmpty || !text.contains(searchText)) {
      return [TextSpan(text: text)];
    }
    List<TextSpan> spans = [];
    int start = 0;
    int indexOfHighlight;

    while ((indexOfHighlight = text.indexOf(searchText, start)) != -1) {
      if (indexOfHighlight > start) {
        spans.add(TextSpan(text: text.substring(start, indexOfHighlight)));
      }
      spans.add(
        TextSpan(
          text: searchText,
          style: TextStyle(
            backgroundColor: Colors.yellow,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
      start = indexOfHighlight + searchText.length;
    }
    spans.add(TextSpan(text: text.substring(start)));
    return spans;
  }
}
