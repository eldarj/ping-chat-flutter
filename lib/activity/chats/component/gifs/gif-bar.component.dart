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

  const GifBar({Key key, this.sendFunc}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GifBarState();
}

class GifBarState extends State<GifBar> {
  bool displayLoader = false;

  TextEditingController searchController = TextEditingController();

  List<String> gifs = giphyClientService.getRecentGifs();

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DEVICE_MEDIA_SIZE.width,
      height: DEVICE_MEDIA_SIZE.height / 3,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          buildSearchBar(),
          buildGifGrid(),
        ],
      ),
    );
  }

  buildSearchBar() {
    return Container(
        margin: EdgeInsets.only(left: 5, right: 5, top: 10, bottom: 5),
        child: TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          keyboardType: TextInputType.text,
          onSubmitted: onSearchGifs,
          decoration: InputDecoration(
              hintText: '',
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200, width: 0.75)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: CompanyColor.blueDark, width: 0.75)),
              prefixIcon: Icon(Icons.search),
              labelText: 'Search GIFs',
              contentPadding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 15)),
        ));
  }

  buildGifGrid() {
    Widget w = Spinner(size: 20);

    if (!displayLoader) {
      if (gifs.length > 0) {
        w = Container(
          padding: EdgeInsets.only(left: 10, right: 10),
          child: GridView.builder(
              itemCount: gifs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 10, mainAxisSpacing: 10, crossAxisCount: 2),
              itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    widget.sendFunc.call(gifs[index]);
                  },
                  child: CachedNetworkImage(
                    imageUrl: gifs[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => ActivityLoader.shimmer(child: Container(color: Colors.white)),
                  )
              )
          ),
        );

      } else {
        w = Container(
          child: Text('No gifs to display')
        );
      }
    }

    return Expanded(
      child: Center(
        child: w
      )
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
