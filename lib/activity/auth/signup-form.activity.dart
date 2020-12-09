import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/shared/component/spinner.element.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/util/http/http-client.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class SignUpFormActivity extends StatefulWidget {
  ClientDto clientDto;

  SignUpFormActivity({this.clientDto});

  @override
  State<StatefulWidget> createState() => new SignUpFormActivityState();
}

class SignUpFormActivityState extends State<SignUpFormActivity> {
  static const String INVALID_FIELD_MESSAGE = 'Polja moraju biti duža od 3 slova';

  ScaffoldState scaffold;

  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  String validationMessage = '';
  bool displayLoader = false;

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          body: Builder(builder: (context) {
            scaffold = Scaffold.of(context);
            return Center(
                child: Container(
                  width: 300,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildImageCover(),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            ..._buildDescriptionTextWidgets(),
                            Container(child: TextField(
                              controller: firstNameController,
                              onChanged: refreshState,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                  hintText: 'Ime',
                                  labelText: 'Ime',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(15)),
                            )),
                            Container(margin: EdgeInsets.only(top: 15), child: TextField(
                              controller: lastNameController,
                              onChanged: refreshState,
                              keyboardType: TextInputType.text,
                              decoration: InputDecoration(
                                  hintText: 'Prezime',
                                  labelText: 'Prezime',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.all(15)),
                            )),
                            Container(
                                margin: EdgeInsets.only(top: 5, left: 2),
                                child: Text(validationMessage,
                                    style: TextStyle(color: Colors.red))),
                            Container(
                              margin: EdgeInsets.only(top: 20),
                              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                                GradientButton(
                                    child: displayLoader ? Container(height: 20, width: 20, child: Spinner())
                                        : Text('Snimi'),
                                    onPressed: areInputsValid() && !displayLoader ? () {
                                      doUpdateFirstNameLastName(firstNameController.text, lastNameController.text)
                                          .then(onUpdateInfoSuccess, onError: onUpdateInfoError);
                                    } : null
                                )
                              ]),
                            )
                          ])              ],
                  ),
                ));
          })
      ),
    );
  }

  Container _buildImageCover() {
    return Container(child: LogoComponent.build(imageHeight: 60, displayText: false));
  }

  List<Widget> _buildDescriptionTextWidgets() {
    return [
      Container(
        margin: EdgeInsets.only(top: 15),
        child: Text('Odlično, spremni ste!',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      ),
      Container(
          margin: EdgeInsets.only(top: 10, bottom: 10),
          child: Text('Unesite vaše ime i prezime'))
    ];
  }

  bool areInputsValid() {
    var valid = firstNameController.text.length >= 3 && lastNameController.text.length >= 3;
    this.validationMessage = valid ? '' : INVALID_FIELD_MESSAGE;
    return valid;
  }

  void refreshState(_) => setState(() {
    // refresh state
  });

  Future<void> doUpdateFirstNameLastName(firstName, lastName) async {
    FocusScope.of(context).unfocus();

    setState(() {
      this.displayLoader = true;
    });

    await Future.delayed(Duration(seconds: 1));

    http.Response response = await HttpClient.post('/api/users/${widget.clientDto.id}/name',
        body: {'firstName': firstName, 'lastName': lastName});

    if (response.statusCode != 200) {
      throw new Exception();
    }
  }

  void onUpdateInfoSuccess(_) async {
    ClientDto user = await UserService.getUser();
    user.firstName = firstNameController.text;
    user.lastName = lastNameController.text;
    await UserService.setUser(user);

    setState(() {
      displayLoader = false;
    });

    scaffold.showSnackBar(SnackBarsComponent.success('Uspješno ste snimili podatke!'));

    await Future.delayed(Duration(seconds: 1));

    NavigatorUtil.replace(context, ContactsActivity());
  }

  void onUpdateInfoError(_) {
    setState(() {
      displayLoader = false;
    });

    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () {
      doUpdateFirstNameLastName(firstNameController.text, lastNameController.text)
          .then(onUpdateInfoSuccess, onError: onUpdateInfoError);
    }));
  }
}
