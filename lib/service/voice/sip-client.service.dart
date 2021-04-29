import 'dart:async';

import 'package:flutterping/service/voice/call-state.publisher.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sip_ua/sip_ua.dart';

class SipClientService implements SipUaHelperListener {
  SIPUAHelper helper;

  static final SipClientService _appData = new SipClientService._internal();

  factory SipClientService() {
    return _appData;
  }

  SipClientService._internal() {
    // print('SipClientService - internally creating SIPUAHelper');
    // helper = SIPUAHelper();
    // helper.loggingLevel(Log.Level.nothing);
    // helper.addSipUaHelperListener(this);
  }

  // SipClientService
  register(user, password) {
    print('SipClientService - REGISTER');
    UaSettings settings = UaSettings();

    settings.webSocketUrl = 'ws://192.168.0.13:5066';
    // settings.webSocketSettings.extraHeaders = {
    //   'Origin': ' https://tryit.jssip.net',
    //   'Host': 'tryit.jssip.net:10443'
    // };
    settings.webSocketSettings.allowBadCertificate = true;
    settings.webSocketSettings.userAgent = 'Dart/2.8 (dart:io) for OpenSIPS.';
    settings.registerParams.extraContactUriParams = <String, String>{
      'pn-provider': 'fcm',
      'transport': 'ws'
    };

    settings.uri = 'sip:' + user + '@192.168.0.13';
    settings.authorizationUser = user;
    settings.password = password;
    settings.displayName = user;
    settings.userAgent = 'Dart SIP Client v1.0.0';
    settings.dtmfMode = DtmfMode.RFC2833;

    helper.start(settings);
  }

  call(target) {
    print('SipClientService - CALL');
    helper.call(target, true);
  }

  answer(call) {
    call.answer(helper.buildCallOptions(true));
  }

  // Publishers
  Map<String, StreamSubscription> registrationStateSubs = new Map();
  PublishSubject<RegistrationState> registrationStateSubject = PublishSubject<RegistrationState>();

  addListener(String key, Function callback) {
    if (registrationStateSubs.containsKey(key)) {
      registrationStateSubs[key].cancel();
      registrationStateSubs.remove(key);
      registrationStateSubs[key] = registrationStateSubject.listen(callback);
    } else {
      registrationStateSubs[key] = registrationStateSubject.listen(callback);
    }
  }

  removeListener(String key) {
    registrationStateSubs[key]?.cancel();
    registrationStateSubs.remove(key);
  }

  // SipUaHelperListener
  @override
  void callStateChanged(Call call, CallState state) {
    print('SipClientService - call state changed');
    print(call.state.toString());
    print(state.state.toString());

    callStatePublisher.subject.add(new CallEvent(call: call, callState: state));
  }

  @override
  void registrationStateChanged(RegistrationState state) {
    print('SipClientService - registration state changed');
    registrationStateSubject.add(state);
    print(state.state.toString());
  }

  @override
  void transportStateChanged(TransportState state) {
    print('SipClientService - transport state changed');
    print(state.state.toString());
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    print('SipClientService - new message');
    print(msg.toString());
    print(msg.message.toString());
  }
}

final sipClientService = new SipClientService();
