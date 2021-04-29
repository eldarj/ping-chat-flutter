import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/activity/data-space/component/ds-document.component.dart';
import 'package:flutterping/activity/data-space/component/ds-media.component.dart';
import 'package:flutterping/activity/data-space/create-directory.activity.dart';
import 'package:flutterping/activity/data-space/image/image-viewer.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/data-space/data-space-new-directory.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/storage.io.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/error.component.dart';
import 'package:flutterping/shared/component/loading-button.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/dialog/generic-alert.dialog.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/file-type-resolver.util.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:tus_client/tus_client.dart';


class DataSpaceActivity extends StatefulWidget {
  final int userId;

  const DataSpaceActivity({Key key, this.userId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new DataSpaceActivityState();
}

class DataSpaceActivityState extends State<DataSpaceActivity> {
  static const String STREAMS_LISTENER_ID = "DataSpaceStreamsListener";
  ScaffoldState scaffold;
  BuildContext getScaffoldContext() => scaffold.context;

  bool displayLoader = true;
  bool isError = false;

  String picturesPath;

  int currentDirectoryNodeId = 0;

  String currentDirectoryNodeName = 'My dataspace';

  int gridHorizontalSize = 2;

  List<DSNodeDto> nodes = new List();

  bool displayUploadingFiles = false;

  bool displayDeleteLoader = false;

  List<File> files;

  double contentOpacity = 1;

  Queue<DSNodeDto> nodeBreadcrumbs = new Queue();

  openFilePicker() async {
    files = await FilePicker.getMultiFile();

    files.forEach((file) {
      uploadAndSendFile(file);
    });
  }

  uploadAndSendFile(file) async {
    var fileName = basename(file.path);
    var fileType = FileTypeResolverUtil.resolve(extension(fileName));
    var fileSize = file.lengthSync();
    var fileUrl = Uri.parse(API_BASE_URL + '/files/uploads/' + fileName).toString();

    file = await file.copy(picturesPath + '/' + fileName);

    var userToken = await UserService.getToken();

    DSNodeDto dsNodeDto = new DSNodeDto();
    dsNodeDto.ownerId = widget.userId;
    if (currentDirectoryNodeId != 0) {
      dsNodeDto.parentDirectoryNodeId = currentDirectoryNodeId;
    }
    dsNodeDto.nodeName = fileName;
    dsNodeDto.nodeType = fileType;
    dsNodeDto.fileUrl = fileUrl;
    dsNodeDto.description = 'Uploaded to my data space';
    dsNodeDto.fileSizeBytes = fileSize;
    dsNodeDto.pathOnSourceDevice = file.path;

    TusClient fileUploadClient = TusClient(
      Uri.parse(API_BASE_URL + DATA_SPACE_ENDPOINT),
      file,
      store: TusMemoryStore(),
      headers: {'Authorization': 'Bearer $userToken'},
      metadata: {'dsNodeEncoded': json.encode(dsNodeDto)},
    );

    setState(() {
      displayUploadingFiles = true;
    });

    try {
      await fileUploadClient.upload(
        onComplete: (response) async {
          doGetData().then(onGetDataSuccess, onError: onGetDataError);
        },
        onProgress: (progress) {
        },
      );
    } catch (exception) {
      print('Error uploading file');
      print(exception); //TODO: Handling
    }
  }

  init() async {
    picturesPath = await new StorageIOService().getPicturesPath();
    doGetData().then(onGetDataSuccess, onError: onGetDataError);

    dataSpaceNewDirectoryPublisher.addListener(STREAMS_LISTENER_ID, (DSNodeDto dsNode) {
      nodes.add(dsNode);
      setState(() {});
    });

    dataSpaceDeletePublisher.addListener(STREAMS_LISTENER_ID, (int nodeId) {
      setState(() {
        nodes.removeWhere((element) => element.id == nodeId);
      });
    });
  }

  @override
  initState() {
    super.initState();
    init();
  }

  @override
  dispose() {
    super.dispose();
    dataSpaceNewDirectoryPublisher.removeListener(STREAMS_LISTENER_ID);
    dataSpaceDeletePublisher.removeListener(STREAMS_LISTENER_ID);
  }

  onBackPressed(getContext) async {
    if (currentDirectoryNodeId == 0) {
      Navigator.of(getContext()).pop();
    } else {
      if (nodeBreadcrumbs.isNotEmpty) {
        nodeBreadcrumbs.removeLast();
        if (nodeBreadcrumbs.isNotEmpty) {
          var previousNode = nodeBreadcrumbs.last;
          currentDirectoryNodeName = previousNode.nodeName;
          currentDirectoryNodeId = previousNode.id;
          doGetData().then(onGetDataSuccess, onError: onGetDataError);
        } else {
          setState(() {
            currentDirectoryNodeName = 'My dataspace';
            currentDirectoryNodeId = 0;
            doGetData().then(onGetDataSuccess, onError: onGetDataError);
          });
        }
      } else {
        setState(() {
          currentDirectoryNodeName = 'My dataspace';
          currentDirectoryNodeId = 0;
          doGetData().then(onGetDataSuccess, onError: onGetDataError);
        });
      }
    }
  }

  onNavigateToDirectory(node) {
    currentDirectoryNodeId = node.id;
    currentDirectoryNodeName = node.nodeName;
    nodeBreadcrumbs.addLast(node);
    doGetData().then(onGetDataSuccess, onError: onGetDataError);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => onBackPressed(getScaffoldContext),
      child: Scaffold(
          appBar: BaseAppBar.getBackAppBar(getScaffoldContext,
              titleText: currentDirectoryNodeName,
              onBackPressed: onBackPressed,
              actions: [
                buildCreateDirectoryButton(),
                buildDeleteDirectoryButton(),
              ]),
          drawer: NavigationDrawerComponent(),
          floatingActionButton: buildFloatingActionButton(),
          body: Builder(builder: (context) {
            scaffold = Scaffold.of(context);
            return AnimatedOpacity(
                opacity: contentOpacity,
                duration: Duration(milliseconds: 250),
                child: buildActivityContent()
            );
          })
      ),
    );
  }

  buildActivityContent() {
    Widget w = ActivityLoader.build();

    if (!displayLoader) {
      if (!isError) {
        if (nodes != null && nodes.length > 0) {
          w = Container(
            color: Colors.white,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                GestureDetector(
                  onHorizontalDragEnd: (DragEndDetails details) async {
                    if (details.primaryVelocity > 0) {
                      if (gridHorizontalSize < 3) {
                        setState(() {
                          gridHorizontalSize++;
                          contentOpacity = 0.5;
                        });
                        await Future.delayed(Duration(milliseconds: 500));
                        setState(() {
                          contentOpacity = 1;
                        });
                      }
                    } else if (details.primaryVelocity < 0) {
                      if (gridHorizontalSize > 1) {
                        setState(() {
                          gridHorizontalSize--;
                          contentOpacity = 0.5;
                        });
                        await Future.delayed(Duration(milliseconds: 500));
                        setState(() {
                          contentOpacity = 1;
                        });
                      }
                    }
                  },
                  child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisSpacing: 2.5, mainAxisSpacing: 2.5, crossAxisCount: gridHorizontalSize),
                      itemCount: nodes.length, itemBuilder: (context, index) {
                    var node = nodes[index];
                    return buildSingleNode(node);
                  }),
                ),
                buildUploadingFilesContainer(),
              ],
            ),
          );
        } else {
          w = Center(
            child: Container(
              margin: EdgeInsets.all(25),
              child: Text('No media to display', style: TextStyle(color: Colors.grey)),
            ),
          );
        }
      } else {
        w = ErrorComponent.build(actionOnPressed: () async {
          setState(() {
            displayLoader = true;
            isError = false;
          });

          doGetData().then(onGetDataSuccess, onError: onGetDataError);
        });
      }
    }

    return w;
  }

  buildSingleNode(DSNodeDto node) {
    Widget _w;

    if (node.nodeType == 'DIRECTORY') {
      _w = GestureDetector(
        onTap: () => onNavigateToDirectory(node),
        child: Container(
          color: CompanyColor.backgroundGrey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                  child: Icon(Icons.folder_open, color: Colors.grey.shade600)),
              Text(node.nodeName),
            ],
          ),
        ),
      );
    } else {
      String filePath = picturesPath + '/' + node.nodeName;

      File file = File(filePath);
      bool isFileValid = file.existsSync() && file.lengthSync() > 0;

      if (!isFileValid) {
        _w = Icon(Icons.broken_image_outlined, color: Colors.grey.shade400);
      } else if (node.nodeType == 'IMAGE') {
        var imageSize = DEVICE_MEDIA_SIZE.width / gridHorizontalSize;
        _w = GestureDetector(
          onTap: () async {
            var result = await NavigatorUtil.push(scaffold.context,
                ImageViewerActivity(
                    nodeId: node.id,
                    sender: node.description,
                    timestamp: node.createdTimestamp,
                    file: File(filePath)));

            if (result != null && result['deleted'] == true) {
              setState(() {
                nodes.removeWhere((element) => element.id == node.id);
              });
            }
          },
          child: Container(
            color: Colors.grey.shade200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Spinner(),
                Container(
                    height: imageSize, width: imageSize,
                    child: Image.file(File(filePath), fit: BoxFit.cover)),
              ],
            ),
          ),
        );
      } else if (node.nodeType == 'RECORDING' || node.nodeType == 'MEDIA') {
        _w = DSMedia(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: picturesPath);
      } else {
        _w = DSDocument(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: picturesPath);
      }
    }

    return _w;
  }

  Widget buildDeleteDirectoryButton() {
    Widget _w = Container();

    print(currentDirectoryNodeName);
    if (currentDirectoryNodeId != 0 && !['Sent', 'Received'].contains(currentDirectoryNodeName)) {
      _w = Container(
        width: 60,
        child: LoadingButton(
            child: Icon(Icons.delete_outline, color: Colors.grey.shade600),
            displayLoader: displayDeleteLoader,
            loaderSize: 25,
            onPressed: () {
              var dialog = GenericAlertDialog(
                  title: 'Delete directory',
                  message: 'Directory "${currentDirectoryNodeName}" will be deleted with all it\'s content.',
                  onPostivePressed: () {
                    doDeleteDirectory().then(onDeleteDirectorySuccess, onError: onDeleteDirectoryError);
                  },
                  positiveBtnText: 'Delete',
                  negativeBtnText: 'Cancel');
              showDialog(context: getScaffoldContext(), builder: (BuildContext context) => dialog);
            }
        ),
      );
    }

    return _w;
  }

  Widget buildCreateDirectoryButton() {
    return GestureDetector(
        onTap: () {
          NavigatorUtil.push(getScaffoldContext(), CreateDirectoryActivity(
            userId: widget.userId,
            parentNodeId: currentDirectoryNodeId,
            parentNodeName: currentDirectoryNodeName,
          ));
        },
        child: Container(
            width: 50,
            child: Icon(Icons.create_new_folder_outlined, color: Colors.grey.shade600)));
  }

  buildFloatingActionButton() {
    Widget _w;

    if (!displayUploadingFiles) {
      _w = FloatingActionButton(
        onPressed: openFilePicker,
        child: Icon(Icons.file_upload, color: Colors.white),
        backgroundColor: CompanyColor.blueDark,
      );
    } else {
      _w = Container();
    }

    return _w;
  }

  buildUploadingFilesContainer() {
    Widget _w;
    if (displayUploadingFiles) {
      _w = Container(
          height: 50,
          color: Colors.white,
          child: Row(children: [
            Container(
                margin: EdgeInsets.only(left: 15, right: 15),
                child: Spinner(size: 25)),
            Text('Uploading'),
          ]));
    } else {
      _w = Container();
    }

    return Container(child: _w);
  }

  Future doGetData() async {
    setState(() {
      displayLoader = true;
      currentDirectoryNodeName = currentDirectoryNodeName;
    });

    String url = '/api/data-space/${widget.userId}';

    if (currentDirectoryNodeId != 0) {
      url += '/' + currentDirectoryNodeId.toString();
    }

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    var decode = response.decode();
    var list = List<DSNodeDto>.from(decode.map((e) => DSNodeDto.fromJson(e))).toList();
    return list;
  }

  void onGetDataSuccess(result) async {
    await Future.delayed(Duration(milliseconds: 500));

    setState(() {
      nodes = result;
      displayLoader = false;
      displayUploadingFiles = false;
      isError = false;
    });
  }

  void onGetDataError(Object error) {
    print('error');
    setState(() {
      displayLoader = false;
      displayUploadingFiles = false;
      isError = true;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(actionOnPressed: () async {
      setState(() {
        displayLoader = true;
        isError = false;
      });
    }));
  }

  Future doDeleteDirectory() async {
    setState(() {
      displayDeleteLoader = true;
    });

    String url = '/api/data-space/directory/' + currentDirectoryNodeId.toString();

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 200) {
      throw Exception();
    }

    return true;
  }

  onDeleteDirectorySuccess(_) async {
    await Future.delayed(Duration(seconds: 1));

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Directory deleted.'));
    setState(() {
      displayDeleteLoader = false;
    });

    onBackPressed(getScaffoldContext);
  }

  onDeleteDirectoryError(error) {
    setState(() {
      displayDeleteLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}
