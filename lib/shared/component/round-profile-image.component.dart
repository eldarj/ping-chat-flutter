
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RoundProfileImageComponent extends StatefulWidget {
  static const String DEFAULT_IMAGE_PATH = 'static/graphic/client/default-profile.jpg';
  static const String _QUESTION_MARK_IMAGE_PATH = 'static/graphic/icon/question-mark-24.png';

  final bool displayQuestionMarkImage;
  final String url;
  final double width;
  final double height;
  final Color backgroundColor;
  final BoxBorder border;
  final double borderRadius;
  final double margin;

  const RoundProfileImageComponent({
    this.displayQuestionMarkImage = false,
    this.url,
    this.height = 55,
    this.width = 55,
    this.backgroundColor,
    this.border,
    this.borderRadius = 30.0,
    this.margin = 10.0
  }) : super();

  @override
  State<StatefulWidget> createState() => new RoundProfileImageComponentState();
}

class RoundProfileImageComponentState extends State<RoundProfileImageComponent> {
  @override
  Widget build(BuildContext context) {
    return Container(width: widget.width, height: widget.height, margin: EdgeInsets.all(widget.margin),
      child: Container(
        decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.grey.shade50,
            border: widget.border,
            borderRadius: BorderRadius.circular(widget.borderRadius)
        ),
        child: ClipRRect(borderRadius: BorderRadius.circular(widget.borderRadius),
            child: getImage()),
      ),
    );
  }

  getImage() {
    if (widget.displayQuestionMarkImage) {
      return Container(
        color: Colors.grey.shade400,
        child: Image.asset(RoundProfileImageComponent._QUESTION_MARK_IMAGE_PATH,
          color: Colors.white,
        ),
      );
    } else if (widget.url != null) {
      return CachedNetworkImage(imageUrl: widget.url, fit: BoxFit.cover,
          placeholder: (context, url) => Container(
              margin: EdgeInsets.all(15),
              child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100)));
    } else {
      return Image.asset(RoundProfileImageComponent.DEFAULT_IMAGE_PATH);
    }
  }
}
