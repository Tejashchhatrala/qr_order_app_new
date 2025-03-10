import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // Request permission
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Configure notification channels
    await _configureNotificationChannels();

    // Handle notification tap
    await _configureTapActions();
  }

  Future<void> _configureNotificationChannels() async {
    const androidChannel = AndroidNotificationChannel(
      'orders_channel',
      'Orders',
      description: 'Notifications for order updates',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> _configureTapActions() async {
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (details) {
        _handleNotificationTap(details.payload);
      },
    );
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      final data = json.decode(payload);
      if (data['type'] == 'order_update') {
        // Handle navigation to order tracking screen
        // You'll need to implement navigation using a navigation service
      }
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'orders_channel',
            'Orders',
            channelDescription: 'Notifications for new orders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  }

  Future<void> sendOrderStatusNotification(Order order) async {
    final statusMessages = {
      OrderStatus.preparing: 'Your order is being prepared',
      OrderStatus.ready: 'Your order is ready for pickup',
      OrderStatus.completed: 'Your order has been completed',
    };

    if (statusMessages.containsKey(order.status)) {
      await _localNotifications.show(
        order.hashCode,
        'Order Update',
        statusMessages[order.status],
        NotificationDetails(
          android: AndroidNotificationDetails(
            'orders_channel',
            'Orders',
            channelDescription: 'Notifications for order updates',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        payload: json.encode({
          'type': 'order_update',
          'orderId': order.id,
        }),
      );
    }
  }

  Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
}
