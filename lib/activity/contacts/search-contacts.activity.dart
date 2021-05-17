import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/calls/callscreen.activity.dart';
import 'package:flutterping/activity/chats/single-chat/chat.activity.dart';
import 'package:flutterping/activity/contacts/single/single-contact.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/service/contact/contact.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/info/info.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;

enum SearchContactsType {
  CHAT, CONTACT
}

class SearchContactsActivity extends StatefulWidget {
  final SearchContactsType type;

  final List<ContactDto> contacts;

  const SearchContactsActivity({Key key,
    this.type = SearchContactsType.CHAT,
    this.contacts}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new SearchContactsActivityState();
}

class SearchContactsActivityState extends BaseState<SearchContactsActivity> {
  static const String STREAMS_LISTENER_ID = "SearchContactsActivityListener";

  Timer fetchTimer;
  bool displayLoader = false;

  bool doFetchContacts = false;

  bool isFetchingContacts = false;

  TextEditingController searchController = TextEditingController();

  List<ContactDto> contacts = [];
  List<ContactDto> originalContacts = [];

  String searchString = '';

  bool hasPreviouslySearched = false;

  int userId;
  String username;

  onSearch() async {
    if (!isFetchingContacts) {
      setState(() {
        hasPreviouslySearched = true;
        isFetchingContacts = true;
      });

      await Future.delayed(Duration(seconds: 1));

      var filteredContacts = originalContacts.where((element) {
        String searchString = element.contactName + element.contactPhoneNumber;
        return searchString.toLowerCase().contains(searchController.text.toLowerCase());
      }).toList();

      setState(() {
        isFetchingContacts = false;
        doFetchContacts = false;
        contacts = filteredContacts;
      });
    }
  }

  onChanged() {
    doFetchContacts = true;
  }

  initData() async {
    ClientDto user = await UserService.getUser();
    this.userId = user.id;
    this.username = user.firstName;

    doGetContacts().then(onGetContactsSuccess, onError: onGetContactsError);

    contactPublisher.onFavouritesUpdate(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      var contact = contacts.firstWhere((element) => element.contactBindingId == contactEvent.contactBindingId, orElse: () => null);
      if (contact != null) {
        setState(() {
          contact.favorite = contactEvent.value;
        });
      }
    });

    contactPublisher.onNameUpdate(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      var contact = contacts.firstWhere((element) => element.contactBindingId == contactEvent.contactBindingId, orElse: () => null);
      if (contact != null) {
        setState(() {
          contact.contactName = contactEvent.value;
        });
      }
    });
  }

  initFetcher() {
    fetchTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      if (mounted && fetchTimer.isActive) {
        if (doFetchContacts && !isFetchingContacts) {
          onSearch();
        }
      } else {
        fetchTimer.cancel();
      }
    });
  }

  @override
  void initState() {
    initData();
    super.initState();
    initFetcher();
  }

  @override
  void dispose() {
    searchController.dispose();
    fetchTimer.cancel();
    super.dispose();
  }

  @override
  preRender() async {
    appBar = BaseAppBar.getCloseAppBar(getScaffoldContext, elevation: 0.0);
    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.centerRight,
          children: [
            isFetchingContacts
                ? Container(margin: EdgeInsets.only(right: 15), child: Spinner(size: 25))
                : Container(),
            Container(
                color: Colors.white,
                margin: EdgeInsets.only(left: 2.5, right: 2.5),
                child: TextField(
                  controller: searchController,
                  textInputAction: TextInputAction.search,
                  keyboardType: TextInputType.text,
                  onChanged: (_) => onChanged(),
                  onSubmitted: (_) => onSearch(),
                  decoration: InputDecoration(
                      hintText: '',
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search by name or phone number',
                      contentPadding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 15)),
                )),
          ],
        ),
        buildActivityContent()
      ],
    );
  }

  Widget buildActivityContent() {
    Widget widget = Container();

    if (!isError) {
      if (contacts != null && contacts.length > 0) {
        widget = buildListView();
      } else {
        widget = Center(
          child: Container(
            margin: EdgeInsets.all(25),
            child: Text(hasPreviouslySearched ? 'Couldn\'t find any contacts' : 'Search contacts by their name or phone number',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ),
        );
      }
    } else {
      widget = Expanded(child: InfoComponent.errorPanda());
    }

    return widget;
  }

  Widget buildListView() {
    return Expanded(
      child: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          return buildListItem(index);
        },
      ),
    );
  }

  Widget buildListItem(int index) {
    ContactDto contact = contacts[index];
    return GestureDetector(
      onTap: () {
        NavigatorUtil.push(context, SingleContactActivity(
          peer: contact.contactUser,
          userId: userId,
          contactName: contact.contactName,
          contactBindingId: contact.contactBindingId,
          contactPhoneNumber: contact.contactPhoneNumber,
          favorite: contact.favorite,
          statusLabel: '',
          myContactName: username,
        ));
      },
      child: Container(
        decoration: BoxDecoration(
            color: contact.favorite ? Colors.white : Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: CompanyColor.backgroundGrey, width: 1))
        ),
        padding: EdgeInsets.all(10),
        child: Row(
            children: [
              Container(
                  padding: EdgeInsets.only(left: 5, right: 10),
                  child: Stack(
                      alignment: AlignmentDirectional.topEnd,
                      children: [
                        RoundProfileImageComponent(displayQuestionMarkImage: contact.contactUser == null,
                            url: contacts[index].contactUser?.profileImagePath,
                            margin: 2.5, border: contact.favorite ? Border.all(color: Colors.yellow.shade700, width: 3) : null,
                            borderRadius: 50, height: 50, width: 50),
                        Container(
                            decoration: BoxDecoration(
                                color: Colors.green,
                                border: Border.all(color: Colors.white, width: 1.5),
                                borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(5),
                                    bottomLeft: Radius.circular(5))
                            ),
                            margin: EdgeInsets.all(5),
                            width: 10, height: 10)
                      ])
              ),
              buildItemDetails(contact)
            ]
        ),
      ),
    );
  }

  buildItemDetails(ContactDto contact) {
    Widget infoSection;
    Widget rightsideSection;

    if (widget.type == SearchContactsType.CHAT) {
      infoSection = Text(contact.contactPhoneNumber, style: TextStyle(color: Colors.grey));
      rightsideSection = Row(children: [
        Container(
          width: 45, height: 45,
          margin: EdgeInsets.only(right: 15),
          child: FlatButton(
            color: Colors.grey.shade200,
            padding: EdgeInsets.all(0),
            shape: StadiumBorder(),
            onPressed: () {
              NavigatorUtil.replace(context, ChatActivity(
                  myContactName: username, peer: contact.contactUser, peerContactName: contact.contactName,
                  statusLabel: '', contactBindingId: contact.contactBindingId));
            },
            child: Icon(Icons.message, size: 17.5, color: Colors.grey.shade500),
          ),
        ),
        Container(
          width: 45, height: 45,
          margin: EdgeInsets.only(right: 5),
          child: FlatButton(
            color: Colors.grey.shade200,
            padding: EdgeInsets.all(0),
            shape: StadiumBorder(),
            onPressed: () async {
              await Future.delayed(Duration(milliseconds: 250));
              NavigatorUtil.replace(context, new CallScreenWidget(
                target: contact.contactUser.fullPhoneNumber,
                contactName: contact.contactName,
                fullPhoneNumber: contact.contactUser.fullPhoneNumber,
                profileImageWidget: CachedNetworkImage(imageUrl: contact.contactUser.profileImagePath,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                      margin: EdgeInsets.all(15),
                      child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100)),
                ),
                direction: 'OUTGOING',
              ));
            },
            child: Icon(Icons.call, size: 17.5, color: Colors.grey.shade500),
          ),
        ),
      ]);
    } else {
      rightsideSection = Text(contact.contactPhoneNumber, style: TextStyle(color: Colors.grey));
      infoSection = contact.contactUser != null ? Visibility(
          visible: contact.contactUser.displayMyFullName,
          child: Text(
              (contact.contactUser.firstName ?? '')
                  + ' '
                  + (contact.contactUser.lastName ?? ''),
              style: TextStyle(
                  color: Colors.grey.shade500
              )
          )
      ) : Container();
    }

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            child: Text(contact.contactName,
                                style: TextStyle(fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87))),
                        infoSection
                      ]
                  ),
                )
              ],
            ),
          ),
          rightsideSection
        ],
      ),
    );
  }

  Future<dynamic> doGetContacts() async {
    scaffold.removeCurrentSnackBar();

    setState(() {
      isFetchingContacts = true;
      doFetchContacts = false;
      isError = false;
    });

    String url = '/api/contacts/search'
        '?userId=' + userId.toString() +
        '&searchQuery=' + searchController.text;

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return response.decode();
  }

  void onGetContactsSuccess(fetchedContacts) {
    scaffold.removeCurrentSnackBar();

    contacts.clear();
    fetchedContacts.forEach((element) {
      originalContacts.add(ContactDto.fromJson(element));
      contacts = originalContacts;
    });

    setState(() {
      hasPreviouslySearched = true;
      isFetchingContacts = false;
      isError = false;
    });
  }

  void onGetContactsError(Object error) {
    setState(() {
      isFetchingContacts = false;
      isError = true;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () async {
      doGetContacts().then(onGetContactsSuccess, onError: onGetContactsError);
    }));
  }
}
