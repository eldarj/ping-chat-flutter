import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutterping/activity/chats/chat-list.activity.dart';
import 'package:flutterping/activity/contacts/contacts.activity.dart';
import 'package:flutterping/main.dart';
import 'package:flutterping/service/http/http-client.service.dart';
import 'package:flutterping/util/navigation/navigator.util.dart';

class NotificationService {
  static final NotificationService _appData = new NotificationService._internal();

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

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

  NotificationService initializeLocalPlugin() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    var initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ping_full_launcher_round'), iOS: null, macOS: null
    );

    _initializeLocalPlugin(initSettings);

    return this;
  }

  Future _onMessage (Map<String, dynamic> message) async {
    var notificationMessage = Map.from(message);

    var data = notificationMessage['data'];
    var action = data['click_action'];

    if (action == 'FLUTTER_CONTACT_REGISTERED') {
      var notification = notificationMessage['notification'];
      String groupKey = 'onMessageKey';
      String groupChannelId = 'onMessageChannelId';
      String groupChannelName = 'onMessageChannelName';
      String groupChannelDescription = 'onMessageChannelDescription';

      AndroidNotificationDetails androidNotificationDetails = _createAndroidNotificationDetails(groupKey,
          groupChannelId, groupChannelName, groupChannelDescription);

      var title = notification['title'];
      var body = notification['body'];

      await flutterLocalNotificationsPlugin.show(900, title, body,
          NotificationDetails(android: androidNotificationDetails));
    }
  }

  Future _onOpenNotification(Map<String, dynamic> unused) async {
    NavigatorUtil.push(ROOT_CONTEXT, ChatListActivity());
  }

  Future _onOpenLocalNotification (String payload) async {
    NavigatorUtil.push(ROOT_CONTEXT, ContactsActivity());
  }

  Future _registerUser(token) async {
    return HttpClientService.post('/api/users/firebase-token', body: token);
  }

  void _initializeLocalPlugin(settings) async {
    await flutterLocalNotificationsPlugin.initialize(settings,
        onSelectNotification: (payload) => _onOpenLocalNotification(payload));
  }

  static AndroidNotificationDetails _createAndroidNotificationDetails(String groupKey,
      String groupChannelId, String groupChannelName, String groupChannelDescription) {

    return AndroidNotificationDetails(
        groupChannelId, groupChannelName, groupChannelDescription,
        importance: Importance.max,
        priority: Priority.max,
        enableLights: true,
        groupKey: groupKey);
  }
}

final notificationService = NotificationService();
