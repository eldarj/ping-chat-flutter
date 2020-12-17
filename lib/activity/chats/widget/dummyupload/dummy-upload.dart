import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:path/path.dart' show join, basename;
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:tus_client/tus_client.dart';
import 'package:url_launcher/url_launcher.dart';

class DummyUploadActivity extends StatefulWidget {
  @override
  _DummyUploadActivityState createState() => _DummyUploadActivityState();
}

class _DummyUploadActivityState extends State<DummyUploadActivity> {
  double _progress = 0;
  File _file;
  TusClient _client;
  Uri _fileUrl;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TUS Client Upload Demo'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                "This demo uses TUS client to upload a file",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6),
              child: Card(
                color: Colors.teal,
                child: InkWell(
                  onTap: () async {
                    _file = await _copyToTemp(await FilePicker.getFile());
                    setState(() {
                      _progress = 0;
                      _fileUrl = null;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        Icon(Icons.cloud_upload, color: Colors.white, size: 60),
                        Text(
                          "Upload a file",
                          style: TextStyle(fontSize: 25, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: RaisedButton(
                      onPressed: _file == null
                          ? null
                          : () async {
                        // Create a client
                        print("Create a client");
                        _client = TusClient(
                          Uri.parse("http://192.168.1.4:8089/api/data-space/upload"),
                          _file,
                          store: TusMemoryStore(),
                          headers: {'authorization': 'Bearer ${await UserService.getToken()}'},
                        );

                        print("Starting upload");
                        await _client.upload(
                          onComplete: (response) async {
                            var r = response;
                            print(response);
                            print("Completed!");
                            await _clearFromTemp();
                            setState(() => _fileUrl = Uri.parse(response.headers['x-location']));
                          },
                          onProgress: (progress) {
                            print("Progress: $progress");
                            setState(() => _progress = progress);
                          },
                        );
                      },
                      child: Text("Upload"),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: RaisedButton(
                      onPressed: _progress == 0
                          ? null
                          : () async {
                        _client.pause();
                      },
                      child: Text("Pause"),
                    ),
                  ),
                ],
              ),
            ),
            Stack(
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(1),
                  color: Colors.grey,
                  width: double.infinity,
                  child: Text(" "),
                ),
                FractionallySizedBox(
                  widthFactor: _progress / 100,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.all(1),
                    color: Colors.green,
                    child: Text(" "),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(1),
                  width: double.infinity,
                  child: Text("Progress: ${_progress.toStringAsFixed(1)}%"),
                ),
              ],
            ),
            GestureDetector(
              onTap: _progress != 100
                  ? null
                  : () async {
                await launch(_fileUrl.toString());
              },
              child: Container(
                color: _progress == 100 ? Colors.green : Colors.grey,
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.all(8.0),
                child:
                Text(_progress == 100 ? "Link to view:\n $_fileUrl" : "-"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Copy file to temporary directory before uploading
  Future<File> _copyToTemp(File chosenFile) async {
    if (chosenFile != null) {
      Directory tempDir = await getTemporaryDirectory();
      String newPath = join(tempDir.path, basename(chosenFile.path));
      print("Chosen file: ${chosenFile.absolute.path}");
      print("Temp file: $newPath");
      return await chosenFile.copy(newPath);
    }
    return chosenFile;
  }

  /// clear file from temporary directory after uploading
  _clearFromTemp() async {
    await _file?.delete();
    setState(() => _file = null);
  }
}
