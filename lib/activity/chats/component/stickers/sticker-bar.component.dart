import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/persistence/sticker.prefs.service.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';

class StickerBar extends StatefulWidget {
  final Function(String) sendFunc;

  final Function onClose;

  const StickerBar({
    Key key,
    this.sendFunc,
    this.onClose
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => StickerBarState();
}

class StickerBarState extends State<StickerBar> {
  StickerService stickerService = new StickerService();

  int selectedIndex = 1;

  bool loadingRecent = true;

  List recentStickers;

  Map stickersMap2 = {
    0: {},
    1: [
      'panda1.png','panda2.png','panda3.png','panda4.png','panda5.png',
      'panda6.png','panda7.png','panda8.png','panda9.png','panda10.png',
      'panda11.png','panda12.png','panda13.png','panda14.png'
    ],
    2: [
      'mimi1.gif', 'mimi2.gif', 'mimi4.gif', 'mimi5.gif', 'mimi6.gif',
      'mimi7.gif', 'mimi8.gif', 'mimi9.gif'
    ],
    3: [
      'stitch1.png','stitch2.png','stitch3.png','stitch4.png','stitch5.png',
      'stitch6.png','stitch8.png','stitch11.png','stitch10.png'
    ],
    4: [
      'emoti-1.png','emoti-2.png','emoti-3.png','emoti-4.png','emoti-5.png',
      'emoti-8.png', 'emoti-7.png', 'emoti-6.png', 'fit-1.png'
    ]
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
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildCloseButton(),
          buildStickerGrid(),
          buildToolbar()
        ],
      ),
    );
  }

  Widget buildCloseButton() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [Shadows.topShadow()]
      ),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: widget.onClose,
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CloseButton(onPressed: widget.onClose)
              ]),
        ),
      ),
    );
  }

  Widget buildToolbar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.white),
      ),
      child: Row(children: [
        buildToolbarButton(index: 0, icon: Icons.access_time),
        buildToolbarButton(index: 1, image: 'panda0.ico', size: 30),
        buildToolbarButton(index: 2, image: 'mimi0.jpg', size: 45),
        buildToolbarButton(index: 3, image: 'stitch1.png', size: 50),
        buildToolbarButton(index: 4, icon: Icons.sentiment_very_satisfied),
      ]),
    );
  }

  Widget buildToolbarButton({index, icon, image, double size}) {
    Widget w;

    if (icon != null) {
      w = Icon(icon);
    } else {
      w = Image.asset('static/graphic/sticker/' + image);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
          width: 70,
          height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              border: Border.all(color: selectedIndex == index ? CompanyColor.bluePrimary : Colors.grey.shade200)
          ),
          child: Container(
              width: size,
              height: size,
              child: w
          )
      ),
    );
  }

  Widget buildStickerGrid() {
    Widget w;

    if (selectedIndex == 0) {
      if (loadingRecent) {
        w = Container(margin: EdgeInsets.all(20), child: Spinner());
      } else {
        w = _buildStickerGrid(recentStickers);
      }
    } else {
      w = _buildStickerGrid(stickersMap2[selectedIndex]);
    }

    return w;
  }

  Widget _buildStickerGrid(List stickers) {
    Widget w = Center(child: Text('No stickers to display', style: TextStyle(color: Colors.grey.shade400)));

    if (stickers.length > 0) {
      w = GridView.builder(
        itemCount: stickers.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisSpacing: 2, mainAxisSpacing: 2, crossAxisCount: 5),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () async {
            recentStickers = await stickerService.addRecent(stickers[index]);
            widget.sendFunc(stickers[index]);
          },
          child: Container(
              child: Image.asset('static/graphic/sticker/' + stickers[index])),
        ),
      );
    }


    return Container(
      height: 180.0,
      child: w,
    );
  }
}
