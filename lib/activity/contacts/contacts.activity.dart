import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutterping/activity/contacts/add-contact.activity.dart';
import 'package:flutterping/activity/contacts/search-contacts.activity.dart';
import 'package:flutterping/activity/contacts/single-contact.activity.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/linear-progress-loader.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class ContactsActivity extends StatefulWidget {
  final bool displaySavedContactSnackbar;
  final String savedContactName;
  final String savedContactPhoneNumber;

  const ContactsActivity({this.displaySavedContactSnackbar = false, this.savedContactName, this.savedContactPhoneNumber}): super();

  @override
  State<StatefulWidget> createState() => new ContactsActivityState();
}

class ContactsActivityState extends BaseState<ContactsActivity> {
  var displayLoader = true;

  int userId = 0;

  String username;

  List<ContactDto> contacts = new List();
  int totalContacts = 0;

  bool isLoadingOnScroll = false;
  int pageNumber = 1;
  int pageSize = 50;

  int selectedTabIndex = 0;

  getContacts() async {
    var user = await UserService.getUser();
    userId = user.id;
    username = user.firstName;

    doGetContacts().then(onGetContactsSuccess, onError: onGetContactsError);
  }

  @override
  initState() {
    super.initState();
    if (widget.displaySavedContactSnackbar) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scaffold.showSnackBar(SnackBarsComponent
            .success('Contact ${widget.savedContactName} (${widget.savedContactPhoneNumber}) successfully added!'));
      });
    }
    getContacts();
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
                  IconButton(icon: Icon(Icons.search),
                      onPressed: () {
                        NavigatorUtil.push(context, SearchContactsActivity(
                            type: SearchContactsType.CONTACT,
                            contacts: contacts));
                      }),
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: IconButton(icon: Icon(Icons.person_add),
                        onPressed: () {
                          NavigatorUtil.push(context, AddContactActivity());
                        }),
                  ),
                ],
                bottomTabs: TabBar(
                    onTap: (index) {
                      selectedTabIndex = index;
                      setState(() {
                        displayLoader = true;
                      });
                      doGetContacts(clearRides: true, favouritesOnly: index == 1)
                          .then(onGetContactsSuccess, onError: onGetContactsError);
                    },
                    tabs: [
                      Tab(icon: Icon(Icons.people)),
                      Tab(icon: Icon(Icons.star_border)),
                    ]
                )),
            drawer: NavigationDrawerComponent(),
            bottomNavigationBar: new BottomNavigationComponent(currentIndex: 1).build(context),
            floatingActionButton: FloatingActionButton(
              elevation: 1,
              backgroundColor: CompanyColor.blueDark,
              child: Icon(Icons.search, color: Colors.white),
              onPressed: () {
                print('USER ID');
                print(userId.toString());
                NavigatorUtil.push(context, SearchContactsActivity(
                    type: SearchContactsType.CONTACT,
                    contacts: contacts
                ));
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
    Widget widget = ActivityLoader.build();

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
                          NavigatorUtil.push(context, AddContactActivity());
                        }),
                      )                    ],
                  ) : Text('You don\'t have any contacts in your favorites', style: TextStyle(color: Colors.grey)),
                ),
              ),
              Container(
                  child: Text(totalContacts > 0 ? 'Showing ${contacts.length} of ${totalContacts}' : '',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12))
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

          doGetContacts(clearRides: true).then(onGetContactsSuccess, onError: onGetContactsError);
        });
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
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(contact.favorite ? Icons.star : Icons.star_border, color: Colors.yellow)),
                    onTap: () => doUpdateFavourites(contact, index).then(onUpdateFavouritesSuccess, onError: onUpdateFavouritesError),
                  ),
                  IconSlideAction(
                    color: Colors.grey.shade300,
                    iconWidget: Container(
                        padding: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Icon(Icons.delete, color: Colors.red)),
                    onTap: () => print('Delete'),
                  ),
                ],
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
                                                margin: EdgeInsets.only(bottom: 5),
                                                child: Text(contact.contactName,
                                                    style: TextStyle(fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black87))
                                            ),
                                            contact.contactUser != null ? Visibility(
                                                visible: contact.contactUser.displayMyFullName,
                                                child: Text(contact.contactUser.firstName + ' ' +
                                                    contact.contactUser.lastName)
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
              ),
            );
          },
        ),
      ),
    );
  }

  Future<ContactDto> doUpdateFavourites(ContactDto contactDto, int index) async {
    String url = '/api/contacts/${contactDto.id}/favourite';

    http.Response response = await HttpClientService.post(url, body: !contactDto.favorite);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    return contactDto;
  }

  onUpdateFavouritesSuccess(ContactDto contactDto) {
    setState(() {
      contactDto.favorite = !contactDto.favorite;
    });

    scaffold.removeCurrentSnackBar();
    if (contactDto.favorite) {
      scaffold.showSnackBar(SnackBarsComponent.success('${contactDto.contactName} added to favourites.'));
    } else {
      scaffold.showSnackBar(SnackBarsComponent.info('${contactDto.contactName} removed from favourites.'));
    }
  }

  onUpdateFavouritesError(error) {
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
        scaffold.showSnackBar(SnackBar(
            content: Text('All contacts displayed', style: TextStyle(color: Colors.white)),
            duration: Duration(seconds: 2),
            backgroundColor: Theme.of(context).accentColor
        ));
      }
    }
  }

  Future<dynamic> doGetContacts({page = 1, clearRides = false, favouritesOnly = false}) async {
    if (clearRides) {
      contacts.clear();
      pageNumber = 1;
    }

    String url = '/api/contacts'
        '?pageNumber=' + page.toString() +
        '&pageSize=' + pageSize.toString() +
        '&userId=' + userId.toString() +
        '&favourites=' + favouritesOnly.toString();

    http.Response response = await HttpClientService.get(url);

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


      doGetContacts(clearRides: true).then(onGetContactsSuccess, onError: onGetContactsError);
    }));
  }
}
