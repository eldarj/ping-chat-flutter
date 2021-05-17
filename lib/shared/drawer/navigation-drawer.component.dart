import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/chats/component/share-files/share-files.modal.dart';
import 'package:flutterping/activity/contacts/add-contact.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/contacts/qr-scanner.activity.dart';
import 'package:flutterping/activity/data-space/data-space.activity.dart';
import 'package:flutterping/activity/policy/policy-info.activity.dart';
import 'package:flutterping/activity/profile/my-profile.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/presence-event.model.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/service/profile/profile.publisher.dart';
import 'package:flutterping/service/ws/ws-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/partial/drawer-items.dart';
import 'package:flutterping/shared/drawer/partial/logout.dialog.dart';
import 'package:flutterping/shared/modal/floating-modal.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

class NavigationDrawerComponent extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => NavigationDrawerComponentState();
}

class NavigationDrawerComponentState extends BaseState<NavigationDrawerComponent> {
  static const String STREAMS_LISTENER_ID = "NavigationDrawerListener";

  ClientDto user;

  bool displayLoader = true;

  init() async {
    user = await UserService.getUser();
    setState(() {
      displayLoader = false;
    });

    profilePublisher.onProfileImageUpdate(STREAMS_LISTENER_ID, (String profileImage) {
      setState(() {
        user.profileImagePath = profileImage;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    profilePublisher.removeListener(STREAMS_LISTENER_ID);
    super.dispose();
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
              child: Column(
                children: [
                  BaseAppBar.getCloseAppBar(() => scaffold.context),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        Material(
                          color: Colors.white,
                          elevation: 10.0,
                          shadowColor: Color.fromRGBO(0, 0, 0, 0.2),
                          child: InkWell(
                            onTap: () {
                              NavigatorUtil.push(context, MyProfileActivity());
                            },
                            child: Container(
                              padding: EdgeInsets.only(top: 20, bottom: 30),
                              child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    displayLoader ? Container(margin:EdgeInsets.all(20), height: 80, width: 80, child: CircularProgressIndicator())
                                        : Container(
                                        margin: EdgeInsets.only(bottom: 20),
                                        decoration: BoxDecoration(
                                            boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 15, spreadRadius: 2.5)],
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
                        ),
                        Container(
                          child: !displayLoader ? SingleChildScrollView(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              SizedBox(height: 15),
                              buildSectionTitle("Me"),
                              buildDrawerItem(context, 'My profile',
                                  buildIcon(icon: Icons.alternate_email, backgroundColor: Colors.red),
                                  activity: MyProfileActivity()),
                              buildDrawerItem(context, 'Active status',
                                buildIcon(icon: user.isActive ? Icons.check : Icons.visibility_off,
                                    backgroundColor: user.isActive ? Colors.green : Colors.grey),
                                labelDescription: user.isActive ? "On" : "Off",
                                onTapFunction: () {
                                  showModalBottomSheet(context: context, builder: (BuildContext context) {
                                    return Container(
                                        child: Wrap(children: [
                                          ListTile(leading: Icon(Icons.check_circle, color: Colors.green),
                                              title: Text('Display my status'),
                                              onTap: setPresenceStatusOnline),
                                          ListTile(leading: Icon(Icons.visibility_off),
                                              title: Text('Appear offline'),
                                              onTap: setPresenceStatusOffline),
                                        ])
                                    );
                                  });
                                },
                              ),
                              buildSectionTitle("Chats"),
                              buildDrawerItem(context, 'Chats',
                                  buildIcon(icon: Icons.chat, backgroundColor: Colors.blue),
                                  activity: ChatListActivity()),
                              buildDrawerItem(context, 'My contacts',
                                  buildIcon(icon: Icons.people, backgroundColor: Colors.orangeAccent.shade700),
                                  activity: ContactsActivity()),
                              buildDrawerItem(context, 'Add contact',
                                buildIcon(icon: Icons.group_add, backgroundColor: Colors.deepPurpleAccent.shade200),
                                labelDescription: 'Add new or sync phone contacts',
                                onTapFunction: () {
                                  showCustomModalBottomSheet(context: context,
                                      expand: false,
                                      containerWidget: (_, animation, child) => FloatingModal(child: child),
                                      builder: (BuildContext context) {
                                        return Wrap(children: [
                                          ListTile(leading: Icon(Icons.person_add),
                                              title: Text('New contact'),
                                              onTap: () {
                                                NavigatorUtil.push(context, AddContactActivity(
                                                    user: user
                                                ));
                                              }),
                                          ListTile(
                                              leading: Icon(Icons.qr_code),
                                              title: Text('Scan QR'),
                                              onTap: () {
                                                NavigatorUtil.push(context, QrScannerActivity(
                                                    user: user
                                                ));
                                              }),
                                          // ListTile(leading: Icon(Icons.contacts),
                                          //     title: Text('Sync phone contacts'),
                                          //     onTap: () {
                                          //       NavigatorUtil.push(context, AddContactActivity(
                                          //           user: user
                                          //       ));
                                          //     }),
                                        ]);
                                      });
                                },
                              ),
                              buildSectionTitle("Data Space"),
                              buildDrawerItem(context, 'My dataspace',
                                  buildIcon(icon: Icons.image, backgroundColor: Colors.redAccent),
                                  activity: DataSpaceActivity(userId: user.id),
                                  labelDescription: 'Your stored data and shared media'),
                              buildSectionTitle("Help & FAQ"),
                              buildDrawerItem(context, 'Terms of Services and Privacy Policy',
                                  buildIcon(icon: Icons.copyright, backgroundColor: Colors.blueGrey.shade800),
                                  activity: PolicyInfoActivity()
                              ),
                              Container(
                                color: CompanyColor.backgroundGrey,
                                margin: EdgeInsets.only(top: 25),
                                padding: EdgeInsets.only(top: 10, bottom: 10),
                                child: buildDrawerItem(context, 'Logout',
                                    buildIcon(icon: Icons.exit_to_app, backgroundColor: Colors.red.shade300),
                                    onTapFunction: () => showDialog(context: context, builder: (BuildContext context) {
                                      return LogoutDialog();
                                    })),
                              ),
                            ]),
                          ) : Container(margin:EdgeInsets.all(20),
                              color: CompanyColor.backgroundGrey,
                              height: 300),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            )
        )
    );
  }

  void setPresenceStatusOnline() async {
    PresenceEvent presenceEvent = new PresenceEvent();
    presenceEvent.userPhoneNumber = user.fullPhoneNumber;
    presenceEvent.status = true;

    sendPresenceEvent(presenceEvent);
    await UserService.setUserStatus(true);
    user = await UserService.getUser();
    setState(() {
    });

    Navigator.pop(context);
    scaffold.showSnackBar(SnackBarsComponent.success('Your online status will be publicly visible.'));
  }


  void setPresenceStatusOffline() async {
    PresenceEvent presenceEvent = new PresenceEvent();
    presenceEvent.userPhoneNumber = user.fullPhoneNumber;
    presenceEvent.status = false;

    sendPresenceEvent(presenceEvent);
    await UserService.setUserStatus(false);
    user = await UserService.getUser();
    setState(() {
    });

    Navigator.pop(context);
    scaffold.showSnackBar(SnackBarsComponent.info("Your status will be shown as 'offline'."));
  }
}
