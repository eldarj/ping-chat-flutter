import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/data-space/contact-shared/contact-shared.activity.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/activity/data-space/create-directory.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/shared/dialog/generic-alert.dialog.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class AppbarOptionsComponent extends StatelessWidget {
  static const String CREATE_DIRECTORY_KEY = 'CREATE_DIRECTORY_KEY';
  static const String DELETE_DIRECTORY_KEY = 'DELETE_DIRECTORY_KEY';

  final int userId;

  final String parentNodeName;

  final int parentNodeId;

  const AppbarOptionsComponent({Key key, this.userId, this.parentNodeName, this.parentNodeId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (choice) {
        if (choice == CREATE_DIRECTORY_KEY) {
          NavigatorUtil.push(context, CreateDirectoryActivity(
            userId: userId,
            parentNodeId: parentNodeId,
            parentNodeName: parentNodeName,
          ));
        } else if (choice == DELETE_DIRECTORY_KEY) {
          var dialog = GenericAlertDialog(
              title: 'Izbriši trenutni direktorij?',
              message: 'Direktorij "${parentNodeName}" će biti izbrisan sa svim sadržavajućim datotekama.',
              onPostivePressed: () {
                doDeleteDirectory().then(onDeleteDirectorySuccess, onError: onDeleteDirectoryError);
              },
              positiveBtnText: 'Izbriši',
              negativeBtnText: 'Odustani');
          showDialog(context: context, builder: (BuildContext context) => dialog);
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
              value: DELETE_DIRECTORY_KEY,
              child: Row(children: [ Container(margin:EdgeInsets.only(right: 5),
                  child: Icon(Icons.delete, color: Colors.grey.shade400)), Text('Izbriši direktorij') ])
          ),
          PopupMenuItem<String>(
              value: CREATE_DIRECTORY_KEY,
              child: Row(children: [ Container(margin:EdgeInsets.only(right: 5),
                  child: Icon(Icons.create_new_folder, color: Colors.grey.shade400)), Text('Novi direktorij') ])
          ),
        ];
      },
    );
  }

  Future doDeleteDirectory() async {
    String url = '/api/data-space/directory/' + parentNodeId.toString();

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 200) {
      throw Exception();
    }

    return true;
  }

  onDeleteDirectorySuccess(_) async {
  }

  onDeleteDirectoryError(error) {
  }
}
