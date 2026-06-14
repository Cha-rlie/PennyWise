import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReadingStreams {
  // Singleton instance
  static ReadingStreams? _instance;

  late final String userId;
  final _firestore = FirebaseFirestore.instance;
  // Flag to stop going straight to MainApp Page right after authentication
  // This is a problem because it skips loading the data correctly into Firestore
  static final ValueNotifier<bool> isPostAuthDataComplete = ValueNotifier(false);

  // Singleton pattern implementation where this constructor is private to this file only
  ReadingStreams._(String userId) {this.userId = userId;}

  static void initialize(String userId) {
    _instance = ReadingStreams._(userId);
  }

  static ReadingStreams getInstance() {
    return _instance!;
  }

  // To be called when user logs out to prevent memory leaks and unintended data access across users
  static void dispose() {
    _instance = null;
  }

  // All the streams that the app will listen to for real-time updates from Firebase Firestore
  late final Stream<DocumentSnapshot> publicUserStream = _firestore.collection("public-users").doc(userId).snapshots().asBroadcastStream();
  late final Stream<DocumentSnapshot> privateUserStream = _firestore.collection("private-users").doc(userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> debtsOwedStream = _firestore.collection("debts").where("owedTo", isEqualTo: userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> debtsOwingStream = _firestore.collection("debts").where("owedBy", isEqualTo: userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> expensesStream = _firestore.collection("expenses").where("participants", arrayContains: userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> friendshipsStream = _firestore.collection("friendships").where("members", arrayContains: userId).snapshots().asBroadcastStream();
  late final Stream<QuerySnapshot> tripsStream = _firestore.collection("trips").where("participants", arrayContains: userId).snapshots().asBroadcastStream();

  // For currency conversion
  Map<String, double> _exchangeRates = {};
  String _ratesBaseCurrency = "USD";
  DateTime? _ratesFetchedAt;

  // Get the rates at the beginning of a session (user being authenticated)
  Future<void> initExchangeRates() async {
    // Do not get new conversion rates, if the last conversion rates were taken less than an hour ago
    if (_ratesFetchedAt != null && DateTime.now().difference(_ratesFetchedAt!) < Duration(hours: 1)) {
      return;
    }

    try {
      final response = await http.get(Uri.parse(
        "https://v6.exchangerate-api.com/v6/e76c864b854109da4a0a6959/latest/USD"
      ));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _exchangeRates = Map<String, double>.from(
          (data["conversion_rates"] as Map).map(
            (key, value) => MapEntry(key, (value as num).toDouble())
          )
        );
        _ratesFetchedAt = DateTime.now();
      }
    } catch (e) {
      debugPrint("Failed to fetch exchange rates: $e");
    }
  }

  double convertFromUSD(double amountUSD, String targetCurrency) {
    if (targetCurrency == "USD") return amountUSD;
    final rate = _exchangeRates[targetCurrency];
    if (rate == null) return amountUSD; // Failsafe in case rates could not be retrieved
    return amountUSD * rate;
  }
  
  double convertToUSD(double amount, String originalCurrency) {
    if (originalCurrency == "USD") return amount;
    final rate = _exchangeRates[originalCurrency];
    if (rate == null) return amount; // Failsafe in case rates could not be retrieved
    return amount * (1/rate);
  }

}