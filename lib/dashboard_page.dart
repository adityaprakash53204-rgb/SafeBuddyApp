import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'map_page.dart';
import 'battery_page.dart';
import 'ring_device_page.dart';
import 'sms_reader.dart';
import 'floating_text_field_widget.dart';
import 'sms_service.dart'; // 👈 Add this

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SmsReader smsReader = SmsReader();
  final SmsService _smsService = SmsService();

  String? _location;
  String? _battery;

  @override
  void initState() {
    super.initState();
    _setupSms();
  }

  Future<void> _setupSms() async {
    final granted = await _smsService.requestPermissions();
    if (!granted) return;

    _smsService.startListening(
      onLocation: (lat, lon) {
        setState(() => _location = "Lat: $lat, Lon: $lon");
      },
      onBattery: (batt) {
        setState(() => _battery = "$batt%");
      },
    );
  }

  void _sendLoc() => _smsService.sendCommand("+919876543210", "LOC");
  void _sendBat() => _smsService.sendCommand("+919876543210", "BAT");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Safe Buddy'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to the Dashboard!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Text(_location ?? "No location yet"),
                Text(_battery ?? "No battery info"),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _sendLoc,
                  child: Text("Request Location"),
                ),
                ElevatedButton(
                  onPressed: _sendBat,
                  child: Text("Request Battery"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapPage(
                          smsMessage: smsReader.getLatestMessage(),
                        ),
                      ),
                    );
                  },
                  child: Text('Open Map Page'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BatteryPage(
                          smsMessage: smsReader.getLatestMessage(),
                        ),
                      ),
                    );
                  },
                  child: Text('Open Battery Page'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RingDevicePage(
                          smsMessage: smsReader.getLatestMessage(),
                        ),
                      ),
                    );
                  },
                  child: Text('Ring Device'),
                ),
              ],
            ),
          ),
          FloatingTextFieldWidget(),
        ],
      ),
    );
  }
}
