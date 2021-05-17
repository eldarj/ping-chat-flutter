import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

const double MESSAGE_BUBBLE_RADIUS = 15;
const double MESSAGE_REPLY_RADIUS = 10;
const double IMAGE_BUBBLE_RADIUS = 10;

BoxDecoration imageDecoration(pinned, {displayBubble = true, myMessageBackground}) => BoxDecoration(
  color: myMessageBackground ?? CompanyColor.myMessageBackground,
  borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(IMAGE_BUBBLE_RADIUS),
      bottomRight: Radius.circular(displayBubble ? IMAGE_BUBBLE_RADIUS : 5),
      topLeft: Radius.circular(IMAGE_BUBBLE_RADIUS),
      topRight: Radius.circular(0),
  ),
  boxShadow: [
    Shadows.bottomShadow(color: Colors.black54, blurRadius: 0, topDistance: 0)
  ]
);

BoxDecoration peerImageDecoration(pinned, {displayBubble = true, myMessageBackground}) => BoxDecoration(
    color: Color.fromRGBO(239, 239, 239, 1),
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(displayBubble ? IMAGE_BUBBLE_RADIUS : 5),
      bottomRight: Radius.circular(IMAGE_BUBBLE_RADIUS),
      topLeft: Radius.circular(0),
      topRight: Radius.circular(IMAGE_BUBBLE_RADIUS),
    ),
    boxShadow: [
      Shadows.bottomShadow(color: Colors.black54, blurRadius: 0, topDistance: 0)
    ]
);

BoxDecoration peerTextBoxDecoration({ displayBubble = true }) => BoxDecoration(
  color: Color.fromRGBO(243, 243, 245, 1),
  borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(displayBubble ? MESSAGE_BUBBLE_RADIUS : 5),
      topRight: Radius.circular(MESSAGE_BUBBLE_RADIUS),
      bottomRight: Radius.circular(MESSAGE_BUBBLE_RADIUS)),
);

BoxDecoration myTextBoxDecoration({ myMessageBackground, displayBubble = true }) => BoxDecoration(
  color: myMessageBackground ?? CompanyColor.myMessageBackground,
  borderRadius: BorderRadius.only(
      topLeft: Radius.circular(MESSAGE_BUBBLE_RADIUS),
      bottomLeft: Radius.circular(MESSAGE_BUBBLE_RADIUS),
      bottomRight: Radius.circular(displayBubble ? MESSAGE_BUBBLE_RADIUS : 5)),
);

BoxDecoration stickerBoxDecoration() => BoxDecoration(color: Colors.transparent);

BoxDecoration gifBoxDecoration(pinned, { isPeerMessage = false, myMessageBackground }) => BoxDecoration(
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(IMAGE_BUBBLE_RADIUS),
      bottomRight: Radius.circular(IMAGE_BUBBLE_RADIUS),
      topLeft: Radius.circular(isPeerMessage ? 0 : IMAGE_BUBBLE_RADIUS),
      topRight: Radius.circular(!isPeerMessage ? 0 : IMAGE_BUBBLE_RADIUS),
    ),
    boxShadow: [
      Shadows.bottomShadow(color: Colors.black54, blurRadius: 0, topDistance: 0)
    ]
);
