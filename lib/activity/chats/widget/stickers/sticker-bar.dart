

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/persistence/sticker.prefs.service.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/var/global.var.dart';

class StickerBar extends StatefulWidget {
  final ClientDto peer;

  final String myContactName;

  final String peerContactName;

  final int contactBindingId;

  final Function(String) sendFunc;

  const StickerBar({Key key, this.peer, this.myContactName, this.peerContactName, this.contactBindingId, this.sendFunc}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StickerBarState();
}

class StickerBarState extends State<StickerBar> {
  StickerService stickerService = new StickerService();

  int selectedIndex = 0;

  Map stickersMap = {
    0: {},
    1: {
      0: ['panda1.png','panda2.png','panda3.png','panda4.png','panda5.png'],
      1: ['panda6.png','panda7.png','panda8.png','panda9.png','panda10.png'],
      2: ['panda11.png','panda12.png','panda13.png','panda14.png'],
    },
    2: {
      0: ['mimi1.gif', 'mimi2.gif', 'mimi4.gif', 'mimi5.gif', 'mimi6.gif'],
      1: ['mimi7.gif', 'mimi8.gif', 'mimi9.gif']
    },
    3: {
      0: ['stitch1.png','stitch2.png','stitch3.png','stitch4.png','stitch5.png',],
      1: ['stitch6.png','stitch7.png','stitch8.png','stitch9.png','stitch10.png',],
      2: ['stitch11.png',],
    },
  };

  loadRecentStickers() async {
    var recentStickers = await stickerService.loadRecent();
  }

  @override
  initState() {
    super.initState();
    loadRecentStickers();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        buildStickerGrid(),
        buildToolbar()
      ],
    );
  }

  buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(children: [
        buildToolbarButton(index: 0, icon: Icons.access_time),
        buildToolbarButton(index: 1, image: 'panda0.ico', size: 30),
        buildToolbarButton(index: 2, image: 'mimi0.jpg', size: 45),
        buildToolbarButton(index: 3, image: 'stitch1.png', size: 55),
      ]),
    );
  }

  Widget buildToolbarButton({index, icon, image, double size}) {
    var ch;
    if (icon != null) {
      ch = Icon(icon);
    } else {
      ch = Image.asset('static/graphic/sticker/' + image);
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
          width: 70, height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              border: Border.all(color: selectedIndex == index ? CompanyColor.bluePrimary : Colors.grey.shade200)
          ),
          child: Container(
              width: size, height: size,
              child: ch
          )
      ),
    );
  }

  buildStickerGrid() {
    double stickerSize = (MediaQuery.of(context).size.width / 5) - 15;
    var stickers = stickersMap[selectedIndex];
    return Container(
      child: ListView(
        children: <Widget>[
          ...stickers.entries.map((mapEntry) {
            return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              ...mapEntry.value.map((stickerName) {
                return GestureDetector(
                  onTap: () {
                    widget.sendFunc(stickerName);
                  },
                  child: Container(
                      width: stickerSize, height: stickerSize,
                      margin: EdgeInsets.all(5),
                      child: Image.asset('static/graphic/sticker/' + stickerName)),
                );
              }).toList()
            ]);
          }).toList()
        ],
      ),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5))),
      padding: EdgeInsets.only(left: 5, right: 5, top: 15, bottom: 15),
      height: 180.0,
    );
  }
}
