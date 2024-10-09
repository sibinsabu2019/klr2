// lib/models.dart
import 'package:flutter/material.dart';

class LotteryResultInfo {
  final String id;
  final String lotteryName;
  final String serialNumber;
  final String drawDate;

  const LotteryResultInfo({
    required this.drawDate,
    required this.id,
    required this.lotteryName,
    required this.serialNumber,
  });

  @override
  String toString() {
    return '$id\n$lotteryName\n$serialNumber\n$drawDate';
  }
}
