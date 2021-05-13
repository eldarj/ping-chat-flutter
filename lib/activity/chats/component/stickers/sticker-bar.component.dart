import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/persistence/sticker.prefs.service.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';

class StickerBar extends StatefulWidget {
  final Function(String) sendFunc;

  const StickerBar({Key key, this.sendFunc}) : super(key: key);

  @override
  State<StatefulWidget> createState() => StickerBarState();
}

class StickerBarState extends State<StickerBar> {
  StickerService stickerService = new StickerService();

  int selectedIndex = 1;

  Map recentStickers;

  bool loadingRecent = true;

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
      1: ['stitch6.png','stitch8.png','stitch11.png','stitch10.png',],
    },
    4: {
      0: ['emoti-1.png','emoti-2.png','emoti-3.png','emoti-4.png','emoti-5.png'],
      1: ['emoti-8.png', 'emoti-7.png', 'emoti-6.png', 'fit-1.png']
    }
  };

  loadRecentStickers() async {
    recentStickers = await stickerService.loadRecent();
    setState(() {
      loadingRecent = false;
    });
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
        buildToolbarButton(index: 4, icon: Icons.sentiment_very_satisfied),
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
    if (selectedIndex == 0) {
      return !loadingRecent ? _buildStickers(recentStickers)
          : Container(margin: EdgeInsets.all(20), child: Spinner());
    } else {
      return _buildStickers(stickersMap[selectedIndex]);
    }
  }

  _buildStickers(stickers) {
    double stickerSize = (MediaQuery.of(context).size.width / 5) - 15;

    return Container(
      child: stickers.length > 0 ? ListView(
        children: [
          ...stickers.entries.map((mapEntry) {
            return Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              ...mapEntry.value.map((stickerName) {
                return GestureDetector(
                  onTap: () async {
                    recentStickers = await stickerService.addRecent(stickerName);
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
      ) : Text('No stickers to display', style: TextStyle(color: Colors.grey.shade400)),
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 0.5))),
      padding: EdgeInsets.only(left: 5, right: 5, top: 0, bottom: 0),
      height: 180.0,
    );
  }
}
