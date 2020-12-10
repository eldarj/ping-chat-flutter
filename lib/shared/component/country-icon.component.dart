
import 'dart:wasm';

import 'package:flutter/cupertino.dart';

class CountryIconComponent {
  static const iconRouter = {
    'Bosna i Hercegovina': 'static/graphic/flag/bih-flag.png',
    'Srbija': 'static/graphic/flag/serbia-flag.png',
  };

  static Widget buildCountryIcon(countryName, {double height: 30, double width: 30}) {
    return Container(
        child: Image.asset(iconRouter[countryName], height: height, width: width)
    );
  }
}
