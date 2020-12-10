import 'package:flutter/material.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';

class ActivityLoader {
  static Center build() {
    return Center(
      child: Spinner(),
    );
  }
}
