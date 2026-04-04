import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';

class StudyAlertService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> init() async {
    // Initialize Notifications
    const initializationSettings = InitializationSettings(
      // Linux requires a default action name
      linux: LinuxInitializationSettings(
        defaultActionName: 'Open',
      ),
      // Windows requires these specific identifiers in newer versions
      windows: WindowsInitializationSettings(
        appName: 'StudyAssistant',
        appUserModelId: 'com.example.study_assistant',
        guid: 'your-unique-guid-here-12345', 
      ),
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<void> showAlert() async {
    // 1. Play Sound
    try {
      await _audioPlayer.play(AssetSource('audio/ding.wav'));
    } catch (e) {
      print("Error playing sound: $e");
    }

    // 2. Show System Notification
    // Note: We use named arguments here to fix the "Too many positional arguments" error
    await _notificationsPlugin.show(
      id: 0,
      title: 'Study Session Complete!',
      body: 'Great job! Time to take a break.',
      notificationDetails: const NotificationDetails(
        windows: WindowsNotificationDetails(
          subtitle: 'Break Time!',
        ),
        linux: LinuxNotificationDetails(
          actions: <LinuxNotificationAction>[
            LinuxNotificationAction(
              key: 'open',
              label: 'Open',
            ),
          ],
        ),
      ),
    );
  }
}