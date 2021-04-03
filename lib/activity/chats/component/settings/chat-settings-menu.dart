import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/contacts/single-contact.activity.dart';
import 'package:flutterping/activity/data-space/contact-shared/contact-shared.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class ChatSettingsMenu extends StatelessWidget {
  final ClientDto peer;

  final String peerContactName;

  final int contactBindingId;

  final String picturesPath;

  final String myContactName;

  final String statusLabel;

  final int userId;

  const ChatSettingsMenu({Key key, this.peer, this.peerContactName, this.contactBindingId, this.picturesPath, this.myContactName, this.statusLabel, this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (choice) {
        if (choice == 'info') {
          NavigatorUtil.push(context, SingleContactActivity(
            myContactName: myContactName,
            statusLabel: statusLabel,
            peer: peer,
            userId: userId,
            contactName: peerContactName,
            contactBindingId: contactBindingId,
            favorite: false,
          ));
        } else if (choice == 'media') {
          NavigatorUtil.push(context, ContactSharedActivity(
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
              child: Row(children: [
                Container(
                    width: 30,
                    margin:EdgeInsets.only(right: 20, left: 5),
                    child: Icon(Icons.person)),
                Text('Profile')
              ])
          ),
          PopupMenuItem<String>(
              value: 'media',
              child: Row(children: [
                Container(
                    width: 30,
                    margin:EdgeInsets.only(right: 20, left: 5),
                    child: Icon(Icons.image_outlined)),
                Text('Shared media')
              ])
          )
        ];
      },
    );
  }

}
