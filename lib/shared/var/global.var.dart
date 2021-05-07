import 'package:flutter/material.dart';

class CompanyColor {
  static Color blueLight = Color.fromRGBO(162, 226, 243, 1); // #A2ECF3
  static Color blueAccent = Color.fromRGBO(37, 218, 227, 1); // #25E4E3
  static Color bluePrimary = Color.fromRGBO(38, 197, 221, 1); // #26CFDD
  static const Color blueDark = Color.fromRGBO(28, 166, 197, 1); // #63CFD9

  static Color accentGreenLight = Color(0xff1bb29f);
  static Color accentGreen = Color.fromRGBO(0, 102, 116, 1);
  static Color accentGreenDark = Color.fromRGBO(47, 72, 88, 1);

  static Color accentPurpleLight = Color.fromRGBO(97, 82, 157, 1);
  static Color accentPurple = Color.fromRGBO(79, 69, 110, 1);
  static Color accentPurpleDark = Color.fromRGBO(63, 58, 96, 1);

  static Color red = Color.fromRGBO(231, 76, 60, 1);
  static Color green = Colors.green.shade400;

  static Color grey = Colors.grey;

  static Color iconGrey = Colors.grey.shade700;

  static Color backgroundGrey = Colors.grey.shade100;

  // Component colors
  static Color myMessageBackground = Color.fromRGBO(235, 255, 220, 1);
  static Color myMessageBorder = Color.fromRGBO(230, 245, 230, 1);
}

class Shadows {
  static topShadow(
      {color: const Color(0xFFE9E9E9), double blurRadius: 1, double spreadRadius: 0, double topDistance: 0.7}) {
    return BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: Offset.fromDirection(4.7, topDistance));
  }

  static bottomShadow(
      {color: const Color(0xFFE9E9E9), double blurRadius: 1, double spreadRadius: 0, double topDistance: 0.7}) {
    return BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: Offset.fromDirection(1, topDistance));
  }

  static base(
      {color: const Color(0xFFE0E0E0), double blurRadius: 5, double spreadRadius: 5 }) {
    return BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius
    );
  }
}
