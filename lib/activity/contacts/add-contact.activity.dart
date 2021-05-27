import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/contacts/dialog/invite-contact.dialog.dart';
import 'package:flutterping/activity/contacts/qr-scanner.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
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
  final ClientDto user;

  const AddContactActivity({Key key, this.user}) : super(key: key);

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
    DropdownMenuItem(value: 'placeholder', child: Text('Counry code'))
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
    appBar = BaseAppBar.getCloseAppBar(
        getScaffoldContext,
        actions: [
          TextButton(
              onPressed: () {
                NavigatorUtil.replace(context, QrScannerActivity(user: widget.user));
              },
              child: Row(children: [
                Icon(Icons.qr_code),
                Container(
                    padding: EdgeInsets.only(left: 10, right: 10),
                    child: Text('Scan QR'))
              ]),
            style: TextButton.styleFrom(
              primary: Colors.grey.shade700
            ))
        ]
    );
    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 2.5, right: 2.5, top: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(width: 0.35, color: Colors.grey.shade800))
            ),
            child: Row(
              children: [
                Container(
                    padding: EdgeInsets.all(10),
                    margin: EdgeInsets.only(left: 7.5, right: 10),
                    decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(50.0),
                    ),
                    child: Icon(Icons.person_add_alt_1, color: Colors.grey.shade300, size: 20)),
                Container(child: Text('Add a new contact', style: TextStyle(color: Colors.grey.shade700))),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 20, right: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  margin: EdgeInsets.only(top: 10, bottom: 10),
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
                    hintText: 'Phone number',
                    labelText: 'Phone number',
                    border: OutlineInputBorder(),
                    errorText: phoneNumberValidationMessage.length > 0 ? phoneNumberValidationMessage : null,
                    contentPadding: EdgeInsets.all(15)),
              ),
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                child: TextField(
                  controller: contactNameController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                      hintText: 'Contact name',
                      labelText: 'Contact name',
                      errorText: contactNameValidationMessage.length > 0 ? contactNameValidationMessage : null,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(15)),
                ),
              ),
              Container(
                child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  GradientButton(
                    child: displayLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Add'),
                    onPressed: countryCodesLoaded && !displayLoader ?
                        () => onGetStarted(context) : null,
                  )
                ]),
              )
            ]),
          )
        ],
      ),
    );
  }

  void onGetStarted(BuildContext context) {
    // refresh the state
    scaffold.removeCurrentSnackBar();

    setState(() {
      phoneNumberValidationMessage = phoneNumberController.text.length == 0
          ? 'Enter a phone number'
          : !validPhoneNumberChars.hasMatch(phoneNumberController.text) ? 'Phonenumber can contain digits only' : '';

      contactNameValidationMessage = contactNameController.text.length < 3 ? 'Enter a contact name' : '';
    });

    if (phoneNumberValidationMessage.length > 0 || contactNameValidationMessage.length > 0) {
      scaffold.removeCurrentSnackBar();
      scaffold.showSnackBar(SnackBarsComponent.error(content: 'Please check the entered data.', duration: Duration(seconds: 2)));
    } else {
      setState(() { displayLoader = true; });
      doAddContact(dialCodesMap[selectedCallingCodeId], phoneNumberController.text, contactNameController.text)
          .then(onAddContactSuccess, onError: onAddContactError);
    }
  }

  Future<ContactDto> doAddContact(String dialCode, String phoneNumber, String contactName) async {
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

  onAddContactSuccess(ContactDto contactDto) async {
    setState(() { displayLoader = false; });

    if (contactDto.contactUserExists) {
      NavigatorUtil.push(context, ContactsActivity(
          displaySavedContactSnackbar: true,
          savedContactName: contactDto.contactName,
          savedContactPhoneNumber: contactDto.contactPhoneNumber
      ));
    } else {
      scaffold.removeCurrentSnackBar();
      scaffold.showSnackBar(SnackBarsComponent.success('You successfully added ${contactDto.contactPhoneNumber}'));

      await showDialog(context: context, builder: (BuildContext context) {
        return InviteContactDialog(contactName: contactDto.contactName,
            contactPhoneNumber: contactDto.contactPhoneNumber);
      }).then((invited) {
        if (invited != null && invited) {
          scaffold.removeCurrentSnackBar();
          scaffold.showSnackBar(SnackBarsComponent.success('Successfully sent to ${contactDto.contactPhoneNumber}'));
        }
        NavigatorUtil.push(context, ContactsActivity(
            displaySavedContactSnackbar: true,
            savedContactName: contactDto.contactName,
            savedContactPhoneNumber: contactDto.contactPhoneNumber
        ));
      });
    }
  }

  onAddContactError(error) {
    setState(() { displayLoader = false; });

    String message = error is CustomException ? error.toString() : null;
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(content: message, actionOnPressed: () {
      setState(() { displayLoader = true; });
      doAddContact(dialCodesMap[selectedCallingCodeId], phoneNumberController.text, contactNameController.text)
          .then(onAddContactSuccess, onError: onAddContactError);
    }));
  }

  void onChangeCountryCode(String selection) {
    setState(() { selectedCallingCodeId = selection; });
  }

  Future<List<DropdownMenuItem<String>>> doGetCountryCodes() async {
    http.Response response = await HttpClientService.get('/api/country-codes', cacheKey: "countryCodes");
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
