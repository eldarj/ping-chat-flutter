import 'package:flutter/material.dart';

class TopPaneComponent {
  static Widget build(Widget child) {
    return Container(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                    padding: EdgeInsets.all(40),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(25),
                            bottomLeft: Radius.circular(25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 15.0, // soften the shadow
                            spreadRadius: 1.0, //extend the shadow
                          )
                        ]),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(child: child)
                      ],
                    )
                ),
              ),
              Expanded(
                flex: 1,
                child: Container(
                    margin: EdgeInsets.all(15),
                    child: Text('Experiencing any issues? Please ping us at support@ping.me',
                        style: TextStyle(
                            fontWeight: FontWeight.w300,
                            color: Colors.grey.shade600,
                            fontSize: 13)
                    )
                ),
              )
            ]));
  }
}
