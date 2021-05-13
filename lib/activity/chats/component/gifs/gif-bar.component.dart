import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/gif/giphy.client.service.dart';
import 'package:flutterping/service/persistence/sticker.prefs.service.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';

class GifBar extends StatefulWidget {
  final Function(String) sendFunc;

  final Function onSearchGifs;

  const GifBar({Key key, this.sendFunc, this.onSearchGifs}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GifBarState();
}

class GifBarState extends State<GifBar> {
  bool displayLoader = false;

  TextEditingController searchController = TextEditingController();

  List<String> gifs = [];

  loadRecentStickers() async {

  }

  @override
  initState() {
    super.initState();
    loadRecentStickers();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: DEVICE_MEDIA_SIZE.height / 3,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          buildSearchBar(),
          Expanded(
              child: Center(
                child: buildGifGrid()
              )
          ),
        ],
      ),
    );
  }

  buildSearchBar() {
    return Container(
        margin: EdgeInsets.only(left: 5, right: 5),
        child: TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          onSubmitted: onSearchGifs,
          decoration: InputDecoration(
              hintText: '',
              prefixIcon: Icon(Icons.search),
              labelText: 'Search for gifs',
              contentPadding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 15)),
        ));
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
          // selectedIndex = index;
        });
      },
      child: Container(
          width: 70, height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              // border: Border.all(color: selectedIndex == index ? CompanyColor.bluePrimary : Colors.grey.shade200)
          ),
          child: Container(
              width: size, height: size,
              child: ch
          )
      ),
    );
  }

  buildGifGrid() {
    Widget w = Spinner(size: 20);

    if (!displayLoader) {
      if (gifs.length > 0) {
        w = Container(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 10, mainAxisSpacing: 10, crossAxisCount: 3),
              itemCount: gifs.length, itemBuilder: (context, index) {
            return Container(
                child: CachedNetworkImage(
                  imageUrl: gifs[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => ActivityLoader.shimmer(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(height: 10, margin: EdgeInsets.only(top: 5, bottom: 5), color: Colors.white),
                        Container(height: 10, margin: EdgeInsets.only(top: 5, bottom: 5), color: Colors.white),
                        Container(height: 10, margin: EdgeInsets.only(top: 5, bottom: 5), color: Colors.white),
                      ]
                  )),
                )
            );
          }),
        );

      } else {
        w = Container(
          child: Text('No gifs to display')
        );
      }
    }

    return w;
    // if (selectedIndex == 0) {
    //   return !loadingRecent ? _buildStickers(recentStickers)
    //       : Container(margin: EdgeInsets.all(20), child: Spinner());
    // } else {
    //   return _buildStickers(stickersMap[selectedIndex]);
    // }
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
                    // recentStickers = await stickerService.addRecent(stickerName);
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

  onSearchGifs(query) async {
    setState(() {
      displayLoader = true;
    });

    gifs = await giphyClientService.getGifs(query);

    setState(() {
      displayLoader = false;
    });
  }
}
