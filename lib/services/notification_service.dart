import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class NotificationService {
  final GlobalKey<NavigatorState> navigatorKey;

  NotificationService({
    required this.navigatorKey,
  });

  // Initialize OneSignal
  Future<void> initialize(String oneSignalAppId) async {
    // Set log level for debugging
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

    // Initialize OneSignal with your app ID
    OneSignal.initialize(oneSignalAppId);

    // Request permission for push notifications
    await OneSignal.Notifications.requestPermission(true);

    // Set up notification handlers for foreground notifications
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      // Display the notification when app is in foreground
      event.notification.display();
    });

    // Set up click listener for when user taps a notification
    OneSignal.Notifications.addClickListener((event) {
      print('Notification clicked: ${event.notification.additionalData}');
      handleNotificationClick(event);
    });
  }

  // Store the driver's OneSignal player ID in your database
  Future<void> savePlayerId(String driverId, String token) async {}

  // Handle notification clicks
  void handleNotificationClick(OSNotificationClickEvent event) {}
}
