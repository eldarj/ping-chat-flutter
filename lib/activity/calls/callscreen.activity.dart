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
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutterping/util/widget/base.state.dart';

import 'package:sip_ua/sip_ua.dart';

class CallScreenWidget extends StatefulWidget {
  final String target;

  final String contactName;

  final String fullPhoneNumber;

  final Widget profileImageWidget;

  final Color backgroundColor;

  final String direction;

  final Call incomingCall;

  const CallScreenWidget({Key key,
    this.target,
    this.contactName,
    this.fullPhoneNumber,
    this.profileImageWidget,
    this.direction,
    this.backgroundColor,
    this.incomingCall}) : super(key: key);

  @override
  CallScreenActivityState createState() => CallScreenActivityState(direction: direction, call: incomingCall);
}

class CallScreenActivityState extends State<CallScreenWidget> {
  ScaffoldState scaffold;

  BuildContext getScaffoldContext() => scaffold.context;

  bool displayLoader = true;

  bool callOngoing = false;

  Timer callDurationTimer;
  String callDurationLabel = '00:00';

  MediaStream localMediaStream;
  MediaStream remoteMediaStream;

  bool isAudioMuted = false;
  bool isSpeakerOn = false;

  Call call;

  String direction;
  String stateLabel = 'Connecting...';
  String remote_identity = 'loading remote';

  CallStateEnum callState = CallStateEnum.NONE;

  CallScreenActivityState({this.direction, this.call}) : super();

  void initCall() async {
    await Future.delayed(Duration(seconds: 1));
    print('DEBUGGING ' + widget.target);
    sipClientService.call(widget.target);
  }

  @override
  initState() {
    super.initState();

    callStatePublisher.addListener('123', (CallEvent callEvent) {
      print('CALL STATE PUBLISHER - CALLSCREEN');
      var call = callEvent.call;
      var callState = callEvent.callState;
      if (mounted) {
        setState(() {
          this.callState = call.state;
          this.call = call;

          if (call.state == CallStateEnum.CONNECTING) {
            stateLabel = 'Connecting...';

          } else if (call.state == CallStateEnum.ACCEPTED) {
            stateLabel = 'Accepted';

          } else if (call.state == CallStateEnum.CONFIRMED) {
            stateLabel = 'Confirmed';
            callOngoing = true;
            displayLoader = false;
            callDurationTimer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
              Duration duration = Duration(seconds: timer.tick);
              if (mounted && callDurationTimer.isActive) {
                print('duration.......');
                this.setState(() {
                  callDurationLabel = [duration.inMinutes, duration.inSeconds]
                      .map((seg) => seg.remainder(60).toString().padLeft(2, '0'))
                      .join(':');
                });
              } else {
                callDurationTimer.cancel();
              }
            });
          } else if (call.state == CallStateEnum.PROGRESS) {
            stateLabel = 'Ringing';
          } else if (call.state == CallStateEnum.FAILED) {
            Navigator.pop(context);

          } else if (call.state == CallStateEnum.ENDED) {
            Navigator.pop(context);

          } else if (call.state == CallStateEnum.MUTED) {
            if (callState.audio) isAudioMuted = true;

          } else if (call.state == CallStateEnum.UNMUTED) {
            if (callState.audio) isAudioMuted = false;

          } else if (call.state == CallStateEnum.STREAM) {
            print('STREAM EVENT' + callState.originator);
            MediaStream stream = callState.stream;
            if (callState.originator == 'local') {
              callState.stream?.getAudioTracks()?.first?.enableSpeakerphone(false);
              localMediaStream = stream;
            }
            if (callState.originator == 'remote') {
              remoteMediaStream = stream;
            }
          }

          direction = call.direction;
          remote_identity = call.remote_identity;
        });
      }
    });

    if (direction == 'OUTGOING') {
      initCall();
    }
  }

  @override
  dispose() {
    super.dispose();
    callStatePublisher.removeListener('123');
    disposeCallObjects();
  }

  void disposeCallObjects() {
    if (call != null && call.state != CallStateEnum.FAILED && call.state != CallStateEnum.ENDED) {
      call.hangup();
    }

    if (callDurationTimer != null) {
      callDurationTimer.cancel();
    }
  }

  void onHangup() {
    disposeCallObjects();
  }

  void onAccept() {
    sipClientService.answer(call);
  }

  void onToggleMute() {
    if (isAudioMuted) {
      call.unmute(true, false);
    } else {
      call.mute(true, false);
    }
  }

  void onToggleSpeaker() {
    if (localMediaStream != null) {
      isSpeakerOn = !isSpeakerOn;
      localMediaStream.getAudioTracks()[0].enableSpeakerphone(isSpeakerOn);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Builder(builder: (context) {
          scaffold = Scaffold.of(context);
          return buildActivityContent();
        })
    );
  }

  Widget buildActivityContent() {
    double imageBlur = widget.profileImageWidget != null ? 15 : 0;
    Border profileBorder = callOngoing
        ? Border.all(color: Color.fromRGBO(90, 254, 90, 0.3), width: 10)
        : Border.all(color: Color.fromRGBO(255, 255, 255, 0.1), width: 10);

    return Stack(
      children: [
        widget.profileImageWidget == null ? Container(
          height: DEVICE_MEDIA_SIZE.height,
          width: DEVICE_MEDIA_SIZE.width,
          color: widget.backgroundColor ?? Colors.grey.shade800,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 85, color: Colors.black12,
                  padding: EdgeInsets.only(top: 30, left: 5, right: 10),
                  child: Row(children: [
                    IconButton(onPressed: () {
                      Navigator.pop(context);
                    }, icon: Icon(Icons.close), color: Colors.white),
                  ],),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(top: 25, bottom: 25),
                        child: Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            displayLoader ? SpinKitPulse(
                              color: Colors.white,
                              size: 200.0,
                            ) : Container(),
                            Container(
                              height: 175, width: 175,
                              decoration: BoxDecoration(
                                border: profileBorder,
                                borderRadius: BorderRadius.all(Radius.circular(100)),
                              ),
                              child: ClipRRect(borderRadius: BorderRadius.circular(100),
                                child: widget.profileImageWidget ?? Image.asset(RoundProfileImageComponent.DEFAULT_IMAGE_PATH),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(widget.contactName, style: TextStyle(fontSize: 24, color: Colors.white)),
                      Text(widget.fullPhoneNumber, style: TextStyle(color: Colors.grey)),
                      buildCallDetails(),
                    ],
                  ),
                ),
                Container(
                    margin: EdgeInsets.only(bottom: 25),
                    child: buildCallButtons())
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget buildCallButtons() {
    Widget baseButtons = Row();
    Widget advancedButtons = Row();

    if (callOngoing) {
      baseButtons = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ActionButton(
          onPressed: () => onHangup(),
          icon: Icons.call_end,
          fillColor: Colors.red,
        )
      ]);
      advancedButtons = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        ActionButton(
          icon: isAudioMuted ? Icons.mic_off : Icons.mic,
          checked: isAudioMuted,
          onPressed: () => onToggleMute(),
        ),
        ActionButton(
          icon: isSpeakerOn ? Icons.volume_off : Icons.volume_up,
          checked: isSpeakerOn,
          onPressed: () => onToggleSpeaker(),
        )
      ]);
    } else {
      if (direction == 'OUTGOING') {
        baseButtons = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ActionButton(
            onPressed: () => onHangup(),
            icon: Icons.call_end,
            fillColor: Colors.red,
          ),
        ]);
        advancedButtons = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ActionButton(
            icon: isSpeakerOn ? Icons.volume_off : Icons.volume_up,
            checked: isSpeakerOn,
            onPressed: () => onToggleSpeaker(),
          )
        ]);
      } else {
        baseButtons = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ActionButton(
            fillColor: Colors.green,
            icon: Icons.phone,
            onPressed: () => onAccept(),
          ),
          ActionButton(
            onPressed: () => onHangup(),
            icon: Icons.call_end,
            fillColor: Colors.red,
          ),
        ]);
      }
    }

    return Column(children: [
      Container(
          margin: EdgeInsets.only(bottom: 25),
          child: advancedButtons),
      baseButtons
    ]);
  }

  Widget buildCallDetails() {
    return Column(children: [
      Center(
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                '$remote_identity',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ))),
      Center(
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(callDurationLabel,
                  style: TextStyle(fontSize: 14, color: Colors.white)))),
      Center(
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(direction ?? 'loading direction...',
                  style: TextStyle(fontSize: 14, color: Colors.white)))),
      Center(
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(callState.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.white)))),
      Center(
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text('isSpeakerOn ' + isSpeakerOn.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.white)))),
      Text(stateLabel),
    ]);
  }
}
