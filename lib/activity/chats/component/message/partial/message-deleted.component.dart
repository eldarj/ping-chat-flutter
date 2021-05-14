import 'dart:ui';

import 'package:flutter/material.dart';

const MESSAGE_PADDING = EdgeInsets.only(top: 10, bottom: 10, left: 15, right: 15);

class MessageDeleted extends StatelessWidget {
  const MessageDeleted({Key key}) : super(key: key);

  @override
  Widget build(BuildContext _context) {
    return Container(
      padding: MESSAGE_PADDING,
      child: Row(
          children: [
            Container(child: Icon(Icons.delete_outline, color: Colors.grey.shade400, size: 16)),
            Text('Deleted', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade400))
          ]
      ),
    );
  }
}
