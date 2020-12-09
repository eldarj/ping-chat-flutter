

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
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
  @override
  State<StatefulWidget> createState() => new ContactsActivityState();
}

class ContactsActivityState extends BaseState<ContactsActivity> {
  ScaffoldState scaffold;

  @override
  Widget render() {
    return Center(
        child: Container(
          width: 300,
          child: Text('Contacts'),
        ));
  }
}
