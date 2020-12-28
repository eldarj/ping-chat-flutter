import 'package:flutter/cupertino.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';

class LoadingButton extends StatefulWidget {
  final Widget child;

  final Function onPressed;

  final Color color;

  final bool displayLoader;

  final double loaderSize;

  const LoadingButton({Key key, this.onPressed, this.color, this.child, this.displayLoader = false, this.loaderSize}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LoadingButtonState();
}

class LoadingButtonState extends State<LoadingButton> {

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.color,
      width: 45, height: 45,
      padding: EdgeInsets.all(10),
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: !widget.displayLoader ? () {
          widget.onPressed();
        } : null,
        child: widget.displayLoader ? Spinner(size: widget.loaderSize) : widget.child,
      ),
    );
  }
}
