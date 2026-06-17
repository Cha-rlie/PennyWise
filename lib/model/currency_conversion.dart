import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

class CurrencyConversion {

  // Singleton instance
  static CurrencyConversion? _instance;

  // Singleton pattern implementation where this constructor is private to this file only
  CurrencyConversion._();

  static void initialize() {
    _instance = CurrencyConversion._();
  }

  static CurrencyConversion? getInstanceOrNull() {
    return _instance;
  }

  static CurrencyConversion getInstance() {
    return _instance!;
  }

  // To be called when user logs out to prevent memory leaks and unintended data access across users
  static void dispose() {
    _instance = null;
  }

  // For currency conversion
  Map<String, double> _exchangeRates = {};
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
    return;
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
    if (rate == null) {debugPrint("Rate null"); return amount;} // Failsafe in case rates could not be retrieved
    return amount * (1/rate);
  }
}