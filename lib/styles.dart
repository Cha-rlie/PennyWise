import 'package:flutter/material.dart';
class Styles {
  // Colors
  static const Color primaryColor = Color(0xFFC4F1BE); // Tea Green
  static const Color accentColor = Color(0xFF05B384); // Mint Green
  static const Color backgroundColor = Color(0xFF132A3E); // Deep Space Blue
  static const Color lighterBackgroundColor = Color(0xFF26547D); // Dusk Blue
  static const Color negativeColor = Color(0xFFFF571F); // Tiger Flame
  static const Color red = Color(0xFFB3261E); // Maroon Red
  static const Color white = Color(0xFFFFFFFF); // White
  static const Color black = Color(0xFF000000); // Black

  // Text Styles
  static const TextStyle titleFont = TextStyle(
    fontFamily: 'InstrumentSans',
    fontSize: 60,
    fontWeight: FontWeight.bold,
    color: accentColor,
  );

  static const TextStyle subTitleFont = TextStyle(
    fontFamily: 'InstrumentSans',
    fontSize: 50,
    fontWeight: FontWeight.bold,
    color: accentColor,
  );

  static const TextStyle headingFont = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: white,
  );

  static const TextStyle textFont = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.normal,
    color: white,
  );

}