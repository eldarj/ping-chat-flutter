import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum LogoOrientation {
  horizontal,
  vertical
}
class LogoComponent {
  static Container build({
    LogoOrientation orientation = LogoOrientation.horizontal,
    double imageHeight = 55,
    double fontSize = 35,
    Color textColor = Colors.black87,
    bool whiteFace = false,
    bool displayText = true,
    bool textShadows = false
  }) {
    var widgets = buildWidgets(imageHeight, fontSize, textColor, whiteFace, displayText, textShadows);
    return Container(
        child: orientation == LogoOrientation.horizontal
            ? Row(children: <Widget>[...widgets]) : Column(children: <Widget>[...widgets])
    );
  }

  static List<Widget> buildWidgets(double imageHeight, double fontSize, Color textColor, whiteFace, displayText, bool textShadows) {
    return [
      Container(margin: EdgeInsets.only(right: 10), child: Image(
          image: AssetImage(whiteFace ? 'static/graphic/logo/ping-logo-white.png'
              : 'static/graphic/logo/ping-logo.png'),
          height: imageHeight, width: imageHeight)),
      Text(displayText ? 'Ping' : '',
          style: new TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
              shadows: textShadows ? [ Shadow(
                  color: Colors.black.withOpacity(0.2),
                  offset: Offset(1, 1),
                  blurRadius: 10
              )] : []
          ))
    ];
  }
}
