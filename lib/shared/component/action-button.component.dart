import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class ActionButton extends StatefulWidget {
  final IconData icon;
  final bool checked;
  final Color fillColor;
  final Color splashColor;
  final Function() onPressed;

  const ActionButton(
      {Key key,
        this.icon,
        this.onPressed,
        this.checked = false,
        this.fillColor, this.splashColor}) : super(key: key);

  @override
  _ActionButtonState createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  @override
  Widget build(BuildContext context) {
    return RawMaterialButton(
      onPressed: widget.onPressed,
      splashColor: widget.splashColor != null
          ? widget.splashColor
          : (widget.checked ? Colors.white : Colors.black12),
      fillColor: widget.fillColor != null
          ? widget.fillColor
          : (widget.checked ? Colors.black12 : Colors.white),
      elevation: 1,
      shape: CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Icon(widget.icon, size: 30.0,
          color: widget.fillColor != null
              ? Colors.white
              : (widget.checked ? Colors.white : CompanyColor.blueDark),
        ),
      ),
    );
  }
}
