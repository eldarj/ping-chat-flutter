import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/policy/policy-info.activity.dart';
import 'package:flutterping/model/client-dto.model.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/service/persistence/user.prefs.service.dart';
import 'package:http/http.dart' as http;
import 'package:flutterping/main.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class NotificationService {
  static final NotificationService _appData = new NotificationService._internal();

  factory NotificationService() {
    return _appData;
  }

  NotificationService._internal() {
    _initialize();
  }

  _initialize() async {
  }

  NotificationService initializeNotificationHandlers() {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging();
    firebaseMessaging.configure(
      onMessage: _onMessage,
      onResume: _onOpenNotification,
    );

    return this;
  }

  NotificationService initializeRegister() {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging();

    firebaseMessaging.getToken().then((token) {
      _registerUser(token);
    });

    firebaseMessaging.onTokenRefresh.listen((token) {
      _registerUser(token);
    });

    return this;
  }

  Future _onMessage (Map<String, dynamic> message) async {
    //
  }

  Future _onOpenNotification (Map<String, dynamic> message) async {
    NavigatorUtil.push(ROOT_CONTEXT, ChatListActivity());
  }

  _registerUser(token) async {
    return HttpClientService.post('/api/users/firebase-token', body: token);
  }
}

final notificationService = NotificationService();
