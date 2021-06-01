import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/service/gif/giphy.client.service.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:transparent_image/transparent_image.dart';

class GifBar extends StatefulWidget {
  final Function(String) sendFunc;

  final Function onClose;

  const GifBar({Key key, this.sendFunc, this.onClose}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GifBarState();
}

class GifBarState extends State<GifBar> {
  bool displayLoader = false;

  TextEditingController searchController = TextEditingController();

  List<String> gifs = giphyClientService.getRecentGifs();

  init() async {
    if (gifs.length == 0) {
      setState(() {
        displayLoader = true;
      });

      gifs = await giphyClientService.getGifs("funny");

      setState(() {
        displayLoader = false;
      });
    }
  }

  @override
  initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: DEVICE_MEDIA_SIZE.width,
      height: DEVICE_MEDIA_SIZE.height / 2,
      color: Colors.white,
      child: Column(
        children: [
          buildSearchBar(),
          buildGifGrid(),
        ],
      ),
    );
  }

  Widget buildSearchBar() {
    return Container(
        decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [Shadows.topShadow()]
        ),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                keyboardType: TextInputType.text,
                onSubmitted: onSearchGifs,
                decoration: InputDecoration(
                    hintText: 'Search gifs',
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade200, width: 0.75)),
                    prefixIcon: Icon(Icons.search),
                    labelText: '',
                    contentPadding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 15)),
              )
            ),
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
            )
          ],
        ));
  }

  buildGifGrid() {
    Widget w = Spinner(size: 20);

    if (!displayLoader) {
      if (gifs.length > 0) {
        w = Container(
          child: GridView.builder(
              itemCount: gifs.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisSpacing: 0, mainAxisSpacing: 0, crossAxisCount: 3),
              itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    widget.sendFunc.call(gifs[index]);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FadeInImage.memoryNetwork(
                      image: gifs[index],
                      fit: BoxFit.cover,
                      placeholder: kTransparentImage,
                    ),
                  )
              )
          ),
        );

      } else {
        w = Container(
          child: Text('No gifs to display', style: TextStyle(color: Colors.grey.shade400))
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
