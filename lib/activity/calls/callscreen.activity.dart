import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/model/contact-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/messaging/message-sending.service.dart';
import 'package:flutterping/service/voice/call-state.publisher.dart';
import 'package:flutterping/service/voice/sip-client.service.dart';
import 'package:flutterping/shared/app-bar/base.app-bar.dart';
import 'package:flutterping/shared/component/action-button.component.dart';
import 'package:flutterping/shared/component/loading-button.component.dart';
import 'package:flutterping/shared/component/round-profile-image.component.dart';
import 'package:flutterping/shared/loader/activity-loader.element.dart';
import 'package:flutterping/shared/loader/spinner.element.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';
import 'package:flutterping/util/widget/base.state.dart';

import 'package:sip_ua/sip_ua.dart';

class CallScreenWidget extends StatefulWidget {
  final ContactDto contact;

  final String myContactName;

  final String direction;

  final Call incomingCall;

  const CallScreenWidget({Key key,
    this.contact,
    this.myContactName,
    this.direction,
    this.incomingCall,
  }) : super(key: key);

  @override
  CallScreenActivityState createState() => CallScreenActivityState(direction: direction, call: incomingCall);
}

class CallScreenActivityState extends State<CallScreenWidget> {
  ScaffoldState scaffold;

  BuildContext getScaffoldContext() => scaffold.context;

  MessageSendingService messageSendingService;

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
  String stateLabel = 'Connecting';

  CallScreenActivityState({this.direction, this.call}) : super();

  void initCall() async {
    if (sipClientService.isRegistered) {
      sipClientService.call(widget.contact.contactUser.fullPhoneNumber);
    } else {
      await Future.delayed(Duration(seconds: 3));
      // TODO: Play disconnect sound
      // TODO: Send neutral message

      messageSendingService.sendCallInfoMessage('FAILED', '00:00');
      Navigator.pop(context);
    }
  }

  initHandlers() {
    callStatePublisher.addListener('123', (CallEvent callEvent) {
      print('CALL STATE PUBLISHER - CALLSCREEN: ${callEvent.log()}');
      var call = callEvent.call;
      var callState = callEvent.callState;
      if (mounted) {
        setState(() {
          this.call = call;

          if (call.state == CallStateEnum.CONNECTING) {
            stateLabel = 'Connecting';

          } else if (call.state == CallStateEnum.ACCEPTED) {
            stateLabel = 'Accepted';

          } else if (call.state == CallStateEnum.CONFIRMED) {
            stateLabel = 'Confirmed';
            callOngoing = true;
            displayLoader = false;

            callDurationTimer = Timer.periodic(Duration(seconds: 1), (Timer timer) {
              Duration duration = Duration(seconds: timer.tick);

              if (mounted && callDurationTimer.isActive) {
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
            messageSendingService.sendCallInfoMessage('FAILED', '00:00');
            Navigator.pop(context);

          } else if (call.state == CallStateEnum.ENDED) {
            messageSendingService.sendCallInfoMessage('OUTGOING', callDurationLabel);
            Navigator.pop(context);

          } else if (call.state == CallStateEnum.MUTED) {
            print('MUTED');
            if (callState.audio) isAudioMuted = true;

          } else if (call.state == CallStateEnum.UNMUTED) {
            print('UNMUTED');
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
        });
      }
    });
  }

  @override
  initState() {
    super.initState();

    messageSendingService = new MessageSendingService(widget.contact.contactUser, widget.contact.contactName, widget.myContactName, widget.contact.contactBindingId);
    messageSendingService.initialize();

    initHandlers();

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
    return Stack(
      children: [
        buildBackgroundProfileBackdrop(),
        Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              buildAppBar(),
              Expanded(
                child: Container(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        width: 250,
                        margin: EdgeInsets.only(top: 25),
                        decoration: BoxDecoration(
                          color: Color.fromRGBO(0, 0, 0, 0.5),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        alignment: Alignment.center,
                        child: Stack(
                          children: [
                            buildBackgroundImage(),
                            Column(
                              children: [
                                buildProfileImage(),
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(widget.contact.contactName, style: TextStyle(fontSize: 26, color: Colors.white)),
                                ),
                                Text(widget.contact.contactUser.fullPhoneNumber, style: TextStyle(fontSize: 18, color: Colors.grey.shade300)),
                                buildCallDetails(),
                              ]
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                  margin: EdgeInsets.only(bottom: 25),
                  child: buildCallButtons()
              )
            ],
          ),
        )
      ],
    );
  }

  buildBackgroundProfileBackdrop() {
    Widget w = Container(
        height: DEVICE_MEDIA_SIZE.height,
        width: DEVICE_MEDIA_SIZE.width,
        color: Colors.grey.shade900
    );

    if (widget.contact.contactUser?.profileImagePath != null) {
      w = ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.srcOver),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              child: CachedNetworkImage(
                imageUrl: widget.contact.contactUser.profileImagePath, fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                    margin: EdgeInsets.all(15),
                    child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100)),
              ),
              height: DEVICE_MEDIA_SIZE.height,
              width: DEVICE_MEDIA_SIZE.width,
            ),
          ));
    }

    return w;
  }

  buildAppBar() {
    return Container(
      height: 85, color: Colors.black87,
      padding: EdgeInsets.only(top: 30, left: 5, right: 10),
      child: Row(children: [
        LoadingButton(
          icon: Icons.close,
          color: Colors.white,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ]),
    );
  }

  buildBackgroundImage() {
    Widget w = Container();

    if (widget.contact.backgroundImagePath != null) {
      w = ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Positioned.fill(
            child: Opacity(
              opacity: 0.3,
              child: CachedNetworkImage(
                  fit: BoxFit.cover,
                  imageUrl: API_BASE_URL + '/files/chats/' + widget.contact.backgroundImagePath),
            )),
      );
    }

    return w;
  }

  buildProfileImage() {
    Border profileBorder = callOngoing
        ? Border.all(color: Color.fromRGBO(90, 180, 90, 0.8), width: 10)
        : Border.all(color: Color.fromRGBO(255, 255, 255, 0.1), width: 10);

    return Container(
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
              child: widget.contact.contactUser?.profileImagePath != null
                  ? CachedNetworkImage(
                  imageUrl: widget.contact.contactUser.profileImagePath, fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                      margin: EdgeInsets.all(15),
                      child: CircularProgressIndicator(strokeWidth: 2, backgroundColor: Colors.grey.shade100)))
                  : Image.asset(RoundProfileImageComponent.DEFAULT_IMAGE_PATH),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCallDetails() {
    return Column(
        children: [
          Text(stateLabel, style: TextStyle(color: Colors.white)),
          Center(
              child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 25),
                  child: Text(
                      callDurationLabel,
                      style: TextStyle(fontSize: 16, color: Colors.white)
                  )
              )
          ),
        ]
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

    return Column(
        children: [
          Container(
              margin: EdgeInsets.only(bottom: 25),
              child: advancedButtons
          ),
          baseButtons
        ]
    );
  }
}
