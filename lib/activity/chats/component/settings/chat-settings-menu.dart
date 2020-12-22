import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/contacts/shared-space/shared-space.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class ChatSettingsMenu extends StatelessWidget {
  final ClientDto peer;

  final String peerContactName;

  final int contactBindingId;

  final String picturesPath;

  const ChatSettingsMenu({Key key, this.peer, this.peerContactName, this.contactBindingId, this.picturesPath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (choice) {
        if (choice == 'info') {
          // TODO
        } else if (choice == 'media') {
          NavigatorUtil.push(context, SharedSpaceActivity(
              peer: peer,
              picturesPath: picturesPath,
              peerContactName: peerContactName,
              contactBindingId: contactBindingId));
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
