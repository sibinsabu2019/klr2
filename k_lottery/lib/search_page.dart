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
          backgroundColor:
              Colors.red, // Red background color for the error message
        ),
      );
      return;
    }

    try {
      String formattedDate = DateFormat('dd/MM/yyyy').format(
          selectedDate!); // Adjust format to match your Firestore date format

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Lotteries')
          .where("draw_date", isEqualTo: formattedDate)
          .get();

      List<LotteryResultInfo> results = [];

      for (QueryDocumentSnapshot queryDocumentSnapshot in querySnapshot.docs) {
        // Convert the document data to a Map<String, dynamic>
        Map<String, dynamic> data =
            queryDocumentSnapshot.data() as Map<String, dynamic>;

        // Add the data to the results list as a LotteryResultInfo object
        results.add(LotteryResultInfo(
          id: queryDocumentSnapshot.id, // Using the document ID as the ID
          lotteryName: data['lottery_name'] ??
              '', // Using 'lottery_name' from the document data
          serialNumber: data['lottery_serial_number'] ??
              '', // Using 'lottery_serial_number' from the document data
          drawDate: data['draw_date'] ??
              '', // Using 'draw_date' from the document data
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
          backgroundColor:
              Colors.red, // Red background color for the error message
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
      child:Column(
  children: [
   Container(
  padding: EdgeInsets.all(16.0),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20), // Rounded container for modern look
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05), // Soft shadow for a subtle effect
        blurRadius: 10,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: Column(
    mainAxisSize: MainAxisSize.min, // Adjust size based on content
    children: [
      // Select Date Button
      GestureDetector(
        onTap: selectDate,
        child: Container(
          height: 60, // Increased height for better interaction
          width: double.infinity, // Full width button
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.withOpacity(0.7), Colors.green], // Gradient for a modern look
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),

                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: Text(
              selectedDate == null
                  ? 'Select Date'
                  : 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold, // Stronger font weight
                color: Colors.white, // White text for better contrast
              ),
            ),
          ),
        ),
      ),
      
      SizedBox(height: 20), // Space between buttons

      // Search Button
      Container(width: MediaQuery.of(context).size.width*5,
        child: Expanded(
          child: ElevatedButton(
            onPressed: _search,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16.0), // Taller button
              backgroundColor: Colors.green.withOpacity(0.9), // Lighter teal for contrast
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 10, // Stronger shadow for a floating effect
              shadowColor: Colors.grey.withOpacity(0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Adjust width based on content
              children: [
                Icon(Icons.search, color: Colors.white), // Icon to make the button more engaging
                SizedBox(width: 10), // Space between icon and text
                Text(
                  'Search',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
    SizedBox(height: 24), // Increased padding for better readability
    Expanded(
      child: _searchResults.isEmpty
          ? Center(child: Text('No results found'))
          : ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                var lotteryinfo = _searchResults[index];

                return Card(
                  child: LotteryEntryCard(
                    entry: {
                      "SerialNumber": lotteryinfo.serialNumber,
                      "name": lotteryinfo.lotteryName,
                      "date": lotteryinfo.drawDate,
                    },
                    isNew: false,
                    lotteryinfo: lotteryinfo,
                  ),
                );
              },
            ),
    ),
  ],
));
  }
}
