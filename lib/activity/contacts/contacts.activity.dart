

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/shared/component/spinner.element.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/util/http/http-client.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class ContactsActivity extends StatefulWidget {
  const ContactsActivity();

  @override
  State<StatefulWidget> createState() => new ContactsActivityState();
}

class ContactsActivityState extends BaseState<ContactsActivity> {
  List conversations = [
    {'contactName': 'Indira', "content": 'Haha super eldare super..', "displaySeen": true, "seen": false,
      "when": 'Yesterday', "notifications": 0, "isOnline": true},
    {'contactName': 'Stara', "content": 'Gdje si?? Javi kako prodje', "displaySeen": true, "seen": false,
      "when": 'Today 14:54', "notifications": 4, "isOnline": true},
    {'contactName': 'Miki', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 1, "isOnline": false},
    {'contactName': 'Dragan', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 1, "isOnline": true},
    {'contactName': 'Alen', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 0, "isOnline": true},
    {'contactName': 'Harun', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 0, "isOnline": false},
    {'contactName': 'Idriz', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 0, "isOnline": false},
    {'contactName': 'Admir', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 5, "isOnline": false},
    {'contactName': 'Slaven', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 1, "isOnline": true},
    {'contactName': 'Vojo', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 2, "isOnline": false},
    {'contactName': 'Amer', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 3, "isOnline": true},
    {'contactName': 'Muharem', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 1, "isOnline": false},
    {'contactName': 'Miki', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 1, "isOnline": false},
    {'contactName': 'Miki', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 0, "isOnline": false},
    {'contactName': 'Miki', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 0, "isOnline": false},
    {'contactName': 'Miki', "content": 'Cucemo se, javi se kad god', "displaySeen": false, "seen": true,
      "when": '2 days ago', "notifications": 0, "isOnline": false},
  ];

  @override
  preRender() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scaffold.showSnackBar(SnackBarsComponent.success('Awesome, you\'re all ready to start Pinging!'));
    });

    appBar = BaseAppBar.getProfileAppBar(scaffold,
        titleText: 'Contacts', actions: [
          IconButton(
              icon: Icon(Icons.calendar_today),
              color: Colors.grey,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ContactsActivity()));
              }),
        ]);

    BottomNavigationComponent createState = new BottomNavigationComponent(currentIndex: 1);
    bottomNavigationBar = createState.build(context);

    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return Center(
        child: Container(
          width: 300,
          child: Text('Contacts'),
        ));
  }
}
