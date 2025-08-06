import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'floating_text_field_widget.dart';
import 'manage_devices_page.dart';
import 'dart:convert';

class LocationHistoryPage extends StatefulWidget {
  @override
  _LocationHistoryPageState createState() => _LocationHistoryPageState();
}

class _LocationHistoryPageState extends State<LocationHistoryPage> {
  List<String> _locationHistory = [];
  List<String> _filteredHistory = [];
  List<Device> _devices = [];
  String? _selectedDevice;
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadDevices();
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationHistory = prefs.getStringList('location_history') ?? [];
      _filterHistory();
    });
  }

  void _loadDevices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? devicesJson = prefs.getString('devices');
    if (devicesJson != null) {
      final List<dynamic> devicesList = jsonDecode(devicesJson);
      setState(() {
        _devices = devicesList.map((json) => Device.fromJson(json)).toList();
        if (_devices.isNotEmpty && _selectedDevice == null) {
          _selectedDevice = _devices[0].name;
        }
        _filterHistory();
      });
    }
  }

  void _clearHistory() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear Location History'),
        content: Text('Are you sure you want to clear all location history? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('location_history');
      setState(() {
        _locationHistory = [];
        _filteredHistory = [];
        _startDateTime = null;
        _endDateTime = null;
      });
    }
  }

  void _filterHistory() {
    List<String> tempHistory = _locationHistory;
    if (_selectedDevice != null) {
      tempHistory = tempHistory.where((entry) => entry.startsWith('$_selectedDevice,')).toList();
    }
    if (_startDateTime != null && _endDateTime != null) {
      tempHistory = tempHistory.where((entry) {
        RegExp regex = RegExp(r'Timestamp: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})');
        Match? match = regex.firstMatch(entry);
        if (match != null) {
          DateTime entryDateTime = DateTime.parse(match.group(1)!);
          return entryDateTime.isAfter(_startDateTime!) && entryDateTime.isBefore(_endDateTime!);
        }
        return false;
      }).toList();
    }
    setState(() {
      _filteredHistory = tempHistory;
    });
  }

  String _formatTimestamp(String entry) {
    RegExp regex = RegExp(r'Timestamp: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})');
    Match? match = regex.firstMatch(entry);
    if (match != null) {
      DateTime dateTime = DateTime.parse(match.group(1)!);
      return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
    }
    return 'Unknown';
  }

  Future<void> _showFilterDialog(BuildContext context) async {
    DateTime tempStartDateTime = _startDateTime ?? DateTime.now();
    DateTime tempEndDateTime = _endDateTime ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter by Date & Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: tempStartDateTime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(tempStartDateTime),
                  );
                  if (pickedTime != null) {
                    tempStartDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  }
                }
              },
              child: Text(
                'Start: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(tempStartDateTime)}',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 16),
            GestureDetector(
              onTap: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: tempEndDateTime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(tempEndDateTime),
                  );
                  if (pickedTime != null) {
                    tempEndDateTime = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                    );
                  }
                }
              },
              child: Text(
                'End: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(tempEndDateTime)}',
                style: TextStyle(
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                  color: Colors.blue,
                ),
              ),
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
              setState(() {
                _startDateTime = tempStartDateTime;
                _endDateTime = tempEndDateTime;
                _filterHistory();
              });
              Navigator.pop(context);
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeviceSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Device'),
        content: Container(
          width: double.maxFinite,
          child: _devices.isEmpty
              ? Text('No devices available')
              : ListView.builder(
            shrinkWrap: true,
            itemCount: _devices.length,
            itemBuilder: (context, index) {
              final device = _devices[index];
              return ListTile(
                title: Text(device.name),
                onTap: () {
                  setState(() {
                    _selectedDevice = device.name;
                    _filterHistory();
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedDevice = null;
                _filterHistory();
              });
              Navigator.pop(context);
            },
            child: Text('Show All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location History'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: _showDeviceSelectionDialog,
            tooltip: 'Select Device',
          ),
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter by Date & Time',
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _clearHistory,
            tooltip: 'Clear History',
          ),
        ],
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
          _filteredHistory.isEmpty
              ? Center(
            child: Text(
              'No location history available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          )
              : ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: _filteredHistory.length,
            itemBuilder: (context, index) {
              String entry = _filteredHistory[index];
              String timestamp = _formatTimestamp(entry);
              RegExp regex = RegExp(r'^(.*?),\s*Latitude:\s*([-.\d]+),\s*Longitude:\s*([-.\d]+),');
              Match? match = regex.firstMatch(entry);
              String deviceName = match?.group(1) ?? 'Unknown';
              String latitude = match?.group(2) ?? 'Unknown';
              String longitude = match?.group(3) ?? 'Unknown';
              return ListTile(
                title: Text('Device: $deviceName'),
                subtitle: Text('Latitude: $latitude, Longitude: $longitude\nEntry ${index + 1} • $timestamp'),
              );
            },
          ),
          FloatingTextFieldWidget(),
        ],
      ),
    );
  }
}