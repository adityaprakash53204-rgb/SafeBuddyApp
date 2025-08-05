import 'package:flutter/material.dart';

class SmsReader extends ChangeNotifier {
  static final SmsReader _instance = SmsReader._internal();
  String _latestMessage = '';
  final TextEditingController _controller = TextEditingController();

  factory SmsReader() {
    return _instance;
  }

  SmsReader._internal();

  void updateMessage(String message) {
    _latestMessage = message;
    _controller.text = message;
    notifyListeners();
  }

  String getLatestMessage() {
    return _latestMessage;
  }

  TextEditingController getController() {
    return _controller;
  }
}