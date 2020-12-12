

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class BottomNavigationComponent extends StatelessWidget {
  final int currentIndex;

  final List<Widget> bottomBarActivities = const [
    ChatListActivity(),
    ContactsActivity(),
  ];

  const BottomNavigationComponent({Key key, this.currentIndex }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          title: Text('Chats'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          title: Text('Contacts'),
        ),
      ],
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) {
          NavigatorUtil.push(context, bottomBarActivities[index]);
        }
      },
    );
  }
}
