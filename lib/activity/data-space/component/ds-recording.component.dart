import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/shared/var/global.var.dart';
import 'package:flutterping/util/extension/duration.extension.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';

class DSRecording extends StatefulWidget {
  final DSNodeDto node;

  final String picturesPath;

  final int gridHorizontalSize;

  final Function(DSNodeDto) onNodeSelected;

  final bool multiSelectEnabled;

  const DSRecording({Key key, this.node, this.picturesPath, this.gridHorizontalSize, this.onNodeSelected,
    this.multiSelectEnabled = false}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DSRecordingState();
}

class DSRecordingState extends BaseState<DSRecording> {
  bool isRecordingPlaying = false;

  String recordingCurrentPosition = '00:00';
  int recordingCurrentPositionMillis = 0;

  AudioPlayer audioPlayer = AudioPlayer();

  String filePath;

  double nameContainerSize;

  @override
  void initState() {
    super.initState();

    AudioPlayer.logEnabled = false;
    audioPlayer.onAudioPositionChanged.listen((Duration  p) {
      setState(() {
        recordingCurrentPositionMillis = p.inMilliseconds;
        recordingCurrentPosition = p.format();
      });
    });

    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState audioPlayerState) {
      setState(() {
        isRecordingPlaying = audioPlayerState == AudioPlayerState.PLAYING;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    audioPlayer.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Builder(builder: (context) {
        scaffold = Scaffold.of(context);
        return buildMessageMedia();
      }),
    );
  }

  buildMessageMedia() {
    double iconContainerSize = widget.gridHorizontalSize == 4 ? 0 : 100 / widget.gridHorizontalSize;
    nameContainerSize = DEVICE_MEDIA_SIZE.width / widget.gridHorizontalSize - iconContainerSize - 20;
    double iconSize = 40 / widget.gridHorizontalSize;

    String title = 'Recording';
    IconData icon = isRecordingPlaying ? Icons.pause : Icons.mic_none;
    filePath = widget.picturesPath + '/' + widget.node.nodeName;

    if (!isRecordingPlaying) {
      recordingCurrentPositionMillis = 0;
    }

    var time = widget.node.recordingDuration.split(":");
    String seconds = time[1];
    String minutes = time[0];
    int durationInMillis = (int.parse(minutes) * 60 + int.parse(seconds)) * 1000;
    Widget progressIndicator;

    Widget iconWidget = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
            margin: EdgeInsets.only(bottom: isRecordingPlaying ? 12.5 : 0),
            child: Icon(icon, color: Colors.grey.shade100, size: iconSize)),
        Container(
            margin: EdgeInsets.only(top: isRecordingPlaying ? 12.5 : 0),
            child: Text(recordingCurrentPosition, style: TextStyle(
                fontSize: 11,
                color: isRecordingPlaying ? Colors.grey.shade100 : Colors.transparent))
        ),
      ],
    );

    if (widget.node.recordingDuration != null) {
      title += ' (${widget.node.recordingDuration})';
    }

    progressIndicator = buildProgressIndicator(durationInMillis - 950, Colors.grey.shade500, Colors.indigo);

    return Material(
      color: Colors.grey.shade200,
      child: InkWell(
        onTap: widget.multiSelectEnabled ? () {
          widget.onNodeSelected.call(widget.node);
        } : () async {
          if (isRecordingPlaying) {
            await audioPlayer.stop();
          } else {
            await audioPlayer.play(filePath, isLocal: true);
          }
        },
        onLongPress: widget.multiSelectEnabled ? () {
          widget.onNodeSelected.call(widget.node);
        } : null,
        child: Container(
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  padding: EdgeInsets.only(left: 10, top: 10, bottom: 10),
                  child: Row(
                    children: [
                      widget.gridHorizontalSize == 4 ? Container() : Container(
                        margin: EdgeInsets.only(right: 5),
                        child: Container(
                            width: iconContainerSize, height: iconContainerSize,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(50),
                                color: Colors.indigo
                            ),
                            child: iconWidget),
                      ),
                      Container(
                        width: nameContainerSize,
                        alignment: Alignment.centerLeft,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  height: 15,
                                  child: isRecordingPlaying
                                      ? progressIndicator
                                      : Text(title, overflow: TextOverflow.ellipsis, maxLines: 3)),
                              Text(widget.node.fileSizeFormatted(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ]),
                      )
                    ],
                  ),
                ),
                buildMoreButton(),
              ],
            )),
      ),
    );
  }

  buildProgressIndicator(durationInMillis, loaderColor, progressColor) {
    var maxWidth = nameContainerSize - 10;

    if (durationInMillis < 100) {
      durationInMillis = 100;
    }

    var currentWidth = (recordingCurrentPositionMillis / durationInMillis) * (maxWidth);

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Container(
            width: maxWidth, height: 0.5, color: loaderColor
        ),
        AnimatedContainer(
            duration: Duration(seconds: 1),
            width: currentWidth, height: 2, color: progressColor
        ),
      ],
    );
  }

  buildMoreButton() {
    return GestureDetector(
        onTapDown: (details) async {
          widget.multiSelectEnabled ? () {} : showDSMenu(details);
        },
        child: Container(
          alignment: Alignment.topRight,
          padding: EdgeInsets.only(top: 7.5, right: 2.5),
          constraints: BoxConstraints(
              maxWidth: 50, maxHeight: 50
          ),
          child: Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
        )
    );
  }

  void showDSMenu(details) {
    showMenu(
      context: scaffold.context,
      position: RelativeRect.fromLTRB(details.globalPosition.dx - 25, details.globalPosition.dy - 50, 1000, 1000),
      elevation: 8.0,
      items: [
        PopupMenuItem(value: 'OPEN', child: Text("Open")),
        PopupMenuItem(value: 'DELETE', child: Text("Delete")),
      ],
    ).then((value) {
      if (value == 'DELETE') {
        doDeleteMessage().then(onDeleteMessageSuccess, onError: onDeleteMessageError);
      } else if (value == 'OPEN') {
        OpenFile.open(filePath);
      }
    });
  }

  Future doDeleteMessage() async {
    try {
      var file = File(widget.picturesPath + '/' + widget.node.nodeName);
      file.delete();
    } catch(ignored) {}

    String url = '/api/data-space'
        '?nodeId=' + widget.node.id.toString() +
        '&fileName=' + basename(widget.node.nodeName);

    http.Response response = await HttpClientService.delete(url);

    if (response.statusCode != 200) {
      throw Exception();
    }

    return true;
  }

  onDeleteMessageSuccess(_) async {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.info('Deleted'));
    await Future.delayed(Duration(seconds: 2));
    dataSpaceDeletePublisher.subject.add(widget.node.id);
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}
