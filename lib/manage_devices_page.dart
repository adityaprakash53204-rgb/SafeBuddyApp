import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'floating_text_field_widget.dart';
import 'dart:convert';
import 'dart:math';

class Device {
  final String name;
  final String simNumber;
  final String verificationKey;

  Device({required this.name, required this.simNumber, required this.verificationKey});

  Map<String, dynamic> toJson() => {
    'name': name,
    'simNumber': simNumber,
    'verificationKey': verificationKey,
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    name: json['name'],
    simNumber: json['simNumber'],
    verificationKey: json['verificationKey'],
  );
}

class ManageDevicesPage extends StatefulWidget {
  @override
  _ManageDevicesPageState createState() => _ManageDevicesPageState();
}

class _ManageDevicesPageState extends State<ManageDevicesPage> {
  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  void _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? devicesJson = prefs.getString('devices');
    if (devicesJson != null) {
      final List<dynamic> devicesList = jsonDecode(devicesJson);
      setState(() {
        _devices = devicesList.map((json) => Device.fromJson(json)).toList();
      });
    }
  }

  void _addDevice(Device device) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _devices.add(device);
    });
    await prefs.setString('devices', jsonEncode(_devices.map((d) => d.toJson()).toList()));
  }

  void _deleteDevice(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _devices.removeAt(index);
    });
    await prefs.setString('devices', jsonEncode(_devices.map((d) => d.toJson()).toList()));
  }

  String _generateRandomKey() {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    return String.fromCharCodes(
      Iterable.generate(8, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  Future<void> _showAddDeviceDialog() async {
    final nameController = TextEditingController();
    final simController = TextEditingController();
    final keyController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Device'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Device Name'),
            ),
            TextField(
              controller: simController,
              decoration: InputDecoration(labelText: 'SIM Number'),
              keyboardType: TextInputType.phone,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: keyController,
                    decoration: InputDecoration(labelText: 'Verification Key'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () {
                    keyController.text = _generateRandomKey();
                  },
                  tooltip: 'Generate Random Key',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  simController.text.isNotEmpty &&
                  keyController.text.isNotEmpty) {
                _addDevice(Device(
                  name: nameController.text,
                  simNumber: simController.text,
                  verificationKey: keyController.text,
                ));
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please fill all fields')),
                );
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDeviceDialog() async {
    if (_devices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No devices to delete')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Device'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return ListTile(
                title: Text(device.name),
                subtitle: Text('SIM: ${device.simNumber}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Confirm Delete'),
                        content: Text('Are you sure you want to delete ${device.name}? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _deleteDevice(index);
                      Navigator.pop(context); // Close the delete device dialog
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Devices'),
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
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.add, color: Colors.blue),
                  title: Text('Add Device'),
                  onTap: _showAddDeviceDialog,
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete Device'),
                  onTap: _showDeleteDeviceDialog,
                ),
                ListTile(
                  leading: Icon(Icons.info, color: Colors.blue),
                  title: Text('Device Details'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeviceDetailsPage(devices: _devices),
                      ),
                    );
                  },
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

class DeviceDetailsPage extends StatelessWidget {
  final List<Device> devices;

  DeviceDetailsPage({required this.devices});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device Details'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          devices.isEmpty
              ? Center(
            child: Text(
              'No devices added',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return ListTile(
                title: Text(device.name),
                subtitle: Text('SIM: ${device.simNumber}\nKey: ${device.verificationKey}'),
              );
            },
          ),
          FloatingTextFieldWidget(),
        ],
      ),
    );
  }
}