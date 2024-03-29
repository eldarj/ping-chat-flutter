import 'package:flutter/material.dart';

class MessageTheme {
  Color bubbleColor;
  Color textColor;
  Color statusLabelColor;
  Color seenIconColor;

  Color descriptionColor;
  Color iconColor;

  MessageTheme(this.bubbleColor, this.seenIconColor, {
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    descriptionColor,
    statusLabelColor
  }) {
    this.descriptionColor = descriptionColor ?? Colors.grey.shade600;
    this.statusLabelColor = statusLabelColor ?? Colors.grey.shade100;
  }
}

class CompanyColor {
  static Map<Color, MessageTheme> messageThemes = {
    CompanyColor.myMessageBackground: MessageTheme(CompanyColor.myMessageBackground, Colors.green, textColor: Colors.grey.shade800, statusLabelColor: Colors.grey.shade500, descriptionColor: Colors.grey.shade500, iconColor: CompanyColor.accentGreenLight),
    CompanyColor.blueDark: MessageTheme(CompanyColor.blueDark, Color.fromRGBO(28, 236, 257, 1), textColor: Colors.white, statusLabelColor: Colors.grey.shade100, descriptionColor: Colors.grey.shade300, iconColor: Color.fromRGBO(21, 146, 177, 1)),
    Color(0xff536dfe): MessageTheme(Colors.indigoAccent, Color.fromRGBO(28, 236, 257, 1), textColor: Colors.white, statusLabelColor: Colors.grey.shade300, descriptionColor: Colors.grey.shade300, iconColor: Colors.indigo),
    Color(0xffff5722): MessageTheme(Colors.deepOrange, Color.fromRGBO(255, 200, 0, 1), textColor: Colors.white, statusLabelColor: Colors.grey.shade100, descriptionColor: Colors.grey.shade300, iconColor: Colors.red),
    CompanyColor.accentGreenDark: MessageTheme(CompanyColor.accentGreenDark, Colors.green, textColor: Colors.white, statusLabelColor: Colors.grey.shade100, descriptionColor: Colors.grey.shade300, iconColor: CompanyColor.accentGreenDarker),
    CompanyColor.accentPurpleLight: MessageTheme(CompanyColor.accentPurpleLight, Colors.green, textColor: Colors.white, statusLabelColor: Colors.grey.shade100, descriptionColor: Colors.grey.shade300, iconColor: CompanyColor.accentPurple),
    CompanyColor.accentPurple: MessageTheme(CompanyColor.accentPurple, Colors.green, textColor: Colors.white, statusLabelColor: Colors.grey.shade100, descriptionColor: Colors.grey.shade300, iconColor: CompanyColor.accentPurpleLight)
  };

  static Color blueLight = Color.fromRGBO(162, 226, 243, 1); // #A2ECF3
  static Color blueAccent = Color.fromRGBO(37, 218, 227, 1); // #25E4E3
  static Color bluePrimary = Color.fromRGBO(38, 197, 221, 1); // #26CFDD
  static const Color blueDark = Color.fromRGBO(28, 166, 197, 1); //// #63CFD9
  // Material alt
  static const MaterialColor blueDarkMaterial = const MaterialColor(
      0xFF1CA6C5,
      {
        50:Color.fromRGBO(28, 166, 197, .1),
        100:Color.fromRGBO(28, 166, 197, .2),
        200:Color.fromRGBO(28, 166, 197, .3),
        300:Color.fromRGBO(28, 166, 197, .4),
        400:Color.fromRGBO(28, 166, 197, .5),
        500:Color.fromRGBO(28, 166, 197, .6),
        600:Color.fromRGBO(28, 166, 197, .7),
        700:Color.fromRGBO(28, 166, 197, .8),
        800:Color.fromRGBO(28, 166, 197, .9),
        900:Color.fromRGBO(28, 166, 197, 1),
      });

  static const Color blueDarker = Color.fromRGBO(21, 146, 177, 1); //// #63CFD9

  static Color accentGreenLight = Color(0xff1bb29f);
  static Color accentGreen = Color.fromRGBO(0, 102, 116, 1);
  static Color accentGreenDark = Color.fromRGBO(47, 72, 88, 1);
  static Color accentGreenDarker = Color.fromRGBO(27, 52, 64, 1);

  static Color accentPurpleLight = Color.fromRGBO(97, 82, 157, 1);
  static Color accentPurple = Color.fromRGBO(79, 69, 110, 1);
  static Color accentPurpleDark = Color.fromRGBO(63, 58, 96, 1);

  static Color red = Color.fromRGBO(231, 76, 60, 1);
  static Color redAccent = Color.fromRGBO(241, 86, 80, 1);
  static Color green = Colors.green.shade400;

  static Color grey = Colors.grey;

  static Color iconGrey = Colors.grey.shade700;

  static Color backgroundGrey = Colors.grey.shade100;

  // Component colors
  static Color myMessageBackground = Color.fromRGBO(235, 255, 220, 1);
  static Color myMessageBorder = Color.fromRGBO(230, 245, 230, 1);

  static String toHexString(Color color) {
    return '#ff${color.value.toRadixString(16).substring(2, 8)}';
  }

  static Color fromHexString(String hex) {
    hex = hex.toUpperCase().replaceAll("#", "");

    if (hex.length == 6) {
      hex = "ff" + hex;
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
