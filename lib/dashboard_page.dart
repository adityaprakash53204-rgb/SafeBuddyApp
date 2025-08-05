import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'map_page.dart';
import 'battery_page.dart';
import 'ring_device_page.dart';
import 'sms_reader.dart';
import 'floating_text_field_widget.dart';

class DashboardPage extends StatelessWidget {
  final SmsReader smsReader = SmsReader();

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
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapPage(smsMessage: smsReader.getLatestMessage()),
                      ),
                    );
                  },
                  child: Text('Get Location'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BatteryPage(smsMessage: smsReader.getLatestMessage()),
                      ),
                    );
                  },
                  child: Text('Get Battery'),
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RingDevicePage(smsMessage: smsReader.getLatestMessage()),
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