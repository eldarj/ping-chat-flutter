import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class InfoComponent extends StatelessWidget {
  final String text;

  final String imagePath;
  final IconData icon;

  final Function onButtonPressed;
  final String buttonLabel;

  final bool transparent;

  const InfoComponent(
      this.text,
      {
        Key key,
        this.imagePath,
        this.icon,
        this.buttonLabel,
        this.onButtonPressed,
        this.transparent = true
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
              ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Color.fromRGBO(255, 255, 255, transparent ? 0.5 : 0),
                    BlendMode.srcATop,
                  ),
                  child: iconWidget),
              Container(
                  margin: EdgeInsets.only(bottom: 20, top: 20),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  )),
              onButtonPressed != null ? TextButton(
                  onPressed: onButtonPressed,
                  style: TextButton.styleFrom(
                      elevation: 1,
                      minimumSize: Size(90, 40),
                      backgroundColor: CompanyColor.accentGreenDark
                  ),
                  child: Text(buttonLabel, style: TextStyle(color: Colors.white))
              ) : Container()
            ]),
      ),
    );
  }

  static errorPanda({ onButtonPressed, message = 'Something went wrong, please try again', buttonLabel = 'Try again' }) {
    return InfoComponent(message,
      imagePath: 'static/graphic/sticker/panda/panda7.png',
      onButtonPressed: onButtonPressed,
      buttonLabel: buttonLabel,
      transparent: false,
    );
  }

  static errorDonut({ onButtonPressed, message = 'Something went wrong, please try again', buttonLabel = 'Try again' }) {
    return InfoComponent(message,
      imagePath: 'static/graphic/sticker/coffee/coffee_014.webp',
      onButtonPressed: onButtonPressed,
      buttonLabel: buttonLabel,
      transparent: true,
    );
  }

  static errorHomer({ onButtonPressed, message = 'Something went wrong, please try again', buttonLabel = 'Try again' }) {
    return InfoComponent(message,
      imagePath: 'static/graphic/sticker/homer/homer012.webp',
      onButtonPressed: onButtonPressed,
      buttonLabel: buttonLabel,
      transparent: true,
    );
  }

  static noDataHomer({ text = 'No data to display' }) {
    return InfoComponent(text,
      imagePath: 'static/graphic/sticker/homer/homer012.webp',
    );
  }

  static noDataOwl({ text = 'No data to display' }) {
    return InfoComponent(text,
      imagePath: 'static/graphic/sticker/owl/FreeOwl_022.webp',
    );
  }

  static noDataStitch({ text = 'No data to display' }) {
    return InfoComponent(text,
      imagePath: 'static/graphic/sticker/stitch/stitch006.webp',
    );
  }
}
