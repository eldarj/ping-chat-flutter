import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/pinned-chat/pinned-messages.activity.dart';
import 'package:flutterping/activity/contacts/single/single-contact.activity.dart';
import 'package:flutterping/activity/data-space/contact-shared/contact-shared.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/shared/var/global.var.dart';
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

  final MessageTheme myMessageTheme;

  const ChatSettingsMenu(
      this.myMessageTheme,
      {
        Key key,
        this.peer,
        this.peerContactName,
        this.contact,
        this.contactBindingId,
        this.statusLabel,
        this.picturesPath,
        this.myContactName,
        this.userId,
        this.onDeleteContact,
        this.onDeleteMessages,
      }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: CompanyColor.iconGrey),
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
            myMessageTheme, peer: peer, contact: contact,
          ));
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
              value: 'info',
              child: Row(children: [
                Container(
                    margin:EdgeInsets.only(right: 10, left: 5),
                    child: Icon(Icons.alternate_email, color: CompanyColor.iconGrey, size: 17)),
                Text('Profile')
              ])),
          PopupMenuDivider(height: 0),
          PopupMenuItem<String>(
              value: 'media',
              child: Row(children: [
                Container(
                    margin:EdgeInsets.only(right: 10, left: 5),
                    child: Icon(Icons.image_outlined, color: CompanyColor.iconGrey, size: 17)),
                Text('Shared media')
              ])),
          PopupMenuItem<String>(
              value: 'pinned_messages',
              child: Row(children: [
                Container(
                    margin:EdgeInsets.only(right: 10, left: 5),
                    child: Icon(Icons.push_pin_outlined, color: CompanyColor.iconGrey, size: 17)),
                Text('Pinned messages')
              ])),
          PopupMenuDivider(height: 0),
          PopupMenuItem<String>(
              value: 'delete_contact',
              child: Row(children: [
                Container(
                    margin:EdgeInsets.only(right: 10, left: 5),
                    child: Icon(Icons.delete_outline, color: CompanyColor.iconGrey, size: 17)),
                Text('Delete contact')
              ])),
          PopupMenuItem<String>(
              value: 'delete_messages',
              child: Row(children: [
                Container(
                    margin:EdgeInsets.only(right: 10, left: 5),
                    child: Icon(Icons.announcement_outlined, color: CompanyColor.iconGrey, size: 17)),
                Text('Delete all messages')
              ])),
        ];
      },
    );
  }

}
