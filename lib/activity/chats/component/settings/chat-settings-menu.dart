import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/pinned-chat/pinned-messages.activity.dart';
import 'package:flutterping/activity/contacts/single/single-contact.activity.dart';
import 'package:flutterping/activity/data-space/contact-shared/contact-shared.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class ChatSettingsMenu extends StatelessWidget {
  final ClientDto peer;

  final ContactDto contact;

  final String peerContactName;

  final int contactBindingId;

  final String picturesPath;

  final String myContactName;

  final String statusLabel;

  final int userId;

  final Function onDeleteContact;
  final Function onDeleteMessages;

  const ChatSettingsMenu({Key key, this.peer, this.peerContactName, this.contactBindingId, this.picturesPath, this.myContactName, this.statusLabel, this.userId,
    this.onDeleteContact, this.onDeleteMessages, this.contact
  }) : super(key: key);

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
            contactPhoneNumber: peer.fullPhoneNumber,
            favorite: false,
          ));

        } else if (choice == 'media') {
          NavigatorUtil.push(context, ContactSharedActivity(
              peer: peer,
              picturesPath: picturesPath,
              peerContactName: peerContactName,
              contactBindingId: contactBindingId));

        } else if (choice == 'delete_contact') {
          this.onDeleteContact.call();

        } else if (choice == 'delete_messages') {
          this.onDeleteMessages.call();

        } else if (choice == 'pinned_messages') {
          NavigatorUtil.push(context, PinnedMessagesActivity(
            peer: peer, contact: contact,
          ));
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
              ])),
          PopupMenuItem<String>(
              value: 'media',
              child: Row(children: [
                Container(
                    width: 30,
                    margin:EdgeInsets.only(right: 20, left: 5),
                    child: Icon(Icons.image_outlined)),
                Text('Shared media')
              ])),
          PopupMenuDivider(),
          PopupMenuItem<String>(
              value: 'pinned_messages',
              child: Row(children: [
                Container(
                    width: 30,
                    margin:EdgeInsets.only(right: 20, left: 5),
                    child: Icon(Icons.push_pin_outlined)),
                Text('Pinned messages')
              ])),
          PopupMenuDivider(),
          PopupMenuItem<String>(
              value: 'delete_contact',
              child: Row(children: [
                Container(
                    width: 30,
                    margin:EdgeInsets.only(right: 20, left: 5),
                    child: Icon(Icons.delete_outline)),
                Text('Delete contact')
              ])),
          PopupMenuItem<String>(
              value: 'delete_messages',
              child: Row(children: [
                Container(
                    width: 30,
                    margin:EdgeInsets.only(right: 20, left: 5),
                    child: Icon(Icons.announcement_outlined)),
                Text('Delete all messages')
              ])),
        ];
      },
    );
  }

}
