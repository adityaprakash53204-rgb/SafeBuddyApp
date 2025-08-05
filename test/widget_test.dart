import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safebuddy/main.dart';
import 'package:safebuddy/dashboard_page.dart';
import 'package:safebuddy/map_page.dart';
import 'package:safebuddy/battery_page.dart';
import 'package:safebuddy/ring_device_page.dart';
import 'package:safebuddy/location_history_page.dart';
import 'package:safebuddy/manage_devices_page.dart';
import 'package:safebuddy/sms_reader.dart';
import 'package:safebuddy/floating_text_field_widget.dart';
import 'dart:convert';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Dashboard, Map, Battery, Ring Device, Location History, and Manage Devices pages display correctly with persistent data', (WidgetTester tester) async {
    final smsReader = SmsReader();

    // Test DashboardPage
    await tester.pumpWidget(MaterialApp(home: DashboardPage()));
    expect(find.text('Safe Buddy'), findsOneWidget);
    expect(find.text('Welcome to the Dashboard!'), findsOneWidget);
    expect(find.text('Get Location'), findsOneWidget);
    expect(find.text('Get Battery'), findsOneWidget);
    expect(find.text('Ring Device'), findsOneWidget);
    expect(find.text('Manage Devices'), findsNothing); // Removed from Dashboard
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);

    // Test MapPage with valid location message
    await tester.enterText(find.byType(TextField), 'Location: 37.7749,-122.4194');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(smsReader.getLatestMessage(), 'Location: 37.7749,-122.4194');
    await tester.pumpWidget(MaterialApp(home: MapPage(smsMessage: smsReader.getLatestMessage())));
    await tester.pump();
    expect(find.text('Location Map'), findsOneWidget);
    expect(find.text('Map Placeholder\nLatitude: 37.7749\nLongitude: -122.4194'), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.text('Location: 37.7749,-122.4194'), findsOneWidget);
    await tester.pump(Duration(seconds: 12));
    expect(find.text('Map Placeholder\nLatitude: 37.7749\nLongitude: -122.4194'), findsOneWidget);

    // Test MapPage with invalid message
    await tester.enterText(find.byType(TextField), 'Invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Waiting for message...'), findsOneWidget);
    await tester.pump(Duration(seconds: 10));
    expect(find.text('Location not received, sending request again'), findsOneWidget);

    // Navigate back to DashboardPage
    await tester.pumpWidget(MaterialApp(home: DashboardPage()));
    await tester.pump();
    expect(find.text('Invalid'), findsOneWidget);

    // Test BatteryPage with valid battery message
    await tester.enterText(find.byType(TextField), 'Battery: 75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: BatteryPage(smsMessage: smsReader.getLatestMessage())));
    await tester.pump();
    expect(find.text('Battery Status'), findsOneWidget);
    expect(find.text('Battery: 75%'), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.text('Battery: 75'), findsOneWidget);
    await tester.pump(Duration(seconds: 12));
    expect(find.text('Battery: 75%'), findsOneWidget);

    // Test BatteryPage with invalid message
    await tester.enterText(find.byType(TextField), 'Invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Waiting for message...'), findsOneWidget);
    await tester.pump(Duration(seconds: 10));
    expect(find.text('Battery not received, sending request again'), findsOneWidget);

    // Test RingDevicePage with valid ring message
    await tester.enterText(find.byType(TextField), 'Ring: on');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: RingDevicePage(smsMessage: smsReader.getLatestMessage())));
    await tester.pump();
    expect(find.text('Ring Device'), findsOneWidget);
    expect(find.text('Ringing device...'), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.text('Ring: on'), findsOneWidget);
    await tester.pump(Duration(seconds: 12));
    expect(find.text('Ringing device...'), findsOneWidget);

    // Test RingDevicePage with invalid message
    await tester.enterText(find.byType(TextField), 'Invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Waiting for message...'), findsOneWidget);
    await tester.pump(Duration(seconds: 10));
    expect(find.text('Ring command not received, sending request again'), findsOneWidget);

    // Test LocationHistoryPage with filter and clear history
    SharedPreferences.setMockInitialValues({
      'location_history': [
        'Latitude: 37.7749, Longitude: -122.4194, Timestamp: 2025-08-05T10:00:00.000',
        'Latitude: 40.7128, Longitude: -74.0060, Timestamp: 2025-08-05T12:00:00.000',
      ],
    });
    await tester.pumpWidget(MaterialApp(home: LocationHistoryPage()));
    await tester.pump();
    expect(find.text('Location History'), findsOneWidget);
    expect(find.text('Latitude: 37.7749, Longitude: -122.4194'), findsOneWidget);
    expect(find.text('Latitude: 40.7128, Longitude: -74.0060'), findsOneWidget);
    expect(find.textContaining('Entry 1 • 2025-08-05 10:00:00'), findsOneWidget);
    expect(find.textContaining('Entry 2 • 2025-08-05 12:00:00'), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    // Test filter dialog
    await tester.tap(find.byIcon(Icons.filter_alt));
    await tester.pumpAndSettle();
    expect(find.text('Filter by Date & Time'), findsOneWidget);
    await tester.tap(find.textContaining('Start:'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // Select default date
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // Select default time
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('End:'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // Select default date
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK')); // Select default time
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Latitude: 37.7749, Longitude: -122.4194'), findsOneWidget);
    expect(find.text('Latitude: 40.7128, Longitude: -74.0060'), findsOneWidget);

    // Test clear history with warning dialog
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    expect(find.text('Clear Location History'), findsOneWidget);
    expect(find.text('Are you sure you want to clear all location history? This action cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Latitude: 37.7749, Longitude: -122.4194'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();
    expect(find.text('No location history available'), findsOneWidget);

    // Test ManageDevicesPage via hamburger menu
    await tester.pumpWidget(MaterialApp(home: DashboardPage()));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.menu)); // Open hamburger menu
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manage Devices'));
    await tester.pumpAndSettle();
    expect(find.text('Manage Devices'), findsOneWidget);
    expect(find.text('Add Device'), findsOneWidget);
    expect(find.text('Device Details'), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);

    // Test Add Device dialog
    SharedPreferences.setMockInitialValues({
      'devices': jsonEncode([
        {'name': 'Device 1', 'simNumber': '1234567890', 'verificationKey': 'key1'},
        {'name': 'Device 2', 'simNumber': '0987654321', 'verificationKey': 'key2'},
      ]),
    });
    await tester.pumpWidget(MaterialApp(home: ManageDevicesPage()));
    await tester.pump();
    await tester.tap(find.text('Add Device'));
    await tester.pumpAndSettle();
    expect(find.text('Add Device'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Device 3');
    await tester.enterText(find.byType(TextField).at(1), '1112223333');
    await tester.enterText(find.byType(TextField).at(2), 'key3');
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device Details'));
    await tester.pumpAndSettle();
    expect(find.text('Device Details'), findsOneWidget);
    expect(find.text('Device 1'), findsOneWidget);
    expect(find.text('Device 2'), findsOneWidget);
    expect(find.text('Device 3'), findsOneWidget);
    expect(find.text('SIM: 1234567890\nKey: key1'), findsOneWidget);
    expect(find.text('SIM: 0987654321\nKey: key2'), findsOneWidget);
    expect(find.text('SIM: 1112223333\nKey: key3'), findsOneWidget);

    // Test Add Device with empty fields
    await tester.pumpWidget(MaterialApp(home: ManageDevicesPage()));
    await tester.pump();
    await tester.tap(find.text('Add Device'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    expect(find.text('Please fill all fields'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Test DeviceDetailsPage with no devices
    SharedPreferences.setMockInitialValues({'devices': jsonEncode([])});
    await tester.pumpWidget(MaterialApp(home: ManageDevicesPage()));
    await tester.pump();
    await tester.tap(find.text('Device Details'));
    await tester.pumpAndSettle();
    expect(find.text('No devices added'), findsOneWidget);
  });
}