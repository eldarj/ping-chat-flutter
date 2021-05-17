import 'package:flutter/material.dart';

class InfoComponent extends StatelessWidget {
  final String text;

  final String imagePath;
  final IconData icon;

  final Function onButtonPressed;
  final String buttonLabel;

  const InfoComponent(
      {
        Key key,
        this.text,
        this.imagePath,
        this.icon,
        this.buttonLabel,
        this.onButtonPressed,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget iconWidget = Container();

     if (imagePath != null) {
       iconWidget = Opacity(
           opacity: 0.8,
           child: Image.asset(imagePath, width: 150, height: 150));
     } else if (icon != null) {
       iconWidget = Icon(icon, color: Colors.grey, size: 60);

     }

    return Center(
      child: Container(
        width: 230,
        margin: EdgeInsets.only(bottom: 30),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              Container(
                  margin: EdgeInsets.only(bottom: 20, top: 10),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )),
              onButtonPressed != null ? FlatButton(color: Colors.red.shade400,
                  onPressed: onButtonPressed,
                  child: Text(buttonLabel, style: TextStyle(color: Colors.white))
              ) : Container()
            ]),
      ),
    );
  }

  static error(context, { onButtonPressed, buttonLabel }) {
    return InfoComponent(
      text: 'Something went wrong',
      imagePath: 'static/graphic/sticker/panda/panda7.png',
      onButtonPressed: onButtonPressed,
      buttonLabel: buttonLabel ?? 'Try again',
    ).build(context);
  }

  static noData2(context) {
    return InfoComponent(
      text: 'No data to display',
      imagePath: 'static/graphic/sticker/panda/panda7.png',
    );
  }
}
