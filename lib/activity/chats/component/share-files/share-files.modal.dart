import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';
import 'package:flutterping/util/extension/http.response.extension.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/model/message-dto.model.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/util/other/file-type-resolver.util.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:path/path.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:tus_client/tus_client.dart';

import '../../../../shared/modal/floating-modal.dart';

const GOOGLE_MAPS_KEY = 'AIzaSyCP-LhaiRcd2Y8jewmktnlaQf3oXye_rfI';

class ShareFilesModal extends StatefulWidget {
  final int userId;
  final int peerId;
  final int userSentNodeId;
  final String myContactName;

  final String picturesPath;

  final Function(MessageDto, double) onProgress;

  final MessageSendingService messageSendingService;

  const ShareFilesModal({Key key, this.messageSendingService, this.onProgress,
    this.peerId, this.picturesPath, this.userId, this.userSentNodeId, this.myContactName}) : super(key: key);

  @override
  State<StatefulWidget> createState() => ShareFilesModalState();
}

class ShareFilesModalState extends BaseState<ShareFilesModal> {
  List<File> files;

  bool isLoadingLocation = false;

  void getLocationImage() async {
    setState(() {
      isLoadingLocation = true;
    });

    Location location = new Location();

    bool serviceEnabled;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        setState(() {
          isLoadingLocation = false;
        });
        scaffold.showSnackBar(SnackBarsComponent.info('Please enable location on your device.'));
        return;
      }
    }

    PermissionStatus permissionStatus = await location.hasPermission();
    if (permissionStatus == PermissionStatus.denied) {
      permissionStatus = await location.requestPermission();
      if (permissionStatus != PermissionStatus.granted) {
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }
    }

    LocationData locationData = await location.getLocation();
    double longitude = locationData.longitude;
    double latitude = locationData.latitude;

    var url = 'https://maps.googleapis.com/maps/api/staticmap'
        '?center=$latitude,$longitude'
        '&zoom=16&size=600x600'
        '&markers=$latitude,$longitude'
        '&key=$GOOGLE_MAPS_KEY';

    var response;

    try {
      response = await http.get(Uri.encodeFull(url)).timeout(Duration(seconds: 10));
    } catch(exception) {
      print(exception);
    }

    if(response != null && response.statusCode == 200) {
      var uint8list = response.bodyBytes;
      var buffer = uint8list.buffer;
      ByteData byteData = ByteData.view(buffer);

      var date = DateTime.now();
      String timestamp = DateFormat("yyMMdd-Hms").format(date);

      File file = new File(widget.picturesPath + '/location-$timestamp.jpeg');
      await file.writeAsBytes(buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));


      String messageSubText;
      var reverseGeocodingUrl = "https://maps.googleapis.com/maps/api/geocode/json"
          "?latlng=$latitude,$longitude"
          "&key=$GOOGLE_MAPS_KEY";

      try {
        var geocodingResponse = await http.get(
            Uri.encodeFull(reverseGeocodingUrl)
        ).timeout(Duration(seconds: 10));

        if (geocodingResponse != null && geocodingResponse.statusCode == 200) {
          List results = geocodingResponse.decode()['results'];

          var address = results.firstWhere((element) {
            var element2 = element['formatted_address'];
            return element2 != null;
          }, orElse: () => null);

          if (address != null) {
            messageSubText = address['formatted_address'];
          }
        }
      } catch(exception) {
        print(exception);
      }

      setState(() {
        isLoadingLocation = false;
      });

      Navigator.of(getScaffoldContext()).pop();

      uploadAndSendFile(file, messageType: 'MAP_LOCATION', text: messageSubText);

    } else {
      setState(() {
        isLoadingLocation = false;
      });

      scaffold.showSnackBar(SnackBarsComponent.error(content: 'Couldn\'t send your location.',
          duration: Duration(seconds: 2),
          actionLabel: ''));

      return;
    }
  }

  void openFilePicker() async {
    Navigator.of(getScaffoldContext()).pop();

    files = await FilePicker.getMultiFile();

    files.forEach((file) {
      uploadAndSendFile(file);
    });
  }

  void openCamera() async {
    Navigator.of(getScaffoldContext()).pop();

    final pickedFile = await ImagePicker().getImage(source: ImageSource.camera);
    File file = File(pickedFile.path);

    uploadAndSendFile(file);
  }

  uploadAndSendFile(file, { messageType, text }) async {
    var fileName = basename(file.path);
    var fileSize = file.lengthSync();
    var fileUrl = Uri.parse(API_BASE_URL + '/files/uploads/' + fileName).toString();
    if (messageType == null) {
      messageType = FileTypeResolverUtil.resolve(extension(fileName));
    }

    var pathInPictures = widget.picturesPath + '/' + fileName;
    if (file.path != pathInPictures) {
      file = await file.copy(pathInPictures);
    }

    var userToken = await UserService.getToken();

    DSNodeDto dsNodeDto = new DSNodeDto();
    dsNodeDto.ownerId = widget.userId;
    dsNodeDto.receiverId = widget.peerId;
    dsNodeDto.parentDirectoryNodeId = widget.userSentNodeId;
    dsNodeDto.nodeName = fileName;
    dsNodeDto.nodeType = messageType;
    dsNodeDto.description = widget.myContactName;
    dsNodeDto.fileUrl = fileUrl;
    dsNodeDto.fileSizeBytes = fileSize;
    dsNodeDto.pathOnSourceDevice = file.path;

    TusClient fileUploadClient = TusClient(
      Uri.parse(API_BASE_URL + DATA_SPACE_ENDPOINT),
      file,
      store: TusMemoryStore(),
      headers: {'Authorization': 'Bearer $userToken'},
      metadata: {'dsNodeEncoded': json.encode(dsNodeDto)},
    );

    MessageDto message = widget.messageSendingService.addPreparedFile(
        fileName, file.path, fileUrl, fileSize, messageType, text: text);

    message.stopUploadFunc = () async {
      message.stoppedUpload = true; // TODO: Handle stop upload
      message.isUploading = false;
      await Future.delayed(Duration(seconds: 2));
      fileUploadClient.delete();
    };

    widget.onProgress(message, 10);
    await Future.delayed(Duration(milliseconds: 500));
    widget.onProgress(message, 30);
    await Future.delayed(Duration(milliseconds: 500));

    try {
      await fileUploadClient.upload(
        onComplete: (response) async {
          var nodeId = response.headers['x-nodeid'];
          message.isUploading = false;
          message.nodeId = int.parse(nodeId);
          await Future.delayed(Duration(milliseconds: 250));
          widget.messageSendingService.sendFile(message);
        },
        onProgress: (progress) {
          if (widget.onProgress != null) {
            if (progress > 30) {
              widget.onProgress(message, progress);
            }
          }
        },
      );
    } catch (exception) {
      print('Error uploading file');
      print(exception); //TODO: Handling
    }
  }

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (context) {
        scaffold = Scaffold.of(context);
        int gridItemCountByWidth = DEVICE_MEDIA_SIZE.width ~/ 125;

        return FloatingModal(
          child: Container(
            color: Colors.white,
            child: Column(
                children: [
                  // Close button
                  Container(
                      height: 50,
                      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: IconButton(
                            icon: Icon(Icons.close),
                            iconSize: 25,
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        )
                      ])
                  ),
                  // Items
                  Flexible(
                    child: Container(
                      child: GridView.count(
                          crossAxisCount: gridItemCountByWidth,
                          children: [
                            buildShareItem(
                                text: 'Send files',
                                icon: Icons.photo_library,
                                color: Colors.deepPurpleAccent,
                                onTap: openFilePicker
                            ),
                            buildShareItem(
                                text: 'Camera',
                                icon: Icons.camera_alt,
                                color: Colors.cyan,
                                onTap: openCamera
                            ),
                            buildShareItem(
                                text: 'Location',
                                icon: Icons.location_on_outlined,
                                color: Colors.red,
                                onTap: getLocationImage,
                                isLoading: isLoadingLocation,
                                spinnerColor: Colors.red.shade700
                            )
                          ]),
                    ),
                  )
                ]
            ),
          ),
        );
      }),
    );
  }
}
