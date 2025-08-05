import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'floating_text_field_widget.dart';

class LocationHistoryPage extends StatefulWidget {
  @override
  _LocationHistoryPageState createState() => _LocationHistoryPageState();
}

class _LocationHistoryPageState extends State<LocationHistoryPage> {
  List<String> _locationHistory = [];
  List<String> _filteredHistory = [];
  DateTime? _startDateTime;
  DateTime? _endDateTime;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationHistory = prefs.getStringList('location_history') ?? [];
      _filteredHistory = _locationHistory;
    });
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
    if (_startDateTime == null || _endDateTime == null) {
      setState(() {
        _filteredHistory = _locationHistory;
      });
      return;
    }
    setState(() {
      _filteredHistory = _locationHistory.where((entry) {
        RegExp regex = RegExp(r'Timestamp: (\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})');
        Match? match = regex.firstMatch(entry);
        if (match != null) {
          DateTime entryDateTime = DateTime.parse(match.group(1)!);
          return entryDateTime.isAfter(_startDateTime!) && entryDateTime.isBefore(_endDateTime!);
        }
        return false;
      }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Location History'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter History',
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
              String location = entry.split(', Timestamp:')[0];
              return ListTile(
                title: Text(location),
                subtitle: Text('Entry ${index + 1} • $timestamp'),
              );
            },
          ),
          FloatingTextFieldWidget(),
        ],
      ),
    );
  }
}