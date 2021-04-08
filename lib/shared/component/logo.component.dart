import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LogoComponent {
  static Container logo = Container(
      margin: EdgeInsets.only(right: 10),
      child: Image(image: AssetImage('static/graphic/logo/ping-logo.png'),
          height: 55, width: 55)
  );

  static Container vertical = Container(
      child: Column(children: [
        logo,
        Text('Ping', style: new TextStyle(
            color: Colors.black87,
            fontSize: 50,
            fontWeight: FontWeight.bold
        ))
      ])
  );

  static Container horizontal = Container(
      child: Row(children: [
        logo,
        Text('Ping', style: new TextStyle(
            color: Colors.black87,
            fontSize: 50,
            fontWeight: FontWeight.bold
        ))
      ])
  );
}
