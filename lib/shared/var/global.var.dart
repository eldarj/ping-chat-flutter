import 'package:flutter/material.dart';

class CompanyColor {
  static Color blueLight = Color.fromRGBO(162, 226, 243, 1); // #A2ECF3
  static Color blueAccent = Color.fromRGBO(37, 218, 227, 1); // #25E4E3
  static Color bluePrimary = Color.fromRGBO(38, 197, 221, 1); // #26CFDD
  static Color blueDark = Color.fromRGBO(28, 166, 197, 1); // #63CFD9

  static Color accentGreen = Color.fromRGBO(0, 102, 116, 1);
  static Color accentGreenLight = Color(0xff1bb29f);
  static Color accentGreenDark = Color.fromRGBO(47, 72, 88, 1);

  static Color red = Color.fromRGBO(231, 76, 60, 1);
  static Color green = Colors.green.shade400;
}

class Shadows {
  static topShadow(
      {color: const Color(0xFFE0E0E0), double blurRadius: 2, double spreadRadius: 0, double topDistance: 1}) {
    return BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: Offset.fromDirection(4.7, topDistance));
  }
}
