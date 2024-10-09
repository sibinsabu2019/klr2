import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:k_lottery/home.dart';
import 'package:k_lottery/shared_models.dart';


class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  DateTime? selectedDate;
  List<LotteryResultInfo> _searchResults = [];
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dateController.text = '';
  }

  Future<void> _search() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red, // Red background color for the error message
        ),
      );
      return;
    }

    try {
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate!); // Adjust format to match your Firestore date format

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Lotteries')
          .where("draw_date", isEqualTo: formattedDate)
          .get();

      List<LotteryResultInfo> results = [];

      for (QueryDocumentSnapshot queryDocumentSnapshot in querySnapshot.docs) {
        // Convert the document data to a Map<String, dynamic>
        Map<String, dynamic> data = queryDocumentSnapshot.data() as Map<String, dynamic>;

        // Add the data to the results list as a LotteryResultInfo object
        results.add(LotteryResultInfo(
          id: queryDocumentSnapshot.id, // Using the document ID as the ID
          lotteryName: data['lottery_name'] ?? '', // Using 'lottery_name' from the document data
          serialNumber: data['lottery_serial_number'] ?? '', // Using 'lottery_serial_number' from the document data
          drawDate: data['draw_date'] ?? '', // Using 'draw_date' from the document data
        ));
      }

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      print('Error fetching results: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching results'),
          backgroundColor: Colors.red, // Red background color for the error message
        ),
      );
    }
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: selectDate,
                  child: Text(selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}'),
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: _search,
                child: Text(
                  'Search',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 20, 28, 137),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(child: Text('No results found'))
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1, // Two-column layout
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      childAspectRatio: 2, // Adjust the aspect ratio as needed
                    ),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      var lotteryinfo = _searchResults[index]; // Access the LotteryResultInfo object directly

                      return LotteryEntryCard(
                        entry: {
                          "SerialNumber": lotteryinfo.serialNumber,
                          "name": lotteryinfo.lotteryName,
                          "date": lotteryinfo.drawDate,
                        }, // Pass a map with the necessary fields
                        isNew: false, // Mark the first item as new
                        lotteryinfo: lotteryinfo,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
