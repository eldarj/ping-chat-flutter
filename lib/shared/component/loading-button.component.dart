import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';

class LoadingButton extends StatefulWidget {
  final Widget child;

  final Function onPressed;

  final bool displayLoader;

  final double loaderSize;

  final disabled;

  final IconData icon;

  const LoadingButton({
    Key key,
    this.onPressed,
    this.child,
    this.icon,
    this.displayLoader = false,
    this.disabled = false,
    this.loaderSize,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => LoadingButtonState();
}

class LoadingButtonState extends State<LoadingButton> {

  @override
  Widget build(BuildContext context) {
    Widget _child;

    if (widget.icon != null) {
      _child = Icon(widget.icon, color: widget.disabled ? Colors.grey.shade300 : Colors.grey.shade600);
    } else {
      _child = widget.child;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: !widget.disabled && !widget.displayLoader ? () {
          widget.onPressed();
        } : null,
        child: Container(
          color: Colors.transparent,
          width: 45, height: 45,
          padding: EdgeInsets.all(10),
          alignment: Alignment.center,
          child: widget.displayLoader ? Spinner(size: widget.loaderSize) : _child,
        ),
      ),
    );
  }
}
