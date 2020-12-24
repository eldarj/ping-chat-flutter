

import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutterping/service/data-space/data-space-delete.publisher.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/shared/component/snackbars.component.dart';
import 'package:flutterping/util/widget/base.state.dart';
import 'package:path/path.dart';
import 'package:flutterping/util/extension/duration.extension.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/main.dart';
import 'package:flutterping/model/ds-node-dto.model.dart';
import 'package:flutterping/shared/var/global.var.dart';

class DSMedia extends StatefulWidget {
  final DSNodeDto node;

  final String picturesPath;

  const DSMedia({Key key, this.node, this.picturesPath}) : super(key: key);

  @override
  State<StatefulWidget> createState() => DSMediaState();
}

class DSMediaState extends BaseState<DSMedia> {
  bool isRecordingPlaying = false;

  String recordingCurrentPosition = '00:00';

  AudioPlayer audioPlayer = AudioPlayer();


  @override
  void initState() {
    super.initState();
    AudioPlayer.logEnabled = false;
    audioPlayer.onAudioPositionChanged.listen((Duration  p) {
      setState(() {
        recordingCurrentPosition = p.format();
      });
    });

    audioPlayer.onPlayerStateChanged.listen((AudioPlayerState s) {
      setState(() {
        isRecordingPlaying = s == AudioPlayerState.PLAYING;
      });
    });
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
    String title = widget.node.nodeName;
    String filePath = widget.picturesPath + '/' + widget.node.nodeName;
    Widget iconWidget = Icon(Icons.ondemand_video, color: Colors.grey.shade100, size: 20);

    if (widget.node.nodeType == 'RECORDING') {
      title = 'Recording';
      IconData icon = isRecordingPlaying ? Icons.pause : Icons.mic_none;

      if (widget.node.recordingDuration != null) {
        title += ' (${widget.node.recordingDuration})';
      }

      iconWidget = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
              margin: EdgeInsets.only(bottom: isRecordingPlaying ? 12.5 : 0),
              child: Icon(icon, color: Colors.grey.shade100, size: 20)),
          Container(
              margin: EdgeInsets.only(top: isRecordingPlaying ? 12.5 : 0),
              child: Text(recordingCurrentPosition, style: TextStyle(
                  fontSize: 11,
                  color: isRecordingPlaying ? Colors.grey.shade100 : Colors.transparent))
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () async {
        if (widget.node.nodeType == 'MEDIA') {
          OpenFile.open(filePath);
        } else {
          if (isRecordingPlaying) {
            await audioPlayer.stop();
          } else {
            await audioPlayer.play(filePath, isLocal: true);
          }
        }
      },
      onLongPressEnd: (details) {
        showMenu(
          context: scaffold.context,
          position: RelativeRect.fromLTRB(details.globalPosition.dx, details.globalPosition.dy, 100000, 0),
          elevation: 8.0,
          items: [PopupMenuItem(value: 'DELETE', child: Text("Delete")),],
        ).then((value) {
          if (value == 'DELETE') {
            doDeleteMessage().then(onDeleteMessageSuccess, onError: onDeleteMessageError);
          }
        });
      },
      child: Container(
          color: Colors.grey.shade200,
          padding: EdgeInsets.all(10),
          child: Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 10),
                child: Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: CompanyColor.accentGreenLight
                    ),
                    child: iconWidget),
              ),
              Container(
                width: DEVICE_MEDIA_SIZE.width / 2 - 100,
                alignment: Alignment.centerLeft,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title),
                      Text(widget.node.fileSizeFormatted(), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ]),
              )
            ],
          )),
    );
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
    scaffold.showSnackBar(SnackBarsComponent.info('Izbrisali ste datoteku.'));
    await Future.delayed(Duration(seconds: 2));
    dataSpaceDeletePublisher.subject.add(widget.node.id);
  }

  onDeleteMessageError(error) {
    scaffold.removeCurrentSnackBar();
    scaffold.showSnackBar(SnackBarsComponent.error());
  }
}
