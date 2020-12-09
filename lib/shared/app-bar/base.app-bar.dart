
import 'package:flutter/material.dart';

class BaseAppBar {
  static getBase(ScaffoldState scaffold, leading, {
    titleWidget, titleText, actions
  }) {
    return AppBar(
        elevation: 0.0,
        centerTitle: true,
        backgroundColor: Colors.grey.shade200,
        leading: leading,
        title: titleText != null ? Text(titleText) : titleWidget,
        actions: actions);
  }
}
