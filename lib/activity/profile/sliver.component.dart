import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/main.dart';
import 'package:transparent_image/transparent_image.dart';

class SliverComponent extends SliverPersistentHeaderDelegate {
  final Widget leading;

  final double expandedHeight;

  final Widget profileImage;

  SliverComponent({@required this.expandedHeight, this.leading, this.profileImage});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    double leftOffset = shrinkOffset / expandedHeight * 56;
    double leftMargin = (1 - (shrinkOffset / expandedHeight)) * 20;

    return Container(
      color: Colors.grey.shade100,
      child: Stack(
        fit: StackFit.expand,
        children: [
          profileImage,
          Container(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                    height: kToolbarHeight,
                    width: kToolbarHeight,
                    child: leading),
              ],
            ),
          ),
          Positioned(
              bottom: 0,
              left: leftOffset + leftMargin,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                      color: Colors.red,
                      alignment: Alignment.center,
                      height: kToolbarHeight + MediaQuery.of(context).padding.top,
                      child: Text('Eldar Jahijagic', style: TextStyle(
                        fontSize: 20, color: Colors.white
                      ))
                  ),
                ],
              )
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => expandedHeight;

  @override
  double get minExtent => kToolbarHeight;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}
