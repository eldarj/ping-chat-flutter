import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/service/voice/call-state.publisher.dart';
import 'package:flutterping/service/voice/sip-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/action-button.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/util/widget/base.state.dart';

import 'package:sip_ua/sip_ua.dart';

class CallScreenWidget extends StatefulWidget {
  final String target;

  final String contactName;

  final String fullPhoneNumber;

  final Widget profileImageWidget;

  final Color backgroundColor;

  const CallScreenWidget({Key key, this.target, this.contactName, this.fullPhoneNumber,
    this.profileImageWidget, this.backgroundColor = Colors.grey}) : super(key: key);

  @override
  _MyCallScreenWidget createState() => _MyCallScreenWidget();
}

class _MyCallScreenWidget extends BaseState<CallScreenWidget> {
  bool displayLoader = false;

  MediaStream _localStream;
  MediaStream _remoteStream;

  bool _showNumPad = false;
  String _timeLabel = '00:00';
  Timer _timer;
  bool _audioMuted = false;
  bool _speakerOn = false;
  bool _hold = false;
  String _holdOriginator;
  CallStateEnum _state = CallStateEnum.NONE;

  String remote_identity = 'loading remote';

  String direction = 'loading direction';

  Call call;

  @override
  initState() {
    super.initState();

    callStatePublisher.addListener('123', (Call call) {
      print('CALL STATE PUBLISHER');
      setState(() {
        _state = call.state;
        this.call = call;
        direction = call.direction;
        remote_identity = call.remote_identity;
        displayLoader = false;
      });
    });

    // sipClientService.call(widget.target);

    _startTimer();
  }

  @override
  deactivate() {
    super.deactivate();
    callStatePublisher.removeListener('123');
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
      Duration duration = Duration(seconds: timer.tick);
      if (mounted) {
        this.setState(() {
          _timeLabel = [duration.inMinutes, duration.inSeconds]
              .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
              .join(':');
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void callStateChanged(Call call, CallState callState) {
    if (callState.state == CallStateEnum.HOLD ||
        callState.state == CallStateEnum.UNHOLD) {
      _hold = callState.state == CallStateEnum.HOLD;
      _holdOriginator = callState.originator;
      this.setState(() {});
      return;
    }

    if (callState.state == CallStateEnum.MUTED) {
      if (callState.audio) _audioMuted = true;
      this.setState(() {});
      return;
    }

    if (callState.state == CallStateEnum.UNMUTED) {
      if (callState.audio) _audioMuted = false;
      this.setState(() {});
      return;
    }

    if (callState.state != CallStateEnum.STREAM) {
      _state = callState.state;
    }

    switch (callState.state) {
      case CallStateEnum.STREAM:
        _handelStreams(callState);
        break;
      case CallStateEnum.ENDED:
      case CallStateEnum.FAILED:
        _backToDialPad();
        break;
      case CallStateEnum.UNMUTED:
      case CallStateEnum.MUTED:
      case CallStateEnum.CONNECTING:
      case CallStateEnum.PROGRESS:
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
      case CallStateEnum.HOLD:
      case CallStateEnum.UNHOLD:
      case CallStateEnum.NONE:
      case CallStateEnum.CALL_INITIATION:
      case CallStateEnum.REFER:
        break;
    }
  }

  void _backToDialPad() {
    _timer.cancel();
    Timer(Duration(seconds: 2), () {
      Navigator.of(context).pop();
    });
  }

  void _handelStreams(CallState event) async {
    MediaStream stream = event.stream;
    if (event.originator == 'local') {
      event.stream?.getAudioTracks()?.first?.enableSpeakerphone(false);
      _localStream = stream;
    }
    if (event.originator == 'remote') {
      _remoteStream = stream;
    }
  }

  void _handleHangup() {
    call.hangup();
    _timer.cancel();
  }

  void _handleAccept() {
    // call.answer(helper.buildCallOptions());
  }

  void _switchCamera() {
    if (_localStream != null) {
      _localStream.getVideoTracks()[0].switchCamera();
    }
  }

  void _muteAudio() {
    if (_audioMuted) {
      call.unmute(true, false);
    } else {
      call.mute(true, false);
    }
  }

  void _handleHold() {
    if (_hold) {
      call.unhold();
    } else {
      call.hold();
    }
  }

  String _tansfer_target;
  void _handleTransfer() {
    showDialog<Null>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter target to transfer.'),
          content: TextField(
            onChanged: (String text) {
              setState(() {
                _tansfer_target = text;
              });
            },
            decoration: InputDecoration(
              hintText: 'URI or Username',
            ),
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Ok'),
              onPressed: () {
                call.refer(_tansfer_target);
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _handleDtmf(String tone) {
    print('Dtmf tone => $tone');
    call.sendDTMF(tone);
  }

  void _handleKeyPad() {
    this.setState(() {
      _showNumPad = !_showNumPad;
    });
  }

  void _toggleSpeaker() {
    if (_localStream != null) {
      _speakerOn = !_speakerOn;
      _localStream.getAudioTracks()[0].enableSpeakerphone(_speakerOn);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BaseAppBar.getBackAppBar(getScaffoldContext),
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return _buildContent();
        }),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
            padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 24.0),
            child: Container(width: 320, child: _buildActionButtons())));
  }

  List<Widget> _buildNumPad() {
    var lables = [
      [
        {'1': ''},
        {'2': 'abc'},
        {'3': 'def'}
      ],
      [
        {'4': 'ghi'},
        {'5': 'jkl'},
        {'6': 'mno'}
      ],
      [
        {'7': 'pqrs'},
        {'8': 'tuv'},
        {'9': 'wxyz'}
      ],
      [
        {'*': ''},
        {'0': '+'},
        {'#': ''}
      ],
    ];

    return lables
        .map((row) => Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row
                .map((label) => ActionButton(
              title: '${label.keys.first}',
              subTitle: '${label.values.first}',
              onPressed: () => _handleDtmf(label.keys.first),
              number: true,
            ))
                .toList())))
        .toList();
  }

  Widget _buildActionButtons() {
    var hangupBtn = ActionButton(
      title: "hangup",
      onPressed: () => _handleHangup(),
      icon: Icons.call_end,
      fillColor: Colors.red,
    );

    var hangupBtnInactive = ActionButton(
      title: "hangup",
      onPressed: () {},
      icon: Icons.call_end,
      fillColor: Colors.grey,
    );

    var basicActions = <Widget>[];
    var advanceActions = <Widget>[];

    switch (_state) {
      case CallStateEnum.NONE:
      case CallStateEnum.CONNECTING:
        if (direction == 'INCOMING') {
          basicActions.add(ActionButton(
            title: "Accept",
            fillColor: Colors.green,
            icon: Icons.phone,
            onPressed: () => _handleAccept(),
          ));
          basicActions.add(hangupBtn);
        } else {
          basicActions.add(hangupBtn);
        }
        break;
      case CallStateEnum.ACCEPTED:
      case CallStateEnum.CONFIRMED:
        {
          advanceActions.add(ActionButton(
            title: _audioMuted ? 'unmute' : 'mute',
            icon: _audioMuted ? Icons.mic_off : Icons.mic,
            checked: _audioMuted,
            onPressed: () => _muteAudio(),
          ));

          advanceActions.add(ActionButton(
            title: "keypad",
            icon: Icons.dialpad,
            onPressed: () => _handleKeyPad(),
          ));

          advanceActions.add(ActionButton(
            title: _speakerOn ? 'speaker off' : 'speaker on',
            icon: _speakerOn ? Icons.volume_off : Icons.volume_up,
            checked: _speakerOn,
            onPressed: () => _toggleSpeaker(),
          ));

          basicActions.add(ActionButton(
            title: _hold ? 'unhold' : 'hold',
            icon: _hold ? Icons.play_arrow : Icons.pause,
            checked: _hold,
            onPressed: () => _handleHold(),
          ));

          basicActions.add(hangupBtn);

          if (_showNumPad) {
            basicActions.add(ActionButton(
              title: "back",
              icon: Icons.keyboard_arrow_down,
              onPressed: () => _handleKeyPad(),
            ));
          } else {
            basicActions.add(ActionButton(
              title: "transfer",
              icon: Icons.phone_forwarded,
              onPressed: () => _handleTransfer(),
            ));
          }
        }
        break;
      case CallStateEnum.FAILED:
      case CallStateEnum.ENDED:
        basicActions.add(hangupBtnInactive);
        break;
      case CallStateEnum.PROGRESS:
        basicActions.add(hangupBtn);
        break;
      default:
        print('Other state => $_state');
        break;
    }

    var actionWidgets = <Widget>[];

    if (_showNumPad) {
      actionWidgets.addAll(_buildNumPad());
    } else {
      if (advanceActions.isNotEmpty) {
        actionWidgets.add(Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: advanceActions)));
      }
    }

    actionWidgets.add(Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: basicActions)));

    return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.end,
        children: actionWidgets);
  }

  Widget _buildContent() {
    Widget _w = ActivityLoader.build();

    double imageBlur = widget.profileImageWidget != null ? 15 : 0;

    if (!displayLoader) {
      _w = Stack(
        children: [
          widget.profileImageWidget == null ? Container(
            height: DEVICE_MEDIA_SIZE.height,
            width: DEVICE_MEDIA_SIZE.width,
            color: widget.backgroundColor,
          ) : ColorFiltered(
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.srcOver),
            child: Container(
              child: widget.profileImageWidget,
              height: DEVICE_MEDIA_SIZE.height,
              width: DEVICE_MEDIA_SIZE.width,
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: imageBlur, sigmaY: imageBlur),
            child: Container(
              child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                'VOICE CALL' +
                                    (_hold
                                        ? ' PAUSED BY ${this._holdOriginator.toUpperCase()}'
                                        : ''),
                                style: TextStyle(fontSize: 24, color: Colors.black54),
                              ))),
                      Container(
                        height: 100, width: 100,
                        child: ClipRRect(borderRadius: BorderRadius.circular(100),
                          child: widget.profileImageWidget ?? Image.asset(RoundProfileImageComponent.DEFAULT_IMAGE_PATH),
                        ),
                      ),
                      Text(widget.contactName, style: TextStyle(fontSize: 24)),
                      Text(widget.fullPhoneNumber, style: TextStyle(color: Colors.grey)),
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                '$remote_identity',
                                style: TextStyle(fontSize: 18, color: Colors.black54),
                              ))),
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(_timeLabel,
                                  style: TextStyle(fontSize: 14, color: Colors.black54)))),
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(direction,
                                  style: TextStyle(fontSize: 14, color: Colors.black54)))),
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(widget.target,
                                  style: TextStyle(fontSize: 14, color: Colors.black54)))),
                      Center(
                          child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(EnumHelper.getName(_state),
                                  style: TextStyle(fontSize: 14, color: Colors.black54)))),
                    ],
                  )),
            ),
          )
        ],
      );
    }

    return _w;
  }
}
