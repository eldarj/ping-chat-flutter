import 'package:flutter/material.dart';
import 'package:flutterping/shared/var/global.var.dart';

class ActionButton extends StatefulWidget {
  final IconData icon;
  final bool checked;
  final Color fillColor;
  final Color iconColor;
  final Color splashColor;
  final Function() onPressed;

  const ActionButton({Key key,
    this.icon,
    this.onPressed,
    this.checked = false,
    this.fillColor,
    this.iconColor,
    this.splashColor,
  }) : super(key: key);

  @override
  _ActionButtonState createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
        height: 50,
        width: 50,
        margin: EdgeInsets.only(left: 10, right: 10),
        child: RawMaterialButton(
          elevation: 0,
          shape: CircleBorder(),
          onPressed: widget.onPressed,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Icon(widget.icon, size: 25.0,
              color: widget.iconColor != null
              ? widget.iconColor
              : widget.fillColor != null
                  ? Colors.white
                  : (widget.checked ? Colors.white : CompanyColor.blueDark),
            ),
          ),
          splashColor: widget.splashColor != null
              ? widget.splashColor
              : (widget.checked ? Colors.white : Colors.black12),
          fillColor: widget.fillColor != null
              ? widget.fillColor
              : (widget.checked ? Colors.black12 : Colors.white),
        ));
  }
}
