
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/util/base/base.state.dart';

class ChatsActivity extends StatefulWidget {
  const ChatsActivity();

  @override
  State<StatefulWidget> createState() => new ChatsActivityState();
}

class ChatsActivityState extends BaseState<ChatsActivity> {
  var displayLoader = true;

  List<Widget> conversationRows = [];
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
  initState() {
    super.initState();
    doGetChatData().then(onGetChatDataSuccess, onError: onGetChatDataError);
  }

  @override
  preRender() {
    appBar = BaseAppBar.getProfileAppBar(scaffold,
        titleText: 'Chats');

    BottomNavigationComponent createState = new BottomNavigationComponent(currentIndex: 0);
    bottomNavigationBar = createState.build(context);

    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    conversationRows = conversations.map((e) => buildSingleConversationRow(
        contactName: e['contactName'],
        content: Text(e['content']),
        displaySeen: e['displaySeen'],
        notifications: e['notifications'],
        seen: e['seen'],
        when: e['when'],
        isOnline: e['isOnline']
    )).toList();
    return buildActivityContent();
  }

  Widget buildActivityContent() {
    Widget widget = ActivityLoader.build();

    if (!displayLoader) {
      widget = Column(
          children: [
            Expanded(
              child: Container(
                child: CupertinoScrollbar(
                  child: ListView(
                      children: conversationRows
                  ),
                ),
              ),
            ),
          ]
      );
    }

    return widget;
  }

  Container buildSingleConversationRow({String profile, String contactName, Widget content, bool displaySeen = true,
    bool seen = true, String when, int notifications = 0, bool isOnline}) {
    return Container(
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1))
      ),
      padding: EdgeInsets.all(10),
      child: Row(
          children: [
            Container(
                padding: EdgeInsets.only(right: 10),
                child: Stack(
                    alignment: AlignmentDirectional.topEnd,
                    children: [
                      Icon(Icons.account_circle, size: 50),
                      Container(
                          decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              border: Border.all(color: Colors.white, width: 1.5),
                              borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(5),
                                  bottomLeft: Radius.circular(5))
                          ),
                          margin: EdgeInsets.all(5),
                          width: 10, height: 10)
                    ])
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          alignment: Alignment.topLeft,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                    margin: EdgeInsets.only(bottom: 5),
                                    child: Text(contactName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))),
                                content
                              ]
                          ),
                        )                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Row(children: <Widget>[
                        displaySeen ? Container(
                            margin: EdgeInsets.only(right: 5),
                            child: seen? Icon(Icons.check_circle, color: Colors.green, size: 13)
                                : Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 13)
                        ) : Container(),
                        Text(when, style: TextStyle(fontSize: 12))
                      ]),
                      notifications > 0 ? Container(
                          margin: EdgeInsets.only(top: 10),
                          alignment: Alignment.center,
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                            color: Colors.grey.shade200,
                          ),
                          child: Text(notifications.toString(), style: TextStyle(color: Colors.black87))
                      ) : Container()
                    ],
                  )                ],
              ),
            )
          ]
      ),
    );
  }

  Future<void> doGetChatData() async {
    await Future.delayed(Duration(seconds: 3));
    return true;
  }

  void onGetChatDataSuccess(status) async {
    setState(() {
      displayLoader = false;
      isError = false;
    });
  }

  void onGetChatDataError(Object error) {
    setState(() {
      isError = true;
      displayLoader = false;
    });

    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () async {
      setState(() {
        displayLoader = true;
        isError = false;
      });

      await Future.delayed(Duration(seconds: 1));

      doGetChatData().then(onGetChatDataSuccess, onError: onGetChatDataError);
    }));
  }
}
