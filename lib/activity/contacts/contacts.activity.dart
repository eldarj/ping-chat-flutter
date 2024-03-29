import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fgbg/flutter_fgbg.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutterping/activity/contacts/add-contact.activity.dart';
import 'package:flutterping/activity/contacts/search-contacts.activity.dart';
import 'package:flutterping/activity/contacts/single/single-contact.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/service/contact/contact.publisher.dart';
import 'package:flutterping/service/contact/contact.service.dart';
import 'package:flutterping/service/profile/profile.publisher.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/info/info.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:shimmer/shimmer.dart';

class ContactsActivity extends StatefulWidget {
  final String savedContactName;
  final String savedContactPhoneNumber;

  const ContactsActivity({this.savedContactName, this.savedContactPhoneNumber}): super();

  @override
  State<StatefulWidget> createState() => new ContactsActivityState();
}

class ContactsActivityState extends BaseState<ContactsActivity> with WidgetsBindingObserver {
  static const String STREAMS_LISTENER_ID = "ContactsActivityListener";

  var displayLoader = true;

  ClientDto user;
  int userId = 0;
  String username;
  String countryDialCode;

  List<ContactDto> contacts = new List();
  int totalContacts = 0;

  bool isLoadingOnScroll = false;
  int pageNumber = 1;
  int pageSize = 50;

  int selectedTabIndex = 0;

  bool displaySyncLoader = false;

  StreamSubscription<FGBGType> foregroundSubscription;

  initialize() async {
    var user = await UserService.getUser();
    this.user = user;
    userId = user.id;
    countryDialCode = user.countryCode.dialCode;
    username = user.firstName;

    syncContactBook();

    doGetContacts().then(onGetContactsSuccess, onError: onGetContactsError);

    contactPublisher.onNameUpdate(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      var contact = contacts.firstWhere((element) => element.contactBindingId == contactEvent.contactBindingId, orElse: () => null);
      if (contact != null) {
        setState(() {
          contact.contactName = contactEvent.value;
        });
      }
    });

    contactPublisher.onFavouritesUpdate(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      var contact = contacts.firstWhere((element) => element.contactBindingId == contactEvent.contactBindingId, orElse: () => null);
      if (contact != null) {
        setState(() {
          contact.favorite = contactEvent.value;
        });
      }
    });

    contactPublisher.onContactDelete(STREAMS_LISTENER_ID, (ContactEvent contactEvent) {
      setState(() {
        contacts.removeWhere((element) => element.contactBindingId == contactEvent.contactBindingId);
        totalContacts--;
      });
    });

    profilePublisher.onProfileImageUpdate(STREAMS_LISTENER_ID, (String profileImage) {
      setState(() {
        user.profileImagePath = profileImage;
      });
    });
  }

  syncContactBook() async {
    if (!ContactService.isSyncing) {
      ContactService.syncContacts(countryDialCode).then(onSyncSuccess);
      setState(() {
        displaySyncLoader = true;
      });
    }
  }

  @override
  initState() {
    super.initState();


    foregroundSubscription = FGBGEvents.stream.listen((event) {
      if (event == FGBGType.foreground) {
        syncContactBook();
      };
    });

    initialize();
  }

  @override
  void deactivate() {
    if (foregroundSubscription != null) {
      foregroundSubscription.cancel();
    }

    contactPublisher.removeListener(STREAMS_LISTENER_ID);

    profilePublisher.removeListener(STREAMS_LISTENER_ID);

    super.deactivate();
  }

  onSyncSuccess(List result) {
    print('ON SYNC - SUCCESS count=' + result.length.toString());
    totalContacts = totalContacts + result.length;

    result.forEach((contact) {
      contacts.insert(0, ContactDto.fromJson(contact));
    });

    setState(() {
      displaySyncLoader = false;
    });
  }

  @override
  preRender() async {
    floatingActionButton = FloatingActionButton(
      backgroundColor: Colors.white,
      elevation: 1,
      child: Icon(Icons.arrow_upward, color: CompanyColor.blueDark),
      onPressed: () {
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: BaseAppBar.getProfileAppBar(scaffold,
                titleText: 'Contacts',
                actions: [
                  TextButton(child: displaySyncLoader ? Spinner(size: 20)
                      : Icon(Icons.search, size: 24, color: CompanyColor.iconGrey),
                      onPressed: () {
                        NavigatorUtil.push(context, SearchContactsActivity(
                            type: SearchContactsType.CONTACT,
                            contacts: contacts
                        ));
                      }),
                ],
                bottomTabs: TabBar(
                    onTap: (index) {
                      selectedTabIndex = index;
                      setState(() {
                        displayLoader = true;
                      });
                      doGetContacts(clearData: true, favouritesOnly: index == 1)
                          .then(onGetContactsSuccess, onError: onGetContactsError);
                    },
                    indicatorColor: CompanyColor.blueDark,
                    tabs: [
                      Tab(text: 'All'),
                      Tab(text: 'Favourites'),
                    ]
                )),
            drawer: NavigationDrawerComponent(),
            bottomNavigationBar: new BottomNavigationComponent(currentIndex: 1).build(context),
            floatingActionButton: FloatingActionButton(
              elevation: 1,
              backgroundColor: CompanyColor.blueDark,
              child: Icon(Icons.edit, color: Colors.white),
              onPressed: () {
                NavigatorUtil.push(context, AddContactActivity(user: user));
              },
            ),
            body: Builder(builder: (context) {
              scaffold = Scaffold.of(context);
              return buildActivityContent();
            })
        )
    );
  }

  Widget buildActivityContent() {
    // Widget widget = ActivityLoader.build();
    Widget widget = ActivityLoader.contactsShimmer();

    if (!displayLoader) {
      if (!isError) {
        widget = Container(
          child: Column(
            children: [
              contacts != null && contacts.length > 0 ? buildListView() :
              Center(
                child: Container(
                  margin: EdgeInsets.all(25),
                  child: selectedTabIndex == 0 ? Column(
                    children: [
                      RoundProfileImageComponent(displayQuestionMarkImage: true),
                      Text('You don\'t have any contacts, add one and start Pinging!',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      Container(
                        margin: EdgeInsets.only(top: 25),
                        child: GradientButton(text: 'Add a contact', onPressed: () {
                          NavigatorUtil.push(context, AddContactActivity(user: this.user));
                        }),
                      )                    ],
                  ) : Text('You don\'t have any contacts in your favorites', style: TextStyle(color: Colors.grey)),
                ),
              ),
              // Container(
              //     child: Text(totalContacts > 0 ? 'Showing ${contacts.length} of ${totalContacts}' : '',
              //         style: TextStyle(color: Colors.grey.shade400, fontSize: 12))
              // ),
              Opacity(
                  opacity: isLoadingOnScroll ? 1 : 0,
                  child: LinearProgressLoader.build(context)
              )
            ],
          ),
        );
      } else {
        widget = InfoComponent.errorDonut(
          onButtonPressed: () async {
            setState(() {
              displayLoader = true;
              isError = false;
            });

            doGetContacts(clearData: true).then(onGetContactsSuccess, onError: onGetContactsError);
          }
        );
      }
    }

    return widget;
  }

  Widget buildListView() {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!displayLoader) {
          if (scrollInfo is UserScrollNotification) {
            UserScrollNotification userScrollNotification = scrollInfo as UserScrollNotification;
            if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent
                && userScrollNotification.direction == ScrollDirection.reverse) {
              getNextPageOnScroll();
            }
          }
        }
        return true;
      },
      child: Expanded(
        child: ListView.builder(
          itemCount: contacts == null ? 0 : contacts.length,
          itemBuilder: (context, index) {
            var contact = contacts[index];
            return GestureDetector(
              onTap: () {
                NavigatorUtil.push(context, SingleContactActivity(
                  peer: contact.contactUser,
                  userId: userId,
                  contactName: contact.contactName,
                  contactPhoneNumber: contact.contactPhoneNumber,
                  contactBindingId: contact.contactBindingId,
                  favorite: contact.favorite,
                  statusLabel: '',
                  myContactName: username,
                ));
              },
              child: Slidable(
                actionPane: SlidableDrawerActionPane(),
                actionExtentRatio: 0.2,
                actions: [],
                secondaryActions: [
                  IconSlideAction(
                    color: Colors.grey.shade300,
                    iconWidget: Container(
                        height: 35, width: 35,
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(contact.favorite ? Icons.star : Icons.star_border, color: Colors.yellow)),
                    onTap: () => doUpdateFavourites(contact, index).then(onUpdateFavouritesSuccess,
                        onError: (error) => onUpdateFavouritesError(contact, error)),
                  ),
                  IconSlideAction(
                    color: Colors.grey.shade300,
                    iconWidget: Container(
                        height: 35, width: 35,
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(Icons.delete, color: Colors.grey.shade800)),
                    onTap: () => doDeleteContact(contact).then(onDeleteContactSuccess,
                        onError: (error) => onDeleteContactError(contact, error)),
                  ),
                ],
                child: Column(
                  children: [
                    Container(
                      color: contact.favorite ? Colors.white : Colors.grey.shade50,
                      padding: EdgeInsets.only(left: 10, right: 10, top: 7.5, bottom: 7.5),
                      child: Row(
                          children: [
                            Container(
                                padding: EdgeInsets.only(right: 12.5),
                                child: Stack(
                                    alignment: AlignmentDirectional.topEnd,
                                    children: [
                                      RoundProfileImageComponent(displayQuestionMarkImage: contact.contactUser == null,
                                          url: contacts[index].contactUser?.profileImagePath,
                                          margin: 2.5, border: contact.favorite ? Border.all(color: Colors.yellow.shade700, width: 3) : null,
                                          borderRadius: 50, height: 50, width: 50, cacheWidth: 75,
                                      ),
                                    ])
                            ),
                            Expanded(
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
                                                        style: TextStyle(fontSize: 16, color: Colors.black87))
                                                ),
                                                contact.contactUser != null ? Visibility(
                                                    visible: contact.contactUser.displayMyFullName,
                                                    child: Text(
                                                        (contact.contactUser.firstName ?? '')
                                                            + ' '
                                                            + (contact.contactUser.lastName ?? ''),
                                                      style: TextStyle(
                                                        color: Colors.grey.shade500
                                                      ),
                                                    )
                                                ) : Container()
                                              ]
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                  Text(contact.contactPhoneNumber, style: TextStyle(color: Colors.grey))
                                ],
                              ),
                            )
                          ]
                      ),
                    ),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 500),
                      height: contact.displayLinearLoading ? 1 : 0,
                      child: LinearProgressLoader.build(context)
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<ContactDto> doUpdateFavourites(ContactDto contactDto, int index) async {
    setState(() {
      contactDto.displayLinearLoading = true;
    });

    String url = '/api/contacts/${contactDto.id}/favourite';

    http.Response response = await HttpClientService.post(url, body: !contactDto.favorite);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    await Future.delayed(Duration(milliseconds: 500));
    return contactDto;
  }

  onUpdateFavouritesSuccess(ContactDto contactDto) {
    setState(() {
      contactDto.favorite = !contactDto.favorite;
      contactDto.displayLinearLoading = false;
    });

    scaffold.removeCurrentSnackBar();
    if (contactDto.favorite) {
      scaffold.showSnackBar(SnackBarsComponent.success('${contactDto.contactName} added to favourites.'));
    } else {
      scaffold.showSnackBar(SnackBarsComponent.info('${contactDto.contactName} removed from favourites.'));
    }
  }

  onUpdateFavouritesError(contactDto, error) {
    setState(() {
      contactDto.displayLinearLoading = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
        content: 'Something went wrong, please try again.'
    ));
  }

  void getNextPageOnScroll() async {
    if (!isLoadingOnScroll) {
      setState(() {
        isLoadingOnScroll = true;
      });

      if (totalContacts != 0 && pageNumber * pageSize < totalContacts) {
        pageNumber++;
        doGetContacts(page: pageNumber).then(onGetContactsSuccess, onError: onGetContactsError);
      } else {
        setState(() {
          isLoadingOnScroll = false;
        });
        // scaffold.showSnackBar(SnackBar(
        //     content: Text('All contacts displayed', style: TextStyle(color: Colors.white)),
        //     duration: Duration(seconds: 2),
        //     backgroundColor: Theme.of(context).accentColor
        // ));
      }
    }
  }

  Future<dynamic> doGetContacts({page = 1, clearData = false, favouritesOnly = false}) async {
    if (clearData) {
      contacts.clear();
      pageNumber = 1;
    }

    String url = '/api/contacts'
        '?pageNumber=' + page.toString() +
        '&pageSize=' + pageSize.toString() +
        '&userId=' + userId.toString() +
        '&favourites=' + favouritesOnly.toString();

    http.Response response = await HttpClientService.get(url);

    await Future.delayed(Duration(milliseconds: 500));

    if(response.statusCode != 200) {
      throw new Exception();
    }

    dynamic result = response.decode();

    return {'contacts': result['page'], 'totalElements': result['totalElements']};
  }

  void onGetContactsSuccess(result) {
    scaffold.removeCurrentSnackBar();

    List fetchedContacts = result['contacts'];
    totalContacts = result['totalElements'];

    fetchedContacts.forEach((element) {
      contacts.add(ContactDto.fromJson(element));
    });

    setState(() {
      displayLoader = false;
      isLoadingOnScroll = false;
      isError = false;
    });
  }

  void onGetContactsError(Object error) {
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


      doGetContacts(clearData: true).then(onGetContactsSuccess, onError: onGetContactsError);
    }));
  }

  Future<ContactDto> doDeleteContact(contact) async {
    setState(() {
      contact.displayLinearLoading = true;
    });

    String url = '/api/contacts/${contact.id}/delete'
        '?contactBindingId=${contact.contactBindingId}'
        '&userId=${userId}';

    http.Response response = await HttpClientService.delete(url);

    await Future.delayed(Duration(seconds: 1));

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return contact;
  }

  void onDeleteContactSuccess(ContactDto contact) {
    setState(() {
      contact.displayLinearLoading = false;
    });

    contactPublisher.emitContactDelete(contact.contactBindingId);

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Contact ${contact.contactName} deleted'));
  }

  void onDeleteContactError(contact, error) {
    print(error);

    setState(() {
      contact.displayLinearLoading = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}
