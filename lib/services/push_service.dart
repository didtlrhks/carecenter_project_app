import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../firebase_options.dart';
import '../screens/calls/job_detail_screen.dart';
import '../state/auth_controller.dart';

const _channelId = 'job_calls';
const _channelName = '근무 콜';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (_) {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (_) {}
  }
}

class PushService {
  PushService._();
  static final instance = PushService._();

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  AuthController? _auth;
  bool ready = false;
  String? _pendingJobId;

  Future<void> init(AuthController auth) async {
    _auth = auth;
    ready = await _initFirebase();
    if (!ready) {
      debugPrint('Firebase 미설정: 푸시는 인박스 폴링만 사용합니다.');
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _initLocalNotifications();
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _auth?.setDeviceToken(token);
    });

    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _queueFromMessage(initial);

    await syncToken();
  }

  Future<bool> _initFirebase() async {
    try {
      if (Firebase.apps.isNotEmpty) return true;
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      return true;
    } catch (_) {
      try {
        if (Firebase.apps.isNotEmpty) return true;
        await Firebase.initializeApp();
        return true;
      } catch (e) {
        debugPrint('Firebase.initializeApp failed: $e');
        return false;
      }
    }
  }

  Future<void> _requestPermission() async {
    await FirebaseMessaging.instance.requestPermission(alert: true, badge: true, sound: true);
    if (!kIsWeb && Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> _initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) {
        final jobId = _jobIdFromPayload(response.payload);
        if (jobId != null) openJob(jobId);
      },
    );
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: '근무 요청·확정 알림',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> syncToken() async {
    if (!ready) {
      debugPrint('[Push] syncToken skipped: Firebase not ready');
      return;
    }
    final auth = _auth;
    if (auth == null || !auth.isLoggedIn) {
      debugPrint('[Push] syncToken skipped: not logged in');
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[Push] FCM token empty');
        return;
      }
      debugPrint('[Push] FCM token acquired (${token.length} chars), registering…');
      await auth.setDeviceToken(token);
      debugPrint('[Push] device token registered with server');
    } catch (e) {
      debugPrint('[Push] FCM token sync failed: $e');
    }
  }

  Future<void> _onForeground(RemoteMessage message) async {
    final n = message.notification;
    final jobId = _jobIdFromMessage(message);
    await _local.show(
      id: message.hashCode,
      title: n?.title ?? '알림',
      body: n?.body ?? '',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode({'jobRequestId': jobId}),
    );
  }

  void _onOpened(RemoteMessage message) {
    _queueFromMessage(message);
    final jobId = _jobIdFromMessage(message);
    if (jobId != null) openJob(jobId);
  }

  void _queueFromMessage(RemoteMessage message) {
    final jobId = _jobIdFromMessage(message);
    if (jobId != null) _pendingJobId = jobId;
  }

  String? _jobIdFromMessage(RemoteMessage message) {
    final data = message.data;
    final fromData = data['jobRequestId'] ?? data['job_request_id'];
    if (fromData is String && fromData.isNotEmpty) return fromData;
    return null;
  }

  String? _jobIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final map = jsonDecode(payload);
      if (map is Map && map['jobRequestId'] is String) {
        final id = map['jobRequestId'] as String;
        return id.isEmpty ? null : id;
      }
    } catch (_) {}
    return payload;
  }

  void consumePending() {
    final id = _pendingJobId;
    if (id == null) return;
    _pendingJobId = null;
    openJob(id);
  }

  void openJob(String jobId) {
    final nav = navigatorKey.currentState;
    if (nav == null || _auth?.isLoggedIn != true) {
      _pendingJobId = jobId;
      return;
    }
    nav.push(MaterialPageRoute(builder: (_) => JobDetailScreen(jobId: jobId)));
  }
}
