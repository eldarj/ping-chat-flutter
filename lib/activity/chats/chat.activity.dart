

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/http/http-client.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

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
  var displayLoader = true;

  final TextEditingController textEditingController = TextEditingController();
  final FocusNode textFieldFocusNode = FocusNode();

  bool textFieldHasFocus = false;

  int userId = 0;
  int anotherUserId = 0;

  List<MessageDto> messages = new List();
  bool isLoadingOnScroll = false;
  int pageNumber = 1;
  int pageSize = 50;

  onInit() async {
    dynamic user = await UserService.getUser();
    userId = user.id;
    anotherUserId = widget.clientDto.id;
    doGetMessages().then(onGetMessagesSuccess, onError: onGetMessagesError);
  }

  @override
  initState() {
    super.initState();

    onInit();

    KeyboardVisibilityNotification().addNewListener(
      onChange: (bool visible) {
        print('KEYBOARD VISIBLITY');
        textFieldHasFocus = visible;
      },
    );

    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        setState(() {
          print('has focus');
          textFieldHasFocus = true;
        });
      }
    });
  }

  Future doGetMessages({page = 1, clearRides = false, favouritesOnly = false}) async {
    if (clearRides) {
      messages.clear();
      pageNumber = 1;
    }

    String url = '/api/messages'
        '?pageNumber=' + (page - 1).toString() +
        '&pageSize=' + pageSize.toString() +
        '&userId=' + userId.toString() +
        '&anotherUserId=' + anotherUserId.toString();

    http.Response response = await HttpClient.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    await Future.delayed(Duration(seconds: 1  ));
    return {'messages': result['page'], 'totalElements': result['totalElements']};
  }

  onGetMessagesSuccess(result) {
    List filteredMessages = result['messages'];

    filteredMessages.forEach((element) {
      messages.add(MessageDto.fromJson(element));
    });

    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = false;
    });
  }

  onGetMessagesError(error) {
    print(error);
    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = true;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () async {
      setState(() {
        displayLoader = true;
        isError = false;
      });

      await Future.delayed(Duration(seconds: 1));

      doGetMessages(clearRides: true).then(onGetMessagesSuccess, onError: onGetMessagesError);
    }));
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
          return Container(
            color: Colors.white,
            child: Column(children: [
              buildListView(),
              MessageInput(
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.tag_faces),
                    onPressed: () {},
                    color: CompanyColor.blueDark,
                  )
                ],
              ),
              buildInputRow()
            ]),
          );
        })
    );
  }

  Widget buildListView() {
    Widget widget = Center(child: Spinner());

    if (!displayLoader) {
      if (messages != null && messages.length > 0) {
        widget = Expanded(
          child: ListView.builder(
            itemCount: messages == null ? 0 : messages.length,
            itemBuilder: (context, index) {
              var message = messages[index];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Column(children: [
                    Text(message.text)
                  ]),
                ],
              );
            },
          ),
        );
      } else {
        widget = Center(
          child: Container(
            margin: EdgeInsets.all(25),
            child: Text('Here begins history', style: TextStyle(color: Colors.grey)),
          ),
        );
      }
    }

    return widget;
  }

  Widget buildInputRow() {
    return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [Shadows.topShadow()],
          borderRadius: BorderRadius.circular(20),
        ),
        width: MediaQuery.of(context).size.width,
        child: Row(children: [
          Container(
            child: IconButton(
              icon: Icon(Icons.tag_faces),
              onPressed: () {},
              color: CompanyColor.blueDark,
            ),
          ),
          Expanded(child: Container(
            child: TextField(
              onSubmitted: (value) {
                // onSendMessage(textEditingController.text, 0);
              },
              style: TextStyle(fontSize: 15.0),
              controller: textEditingController,
              decoration: InputDecoration.collapsed(
                hintText: 'Vaša poruka...',
                hintStyle: TextStyle(color: Colors.grey),
              ),
              focusNode: textFieldFocusNode,
            ),
          )),
          Container(
            child: Container(
              height: 30, width: 30,
              decoration: BoxDecoration(
                border: Border.all(color: CompanyColor.blueDark, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.gif, color: CompanyColor.blueDark),
            ),
          ),
          Container(
            child: IconButton(
              icon: Icon(Icons.image),
              onPressed: () {},
              color: CompanyColor.blueDark,
            ),
          ),
          Container(
            child: IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: () {},
              color: CompanyColor.blueDark,
            ),
          ),
          textFieldHasFocus ? Container(child: Icon(Icons.send)) :
          Container(
              margin: EdgeInsets.only(top: 5, bottom: 5, left: 5, right: 10),
              height: 45, width: 45,
              decoration: BoxDecoration(
                color: CompanyColor.blueDark,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: Icon(Icons.mic),
                iconSize: 18,
                onPressed: () {},
                color: Colors.white,
              )
          ),
        ]));
  }
}
