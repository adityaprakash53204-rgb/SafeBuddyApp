// lib/services/sms_service.dart

import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_advanced/sms_advanced.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SmsService {
  final SmsReceiver _receiver = SmsReceiver();
  StreamSubscription<SmsMessage>? _sub;

  // Request runtime SMS permission
  Future<bool> requestPermissions() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;

    final result = await Permission.sms.request();

    if (result.isGranted) return true;
    if (result.isPermanentlyDenied) {
      // caller can show dialog guiding user to settings
      return false;
    }
    return false;
  }

  // Start listening for incoming SMS
  // onLocation and onBattery are optional callbacks
  void startListening({Function(String lat, String lon)? onLocation,
                       Function(String battery)? onBattery}) {
    // ensure only one subscription
    _sub?.cancel();
    _sub = _receiver.onSmsReceived.listen((SmsMessage msg) async {
      final body = msg.body ?? "";

      if (!body.startsWith("SafeBuddy")) return;

      // Example location: "SafeBuddy: Location - LAT: 12.9716, LON: 77.5946"
      if (body.contains("Location")) {
        final regex = RegExp(r"LAT:\s*([0-9.+-]+),\s*LON:\s*([0-9.+-]+)");
        final match = regex.firstMatch(body);
        if (match != null) {
          final lat = match.group(1) ?? "";
          final lon = match.group(2) ?? "";
          await _saveLocation(lat, lon);
          onLocation?.call(lat, lon);
        }
      }

      // Example battery: "SafeBuddy: Battery - 78%"
      if (body.contains("Battery")) {
        final regex = RegExp(r"Battery\s*-\s*(\d+)%");
        final match = regex.firstMatch(body);
        if (match != null) {
          final battery = match.group(1) ?? "";
          await _saveBattery(battery);
          onBattery?.call(battery);
        }
      }
    });
  }

  // Stop listening (call from dispose)
  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  // Send SMS command to device
  void sendCommand(String phoneNumber, String command) {
    final sender = SmsSender();
    final message = SmsMessage(phoneNumber, command);
    sender.sendSms(message);
  }

  // SharedPreferences helpers
  Future<void> _saveLocation(String lat, String lon) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_lat', lat);
    await prefs.setString('child_lon', lon);
    await prefs.setString('child_loc_ts', DateTime.now().toIso8601String());
  }

  Future<void> _saveBattery(String battery) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_battery', battery);
    await prefs.setString('child_batt_ts', DateTime.now().toIso8601String());
  }

  Future<Map<String, String?>> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'lat': prefs.getString('child_lat'),
      'lon': prefs.getString('child_lon'),
      'loc_ts': prefs.getString('child_loc_ts'),
      'battery': prefs.getString('child_battery'),
      'batt_ts': prefs.getString('child_batt_ts'),
    };
  }
}
