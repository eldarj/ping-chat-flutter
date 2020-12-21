import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

BoxDecoration imageDecoration() => BoxDecoration(
  border: Border.all(color: Colors.grey.shade300),
  borderRadius: BorderRadius.circular(15),
);

BoxDecoration peerTextBoxDecoration() => BoxDecoration(
  color: Color.fromRGBO(239, 239, 239, 1),
  border: Border.all(color: Color.fromRGBO(230, 230, 230, 1), width: 1),
  borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(10),
      topRight: Radius.circular(10),
      bottomRight: Radius.circular(10)),
  boxShadow: [BoxShadow(color: Colors.grey.shade400,
    offset: Offset.fromDirection(1, 1),
    blurRadius: 0, spreadRadius: 0,
  )],
);

BoxDecoration myTextBoxDecoration() => BoxDecoration(
  color: CompanyColor.myMessageBackground,
  border: Border.all(color: Color.fromRGBO(220, 245, 205, 1), width: 1),
  borderRadius: BorderRadius.only(
      topLeft: Radius.circular(10),
      bottomLeft: Radius.circular(10),
      bottomRight: Radius.circular(15)),
  boxShadow: [BoxShadow(color: Colors.grey.shade400,
    offset: Offset.fromDirection(1, 1),
    blurRadius: 0, spreadRadius: 0,
  )],
);

BoxDecoration stickerBoxDecoration() => BoxDecoration(color: Colors.transparent);
