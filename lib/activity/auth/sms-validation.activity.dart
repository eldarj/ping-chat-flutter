import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/service/user.prefs.service.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/component/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/http/http-client.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/activity/auth/signup-form.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/model/jwt-token-dto.model.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/component/top-pane.component.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';

class SmsValidationActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new SmsValidationState();
  }
}

class SmsValidationState extends State<SmsValidationActivity> {
  ScaffoldState scaffold;

  bool displayLoader = false;

  String smsAuthenticationCode = '';
  String smsValidationMessage = '';
  int smsValidationRetryCount = 0;

  String dialCodeArg;
  String phoneNumberArg;

  JwtTokenDto jwtTokenDto;

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => showSuccessSnackbar());
    super.initState();
  }

  setPassedArguments() {
    var bundledArgs = ModalRoute.of(context).settings.arguments as Map<String, String>;
    phoneNumberArg = bundledArgs['phoneNumber'];
    dialCodeArg = bundledArgs['dialCode'];
  }

  @override
  Widget build(BuildContext context) {
    setPassedArguments();
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return TopPaneComponent.build(Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    LogoComponent.build(),
                    _buildDescriptionContainer(),
                    _buildPinCodeContainer(),
                    _buildValidationContainer(),
                    _buildActionContainer(context)
                  ])));
        }));
  }

  Container _buildActionContainer(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 100),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GradientButton(
                child: displayLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Dalje'),
                onPressed: smsAuthenticationCode.length == 6 && !displayLoader ?
                    () => onGetValidated(context) : null)
          ]),
    );
  }

  Container _buildValidationContainer() {
    return Container(
        margin: EdgeInsets.only(top: 5, left: 2),
        child: Text(smsValidationMessage,
            style: TextStyle(color: Colors.red))
    );
  }

  Container _buildPinCodeContainer() {
    return Container(
        margin: EdgeInsets.only(top: 10),
        child: TextField(
          keyboardType: TextInputType.numberWithOptions(),
          inputFormatters: [
            WhitelistingTextInputFormatter.digitsOnly
          ],
          onChanged: (value) {
            setState(() {
              smsAuthenticationCode = value;
            });
          },
          decoration: InputDecoration(
              hintText: 'Sestocifreni kod',
              labelText: 'SMS PIN Kod',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(15)),
        )
    );
  }

  Container _buildDescriptionContainer() {
    return Container(
        margin: EdgeInsets.only(left: 2.5, right: 2.5, top: 15, bottom: 15), child: RichText(
        text: TextSpan(
          text: 'Molimo unesite šestocifreni PIN kod koji smo vam poslali na ',
          style: TextStyle(color: Colors.black87),
          children: [
            TextSpan(text: ' $dialCodeArg $phoneNumberArg', style: TextStyle(color: CompanyColor.bluePrimary, fontWeight: FontWeight.bold))
          ],
        )));
  }

  void showSuccessSnackbar() {
    scaffold.showSnackBar(SnackBarsComponent.success('Odlično! Još jedan korak i spremni ste.'));
  }

  void onGetValidated(BuildContext context) {
    FocusScope.of(context).unfocus();

    setState(() {
      displayLoader = true;
    });

    doSendAuthRequest(dialCodeArg, phoneNumberArg, smsAuthenticationCode)
        .then(onAuthRequestSuccess, onError: onAuthRequestError);
  }

  Future<Map<String, dynamic>> doSendAuthRequest(String dialCode, String phoneNumber, String pinCode) async {
    http.Response response = await HttpClient.post('/api/authenticate',
        headers: {'phoneNumber': phoneNumber, 'dialCode': dialCode, 'pinCode': pinCode});

    if (response.statusCode == 400) {
      throw new Exception("Error, received 400 response.");
    }

    var responseBody = response.decode();
    return {
      'token': response.headers['authorization'],
      'user': ClientDto.fromJson(responseBody['user'])
    };
  }

  void onAuthRequestSuccess(Map<String, dynamic> response) async {
    setState(() {
      displayLoader = false;
    });

    dynamic user = response['user'];
    await UserService.setUserAndToken(response['token'], user);

    if (user.firstName == null && user.lastName == null) {
      NavigatorUtil.push(context, SignUpFormActivity(clientDto: user));
    } else {
      NavigatorUtil.push(context, ContactsActivity());
    }
  }

  void onAuthRequestError(Object error) {
    FocusScope.of(context).unfocus();

    setState(() { displayLoader = false; });

    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () {
      setState(() {
        displayLoader = true;
        smsValidationMessage = ++smsValidationRetryCount > 3
            ? 'Imate problema? Molimo kontaktirajte support@ping.me'
            : '';
      });
      doSendAuthRequest(dialCodeArg, phoneNumberArg, smsAuthenticationCode)
          .then(onAuthRequestSuccess, onError: onAuthRequestError);
    }));
  }
}
