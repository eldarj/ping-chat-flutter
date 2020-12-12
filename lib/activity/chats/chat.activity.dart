

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/base/base.state.dart';

class ChatActivity extends StatefulWidget {
  final ClientDto clientDto;

  final String contactName;
  final String statusLabel;

  const ChatActivity({Key key, this.clientDto,
    this.contactName, this.statusLabel}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ChatActivityState();
}

class ChatActivityState extends BaseState<ChatActivity> {
  @override
  initState() {
    super.initState();
  }

  @override
  dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar.getBackAppBar(getScaffoldContext, centerTitle: false,
            titleWidget: Row(
              children: [
                RoundProfileImageComponent(url: widget.clientDto.profileImagePath,
                    height: 45, width: 45, borderRadius: 45, margin: 0),
                Container(
                  margin: EdgeInsets.only(left: 10),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.contactName, style: TextStyle(fontWeight: FontWeight.normal)),
                    Text(widget.statusLabel, style: TextStyle(fontSize: 12, color: Colors.grey))
                  ]),
                ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
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
              )
            ]
        ),
        drawer: NavigationDrawerComponent(),
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return buildActivityContent();
        })
    );
  }

  Widget buildActivityContent() {
    return Spinner();
  }
}
