import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/foundation.dart';

class DemoScanner extends StatefulWidget {
  @override
  _DemoScannerState createState() => _DemoScannerState();
}

class _DemoScannerState extends State<DemoScanner> {
  String barcode = '';
  DateTime? selectedDate;
  TextEditingController codeController = TextEditingController();
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    codeController.dispose(); // Dispose of the controller
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
            return value.barcodes.isNotEmpty;
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
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final enteredCode = codeController.text.trim().toUpperCase();
    if (enteredCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter or scan a barcode'),
          backgroundColor: Colors.red,
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
            .doc(doc.id)
            .get();

        if (documentSnapshot.exists) {
          documentSnapshots.add(documentSnapshot);
        }
      }

      bool prizeFound = false; // Flag to track if a prize was found

      for (var doc in documentSnapshots) {



       final prizeDetails = List<String>.from(doc['prize_details']);

  // Clean and process prize details
  List<String> cleanedPrizeDetails = prizeDetails.map((detail) {
  // Split on whitespace, remove parentheses and surrounding spaces, trim
  List<String> parts = detail.split(' ')
      .map((part) => part.replaceAll(RegExp(r'\(.*?\)'), '').trim())
      .toList();

  // Join letters and numbers while preserving order
  List<String> processedParts = [];
  String currentLetters = '';  // To store letters like "PY", "PZ", etc.

  for (String part in parts) {
    if (part.contains(RegExp(r'[a-zA-Z]'))) {
      currentLetters = part;  // Collect letter part
    } else if (part.contains(RegExp(r'\d'))) {
      // Append number to letter if a letter part exists
      if (currentLetters.isNotEmpty) {
        processedParts.add(currentLetters + part);  // Merge letter and number
        currentLetters = '';  // Reset after merging
      } else {
        processedParts.add(part);  // Just a number without letters
      }
    }
  }

  return processedParts.join(' '); // Join processed parts
}).toList();

log("Cleaned Prize Details: $cleanedPrizeDetails");





        List<List<String>> nestedPrizeDetails = [];

        for (String detail in cleanedPrizeDetails) {
          List<String> separatedValues = detail.split(' ');
          nestedPrizeDetails.add(separatedValues);
        }

// log(nestedPrizeDetails.toString());
        // log(cleanedPrizeDetails.toString());

        int foundIndex = -1;

        for (int i = 0; i < nestedPrizeDetails.length; i++) {
          List<String> innerList = nestedPrizeDetails[i];

          if (innerList.contains(enteredCode.replaceAll(' ', ''))) {
            foundIndex = i;
            final prizeInfoDoc = await FirebaseFirestore.instance
                .collection('PrizeInfos')
                .doc(doc.id)
                .get();
            if (prizeInfoDoc.exists) {
              final prizeInfoDetails =
                  List<String>.from(prizeInfoDoc['prize_details']);
              if (foundIndex < prizeInfoDetails.length) {
                final correspondingPrize = prizeInfoDetails[foundIndex];

                debugPrint(
                    "Found prize: $correspondingPrize, Code: $enteredCode");

                _confettiController.play();

                showDialog(
                  context: context,
                  builder: (context) => Stack(
                    alignment: Alignment.center,
                    children: [
                      AlertDialog(
                        title: Text("Congratulations!"),
                        content: Text(
                          "$correspondingPrize\nCode: ${enteredCode.replaceAll(' ', '')}",
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
                return; // Exit the function since we found a prize
              }
            }

            break; // Exit the loop once the number is found
          }
        }

        if (foundIndex != -1) {
          log('Number $enteredCode found in nested list at index $foundIndex');
        } else {
          log('Number $enteredCode not found in nested list');
        }
      }

      if (!prizeFound) {
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
      }
    } catch (e) {
      debugPrint("Error searching for lottery: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while searching for the lottery'),
          backgroundColor: Colors.red,
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
          bottom: isKeyboardOpen
              ? MediaQuery.of(context).viewInsets.bottom + 16
              : 16,
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
                  foregroundColor: Colors.white,
                  backgroundColor: Color.fromARGB(255, 23, 13, 133),
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
