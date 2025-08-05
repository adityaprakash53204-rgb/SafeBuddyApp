import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
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
  String _displayMessage = 'Waiting for message...';
  double? _latitude;
  double? _longitude;
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

  void _processMessage() async {
    String message = _smsReader.getLatestMessage();
    RegExp regex = RegExp(r'Location: (\d+\.\d+),([-]?\d+\.\d+)');
    Match? match = regex.firstMatch(message);
    if (match != null) {
      _latitude = double.tryParse(match.group(1)!);
      _longitude = double.tryParse(match.group(2)!);
      if (_latitude != null && _longitude != null) {
        setState(() {
          _displayMessage = 'Map Placeholder\nLatitude: $_latitude\nLongitude: $_longitude';
          _isValidMessage = true;
        });
        // Save to SharedPreferences with timestamp
        final prefs = await SharedPreferences.getInstance();
        List<String> history = prefs.getStringList('location_history') ?? [];
        String timestamp = DateTime.now().toIso8601String();
        String locationEntry = 'Latitude: $_latitude, Longitude: $_longitude, Timestamp: $timestamp';
        if (!history.contains(locationEntry)) {
          history.add(locationEntry);
          await prefs.setStringList('location_history', history);
        }
      } else {
        _isValidMessage = false;
        _startRetryCycle();
      }
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
          _displayMessage = 'Location not received, sending request again';
        });
        await Future.delayed(Duration(seconds: 2));
      }
    }
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