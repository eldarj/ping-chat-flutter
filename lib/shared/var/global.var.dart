import 'package:flutter/material.dart';

class MessageTheme {
  Color bubbleColor;
  Color textColor;
  Color statusLabelColor;
  Color seenIconColor;

  MessageTheme(this.bubbleColor, this.seenIconColor, {
    this.textColor = Colors.white,
    statusLabelColor
  }) {
    this.statusLabelColor = statusLabelColor ?? Colors.grey.shade100;
  }
}

class CompanyColor {
  static Map<Color, MessageTheme> messageThemes = {
    CompanyColor.myMessageBackground: MessageTheme(CompanyColor.myMessageBackground, Colors.green, textColor: Colors.grey.shade800, statusLabelColor: Colors.grey.shade500),
    CompanyColor.blueDark: MessageTheme(CompanyColor.blueDark, Color.fromRGBO(28, 236, 257, 1), textColor: Colors.white, statusLabelColor: Colors.grey.shade100),
    Colors.indigoAccent: MessageTheme(Colors.indigoAccent, Color.fromRGBO(28, 236, 257, 1), textColor: Colors.white, statusLabelColor: Colors.grey.shade300),
    Colors.deepOrange: MessageTheme(Colors.deepOrange, Color.fromRGBO(255, 200, 0, 1), textColor: Colors.white, statusLabelColor: Colors.grey.shade100),
    CompanyColor.accentGreenDark: MessageTheme(CompanyColor.accentGreenDark, Colors.green, textColor: Colors.white, statusLabelColor: Colors.grey.shade100),
    CompanyColor.accentPurpleLight: MessageTheme(CompanyColor.accentPurpleLight, Colors.green, textColor: Colors.white, statusLabelColor: Colors.grey.shade100),
    CompanyColor.accentPurple: MessageTheme(CompanyColor.accentPurple, Colors.green, textColor: Colors.white, statusLabelColor: Colors.grey.shade100)
  };

  static Color blueLight = Color.fromRGBO(162, 226, 243, 1); // #A2ECF3
  static Color blueAccent = Color.fromRGBO(37, 218, 227, 1); // #25E4E3
  static Color bluePrimary = Color.fromRGBO(38, 197, 221, 1); // #26CFDD
  static const Color blueDark = Color.fromRGBO(28, 166, 197, 1); //// #63CFD9

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

  static String toHexString(Color color) {
    return '#FF${color.value.toRadixString(16).substring(2, 8)}';
  }

  static Color fromHexString(String hex) {
    hex = hex.toUpperCase().replaceAll("#", "");

    if (hex.length == 6) {
      hex = "FF" + hex;
    }

    return Color(int.parse(hex, radix: 16));
  }

  static Brightness getBrightness(Color myChatBubbleColor) {
    Brightness brightness = Brightness.light;

    if (myChatBubbleColor != null) {
      brightness = ThemeData.estimateBrightnessForColor(myChatBubbleColor);
    }

    return brightness;
  }

  // static Color getTextColor(Color chatBubbleColor) {
  //   return textColorByBubble[chatBubbleColor];
  // }
}

class Shadows {
  static topShadow(
      {color: Colors.black12, double blurRadius: 1, double spreadRadius: 0, double topDistance: 0.7}) {
    return BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: Offset.fromDirection(4.7, topDistance));
  }

  static bottomShadow(
      {color: Colors.black12, double blurRadius: 1, double spreadRadius: 0, double topDistance: 0.7}) {
    return BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: Offset.fromDirection(1, topDistance));
  }

  static base(
      {color: Colors.black12, double blurRadius: 5, double spreadRadius: 5 }) {
    return BoxShadow(
        color: color,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius
    );
  }
}
