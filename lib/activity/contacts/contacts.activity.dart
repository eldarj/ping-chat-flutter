

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/bottom-navigation-bar/bottom-navigation.component.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/util/base/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/shared/component/spinner.element.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/util/http/http-client.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class ContactsActivity extends StatefulWidget {
  const ContactsActivity();

  @override
  State<StatefulWidget> createState() => new ContactsActivityState();
}

class ContactsActivityState extends BaseState<ContactsActivity> {
  var displayLoader = true;

  @override
  preRender() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scaffold.showSnackBar(SnackBarsComponent.success('Awesome, you\'re all ready to start Pinging!'));
    });

    appBar = BaseAppBar.getProfileAppBar(scaffold,
        titleText: 'Contacts', actions: [
          IconButton(
              icon: Icon(Icons.calendar_today),
              color: Colors.grey,
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ContactsActivity()));
              }),
        ]);

    BottomNavigationComponent createState = new BottomNavigationComponent(currentIndex: 1);
    bottomNavigationBar = createState.build(context);

    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return buildActivityContent();
  }

  Widget buildActivityContent() {
    Widget widget = ActivityLoader.build();

    if (!displayLoader) {
      widget = Column(
          children: [
            Expanded(
              child: Container(
                child: Text('Hey'),
              ),
            ),
          ]
      );
    }

    return widget;
  }
}
