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

  // Setup method in main dart
  NotificationService initializeNotificationHandlers() {
    FirebaseMessaging firebaseMessaging = FirebaseMessaging();
    firebaseMessaging.configure(
      onMessage: _onLocalNotificationReceived,
      onResume: _onPushNotification,
    );

    return this;
  }

  // Setup method in main dart
  NotificationService initializeLocalPlugin() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    var initSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ping_full_launcher_round'), iOS: null, macOS: null
    );

    _initializeLocalPlugin(initSettings);

    return this;
  }

  // Setup method in main dart
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

  void _initializeLocalPlugin(settings) async {
    await flutterLocalNotificationsPlugin.initialize(settings,
        onSelectNotification: (payload) => _onOpenLocalNotification(payload));
  }

  Future _registerUser(token) async {
    return HttpClientService.post('/api/users/firebase-token', body: token);
  }

  // Notification handlers
  // Create local notification (mainly used for contact registered notif.)
  Future _onLocalNotificationReceived (Map<String, dynamic> message) async {
    var notificationMessage = Map.from(message);

    var data = notificationMessage['data'];
    var action = data['click_action'];

    if (action == 'FLUTTER_CONTACT_REGISTERED') {
      var notification = notificationMessage['notification'];
      String groupKey = 'onMessageKey';
      String groupChannelId = 'onMessageChannelId';
      String groupChannelName = 'onMessageChannelName';
      String groupChannelDescription = 'onMessageChannelDescription';

      var title = notification['title'];
      var body = notification['body'];
      AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
          groupChannelId, groupChannelName, groupChannelDescription,
          importance: Importance.max,
          priority: Priority.max,
          enableLights: true,
          groupKey: groupKey);

      await flutterLocalNotificationsPlugin.show(900, title, body,
          NotificationDetails(android: androidNotificationDetails));
    }
  }

  // On open local notification
  Future _onOpenLocalNotification (String contactPhoneNumber) async {
    NavigatorUtil.push(ROOT_CONTEXT, ContactsActivity());
  }

  // On received push notification click
  Future _onPushNotification(Map<String, dynamic> unused) async {
    NavigatorUtil.push(ROOT_CONTEXT, ChatListActivity());
  }
}

final notificationService = NotificationService();
