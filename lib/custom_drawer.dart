import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'map_page.dart';
import 'battery_page.dart';
import 'ring_device_page.dart';
import 'location_history_page.dart';
import 'manage_devices_page.dart';
import 'sms_reader.dart';

class CustomDrawer extends StatelessWidget {
  final SmsReader smsReader = SmsReader();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Safe Buddy Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.dashboard),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => DashboardPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Location History'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LocationHistoryPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.devices),
            title: Text('Manage Devices'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ManageDevicesPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }
}