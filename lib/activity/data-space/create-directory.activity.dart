import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/activity/contacts/dialog/invite-contact.dialog.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/model/country-code-dto.model.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-new-directory.publisher.dart';
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

class CreateDirectoryActivity extends StatefulWidget {
  final int userId;

  final String parentNodeName;

  final int parentNodeId;

  const CreateDirectoryActivity({Key key, this.userId, this.parentNodeName, this.parentNodeId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new CreateDirectoryActivityState();
}

class CreateDirectoryActivityState extends BaseState<CreateDirectoryActivity> {
  bool displayLoader = false;

  static final validDirectoryNameChars = RegExp(r'^[a-zA-Z0-9]+$');

  TextEditingController directoryNameController = TextEditingController();
  String directoryNameValidationMessage = '';

  @override
  dispose() {
    super.dispose();
    directoryNameController.dispose();
  }

  @override
  preRender() async {
    appBar = BaseAppBar.getBackAppBar(getScaffoldContext, titleText: widget.parentNodeName);
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
                  child: Icon(Icons.create_new_folder, color: Colors.grey.shade300, size: 25)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(child: Text('Novi direktorij', style: TextStyle(fontSize: 16))),
                  Container(child: RichText(text: TextSpan(children: [
                    TextSpan(text: 'Nadređeni direktorij ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    TextSpan(text: widget.parentNodeName, style: TextStyle(color: CompanyColor.blueAccent, fontSize: 12))
                  ])))
                ],
              ),
            ],
          ),
          Divider(height: 25, thickness: 1),
          TextField(
            autofocus: true,
            controller: directoryNameController,
            keyboardType: TextInputType.text,
            decoration: InputDecoration(
                hintText: 'Naziv direktorija',
                labelText: 'Naziv direktorija',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(15)),
          ),
          Container(margin: EdgeInsets.only(top: 5, left: 2),
              child: Text(directoryNameValidationMessage, style: TextStyle(color: CompanyColor.red))
          ),
          Container(
            child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              GradientButton(
                child: displayLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Kreiraj'),
                onPressed: !displayLoader ?
                    () => noCreateDirectory(context) : null,
              )
            ]),
          )

        ],
      ),
    );
  }

  void noCreateDirectory(BuildContext context) {
    setState(() {
      directoryNameValidationMessage = directoryNameController.text.length == 0
          ? 'Unesite naziv direktorija'
          : !validDirectoryNameChars.hasMatch(directoryNameController.text) ? 'Naziv može sadržati samo slova.' : '';
    });

    if (directoryNameValidationMessage.length > 0) {
      scaffold.removeCurrentSnackBar();
      scaffold.showSnackBar(SnackBarsComponent.error(content: 'Molimo ispravite greške.', duration: Duration(seconds: 2)));
    } else {
      setState(() { displayLoader = true; });
      doSendRequest(directoryNameController.text)
          .then(onRequestSuccess, onError: onRequestError);
    }
  }

  Future<DSNodeDto> doSendRequest(String directoryName) async {
    FocusScope.of(context).unfocus();

    DSNodeDto dsNode = new DSNodeDto();
    dsNode.nodeName = directoryName;
    dsNode.nodeType = 'DIRECTORY';
    if (widget.parentNodeId != 0) {
      dsNode.parentDirectoryNodeId = widget.parentNodeId;
    }
    dsNode.ownerId = widget.userId;
    http.Response response = await HttpClientService.post('/api/data-space/${widget.userId}/directory', body: dsNode);

    if (response.statusCode != 200) {
      throw new Exception();
    }

    var decode = json.decode(response.body);
    return DSNodeDto.fromJson(decode);
  }

  onRequestSuccess(DSNodeDto dsNode) async {
    dataSpaceNewDirectoryPublisher.subject.add(dsNode);

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.success('Uspješno ste kreirali direktorij ${dsNode.nodeName}'));
    // setState(() { displayLoader = false; });

    await Future.delayed(Duration(seconds: 1));

    Navigator.of(context).pop();
  }

  onRequestError(error) {
    setState(() { displayLoader = false; });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () {
      setState(() { displayLoader = true; });
      doSendRequest(directoryNameController.text)
          .then(onRequestSuccess, onError: onRequestError);
    }));
  }
}
