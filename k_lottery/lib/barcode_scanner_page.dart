import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/foundation.dart';

class ScannerPage extends StatefulWidget {
  @override
  _ScannerPageState createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  String barcode = '';
  DateTime? selectedDate;
  TextEditingController codeController = TextEditingController();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> scanBarcode() async {
    final scannedBarcode = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AiBarcodeScanner(
          sheetTitle: "Scan Barcode",
          hideSheetTitle: true,
          onDispose: () {
            debugPrint("Barcode scanner disposed!");
          },
          hideGalleryButton: false,
          controller: MobileScannerController(
            detectionSpeed: DetectionSpeed.noDuplicates,
          ),
          onDetect: (BarcodeCapture capture) {
            final String? scannedValue = capture.barcodes.first.rawValue;
            if (scannedValue != null) {
              setState(() {
                barcode = scannedValue;
                codeController.text = scannedValue;
              });
              Navigator.of(context).pop(scannedValue);
            }
          },
          validator: (value) {
            if (value.barcodes.isEmpty) {
              return false;
            }
            return true;
          },
        ),
      ),
    );

    if (scannedBarcode != null) {
      setState(() {
        codeController.text = scannedBarcode;
      });
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

  Future<void> searchLottery() async {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a date'),
          backgroundColor: Colors.red, // Red background color
        ),
      );
      return;
    }

    final enteredCode = codeController.text.trim().toUpperCase();
    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter or scan a barcode'),
          backgroundColor: Colors.red, // Red background color
        ),
      );
      return;
    }

    try {
      String formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate!);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Lotteries')
          .where("draw_date", isEqualTo: formattedDate)
          .get();


 List<DocumentSnapshot> documentSnapshots = [];
      for (var doc in querySnapshot.docs) {
   final documentSnapshot = await FirebaseFirestore.instance
      .collection('PrizeDetails')
      .doc(doc.id)  // Using each document's ID
      .get();

documentSnapshots.add(documentSnapshot);
  // Do something with documentSnapshot
}



     
      for (var doc in documentSnapshots) {
        final prizeDetails = List<String>.from(doc['prize_details']);
        final index = prizeDetails.indexWhere((detail) => detail.contains(enteredCode));

        if (index != -1) {
          final prizeInfoDoc = await FirebaseFirestore.instance
              .collection('PrizeInfos')
              .doc(doc.id)
              .get();

          if (prizeInfoDoc.exists) {
            final prizeInfoDetails = List<String>.from(prizeInfoDoc['prize_details']);
            final correspondingPrize = prizeInfoDetails[index];
            final correspondingDetail = enteredCode;

            debugPrint("Found prize: $correspondingPrize, Location: $correspondingDetail");

            _confettiController.play();

            showDialog(
              context: context,
              builder: (context) => Stack(
                alignment: Alignment.center,
                children: [
                  AlertDialog(
                    title: Text("Congratulations!"),
                    content: Text(
                      "$correspondingPrize\n$correspondingDetail",
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _confettiController.stop();
                        },
                        child: Text("OK"),
                      ),
                    ],
                  ),
                  ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                    colors: const [
                      Colors.red,
                      Colors.blue,
                      Colors.green,
                      Colors.yellow,
                      Colors.orange,
                      Colors.purple,
                    ],
                  ),
                ],
              ),
            );
            return;
          }
        }
      }

      debugPrint("No matching prize found.");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Better Luck Next Time!"),
          content: Text("No prize details found for the entered code."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint("Error searching for lottery: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while searching for the lottery'),
          backgroundColor: Colors.red, // Red background color
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0).copyWith(
          bottom: isKeyboardOpen ? MediaQuery.of(context).viewInsets.bottom + 16 : 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: selectDate,
                child: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : 'Date: ${DateFormat('yyyy-MM-dd').format(selectedDate!)}',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Enter Lottery Code',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: scanBarcode,
                child: const Text('Scan Barcode'),
                style: ElevatedButton.styleFrom(
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: searchLottery,
                child: const Text('Search'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Color.fromARGB(255, 23, 13, 133),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
