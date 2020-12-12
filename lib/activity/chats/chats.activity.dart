import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/contacts/add-contact.activity.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:flutterping/util/http/http-client.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/util/extension/http.response.extension.dart';

class ChatsActivity extends StatefulWidget {
  const ChatsActivity();

  @override
  State<StatefulWidget> createState() => new ChatsActivityState();
}

class ChatsActivityState extends BaseState<ChatsActivity> {
  var displayLoader = true;

  int userId = 0;

  List<MessageDto> chats = new List();
  int totalChats = 0;

  bool isLoadingOnScroll = false;
  int pageSize = 50;
  int pageNumber = 1;

  getUserAndGetChats() async {
    dynamic user = await UserService.getUser();
    userId = user.id;

    doGetChatData().then(onGetChatDataSuccess, onError: onGetChatDataError);
  }

  @override
  initState() {
    super.initState();
    getUserAndGetChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar.getProfileAppBar(scaffold, titleText: 'Chats'),
        drawer: NavigationDrawerComponent(),
        bottomNavigationBar: new BottomNavigationComponent(currentIndex: 0).build(context),
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return buildActivityContent();
        })
    );
  }

  Widget buildActivityContent() {
    Widget widget = ActivityLoader.build();

    if (!displayLoader) {
      if (!isError) {
        widget = Container(
          child: Column(
            children: [
              chats != null && chats.length > 0 ? buildListView() :
              Center(
                child: Container(
                  margin: EdgeInsets.all(25),
                  child: Text('Nemate poruka', style: TextStyle(color: Colors.grey)),
                ),
              ),
              Opacity(
                  opacity: isLoadingOnScroll ? 1 : 0,
                  child: LinearProgressLoader.build(context)
              )
            ],
          ),
        );
      } else {
        widget = ErrorComponent.build(actionOnPressed: () async {
          setState(() {
            displayLoader = true;
            isError = false;
          });

          await Future.delayed(Duration(seconds: 1));
          doGetChatData(clearChats: true).then(onGetChatDataSuccess, onError: onGetChatDataError);
        });
      }
    }

    return widget;
  }

  Widget buildListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!displayLoader && scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
          getNextPageOnScroll();
        }
      },
      child: Expanded(
        child: ListView.builder(
          itemCount: chats == null ? 0 : chats.length,
          itemBuilder: (context, index) {
            var chat = chats[index];
            var profileUrl, contactName;
            if (userId == chat.sender.id) {
              profileUrl = chat.receiver.profileImagePath;
              contactName = chat.receiverContactName;
            } else {
              profileUrl = chat.sender.profileImagePath;
              contactName = chat.senderContactName;
            }
            return buildSingleConversationRow(
                profile: profileUrl,
                contactName: contactName,
                messageContent: chat.text,
                seen: chat.seen,
                when: chat.sentTimestamp
            );
          },
        ),
      ),
    );
  }


  Container buildSingleConversationRow({String profile, String contactName, String messageContent,
    bool displaySeen = true, bool seen = true, String when, int notifications = 0, bool isOnline = false}) {
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
                      RoundProfileImageComponent(url: profile, margin: 2.5, borderRadius: 50, height: 50, width: 50),
                      Container(
                          decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              border: Border.all(color: Colors.white, width: 1),
                              borderRadius: BorderRadius.circular(50)
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
                                    child: Text(contactName, style: TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.bold, color: Colors.black87))),
                                Row(
                                  children: <Widget>[
                                    Text(messageContent, style: TextStyle(color: Colors.grey)),
                                    displaySeen ? Container(
                                        margin: EdgeInsets.only(left: 5),
                                        child: seen? Icon(Icons.check, color: Colors.green, size: 14)
                                            : Icon(Icons.check, color: Colors.grey, size: 14)
                                    ) : Container(),
                                  ],
                                )
                              ]
                          ),
                        )
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(when, style: TextStyle(fontSize: 12)),
                      notifications > 0 ? Container(
                          margin: EdgeInsets.only(top: 10),
                          alignment: Alignment.center,
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                            color: CompanyColor.backgroundGrey,
                          ),
                          child: Text(notifications.toString(), style: TextStyle(color: Colors.black87))
                      ) : Container()
                    ],
                  )
                ],
              ),
            )
          ]
      ),
    );
  }

  void getNextPageOnScroll() async {
    if (!isLoadingOnScroll) {
      setState(() {
        isLoadingOnScroll = true;
      });

      if (totalChats != 0 && pageNumber * pageSize < totalChats) {
        pageNumber++;
        await Future.delayed(Duration(seconds: 1));
        doGetChatData(page: pageNumber).then(onGetChatDataSuccess, onError: onGetChatDataError);
      } else {
        await Future.delayed(Duration(seconds: 1));
        setState(() {
          isLoadingOnScroll = false;
        });
        scaffold.showSnackBar(SnackBar(
            content: Text('Sve smo učitali!.', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).accentColor
        ));
      }
    }
  }

  Future<void> doGetChatData({page = 1, clearChats = false}) async {
    if (clearChats) {
      chats.clear();
      pageNumber = 1;
    }

    String url = '/api/chat/$userId'
        '?pageNumber=' + (page - 1).toString() +
        '&pageSize=' + pageSize.toString();

    http.Response response = await HttpClient.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    return {'chats': result['page'], 'totalElements': result['totalElements']};
  }

  void onGetChatDataSuccess(result) async {
    List filteredChats = result['chats'];
    totalChats = result['totalElements'];

    filteredChats.forEach((element) {
      chats.add(MessageDto.fromJson(element));
    });

    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = false;
    });
  }

  void onGetChatDataError(Object error) {
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

      doGetChatData(clearChats: true).then(onGetChatDataSuccess, onError: onGetChatDataError);
    }));
  }
}
