import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'sms_reader.dart';
import 'floating_text_field_widget.dart';

class MapPage extends StatefulWidget {
  final String smsMessage;

  MapPage({required this.smsMessage});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final SmsReader _smsReader = SmsReader();
  bool _isValid = false;
  String _deviceName = '';
  double _latitude = 0.0;
  double _longitude = 0.0;

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
      if (parts[1] == 'Location') {
        final coords = parts[2].split(',');
        setState(() {
          _isValid = true;
          _deviceName = parsed['deviceName'];
          _latitude = double.parse(coords[0]);
          _longitude = double.parse(coords[1]);
        });
      } else {
        setState(() {
          _isValid = false;
          _deviceName = '';
          _latitude = 0.0;
          _longitude = 0.0;
        });
      }
    } else {
      setState(() {
        _isValid = false;
        _deviceName = '';
        _latitude = 0.0;
        _longitude = 0.0;
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
        title: Text('Location Map'),
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
                ? Text(
              'Map Placeholder\nDevice: $_deviceName\nLatitude: $_latitude\nLongitude: $_longitude',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20),
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