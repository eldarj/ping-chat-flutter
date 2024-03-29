import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:http/http.dart' as http;

class SignUpFormActivity extends StatefulWidget {
  ClientDto clientDto;
  String token;

  SignUpFormActivity({this.clientDto, this.token});

  @override
  State<StatefulWidget> createState() => new SignUpFormActivityState();
}

class SignUpFormActivityState extends State<SignUpFormActivity> {
  static const String INVALID_FIELD_MESSAGE = 'Fields have to contain at least 3 characters';

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
                child: SingleChildScrollView(
                  child: Container(
                    width: 300,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(child: LogoComponent.horizontal),
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...buildDescriptionTextWidgets(),
                              Container(child: TextField(
                                onChanged: refreshState,
                                controller: firstNameController,
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                    hintText: 'Firstname',
                                    labelText: 'Firstname',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(15)),
                              )),
                              Container(margin: EdgeInsets.only(top: 15), child: TextField(
                                onChanged: refreshState,
                                controller: lastNameController,
                                keyboardType: TextInputType.text,
                                textCapitalization: TextCapitalization.words,
                                decoration: InputDecoration(
                                    hintText: 'Lastname',
                                    labelText: 'Lastname',
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
                                          : Text('Save'),
                                      onPressed: areInputsValid() && !displayLoader ? () {
                                        doUpdateFirstNameLastName(firstNameController.text, lastNameController.text)
                                            .then(onUpdateInfoSuccess, onError: onUpdateInfoError);
                                      } : null
                                  )
                                ]),
                              )
                            ])              ],
                    ),
                  ),
                ));
          })
      ),
    );
  }

  List<Widget> buildDescriptionTextWidgets() {
    return [
      Container(
        margin: EdgeInsets.only(top: 15),
        child: Text('Awesome, you are ready!',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
      ),
      Container(
          margin: EdgeInsets.only(top: 10, bottom: 10),
          child: Text('Please enter your first and last name before wrapping up your registration'))
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

    http.Response response = await HttpClientService.post('/api/users/${widget.clientDto.id}/name',
        body: {'firstName': firstName, 'lastName': lastName},
        token: widget.token);

    if (response.statusCode != 200) {
      throw new Exception();
    }
  }

  void onUpdateInfoSuccess(_) async {
    ClientDto user = widget.clientDto;

    user.firstName = firstNameController.text;
    user.lastName = lastNameController.text;

    await UserService.setUserAndToken(widget.token, user);

    setState(() {
      displayLoader = false;
    });

    scaffold.showSnackBar(SnackBarsComponent.success('You successfully registered!'));

    NavigatorUtil.replace(context, ChatListActivity());
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
