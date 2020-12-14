
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatSettingsMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (choice) {
        if (choice == 'info') {

        } else if (choice == 'media') {
          // NavigatorUtil.push(context, AddContactActivity());
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
              value: 'info',
              child: Row(children: [ Container(margin:EdgeInsets.only(right: 5),
                  child: Icon(Icons.info_outline)), Text('View contact') ])
          ),
          PopupMenuItem<String>(
              value: 'media',
              child: Row(children: [ Container(margin:EdgeInsets.only(right: 5),
                  child: Icon(Icons.sd_storage)), Text('Shared media') ])
          )
        ];
      },
    );
  }

}
