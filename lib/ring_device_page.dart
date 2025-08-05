import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'sms_reader.dart';
import 'floating_text_field_widget.dart';

class RingDevicePage extends StatefulWidget {
  final String smsMessage;

  RingDevicePage({required this.smsMessage});

  @override
  _RingDevicePageState createState() => _RingDevicePageState();
}

class _RingDevicePageState extends State<RingDevicePage> {
  String _displayMessage = 'Waiting for message...';
  final SmsReader _smsReader = SmsReader();
  bool _isValidMessage = false;

  @override
  void initState() {
    super.initState();
    _smsReader.addListener(_processMessage);
    _processMessage();
  }

  @override
  void dispose() {
    _smsReader.removeListener(_processMessage);
    super.dispose();
  }

  void _processMessage() {
    String message = _smsReader.getLatestMessage();
    RegExp regex = RegExp(r'Ring: on');
    if (regex.hasMatch(message)) {
      setState(() {
        _displayMessage = 'Ringing device...';
        _isValidMessage = true;
      });
    } else {
      _isValidMessage = false;
      _startRetryCycle();
    }
  }

  void _startRetryCycle() async {
    while (mounted && !_isValidMessage) {
      setState(() {
        _displayMessage = 'Waiting for message...';
      });
      await Future.delayed(Duration(seconds: 10));
      if (mounted && !_isValidMessage) {
        setState(() {
          _displayMessage = 'Ring command not received, sending request again';
        });
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ring Device'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => DashboardPage()),
            );
          },
        ),
      ),
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: double.infinity,
              height: 300,
              color: Colors.grey[200],
              child: Center(
                child: Text(
                  _displayMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          FloatingTextFieldWidget(),
        ],
      ),
    );
  }
}