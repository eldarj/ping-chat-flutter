import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class LinearProgressLoader {
  static Widget build(context) {
    return LinearProgressIndicator(
        backgroundColor: CompanyColor.bluePrimary,
        valueColor: new AlwaysStoppedAnimation<Color>(CompanyColor.blueAccent));
  }
}
