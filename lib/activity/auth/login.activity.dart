import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/top-pane.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/activity/auth/sms-validation.activity.dart';
import 'package:flutterping/model/country-code-dto.model.dart';
import 'package:flutterping/shared/component/logo.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class LoginActivity extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new LoginActivityState();
}

class LoginActivityState extends State<LoginActivity> {
  static final validPhoneNumberChars = RegExp(r'^[0-9]+$');
  ScaffoldState scaffold;

  bool displayLoader = false;

  TextEditingController phoneNumberController = TextEditingController();
  String phoneNumberValidationMessage = '';

  bool countryCodesLoaded = false;
  Map<String, String> dialCodesMap = {};

  String selectedCallingCodeId = 'placeholder';
  List<DropdownMenuItem<String>> callingCodes = [
    DropdownMenuItem(value: 'placeholder', child: Text('Country code'))
  ];

  init() async {
    setState(() {
      this.displayLoader = true;
    });
    doGetCountryCodes().then(onSuccessCountryCodes, onError: onErrorCountryCodes);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return TopPaneComponent.build(AbsorbPointer(
              absorbing: !countryCodesLoaded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LogoComponent.build(),
                  _buildDescriptionContainer(),
                  _buildCountryCodeContainer(),
                  _buildPhoneNumberContainer(),
                  _buidValidationContainer(),
                  _buildActionsContainer(context),
                ],
              )
          ));
        }));
  }

  Container _buildActionsContainer(BuildContext context) {
    return Container(
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        GradientButton(
          child: displayLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Get started'),
          onPressed: countryCodesLoaded && !displayLoader ?
              () => onGetStarted(context) : null,
        )
      ]),
    );
  }

  Widget _buildPhoneNumberContainer() {
    return AnimatedOpacity(
      opacity: countryCodesLoaded ? 1 : 0.5,
      duration: Duration(milliseconds: 500),
      child: TextField(
        controller: phoneNumberController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
            hintText: 'Phonenumber',
            labelText: 'Phonenumber',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.all(15)),
      ),
    );
  }

  Container _buidValidationContainer() {
    return Container(margin: EdgeInsets.only(top: 5, left: 2),
        child: Text(phoneNumberValidationMessage, style: TextStyle(color: CompanyColor.red))
    );
  }

  Widget _buildCountryCodeContainer() {
    return AnimatedOpacity(
      opacity: countryCodesLoaded ? 1 : 0.5,
      duration: Duration(milliseconds: 500),
      child: Container(
          margin: EdgeInsets.only(top: 10, bottom: 20),
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(color: Colors.grey, style: BorderStyle.solid, width: 1),
          ),
          child: DropdownButtonHideUnderline(
              child: DropdownButton(
                isExpanded: true,
                value: selectedCallingCodeId,
                items: callingCodes,
                onChanged: (selection) => onChangeCountryCode(selection),
              ))
      ),
    );
  }

  Container _buildDescriptionContainer() {
    return Container(
        margin: EdgeInsets.only(left: 2.5, right: 2.5, top: 10, bottom: 5), child: Text(
        'We\'ll send you a 2FA PIN verification code via SMS'
    ));
  }

  void onGetStarted(BuildContext context) {
    // refresh the state
    setState(() {
      phoneNumberValidationMessage = phoneNumberController.text.length == 0
          ? 'Enter your phonenumber'
          : !validPhoneNumberChars.hasMatch(phoneNumberController.text) ? 'Phonenumber can contain digits only.' : '';
    });

    if (phoneNumberValidationMessage.length > 0) {
      scaffold.showSnackBar(SnackBarsComponent.error(content: 'Please fix the above errors', duration: Duration(seconds: 2)));
    } else {
      setState(() { displayLoader = true; });
      doSendAuthRequest(dialCodesMap[selectedCallingCodeId], phoneNumberController.text)
          .then(onSuccessAuthRequest, onError: onErrorAuthRequest);
    }
  }

  void onChangeCountryCode(String selection) {
    setState(() { selectedCallingCodeId = selection; });
  }

  Future<List<DropdownMenuItem<String>>> doGetCountryCodes() async {
    http.Response response = await HttpClientService.get('/api/country-codes');
    Map<String, dynamic> responseBody = json.decode(response.body);

    return responseBody.entries.map<DropdownMenuItem<String>>((entry) {
      CountryCodeDto countryCode = CountryCodeDto.fromJson(entry.value);
      dialCodesMap[countryCode.id.toString()] = countryCode.dialCode;
      return new DropdownMenuItem(
          value: '${entry.value['id']}',
          child: new Text(
              '${entry.value['dialCode']} - ${entry.value['countryName']}'));
    }).toList();
  }

  Future<bool> doSendAuthRequest(String dialCode, String phoneNumber) async {
    FocusScope.of(context).unfocus();

    http.Response response = await HttpClientService.post('/api/authenticate',
        headers: {'phoneNumber': phoneNumber, 'dialCode': dialCode});

    return json.decode(response.body)['success'];
  }

  void onSuccessCountryCodes(items) {
    setState(() {
      callingCodes = items;
      selectedCallingCodeId = callingCodes[0].value;
      displayLoader = false;
      countryCodesLoaded = true;
    });
  }

  void onErrorCountryCodes(Object error) {
    print(error);
    setState(() { displayLoader = false; });

    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () {
      setState(() {
        displayLoader = true;
      });
      doGetCountryCodes().then(onSuccessCountryCodes, onError: onErrorCountryCodes);
    }));
  }

  void onSuccessAuthRequest(success) {
    setState(() {
      displayLoader = false;
    });
    if (success) {
      NavigatorUtil.pushWithArguments(context, SmsValidationActivity(), '/sms-validation',
          {'dialCode': dialCodesMap[selectedCallingCodeId], 'phoneNumber': phoneNumberController.text});
    } else {
      this.onErrorAuthRequest('');
    }
  }

  void onErrorAuthRequest(Object error) {
    FocusScope.of(context).unfocus();

    setState(() { displayLoader = false; });

    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () {
      setState(() { displayLoader = true; });
      doSendAuthRequest(dialCodesMap[selectedCallingCodeId], phoneNumberController.text)
          .then(onSuccessAuthRequest, onError: onErrorAuthRequest);
    }));
  }
}
