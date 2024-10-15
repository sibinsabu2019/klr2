import 'package:flutter/material.dart';
import 'package:k_lottery/scert.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart'; 
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
  void _shareContent() async {
    final result = Provider.of<Result>(context, listen: false).data;

    if (result != null) {
      StringBuffer shareText = StringBuffer();
      String appLink =
          'https://play.google.com/store/apps/details?id=com.example.klottery';
      shareText.writeln('Kerala Lottery Results\n');
      shareText.writeln('Download the KLottery App now: $appLink\n');
      shareText.writeln('Prize Details:');
      for (int i = 0; i < result.prizeDetails.length; i++) {
        final prizeDetail = result.prizeDetails[i];
        final prizeInfo =
            result.prizeInfo.length > i ? result.prizeInfo[i] : '';
        shareText.writeln('$prizeDetail\n$prizeInfo\n');
      }

      Share.share(shareText.toString(), subject: 'Kerala Lottery Results');
    } else {
      Share.share('Download KLottery App now',
          subject: 'Kerala Lottery Result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green
        .withOpacity(0.9),
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.0, // Slightly larger text
            fontWeight: FontWeight.bold,
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
                foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.white),
              ),
              onPressed: _shareContent, // Assign share functionality here
              child: Icon(
                Icons.share,
                size: 25.0,
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
                prefixIcon: Icon(Icons.search, color: Colors.teal),
                labelStyle: TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(
                    color: Colors.teal,
                    width: 2.0,
                  ),
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
                      detailedResult:
                          data.prizeInfo[data.prizeDetails.indexOf(e)],
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
      {super.key,
      required this.heading,
      required this.detailedResult,
      required this.searchText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // More balanced padding
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), // Smoother corners
          color: Colors.white, // Clean white background
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: Offset(2, 4), // Shadow to add depth
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0), // More padding for breathing space
              child: Text(
                heading,
                style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.teal,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 25.0,
                    color: Colors.grey[800],
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
            backgroundColor: Colors.yellow[300],
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
