import 'package:flutter/cupertino.dart';

class CountryIconComponent {
  static const iconRouter = {
    'Bosnia and Herzegovina': 'static/graphic/flag/bosnia.png',
    'Serbia': 'static/graphic/flag/serbia.png',
    'Croatia': 'static/graphic/flag/croatia.png',
    'Switzerland': 'static/graphic/flag/switzerland.png',
    'Germany': 'static/graphic/flag/germany.png',
    'Slovenia': 'static/graphic/flag/slovenia.png',
  };

  static Widget buildCountryIcon(countryName, {double height: 30, double width: 30}) {
    return Container(
        child: Image.asset(iconRouter[countryName], height: height, width: width)
    );
  }
}
