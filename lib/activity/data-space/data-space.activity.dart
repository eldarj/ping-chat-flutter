import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutterping/activity/data-space/component/ds-document.component.dart';
import 'package:flutterping/activity/data-space/component/ds-media.component.dart';
import 'package:flutterping/activity/data-space/component/ds-recording.component.dart';
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
import 'package:flutterping/shared/component/loading-button.component.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/dialog/generic-alert.dialog.dart';
import 'package:flutterping/shared/drawer/navigation-drawer.component.dart';
import 'package:flutterping/shared/info/info.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/other/file-type-resolver.util.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:tus_client/tus_client.dart';


void downloadCallback(String id, DownloadTaskStatus status, int progress) {
  final SendPort send = IsolateNameServer.lookupPortByName('DS_ACTIVITY_DOWNLOADER_PORT_KEY');
  send.send({'id': id, 'status': status});
}

class DataSpaceActivity extends StatefulWidget {
  final int userId;

  const DataSpaceActivity({Key key, this.userId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new DataSpaceActivityState();
}

class DataSpaceActivityState extends State<DataSpaceActivity> {
  static const String DS_ACTIVITY_DOWNLOADER_PORT_ID = "DS_ACTIVITY_DOWNLOADER_PORT_KEY";
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

  bool multiSelectEnabled = false;
  int multiSelectCount = 0;

  int totalFilesToUpload = 0;

  int uploadedFiles = 0;

  openFilePicker() async {
    files = await FilePicker.getMultiFile();

    if (files != null) {
      List<Future> uploadTasks = files.map((e) => prepareUploadFiles(e))
          .toList();

      setState(() {
        uploadedFiles = 1;
        totalFilesToUpload = uploadTasks.length;
      });

      Future.wait(uploadTasks).then((_) {
        doGetData().then(onGetDataSuccess, onError: onGetDataError);

      }, onError: (error) {
        scaffold.removeCurrentSnackBar();
        scaffold.showSnackBar(SnackBarsComponent.error(
          content: 'Error occurred during upload', duration: Duration(seconds: 3)
        ));
      });
    }
  }

  Future prepareUploadFiles(file) async {
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

    return fileUploadClient.upload(
      onComplete: (response) {
        setState(() {
          ++uploadedFiles;
        });
        return response;
      },
      onProgress: (progress) {},
    );
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

    ReceivePort _port = ReceivePort();
    IsolateNameServer.registerPortWithName(_port.sendPort, DS_ACTIVITY_DOWNLOADER_PORT_ID);
    _port.listen((dynamic data) {
      String downloadTaskId = data['id'];
      DownloadTaskStatus status = data['status'];

      if ([DownloadTaskStatus.complete, DownloadTaskStatus.failed].contains(status)) {
        nodes.where((node) => node.downloadTaskId == downloadTaskId).forEach((node) async {
          setState(() {
            node.isDownloading = false;
          });
        });
      }
    });

    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  initState() {
    super.initState();
    init();
  }

  @override
  dispose() {
    if (dataSpaceNewDirectoryPublisher != null) {
      dataSpaceNewDirectoryPublisher.removeListener(STREAMS_LISTENER_ID);
    }

    if (dataSpaceDeletePublisher != null) {
      dataSpaceDeletePublisher.removeListener(STREAMS_LISTENER_ID);
    }

    IsolateNameServer.removePortNameMapping(DS_ACTIVITY_DOWNLOADER_PORT_ID);

    super.dispose();
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
                buildMultiSelectAction(),
                buildCreateDirectoryButton(),
                buildDeleteDirectoryButton(),
                buildDeleteContentButton(),
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
          w = GestureDetector(
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
          );
        } else {
          w = InfoComponent.noDataStitch(text: 'No media to display');
        }
      } else {
        w = InfoComponent.errorDonut(message: "Couldn't load your Data Space, please try again", onButtonPressed: () async {
          setState(() {
            displayLoader = true;
            isError = false;
          });

          doGetData().then(onGetDataSuccess, onError: onGetDataError);
        });
      }
    }

    return Container(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          w,
          buildUploadingFilesContainer(),
        ]
      )
    );
  }

  buildSingleNode(DSNodeDto node) {
    Widget _w = Container();

    if (node.isDownloading != null && node.isDownloading) {
      _w = Container(
          color: Colors.grey.shade100,
          child: Center(child: Spinner())
      );
    } else if (node.nodeType == 'DIRECTORY') {
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
        _w = GestureDetector(
            onLongPressStart: (details) {
              onNodeSelected(node);
            },
            onTapDown: multiSelectEnabled ? (_) {
              onNodeSelected(node);
            } : (details) {
              showMenu(
                context: scaffold.context,
                position: RelativeRect.fromLTRB(details.globalPosition.dx - 25, details.globalPosition.dy - 50, 1000, 1000),
                elevation: 8.0,
                items: [
                  PopupMenuItem(value: 'DELETE', child: Text("Delete")),
                ],
              ).then((value) {
                if (value == 'DELETE') {
                  doDeleteMessage(node).then(onDeleteMessageSuccess, onError: onDeleteMessageError);
                }
              });
            },
            child: Container(
                color: Colors.grey.shade100,
                child: Icon(Icons.broken_image_outlined, color: Colors.grey.shade400)));
      } else if (node.nodeType == 'IMAGE' || node.nodeType == 'MAP_LOCATION') {
        var imageSize = DEVICE_MEDIA_SIZE.width / gridHorizontalSize;
        _w = InkWell(
          onLongPress: () {
            onNodeSelected(node);
          },
          onTap: multiSelectEnabled ? () {
            onNodeSelected(node);
          } : () async {
            NavigatorUtil.push(scaffold.context,
                ImageViewerActivity(
                    node: node,
                    picturesPath: picturesPath,
                    nodeId: node.id,
                    sender: node.description,
                    timestamp: node.createdTimestamp,
                    displayShare: true,
                    file: File(filePath))
            );
          },
          child: Container(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Spinner(),
                Container(
                    height: imageSize, width: imageSize,
                    child: Image.file(File(filePath), fit: BoxFit.cover, cacheWidth: 200)),
              ],
            ),
          ),
        );
      } else if (node.nodeType == 'RECORDING') {
        _w = DSRecording(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: picturesPath, multiSelectEnabled: multiSelectEnabled, onNodeSelected: onNodeSelected, displayShare: true, file: file);
      } else if (node.nodeType == 'MEDIA') {
        _w = DSMedia(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: picturesPath, multiSelectEnabled: multiSelectEnabled, onNodeSelected: onNodeSelected, displayShare: true, file: file);
      } else if (node.nodeType == 'FILE') {
        _w = DSDocument(node: node, gridHorizontalSize: gridHorizontalSize, picturesPath: picturesPath, multiSelectEnabled: multiSelectEnabled, onNodeSelected: onNodeSelected, displayShare: true, file: file);
      } else {
        _w = Container(
            color: Colors.grey.shade100,
            child: Center(child: Text('Unrecognized media', style: TextStyle(color: Colors.grey))));
      }
    }

    return Container(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
              height: DEVICE_MEDIA_SIZE.width / gridHorizontalSize,
              width: DEVICE_MEDIA_SIZE.width / gridHorizontalSize,
              child: _w),
          IgnorePointer(
            ignoring: node.nodeType == 'DIRECTORY' ? false : true,
            child: Container(
              child: multiSelectEnabled ? Container(
                  color: Colors.black45,
                  height: DEVICE_MEDIA_SIZE.width / gridHorizontalSize,
                  width: DEVICE_MEDIA_SIZE.width / gridHorizontalSize,
                  child: node.nodeType == 'DIRECTORY'
                      ? Container()
                      : Align(
                        child: Container(
                            decoration: BoxDecoration(
                              color: node.selected != null && node.selected ? Colors.green : Colors.transparent,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                            child: node.selected != null && node.selected
                                ? Icon(Icons.check, size: 20, color: Colors.white)
                                : Icon(Icons.check_box_outline_blank_rounded, size: 27, color: Color.fromRGBO(255, 255, 255, 0.5)),
                        ))
                  ) : Container()
              ),
            ),
        ]
      )
    );
  }

  onNodeSelected(node) {
    if (node.selected != null && node.selected) {
      setState(() {
        node.selected = false;
        --multiSelectCount;
      });
    } else {
      setState(() {
        node.selected = true;
        multiSelectEnabled = true;
        ++multiSelectCount;
      });
    }
  }

  Widget buildDeleteDirectoryButton() {
    Widget _w = Container();

    if (!multiSelectEnabled && currentDirectoryNodeId != 0 && !['Sent', 'Received'].contains(currentDirectoryNodeName)) {
      _w = Container(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: LoadingButton(
            icon: Icons.delete_outline,
            disabled: displayUploadingFiles || displayLoader,
            displayLoader: displayDeleteLoader,
            loaderSize: 25,
            onPressed: () {
              var dialog = GenericAlertDialog(
                  title: 'Delete directory',
                  message: 'Directory $currentDirectoryNodeName will be deleted with all it\'s content.',
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

  Widget buildDeleteContentButton() {
    Widget _w = Container();

    if (!multiSelectEnabled && (currentDirectoryNodeId == 0 || ['Sent', 'Received'].contains(currentDirectoryNodeName))) {
      bool disabled = isError || displayLoader || displayUploadingFiles || nodes == null || nodes.length <= 0 || (currentDirectoryNodeId == 0 && nodes.length <= 2);

      _w = Container(
        padding: EdgeInsets.only(left: 10, right: 10),
        child: LoadingButton(
            icon: Icons.delete_outlined,
            displayLoader: displayDeleteLoader,
            disabled: disabled,
            loaderSize: 25,
            onPressed: () {
              var dialog = GenericAlertDialog(
                  title: 'Delete all content',
                  message: 'All content in $currentDirectoryNodeName will be deleted.',
                  onPostivePressed: () {
                    Future.wait(prepareDeleteContentTasks()).then(onDeleteContentSuccess, onError: onDeleteContentError);
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

  Widget buildMultiSelectAction() {
    Widget w = Container();

    if (multiSelectEnabled) {
      return Row(
        children: [
          Text('Selected $multiSelectCount', style: TextStyle(
              fontSize: 16
          )),
          Container(
            padding: EdgeInsets.only(left: 10, right: 10),
            child: LoadingButton(
              icon: Icons.close,
                displayLoader: displayDeleteLoader,
                onPressed: () {
                setState(() {
                  nodes.forEach((n) { n.selected = false; });
                  multiSelectEnabled = false;
                  multiSelectCount = 0;
                });
              }
            ),
          )
        ]
      );
    }

    return w;
  }

  Widget buildCreateDirectoryButton() {
    Widget w = Container();

    if (!multiSelectEnabled && !['Sent', 'Received'].contains(currentDirectoryNodeName)) {
      w = LoadingButton(
          icon: Icons.create_new_folder_outlined,
          disabled: isError || displayUploadingFiles || displayLoader,
          onPressed: () {
            NavigatorUtil.push(getScaffoldContext(), CreateDirectoryActivity(
              userId: widget.userId,
              parentNodeId: currentDirectoryNodeId,
              parentNodeName: currentDirectoryNodeName,
            ));
          }
      );
    }

    return w;
  }

  buildFloatingActionButton() {
    Widget _w;

    if (multiSelectEnabled) {
      _w = FloatingActionButton(
        elevation: 1,
        backgroundColor: displayDeleteLoader ? Color.fromRGBO(255, 105, 95, 1) : CompanyColor.red,
        child: Icon(Icons.delete_outlined, color: Colors.white),
        onPressed: displayDeleteLoader ? null : () {
          var dialog = GenericAlertDialog(
              title: 'Delete',
              message: 'Are you sure you want to delete $multiSelectCount items?',
              onPostivePressed: () {
                doDeleteSelected();
              },
              positiveBtnText: 'Delete',
              negativeBtnText: 'Cancel');
          showDialog(context: getScaffoldContext(), builder: (BuildContext context) => dialog);
        },
      );
    } else if (!displayUploadingFiles && !displayLoader && !isError) {
      _w = FloatingActionButton(
        elevation: 1,
        backgroundColor: CompanyColor.blueDark,
        child: Icon(Icons.file_upload, color: Colors.white),
        onPressed: openFilePicker,
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
            Text('Uploading $uploadedFiles of $totalFilesToUpload'),
          ]));
    } else {
      _w = Container();
    }

    return Container(child: _w);
  }

  // Get data
  Future<List<DSNodeDto>> doGetData() async {
    setState(() {
      displayLoader = true;
      currentDirectoryNodeName = currentDirectoryNodeName;
    });

    String url = '/api/data-space/${widget.userId}';

    if (currentDirectoryNodeName == 'Received') {
      url += '/received';
    } else if (currentDirectoryNodeName == 'Sent') {
      url += '/sent?directoryId=$currentDirectoryNodeId';
    } else if (currentDirectoryNodeId != 0) {
      url += '/$currentDirectoryNodeId';
    }

    http.Response response = await HttpClientService.get(url);

    if(response.statusCode != 200) {
      throw new Exception();
    }

    var decode = response.decode();
    return List<DSNodeDto>.from(decode.map((e) => DSNodeDto.fromJson(e))).toList();
  }

  doDownloadAndStoreFile(DSNodeDto node) async {
    try {
      return await FlutterDownloader.enqueue(
        url: node.fileUrl,
        savedDir: picturesPath,
        fileName: node.nodeName,
        showNotification: false,
        openFileFromNotification: false,
      );
    } catch(exception) {
      print('Error downloading file on init.');
      print(exception);
    }
  }

  void onGetDataSuccess(List<DSNodeDto> result) async {
    var preparedNodes = result.map((node) async {
      if (node.nodeType != 'DIRECTORY') {
        bool fileExists = File(picturesPath + '/' + node.nodeName).existsSync();
        if (!fileExists) {
          node.isDownloading = true;
          node.downloadTaskId = await doDownloadAndStoreFile(node);
        }
      }

      return node;
    }).toList();

    nodes = await Future.wait(preparedNodes);

    setState(() {
      displayLoader = false;
      displayUploadingFiles = false;
      isError = false;
    });
  }

  void onGetDataError(Object error) {
    setState(() {
      displayLoader = false;
      displayUploadingFiles = false;
      isError = true;
    });
  }

  // Delete
  Future<DSNodeDto> doDeleteMessage(DSNodeDto node) async {
    try {
      var file = File(picturesPath + '/' + node.nodeName);
      file.delete();
    } catch(ignored) {}

    String url = '/api/data-space'
        '?nodeId=' + node.id.toString() +
        '&fileName=' + basename(node.nodeName);

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 200) {
      throw Exception();
    }

    return node;
  }

  onDeleteMessageSuccess(DSNodeDto node) async {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Deleted'));
    await Future.delayed(Duration(seconds: 2));
    dataSpaceDeletePublisher.subject.add(node.id);
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }

  // Delete multiple messages
  doDeleteSelected() async {
    setState(() {
      displayDeleteLoader = true;
    });

    List<DSNodeDto> selectedNodes = nodes.where((node) => node.selected).toList();

    await Future.delayed(Duration(milliseconds: 500));

    List<Future> deleteTasks = selectedNodes.map((node) async {
      try {
        var file = File(picturesPath + '/' + node.nodeName);
        file.delete();
      } catch(ignored) {}

      String url = '/api/data-space'
          '?nodeId=' + node.id.toString() +
          '&fileName=' + basename(node.nodeName);

      http.Response response = await HttpClientService.delete(url);

      if (response.statusCode != 200) {
        throw Exception();
      }

      return node;
    }).toList();

    Future.wait(deleteTasks).then(onDeleteSelectedSuccess, onError: onDeleteSelectedError);
  }

  onDeleteSelectedSuccess(selectedNodes) async {
    setState(() {
      displayDeleteLoader = false;
      multiSelectEnabled = false;
      multiSelectCount = 0;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info(
        'Deleted ${selectedNodes.length} item' + (selectedNodes.length > 1 ? 's' : '')
    ));
    selectedNodes.forEach((node) {
      dataSpaceDeletePublisher.subject.add(node.id);
    });
  }

  onDeleteSelectedError(error) {
    setState(() {
      displayDeleteLoader = false;
      multiSelectEnabled = false;
      multiSelectCount = 0;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }

  // Delete all content
  List<Future<DSNodeDto>> prepareDeleteContentTasks() {
    setState(() {
      displayDeleteLoader = true;
    });

    List<Future<DSNodeDto>> deleteTasks = [];

    deleteTasks = nodes.where((element) => element.nodeName != 'Received' && element.nodeName != 'Sent' && element.id != 0)
        .map<Future<DSNodeDto>>((node) async {
          var url = '/api/data-space';

          if (node.nodeType == 'DIRECTORY') {
            url = '/api/data-space/directory/${node.id}';
          } else {
            url = '/api/data-space'
                '?nodeId=${node.id}'
                '&fileName=${node.nodeName}';
          }

          http.Response response = await HttpClientService.delete(url);

          if (response.statusCode != 200) {
            throw Exception();
          }

          dataSpaceDeletePublisher.subject.add(node.id);

          return node;
    }).toList();

    return deleteTasks;
  }

  onDeleteContentSuccess(List<DSNodeDto> deletedNodes) async {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Content deleted'));

    deletedNodes.forEach((node) {
      try {
        var file = File(picturesPath + '/' + node.nodeName);
        file.delete();
      } catch(ignored) {}
    });

    setState(() {
      displayDeleteLoader = false;
    });
  }

  onDeleteContentError(error) {
    print(error);

    setState(() {
      displayDeleteLoader = false;
    });

    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error(
      content: 'Some data might not have been deleted.',
      duration: Duration(seconds: 5)
    ));
  }

  // Delete directory
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
    scaffold.showSnackBar(SnackBarsComponent.info('Directory deleted'));
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
