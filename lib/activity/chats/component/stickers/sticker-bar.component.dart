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

  ScrollController toolbarScrollController = new ScrollController();

  bool loadingRecent = true;

  List recentStickers;

  Map stickersMap2 = {
    0: {},
    1: [
      'panda/panda1.png','panda/panda2.png','panda/panda3.png','panda/panda4.png','panda/panda5.png',
      'panda/panda6.png','panda/panda7.png','panda/panda8.png','panda/panda9.png','panda/panda10.png',
      'panda/panda11.png','panda/panda12.png','panda/panda13.png','panda/panda14.png'
    ],
    2: [
      'stitch/stitch001.webp', 'stitch/stitch002.webp', 'stitch/stitch003.webp', 'stitch/stitch004.webp',
      'stitch/stitch005.webp', 'stitch/stitch006.webp', 'stitch/stitch007.webp', 'stitch/stitch008.webp',
      'stitch/stitch009.webp', 'stitch/stitch010.webp'
    ],
    3: [
      'owl/FreeOwl_002.webp', 'owl/FreeOwl_003.webp', 'owl/FreeOwl_004.webp', 'owl/FreeOwl_007.webp',
      'owl/FreeOwl_008.webp', 'owl/FreeOwl_009.webp', 'owl/FreeOwl_013.webp', 'owl/FreeOwl_014.webp',
      'owl/FreeOwl_016.webp', 'owl/FreeOwl_017.webp', 'owl/FreeOwl_022.webp', 'owl/FreeOwl_025.webp',
      'owl/FreeOwl_026.webp', 'owl/FreeOwl_028.webp', 'owl/FreeOwl_039.webp'
    ],
    4: [
      'akio/akio2.webp', 'akio/akio3.webp', 'akio/akio4.webp', 'akio/akio5.webp',
      'akio/akio6.webp', 'akio/akio7.webp', 'akio/akio9.webp',
    ],
    5: [
      'bernard/bernard1.webp', 'bernard/bernard5.webp', 'bernard/bernard8.webp',
      'bernard/bernard9.webp', 'bernard/bernard10.webp', 'bernard/bernard11.webp',
    ],
    6: [
      'cats/cats1.webp', 'cats/cats3.webp', 'cats/cats5.webp', 'cats/cats7.webp', 'cats/cats8.webp',
      'cats/cats9.webp', 'cats/cats12.webp', 'cats/cats13.webp', 'cats/cats14.webp', 'cats/cats17.webp',
      'cats/cats18.webp', 'cats/cats19.webp', 'cats/cats20.webp'
    ],
    7: [
      'senya/senya1.webp', 'senya/senya3.webp', 'senya/senya4.webp', 'senya/senya6.webp'
    ],
    8: [
      'homer/homer001.webp', 'homer/homer002.webp', 'homer/homer003.webp', 'homer/homer004.webp',
      'homer/homer005.webp', 'homer/homer006.webp', 'homer/homer007.webp', 'homer/homer008.webp',
      'homer/homer009.webp', 'homer/homer010.webp', 'homer/homer011.webp', 'homer/homer012.webp',
      'homer/homer013.webp'
    ],
    9: [
      'coffee/coffee_001.webp', 'coffee/coffee_002.webp', 'coffee/coffee_003.webp', 'coffee/coffee_004.webp',
      'coffee/coffee_005.webp', 'coffee/coffee_006.webp', 'coffee/coffee_007.webp', 'coffee/coffee_008.webp',
      'coffee/coffee_009.webp', 'coffee/coffee_010.webp', 'coffee/coffee_011.webp', 'coffee/coffee_012.webp',
      'coffee/coffee_013.webp', 'coffee/coffee_014.webp', 'coffee/coffee_015.webp'
    ],
    10: [
      'words/busy.webp', 'words/coffee-time.webp', 'words/cool.webp', 'words/game-over.webp', 'words/hi.webp',
      'words/like.webp', 'words/nom-nom.webp', 'words/ok.webp', 'words/omg.webp', 'words/party-time.webp',
      'words/please.webp', 'words/stop.webp', 'words/what.webp', 'words/why.webp'
    ],
  };

  Widget buildToolbar() {
    return Container(
      height: 55,
      color: Colors.white,
      child: Scrollbar(
        isAlwaysShown: true,
        controller: toolbarScrollController,
        thickness: 1.5,
        child: Container(
          margin: EdgeInsets.only(bottom: 1),
          child: ListView(
              scrollDirection: Axis.horizontal,
              controller: toolbarScrollController,
              children: [
                buildToolbarButton(index: 0, icon: Icons.access_time),
                buildToolbarButton(index: 1, image: 'panda/panda2.png', size: 45),
                buildToolbarButton(index: 2, image: 'stitch/stitch002.webp', size: 40),
                buildToolbarButton(index: 3, image: 'owl/FreeOwl_002.webp', size: 40),
                buildToolbarButton(index: 4, image: 'akio/akio6.webp', size: 40),
                buildToolbarButton(index: 5, image: 'bernard/bernard11.webp', size: 40),
                buildToolbarButton(index: 6, image: 'cats/cats1.webp', size: 40),
                buildToolbarButton(index: 7, image: 'senya/senya6.webp', size: 40),
                buildToolbarButton(index: 8, image: 'homer/homer003.webp', size: 40),
                buildToolbarButton(index: 9, image: 'coffee/coffee_001.webp', size: 40),
                buildToolbarButton(index: 10, image: 'words/like.webp', size: 40),
              ]),
        ),
      ),
    );
  }

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
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade50),
          boxShadow: [Shadows.topShadow(color: Colors.black12)]
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
              padding: EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(Icons.sentiment_very_satisfied, color: Colors.grey.shade500, size: 20),
                  Container(
                      padding: EdgeInsets.only(left: 5),
                      child: Text('Stickers', style: TextStyle(color: Colors.grey.shade500))),
                ],
              )),
          Material(
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
        ],
      ),
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
      child: AnimatedContainer(
          duration: Duration(milliseconds: 250),
          width: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              border: Border.all(
                  width: selectedIndex == index ? 1 : 0.5,
                  color: selectedIndex == index ? CompanyColor.bluePrimary : Colors.grey.shade200)
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
            crossAxisSpacing: 0, mainAxisSpacing: 0, crossAxisCount: 5),
        itemBuilder: (context, index) => GestureDetector(
          onTap: () async {
            recentStickers = await stickerService.addRecent(stickers[index]);
            widget.sendFunc(stickers[index]);
          },
          child: Container(
              padding: EdgeInsets.all(10),
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
