import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-new-directory.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/gradient-button.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;

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
    appBar = BaseAppBar.getCloseAppBar(getScaffoldContext);
    drawer = new NavigationDrawerComponent();
  }

  @override
  Widget render() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(left: 2.5, right: 2.5, top: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                  padding: EdgeInsets.all(10),
                  margin: EdgeInsets.only(left: 7.5, right: 10),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50.0),
                      color: Colors.grey.shade100
                  ),
                  child: Icon(Icons.create_new_folder, color: CompanyColor.iconGrey, size: 20)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(child: Text('Create new directory', style: TextStyle(color: Colors.grey.shade700))),
                  Container(child: RichText(text: TextSpan(children: [
                    TextSpan(text: 'Parent directory ', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    TextSpan(text: widget.parentNodeName, style: TextStyle(color: CompanyColor.blueAccent, fontSize: 12))
                  ])))
                ],
              ),
            ],
          ),
          Divider(height: 25, thickness: 1),
          Container(
            margin: EdgeInsets.only(left: 20, right: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  autofocus: true,
                  controller: directoryNameController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                      hintText: 'Directory name',
                      labelText: 'Directory name',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(15)),
                ),
                Container(margin: EdgeInsets.only(top: 5, left: 2),
                    child: Text(directoryNameValidationMessage, style: TextStyle(color: CompanyColor.red))),
                Container(
                  child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    GradientButton(
                      child: displayLoader ? Container(height: 20, width: 20, child: Spinner()) : Text('Save'),
                      onPressed: !displayLoader ?
                          () => doCreateDirectory(context) : null,
                    )
                  ]),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void doCreateDirectory(BuildContext context) {
    setState(() {
      directoryNameValidationMessage = directoryNameController.text.length == 0
          ? 'Enter a directory name'
          : !validDirectoryNameChars.hasMatch(directoryNameController.text) ? 'Name can contain numbers and letters only' : '';
    });

    if (directoryNameValidationMessage.length <= 0) {
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
    scaffold.showSnackBar(SnackBarsComponent.success('Directory ${dsNode.nodeName} created'));
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
