import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutterping/main.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/shared/component/loading-button.component.dart';
import 'package:path/path.dart';
import 'package:tus_client/tus_client.dart';
import 'package:flutterping/util/other/file-type-resolver.util.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/calls/callscreen.activity.dart';
import 'package:flutterping/activity/chats/single-chat/chat.activity.dart';
import 'package:flutterping/activity/contacts/single/single-contact.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/contact/contact.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
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
  CHAT, CONTACT, SHARE
}

class SearchContactsActivity extends StatefulWidget {
  final SearchContactsType type;

  final DSNodeDto sharedNode;

  final File sharedFile;

  final List<ContactDto> contacts;

  final String picturesPath;

  const SearchContactsActivity({Key key,
    this.type = SearchContactsType.CHAT,
    this.sharedNode, this.sharedFile, this.picturesPath,
    this.contacts}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new SearchContactsActivityState();
}

class SearchContactsActivityState extends BaseState<SearchContactsActivity> {
  static const String STREAMS_LISTENER_ID = "SearchContactsActivityListener";

  bool displayLoader = false;

  bool isFetchingContacts = false;

  TextEditingController searchController = TextEditingController();
  StreamController<String> searchStream = StreamController();

  List<ContactDto> contacts = [];
  List<ContactDto> originalContacts = [];
  List<ContactDto> recentContacts = [];

  String searchString = '';

  bool hasPreviouslySearched = false;
  bool displayRecent = false;

  bool displayShareLoader = false;

  int userId;
  int userSentNodeId;
  String username;

  onSearch() async {
    if (!isFetchingContacts) {
      setState(() {
        hasPreviouslySearched = true;
        isFetchingContacts = true;
      });

      var searchQuery = searchController.text.toLowerCase();

      var filteredContacts = originalContacts.where((element) {
        String searchString = element.contactName + element.contactPhoneNumber;
        return searchString.toLowerCase().contains(searchQuery);
      }).toList();

      setState(() {
        displayRecent = false;
        isFetchingContacts = false;
        contacts = filteredContacts;
      });
    }
  }

  initData() async {
    searchStream.stream
        .transform(StreamTransformer.fromBind((s) => s.debounce(Duration(milliseconds: 200))))
        .listen((s) => onSearch());

    ClientDto user = await UserService.getUser();

    this.userId = user.id;
    this.userSentNodeId = user.sentNodeId;
    this.username = user.firstName;

    doGetContacts().then(onGetContactsSuccess, onError: onGetContactsError);
    doGetRecent().then(onGetRecentSuccess, onError: onGetRecentError);

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

  @override
  void initState() {
    initData();
    super.initState();
  }

  @override
  void dispose() {
    searchController.dispose();
    searchStream.close();
    super.dispose();
  }

  @override
  preRender() async {
    appBar = BaseAppBar.getCloseAppBar(
        getScaffoldContext,
        actions: [
          !displayShareLoader ? Container() : Container(
            padding: EdgeInsets.all(5),
            child: LoadingButton(
              displayLoader: true,
            )
          )
        ],
    );
    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 500),
      opacity: displayShareLoader ? 0.5 : 1,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.centerRight,
              children: [
                isFetchingContacts
                    ? Container(margin: EdgeInsets.only(right: 15), child: Spinner(size: 25))
                    : Container(),
                Container(
                    color: Colors.white,
                    margin: EdgeInsets.only(left: 2.5, right: 2.5, bottom: 0.5),
                    child: TextField(
                      controller: searchController,
                      textInputAction: TextInputAction.search,
                      keyboardType: TextInputType.text,
                      onSubmitted: (_) => onSearch(),
                      onChanged: (value) {
                        searchStream.add(value);
                      },
                      decoration: InputDecoration(
                          hintText: '',
                          prefixIcon: Icon(Icons.search),
                          labelText: 'Search by name or phone number',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(width: 0.25, color: Colors.grey.shade800),
                          ),
                          contentPadding: EdgeInsets.only(left: 20, right: 20, top: 0, bottom: 15)),
                    )),
              ],
            ),
            !hasPreviouslySearched && !displayRecent ? Container(
              padding: EdgeInsets.only(top: 25),
              child: Text('Search contacts by their name or phone number',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey)
              ),
            ) : Container(),
            buildRecentList(),
            buildContactsList()
          ],
        ),
      ),
    );
  }

  buildRecentList() {
    Widget w = Container();

    if (displayRecent && recentContacts != null && recentContacts.length > 0) {
      w = Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(left: 10, top: 10, bottom: 2.5),
              child: Text('RECENT', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500, fontSize: 12))
            ),
            Flexible(
              child: ListView.builder(
                  itemCount: recentContacts.length,
                  itemBuilder: (context, index) {
                    return Container(
                        height: 70,
                        child: buildListItem(recentContacts[index])
                    );
                  }
              ),
            ),
          ],
        ),
      );
    }

    return w;
  }

  buildContactsList() {
    Widget w = Container();

    if (!displayRecent) {
      if (!isError) {
        if (contacts != null && contacts.length > 0) {
          w = Flexible(
            child: ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                return buildListItem(contacts[index]);
              },
            ),
          );
        } else if (hasPreviouslySearched) {
          w = Center(
            child: Container(
              margin: EdgeInsets.all(25),
              child: Text('Couldn\'t find any contacts',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ),
          );
        }
      } else {
        w = Expanded(child: InfoComponent.errorPanda());
      }
    }

    return w;
  }

  Widget buildListItem(ContactDto contact) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.type != SearchContactsType.SHARE ? () {
          NavigatorUtil.push(scaffold.context, SingleContactActivity(
            peer: contact.contactUser,
            userId: userId,
            contactName: contact.contactName,
            contactBindingId: contact.contactBindingId,
            contactPhoneNumber: contact.contactPhoneNumber,
            favorite: contact.favorite,
            statusLabel: '',
            myContactName: username,
          ));
        } : () {},
        child: Container(
          padding: EdgeInsets.only(left: 10, right: 10, top: 7.5, bottom: 7.5),
          child: Row(
              children: [
                Container(
                    padding: EdgeInsets.only(right: 12.5),
                    child: Stack(
                        alignment: AlignmentDirectional.topEnd,
                        children: [
                          RoundProfileImageComponent(displayQuestionMarkImage: contact.contactUser == null,
                              url: contact.contactUser?.profileImagePath,
                              margin: 2.5, border: contact.favorite ? Border.all(color: Colors.yellow.shade700, width: 3) : null,
                              borderRadius: 50, height: 50, width: 50, cacheWidth: 75),
                        ])
                ),
                buildItemDetails(contact)
              ]
          ),
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
            onPressed: contact.contactUser != null ? () {
              NavigatorUtil.replace(scaffold.context, ChatActivity(
                  myContactName: username, peer: contact.contactUser, peerContactName: contact.contactName,
                  statusLabel: '', contactBindingId: contact.contactBindingId));
            } : () {},
            child: Icon(Icons.message, size: 17.5, color: contact.contactUser != null
                ? CompanyColor.blueDark
                : Colors.grey.shade400
            ),
          ),
        ),
        Container(
          width: 45, height: 45,
          margin: EdgeInsets.only(right: 5),
          child: FlatButton(
            color: Colors.grey.shade200,
            padding: EdgeInsets.all(0),
            shape: StadiumBorder(),
            onPressed: contact.contactUser != null ? () async {
              await Future.delayed(Duration(milliseconds: 250));
              NavigatorUtil.replace(scaffold.context, new CallScreenWidget(
                contact: contact,
                myContactName: username,
                direction: 'OUTGOING',
              ));
            } : () {},
            child: Icon(Icons.call, size: 17.5, color: contact.contactUser != null
                ? CompanyColor.blueDark
                : Colors.grey.shade400
            ),
          ),
        ),
      ]);
    } else if (widget.type == SearchContactsType.CONTACT) {
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
    } else {
      rightsideSection = Container(
        width: 45, height: 45,
        margin: EdgeInsets.only(right: 15),
        child: FlatButton(
          color: Colors.grey.shade200,
          padding: EdgeInsets.all(0),
          shape: StadiumBorder(),
          onPressed: () {
            // Send dataspace node as message to contact
            doShareFile(widget.sharedFile, contact);
          },
          child: Container(
              margin: EdgeInsets.only(left: 2.5),
              child: Icon(Icons.send, size: 17.5, color: CompanyColor.blueDark)),
        ),
      );
      infoSection = Text(contact.contactPhoneNumber, style: TextStyle(color: Colors.grey));
    }

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            child: Text(contact.contactName,
                                style: TextStyle(fontSize: 16, color: Colors.black87))),
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

  doShareFile(file, ContactDto contact, { messageType, text }) async {
    setState(() {
      displayShareLoader = true;
    });
    var fileName = basename(file.path);
    var fileSize = file.lengthSync();
    var fileUrl = Uri.parse(API_BASE_URL + '/files/uploads/' + fileName).toString();
    if (messageType == null) {
      messageType = FileTypeResolverUtil.resolve(extension(fileName));
    }

    var pathInPictures = widget.picturesPath + '/' + fileName;
    if (file.path != pathInPictures) {
      file = await file.copy(pathInPictures);
    }

    var userToken = await UserService.getToken();

    DSNodeDto dsNodeDto = new DSNodeDto();
    dsNodeDto.ownerId = userId;
    dsNodeDto.receiverId = contact.contactUser.id;
    dsNodeDto.parentDirectoryNodeId = userSentNodeId;
    dsNodeDto.nodeName = fileName;
    dsNodeDto.nodeType = messageType;
    dsNodeDto.description = username;
    dsNodeDto.fileUrl = fileUrl;
    dsNodeDto.fileSizeBytes = fileSize;
    dsNodeDto.pathOnSourceDevice = file.path;

    TusClient fileUploadClient = TusClient(
      Uri.parse(API_BASE_URL + DATA_SPACE_ENDPOINT),
      file,
      store: TusMemoryStore(),
      headers: {'Authorization': 'Bearer $userToken'},
      metadata: {'dsNodeEncoded': json.encode(dsNodeDto)},
    );

    var messageSendingService = new MessageSendingService(contact.contactUser, contact.contactName, username, contact.contactBindingId);
    await messageSendingService.initialize();
    MessageDto message = messageSendingService.addPreparedFile(
        fileName, file.path, fileUrl, fileSize, messageType, text: text);

    try {
      await fileUploadClient.upload(
        onComplete: (response) async {
          var nodeId = response.headers['x-nodeid'];
          message.isUploading = false;
          message.nodeId = int.parse(nodeId);

          messageSendingService.sendFile(message);

          onShareSuccess(contact);
        },
        onProgress: (progress) {
        },
      );
    } catch (exception) {
      onShareError(exception);
    }
  }

  onShareSuccess(contact) async {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.success(
        'File sent to ${contact.contactName}'
    ));

    await Future.delayed(Duration(seconds: 2));

    Navigator.of(scaffold.context).pop();
  }

  onShareError(error) async {
    print(error);

    setState(() {
      displayShareLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
      content: 'Error sending file, please try again', duration: Duration(seconds: 2)
    ));

    await Future.delayed(Duration(seconds: 2));

    Navigator.of(scaffold.context).pop();
  }


  // Get all contacts
  Future<dynamic> doGetContacts() async {
    scaffold.removeCurrentSnackBar();

    setState(() {
      isFetchingContacts = true;
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

  // Get recent contacts
  Future<List<dynamic>> doGetRecent() async {
    scaffold.removeCurrentSnackBar();

    String url = '/api/contacts/recent';

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return response.decode();
  }

  void onGetRecentSuccess(List<dynamic> recentContacts) {
    this.recentContacts = recentContacts.map((e) => ContactDto.fromJson(e)).toList();
    if (this.recentContacts.length <= 0) {
      setState(() {
        this.displayRecent = false;
      });
    } else {
      setState(() {
        this.displayRecent = true;
      });
    }
  }

  void onGetRecentError(Object error) {
  }
}
