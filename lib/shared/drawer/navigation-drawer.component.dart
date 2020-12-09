import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/chats.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/policy/policy-info.activity.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/drawer/partial/drawer-items.dart';
import 'package:flutterping/shared/drawer/partial/logout.dialog.dart';
import 'package:flutterping/util/base/base.state.dart';

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
  bool isLoading = true;

  String userProfileImagePath;

  initializeUserDetails() async {
    setState(() {
      isLoading = true;
    });
    await Future.delayed(Duration(seconds: 2));
    setState(() {
      isLoading = false;
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
                      margin: const EdgeInsets.only(bottom: 0),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.white)),
                      child: Column(
                          children: [
                            isLoading ? Container(margin:EdgeInsets.all(20), height: 80, width: 80, child: CircularProgressIndicator())
                                : Container(
                                margin: EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                    boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 25, spreadRadius: 5)],
                                    borderRadius: BorderRadius.all(Radius.circular(100))
                                ),
                                child: new RoundProfileImageComponent(url: userProfileImagePath,
                                    height: 100, width: 100, borderRadius: 100, margin: 0)),
                            isLoading ? Column(children: [
                              Container(margin: EdgeInsets.only(bottom: 5), color: Colors.grey.shade200, height: 20, width: 120),
                              Container(color: Colors.grey.shade200, height: 20, width: 50),
                            ]) : Column(children: [
                              Text("Eldar Jahijagic", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400)),
                              Container(
                                margin: EdgeInsets.only(top: 5),
                                child: Row(mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Text("+38762005152", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
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
                            labelDescription: 'pingme@eldarj'),
                        buildDrawerItem(context, 'Active status',
                            buildIcon(icon: Icons.check,
                                backgroundColor: Colors.deepPurpleAccent.shade200),
                            labelDescription: true ? "On" : "Off"),
                        buildDrawerItem(context, 'FeedBack',
                            buildIcon(iconPath: "static/graphic/icon/qrcode.png")),
                        buildSectionTitle("Chats"),
                        buildDrawerItem(context, 'Chats',
                            buildIcon(icon: Icons.chat, backgroundColor: Colors.green.shade400),
                            activity: ChatsActivity()
                        ),
                        buildDrawerItem(context, 'My contacts',
                            buildIcon(icon: Icons.people, backgroundColor: Colors.orangeAccent.shade700),
                            activity: ContactsActivity()
                        ),
                        buildDrawerItem(context, 'Add contact', buildIcon(icon: Icons.group_add, backgroundColor: Colors.deepPurpleAccent.shade200)),
                        buildDrawerItem(context, 'Sync phone contacts', buildIcon(icon: Icons.contact_phone, backgroundColor: Colors.blue.shade700),
                            labelDescription: 'Add all contacts from phone'),
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
                          color: Colors.grey.shade200,
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
