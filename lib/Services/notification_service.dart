import 'package:flutter/material.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _initialized = false;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    const AndroidInitializationSettings initializationSettingsAndroid = 
      AndroidInitializationSettings('@mipmap/ic_launcher');
      
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    
    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showOrderNotification({
    required int orderId,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'order_channel', 
      'Order Notifications',
      channelDescription: 'Notifications for order updates',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );
    
    await _notificationsPlugin.show(
      orderId, 
      title,
      body,
      platformDetails,
    );
  }
}