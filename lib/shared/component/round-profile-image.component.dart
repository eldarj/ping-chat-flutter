
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoundProfileImageComponent extends StatefulWidget {
  static final String _DEFAULT_IMAGE_PATH = 'static/graphic/client/default-profile.jpg';

  final String url;
  final double width;
  final double height;
  final double borderRadius;
  final double margin;

  const RoundProfileImageComponent({this.url, this.height = 55, this.width = 55,
    this.borderRadius = 30.0, this.margin = 10.0}) : super();

  @override
  State<StatefulWidget> createState() => new RoundProfileImageComponentState();
}

class RoundProfileImageComponentState extends State<RoundProfileImageComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(width: widget.width, height: widget.height, margin: EdgeInsets.all(widget.margin),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(widget.borderRadius)
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(widget.borderRadius),
            child: widget.url != null ?
            CachedNetworkImage(imageUrl: widget.url, fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                    margin: EdgeInsets.all(15),
                    child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100)))
                : Image.asset(RoundProfileImageComponent._DEFAULT_IMAGE_PATH)
        ),
      ),
    );
  }
}
