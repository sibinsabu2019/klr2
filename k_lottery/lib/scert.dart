import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'home.dart';

class Result with ChangeNotifier {


  Map<String,dynamic>Languages={};
  LotteryResultData? data; // Make data nullable
  bool isLoading = false;
   String selectedtittle="";
   
    Title(String title)
   {
      selectedtittle=title;
      notifyListeners();
   }
     Future<void> FetchLang(String language) async {
  log("Fetching data for language: $language");
  
  try {
    DocumentSnapshot testDocument = await FirebaseFirestore.instance.collection("Languages").doc(language).get();
    
    if (testDocument.exists) {
      log("Document found. Trying to fetch document: ${FirebaseFirestore.instance.collection("Languages").doc(language).path}");
      
      // Only clear when you have successfully fetched the data
      

      Map<String, dynamic>? fetchedData = testDocument.data() as Map<String, dynamic>?;
      
      if (fetchedData != null) {
        Languages = fetchedData;
        notifyListeners();
        log("Fetched Languages: ${Languages.toString()}");
      } else {
        log("Document has no data.");
      }
    } else {
      log("Document does not exist.");
    }
  } on FirebaseException catch (ex) {
    log("Error fetching data: ${ex.message}");
  }
}


  Future<void> reloadData(String drawCode) async {
    isLoading = true;
    notifyListeners();
    print(drawCode);
    print("Reloading data...");

    data = await getResult(drawCode);
    isLoading = false;
    notifyListeners();
  }

  Future<LotteryResultData?> getResult(String drawCode) async {
    print("Fetching data...");
    try {
      print(drawCode);
      DocumentSnapshot prizeDetailDocument = await FirebaseFirestore.instance
          .collection('PrizeDetails')
          .doc(drawCode)
          .get();

      DocumentSnapshot prizeInfoDocument = await FirebaseFirestore.instance
          .collection('PrizeInfos')
          .doc(drawCode)
          .get();

      if (prizeDetailDocument.exists && prizeInfoDocument.exists) {
        Map<String, dynamic> prizeDetailsData = prizeDetailDocument.data() as Map<String, dynamic>;
        List<String> prizeDetails = (prizeDetailsData['prize_details'] as List)
            .map<String>((e) => e.toString())
            .toList();

        Map<String, dynamic> prizeInfosData = prizeInfoDocument.data() as Map<String, dynamic>;
        List<String> prizeInfo = (prizeInfosData['prize_details'] as List)
            .map<String>((e) => e.toString())
            .toList();

        return LotteryResultData(
          prizeDetails: prizeInfo.where((e) => e != 'nill').toList(),
          prizeInfo: prizeDetails.where((e) => e != 'nill').toList(),
        );
      } else {
        print('Document does not exist');
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}
