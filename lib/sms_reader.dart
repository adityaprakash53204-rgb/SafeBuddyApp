import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'manage_devices_page.dart';

class SmsReader {
  static final SmsReader _instance = SmsReader._internal();
  String _latestMessage = '';
  final TextEditingController _controller = TextEditingController();

  factory SmsReader() {
    return _instance;
  }

  SmsReader._internal();

  String getLatestMessage() => _latestMessage;

  TextEditingController getController() => _controller;

  Future<Map<String, dynamic>?> parseMessage(String message) async {
    final parts = message.split('|');
    if (parts.length < 3) return null;

    final verificationKey = parts[0];
    final command = parts[1];
    final values = parts.sublist(2).join('|');

    // Validate verification key against stored devices
    final prefs = await SharedPreferences.getInstance();
    final String? devicesJson = prefs.getString('devices');
    if (devicesJson == null) return null;

    final List<dynamic> devicesList = jsonDecode(devicesJson);
    final devices = devicesList.map((json) => Device.fromJson(json)).toList();
    final device = devices.firstWhere(
          (d) => d.verificationKey == verificationKey,
      orElse: () => Device(name: '', simNumber: '', verificationKey: ''),
    );

    if (device.verificationKey.isEmpty) return null; // Invalid key

    return {
      'deviceName': device.name,
      'command': command,
      'values': values,
    };
  }

  bool isValidMessage(String message) {
    final parts = message.split('|');
    if (parts.length < 3) return false;

    final command = parts[1];
    final values = parts.sublist(2).join('|');

    if (command == 'Location') {
      final coords = values.split(',');
      if (coords.length != 2) return false;
      try {
        double.parse(coords[0]);
        double.parse(coords[1]);
        return true;
      } catch (e) {
        return false;
      }
    } else if (command == 'Battery') {
      try {
        int.parse(values);
        return true;
      } catch (e) {
        return false;
      }
    } else if (command == 'Ring') {
      return values == 'on';
    }
    return false;
  }

  void updateMessage(String message) async {
    _latestMessage = message;
    _controller.text = message;

    final parsed = await parseMessage(message);
    if (parsed != null && isValidMessage(message)) {
      if (parsed['command'] == 'Location') {
        final prefs = await SharedPreferences.getInstance();
        final List<String> history = prefs.getStringList('location_history') ?? [];
        final coords = parsed['values'].split(',');
        history.add(
          '${parsed['deviceName']}, Latitude: ${coords[0]}, Longitude: ${coords[1]}, Timestamp: ${DateTime.now().toIso8601String()}',
        );
        await prefs.setStringList('location_history', history);
      }
    }
  }
}