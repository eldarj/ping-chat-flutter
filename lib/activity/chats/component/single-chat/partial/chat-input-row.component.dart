

import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:functional_widget_annotation/functional_widget_annotation.dart' show swidget;

part 'chat-input-row.component.g.dart';

@swidget
Widget singleChatInputRow(inputTextController, inputTextFocusNode, displayStickers, displaySendButton, doSendMessage, onOpenShareBottomSheet, onOpenStickerBar) {
  return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [Shadows.topShadow()],
      ),
      width: DEVICE_MEDIA_SIZE.width,
      child: Row(children: [
        Container(
          child: GestureDetector(
            onTap: onOpenStickerBar,
            child: Container(
              height: 35, width: 50,
              child: !displayStickers
                  ? Image.asset('static/graphic/icon/sticker.png', color: CompanyColor.blueDark)
                  : Icon(Icons.keyboard_arrow_down, color: CompanyColor.blueDark),
            ),
          ),
        ),
        Container(constraints: BoxConstraints(maxWidth: DEVICE_MEDIA_SIZE.width - 210),
          child: TextField(
            textInputAction: TextInputAction.newline,
            minLines: 1,
            maxLines: 2,
            onSubmitted: (value) {
              inputTextController.text += "asd";
            },
            style: TextStyle(fontSize: 15.0),
            controller: inputTextController,
            focusNode: inputTextFocusNode,
            decoration: InputDecoration.collapsed(
              hintText: 'Vaša poruka...',
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        Container(
          child: IconButton(
            icon: Icon(Icons.attachment),
            onPressed: onOpenShareBottomSheet,
            color: CompanyColor.blueDark,
          ),
        ),
        Container(
          child: IconButton(
            icon: Icon(Icons.photo_camera),
            onPressed: () {},
            color: CompanyColor.blueDark,
          ),
        ),
        displaySendButton ? Container(
            margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
            height: 45, width: 45,
            decoration: BoxDecoration(
              color: CompanyColor.blueDark,
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: Icon(Icons.send),
              iconSize: 18,
              onPressed: doSendMessage,
              color: Colors.white,
            )
        ) :
        Container(
            margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
            height: 45, width: 45,
            decoration: BoxDecoration(
              color: CompanyColor.blueDark,
              borderRadius: BorderRadius.circular(50),
            ),
            child: IconButton(
              icon: Icon(Icons.mic),
              iconSize: 18,
              onPressed: () {},
              color: Colors.white,
            )
        ),
      ]));
}
