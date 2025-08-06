import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'sms_reader.dart';
import 'floating_text_field_widget.dart';

class BatteryPage extends StatefulWidget {
  final String smsMessage;

  BatteryPage({required this.smsMessage});

  @override
  _BatteryPageState createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  final SmsReader _smsReader = SmsReader();
  bool _isValid = false;
  String _deviceName = '';
  int _batteryLevel = 0;

  @override
  void initState() {
    super.initState();
    _parseMessage(widget.smsMessage);
    _smsReader.getController().addListener(_onMessageChanged);
    _startRetryCycle();
  }

  void _onMessageChanged() {
    if (_smsReader.getLatestMessage() != widget.smsMessage) {
      _parseMessage(_smsReader.getLatestMessage());
    }
  }

  void _parseMessage(String message) async {
    final parsed = await _smsReader.parseMessage(message);
    if (parsed != null && _smsReader.isValidMessage(message)) {
      final parts = message.split('|');
      if (parts[1] == 'Battery') {
        setState(() {
          _isValid = true;
          _deviceName = parsed['deviceName'];
          _batteryLevel = int.parse(parts[2]);
        });
      } else {
        setState(() {
          _isValid = false;
          _deviceName = '';
          _batteryLevel = 0;
        });
      }
    } else {
      setState(() {
        _isValid = false;
        _deviceName = '';
        _batteryLevel = 0;
      });
    }
  }

  void _startRetryCycle() {
    Future.delayed(Duration(seconds: 10), () {
      if (!_isValid && mounted) {
        setState(() {});
        _startRetryCycle();
      }
    });
  }

  @override
  void dispose() {
    _smsReader.getController().removeListener(_onMessageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Battery Status'),
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
            child: _isValid
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 150,
                      height: 150,
                      child: CircularProgressIndicator(
                        value: _batteryLevel / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _batteryLevel > 50
                              ? Colors.green
                              : _batteryLevel > 20
                              ? Colors.yellow
                              : Colors.red,
                        ),
                      ),
                    ),
                    Text(
                      '$_batteryLevel%',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Device: $_deviceName',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
              ],
            )
                : Text(
              _smsReader.getLatestMessage().isEmpty
                  ? 'Waiting for message...'
                  : 'Invalid message or device not recognized',
              style: TextStyle(fontSize: 20),
            ),
          ),
          FloatingTextFieldWidget(),
        ],
      ),
    );
  }
}