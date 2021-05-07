import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

BoxDecoration imageDecoration(pinned, {isPeerMessage = true}) => BoxDecoration(
  color: isPeerMessage ? Color.fromRGBO(239, 239, 239, 1) : CompanyColor.myMessageBackground,
  borderRadius: BorderRadius.circular(15),
  border: Border.all(
      color: pinned != null && pinned
          ? CompanyColor.blueAccent
          : Color.fromRGBO(230, 230, 230, 1),
      width: pinned != null && pinned ? 1.5 : 1
  )
);

BoxDecoration peerTextBoxDecoration(pinned) => BoxDecoration(
  color: Color.fromRGBO(239, 239, 239, 1),
  border: Border.all(
      color: pinned != null && pinned
          ? CompanyColor.blueAccent
          : Color.fromRGBO(230, 230, 230, 1),
      width: pinned != null && pinned ? 1.5 : 1
  ),
  borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(10),
      topRight: Radius.circular(10),
      bottomRight: Radius.circular(10)),
  boxShadow: [BoxShadow(color: Colors.grey.shade200,
    offset: Offset.fromDirection(1, 0.7),
    blurRadius: 0, spreadRadius: 0,
  )],
);

BoxDecoration myTextBoxDecoration(pinned) => BoxDecoration(
  color: CompanyColor.myMessageBackground,
  border: Border.all(
      color: pinned != null && pinned
          ? CompanyColor.blueAccent
          : Color.fromRGBO(220, 245, 205, 1),
      width: pinned != null && pinned ? 1.5 : 1
  ),
  borderRadius: BorderRadius.only( //63731484
      topLeft: Radius.circular(10),
      bottomLeft: Radius.circular(10),
      bottomRight: Radius.circular(15)),
  boxShadow: [BoxShadow(color: Colors.grey.shade200,
    offset: Offset.fromDirection(1, 0.7),
    blurRadius: 0, spreadRadius: 0,
  )],
);

BoxDecoration stickerBoxDecoration() => BoxDecoration(color: Colors.transparent);
