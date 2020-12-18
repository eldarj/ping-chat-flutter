import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/contacts/add-contact.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/policy/policy-info.activity.dart';
import 'package:flutterping/activity/profile/my-profile.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/drawer/partial/drawer-items.dart';
import 'package:flutterping/shared/drawer/partial/logout.dialog.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class NavigationDrawerLeading {
  static build(onPressed) {
    return IconButton(
        icon: Image.asset('static/graphic/icon/menu.png', color: Colors.black, height: 25, width: 25),
        onPressed: onPressed);
  }
}

class NavigationDrawerComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => NavigationDrawerComponentState();
}

class NavigationDrawerComponentState extends BaseState<NavigationDrawerComponent> {
  ClientDto user;

  bool displayLoader = true;

  initializeUserDetails() async {
    user = await UserService.getUser();
    setState(() {
      displayLoader = false;
    });

  }

  @override
  void initState() {
    super.initState();
    initializeUserDetails();
  }

  @override
  Widget render() {
    return Container(
        width: MediaQuery.of(context).size.width,
        child: Drawer(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  Container(
                    color: Colors.white,
                    height: 245.0,
                    child: DrawerHeader(
                      margin: const EdgeInsets.only(top: 10, bottom: 0),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.white)),
                      child: Column(
                          children: [
                            displayLoader ? Container(margin:EdgeInsets.all(20), height: 80, width: 80, child: CircularProgressIndicator())
                                : Container(
                                margin: EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                    boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 25, spreadRadius: 5)],
                                    borderRadius: BorderRadius.all(Radius.circular(100))
                                ),
                                child: new RoundProfileImageComponent(url: user.profileImagePath,
                                    height: 100, width: 100, borderRadius: 100, margin: 0)),
                            displayLoader ? Column(children: [
                              Container(margin: EdgeInsets.only(bottom: 5), color: CompanyColor.backgroundGrey, height: 20, width: 120),
                              Container(color: CompanyColor.backgroundGrey, height: 20, width: 50),
                            ]) : Column(children: [
                              Text(user.firstName + " " + user.lastName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
                              Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text(user.countryCode.dialCode + " " + user.phoneNumber, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
                                  ],
                                ),
                              ),
                            ]),
                          ]
                      ),
                    ),
                  ),
                  Container(
                    child: SingleChildScrollView(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        SizedBox(height: 15),
                        buildSectionTitle("Profile"),
                        buildDrawerItem(context, 'My profile',
                            buildIcon(iconPath: "static/graphic/icon/at.png", backgroundColor: Colors.red),
                            labelDescription: 'pingme@eldarj',
                            activity: MyProfileActivity()),
                        buildDrawerItem(context, 'Active status',
                            buildIcon(icon: Icons.check,
                                backgroundColor: Colors.deepPurpleAccent.shade200),
                            labelDescription: true ? "On" : "Off"),
                        buildDrawerItem(context, 'FeedBack',
                            buildIcon(iconPath: "static/graphic/icon/qrcode.png")),

                        buildSectionTitle("Chats"),
                        buildDrawerItem(context, 'Chats',
                            buildIcon(icon: Icons.chat, backgroundColor: Colors.green.shade400),
                            activity: ChatListActivity()),
                        buildDrawerItem(context, 'My contacts',
                            buildIcon(icon: Icons.people, backgroundColor: Colors.orangeAccent.shade700),
                            activity: ContactsActivity()),
                        buildDrawerItem(context, 'Add contact',
                          buildIcon(icon: Icons.group_add, backgroundColor: Colors.deepPurpleAccent.shade200),
                          labelDescription: 'Add new or sync phone contacts',
                          onTapFunction: () {
                            showModalBottomSheet(context: context, builder: (BuildContext context) {
                              return Container(
                                  child: Wrap(children: [
                                    ListTile(leading: Icon(Icons.person_add),
                                        title: Text('Novi kontakt'),
                                        onTap: () {
                                          NavigatorUtil.push(context, AddContactActivity());
                                        }),
                                    ListTile(leading: Icon(Icons.contacts),
                                        title: Text('Sync phone contacts'),
                                        onTap: () {
                                          NavigatorUtil.push(context, AddContactActivity());
                                        }),
                                  ])
                              );
                            });
                          },
                        ),

                        buildSectionTitle("Preferences"),
                        buildDrawerItem(context, 'Account',
                            buildIcon(icon: Icons.settings, backgroundColor: Colors.orangeAccent),
                            labelDescription: 'Account settings'),
                        buildDrawerItem(context, 'Privacy',
                            buildIcon(icon: Icons.lock, backgroundColor: Colors.blueGrey,)),
                        buildDrawerItem(context, 'Notification and Sounds',
                            buildIcon(icon: Icons.notifications, backgroundColor: Colors.deepPurpleAccent)),
                        buildDrawerItem(context, 'Media and Storage',
                            buildIcon(icon: Icons.image)),

                        buildSectionTitle("Help & FAQ"),
                        buildDrawerItem(context, 'Kontaktirajte nas',
                          buildIcon(icon: Icons.email, backgroundColor: Colors.lightBlue.shade300),
                        ),
                        buildDrawerItem(context, 'Uslovi korištenja',
                            buildIcon(icon: Icons.copyright, backgroundColor: Colors.blueGrey.shade800),
                            activity: PolicyInfoActivity()
                        ),
                        Container(
                          color: CompanyColor.backgroundGrey,
                          margin: EdgeInsets.only(top: 25),
                          padding: EdgeInsets.only(top: 10, bottom: 10),
                          child: buildDrawerItem(context, 'Odjavi se',
                              buildIcon(icon: Icons.exit_to_app, backgroundColor: Colors.red.shade300),
                              onTapFunction: () => showDialog(context: context, builder: (BuildContext context) {
                                return LogoutDialog();
                              })),
                        ),
                      ]),
                    ),
                  )
                ],
              ),
            )
        )
    );
  }
}
