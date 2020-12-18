import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/contacts/dialog/invite-contact.dialog.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/model/country-code-dto.model.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:flutterping/util/exception/custom-exception.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/service/http/http-client.service.dart';

class AddContactActivity extends StatefulWidget {
  const AddContactActivity();

  @override
  State<StatefulWidget> createState() => new AddContactActivityState();
}

class AddContactActivityState extends BaseState<AddContactActivity> {
  var displayLoader = true;

  static final validPhoneNumberChars = RegExp(r'^[0-9]+$');

  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController contactNameController = TextEditingController();
  String phoneNumberValidationMessage = '';
  String contactNameValidationMessage = '';

  bool countryCodesLoaded = false;
  Map<String, String> dialCodesMap = {};

  String selectedCallingCodeId = 'placeholder';
  List<DropdownMenuItem<String>> callingCodes = [
    DropdownMenuItem(value: 'placeholder', child: Text('Pozivni'))
  ];

  @override
  initState() {
    super.initState();
    doGetCountryCodes().then(onSuccessCountryCodes, onError: onErrorCountryCodes);
  }

  @override
  dispose() {
    super.dispose();
    phoneNumberController.dispose();
    contactNameController.dispose();
  }

  @override
  preRender() async {
    appBar = BaseAppBar.getBackAppBar(getScaffoldContext, titleText: 'Novi kontakt');
    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return Container(
      margin: EdgeInsets.only(left: 30, right: 30, top: 15, bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(margin: EdgeInsets.only(right: 10),
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      color: Colors.grey.shade400
                  ),
                  child: Icon(Icons.person, color: Colors.grey.shade300, size: 25)),
              Container(child: Text('Novi kontakt', style: TextStyle(fontSize: 16))),
            ],
          ),
          Divider(height: 25, thickness: 1),
          Container(
              margin: EdgeInsets.only(top: 10, bottom: 15),
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
          TextField(
            controller: phoneNumberController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
                hintText: 'Broj telefona',
                labelText: 'Broj telefona',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(15)),
          ),
          Container(margin: EdgeInsets.only(top: 5, left: 2),
              child: Text(phoneNumberValidationMessage, style: TextStyle(color: CompanyColor.red))
          ),
          Container(
            margin: EdgeInsets.only(top: 5),
            child: TextField(
              controller: contactNameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                  hintText: 'Ime kontakta',
                  labelText: 'Ime kontakta',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(15)),
            ),
          ),
          Container(margin: EdgeInsets.only(top: 5, left: 2),
              child: Text(contactNameValidationMessage, style: TextStyle(color: CompanyColor.red))
          ),
          Container(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              GradientButton(
                child: displayLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Dalje'),
                onPressed: countryCodesLoaded && !displayLoader ?
                    () => onGetStarted(context) : null,
              )
            ]),
          )
        ],
      ),
    );
  }

  void onGetStarted(BuildContext context) {
    // refresh the state
    setState(() {
      phoneNumberValidationMessage = phoneNumberController.text.length == 0
          ? 'Unesite broj telefona'
          : !validPhoneNumberChars.hasMatch(phoneNumberController.text) ? 'Broj može sadržati samo cifre.' : '';

      contactNameValidationMessage = contactNameController.text.length < 3 ? 'Unesite ime kontakta' : '';
    });

    if (phoneNumberValidationMessage.length > 0) {
      scaffold.removeCurrentSnackBar();
      scaffold.showSnackBar(SnackBarsComponent.error(content: 'Molimo ispravite greške.', duration: Duration(seconds: 2)));
    } else {
      setState(() { displayLoader = true; });
      doSendAuthRequest(dialCodesMap[selectedCallingCodeId], phoneNumberController.text, contactNameController.text)
          .then(onSuccessAuthRequest, onError: onErrorAuthRequest);
    }
  }

  Future<ContactDto> doSendAuthRequest(String dialCode, String phoneNumber, String contactName) async {
    FocusScope.of(context).unfocus();

    http.Response response = await HttpClientService.post('/api/contacts', body: new ContactDto(
      contactPhoneNumber: dialCode + phoneNumber,
      contactName: contactName,
    ));

    if (response.statusCode != 200) {
      throw new Exception();
    }

    var decode = json.decode(response.body);
    if (decode['error'] != null) {
      throw new CustomException(decode['error']);
    }

    return ContactDto.fromJson(decode['contact']);
  }

  onSuccessAuthRequest(ContactDto contactDto) async {
    setState(() { displayLoader = false; });

    if (contactDto.contactUserExists) {
      NavigatorUtil.push(context, ContactsActivity(
          displaySavedContactSnackbar: true,
          savedContactName: contactDto.contactName,
          savedContactPhoneNumber: contactDto.contactPhoneNumber
      ));
    } else {
      scaffold.removeCurrentSnackBar();
      scaffold.showSnackBar(SnackBarsComponent.success('Uspješno ste dodali kontakt ${contactDto.contactPhoneNumber}'));

      await showDialog(context: context, builder: (BuildContext context) {
        return InviteContactDialog(contactName: contactDto.contactName,
            contactPhoneNumber: contactDto.contactPhoneNumber);
      }).then((invited) {
        if (invited != null && invited) {
          scaffold.removeCurrentSnackBar();
          scaffold.showSnackBar(SnackBarsComponent.success('Uspješno ste poslali pozivnicu na ${contactDto.contactPhoneNumber}'));
        }
        NavigatorUtil.push(context, ContactsActivity(
            displaySavedContactSnackbar: true,
            savedContactName: contactDto.contactName,
            savedContactPhoneNumber: contactDto.contactPhoneNumber
        ));
      });
    }
  }

  onErrorAuthRequest(error) {
    setState(() { displayLoader = false; });

    String message = error is CustomException ? error.toString() : null;
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(content: message, actionOnPressed: () {
      setState(() { displayLoader = true; });
      doSendAuthRequest(dialCodesMap[selectedCallingCodeId], phoneNumberController.text, contactNameController.text)
          .then(onSuccessAuthRequest, onError: onErrorAuthRequest);
    }));
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

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () {
      setState(() {
        displayLoader = true;
      });
      doGetCountryCodes().then(onSuccessCountryCodes, onError: onErrorCountryCodes);
    }));
  }
}
