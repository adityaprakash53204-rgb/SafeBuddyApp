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

  testWidgets('Dashboard, Map, Battery, Ring Device, Location History, and Manage Devices pages display correctly with dynamic message updates and widgets', (WidgetTester tester) async {
    final smsReader = SmsReader();

    // Set up devices and history for testing
    SharedPreferences.setMockInitialValues({
      'devices': jsonEncode([
        {'name': 'Wristband 1', 'simNumber': '1234567890', 'verificationKey': 'key123'},
        {'name': 'Wristband 2', 'simNumber': '0987654321', 'verificationKey': 'key456'},
      ]),
      'location_history': [
        'Wristband 1, Latitude: 37.7749, Longitude: -122.4194, Timestamp: 2025-08-05T10:00:00.000',
        'Wristband 2, Latitude: 40.7128, Longitude: -74.0060, Timestamp: 2025-08-05T12:00:00.000',
        'Wristband 1, Latitude: 34.0522, Longitude: -118.2437, Timestamp: 2025-08-05T14:00:00.000',
      ],
    });

    // Test DashboardPage
    await tester.pumpWidget(MaterialApp(home: DashboardPage()));
    await tester.pump();
    expect(find.text('Safe Buddy'), findsOneWidget);
    expect(find.text('Welcome to the Dashboard!'), findsOneWidget);
    expect(find.text('Get Location'), findsOneWidget);
    expect(find.text('Get Battery'), findsOneWidget);
    expect(find.text('Ring Device'), findsOneWidget);
    expect(find.text('Manage Devices'), findsNothing);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);

    // Test MapPage with valid location message and dynamic update
    await tester.enterText(find.byType(TextField), 'key123|Location|37.7749,-122.4194');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(smsReader.getLatestMessage(), 'key123|Location|37.7749,-122.4194');
    await tester.pumpWidget(MaterialApp(home: MapPage(smsMessage: smsReader.getLatestMessage())));
    await tester.pump();
    expect(find.text('Location Map'), findsOneWidget);
    expect(find.text('Map Placeholder\nDevice: Wristband 1\nLatitude: 37.7749\nLongitude: -122.4194'), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.text('key123|Location|37.7749,-122.4194'), findsOneWidget);
    await tester.pump(Duration(seconds: 12));
    expect(find.text('Map Placeholder\nDevice: Wristband 1\nLatitude: 37.7749\nLongitude: -122.4194'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'key456|Location|40.7128,-74.0060');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(smsReader.getLatestMessage(), 'key456|Location|40.7128,-74.0060');
    expect(find.text('Map Placeholder\nDevice: Wristband 2\nLatitude: 40.7128\nLongitude: -74.0060'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'invalidKey|Location|37.7749,-122.4194');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Invalid message or device not recognized'), findsOneWidget);
    await tester.pump(Duration(seconds: 10));
    expect(find.text('Invalid message or device not recognized'), findsOneWidget);

    // Navigate back to DashboardPage
    await tester.pumpWidget(MaterialApp(home: DashboardPage()));
    await tester.pump();
    expect(find.text('invalidKey|Location|37.7749,-122.4194'), findsOneWidget);

    // Test BatteryPage with valid battery message and dynamic update
    await tester.enterText(find.byType(TextField), 'key123|Battery|75');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: BatteryPage(smsMessage: smsReader.getLatestMessage())));
    await tester.pump();
    expect(find.text('Battery Status'), findsOneWidget);
    expect(find.text('Battery: 75%\nDevice: Wristband 1'), findsNothing); // Replaced by widget
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Device: Wristband 1'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.text('key123|Battery|75'), findsOneWidget);
    await tester.pump(Duration(seconds: 12));
    expect(find.text('75%'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'key456|Battery|90');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(smsReader.getLatestMessage(), 'key456|Battery|90');
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('Device: Wristband 2'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'key123|Battery|invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Invalid message or device not recognized'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pump(Duration(seconds: 10));
    expect(find.text('Invalid message or device not recognized'), findsOneWidget);

    // Test RingDevicePage with valid ring message and dynamic update
    await tester.enterText(find.byType(TextField), 'key123|Ring|on');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pumpWidget(MaterialApp(home: RingDevicePage(smsMessage: smsReader.getLatestMessage())));
    await tester.pump();
    expect(find.text('Ring Device'), findsOneWidget);
    expect(find.text('Ringing device...\nDevice: Wristband 1'), findsOneWidget);
    expect(find.byType(ScaleTransition), findsOneWidget);
    expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.text('key123|Ring|on'), findsOneWidget);
    await tester.pump(Duration(seconds: 12));
    expect(find.text('Ringing device...\nDevice: Wristband 1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'key456|Ring|on');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(smsReader.getLatestMessage(), 'key456|Ring|on');
    expect(find.text('Ringing device...\nDevice: Wristband 2'), findsOneWidget);
    expect(find.byType(ScaleTransition), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'invalidKey|Ring|on');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Invalid message or device not recognized'), findsOneWidget);
    expect(find.byType(ScaleTransition), findsNothing);
    await tester.pump(Duration(seconds: 10));
    expect(find.text('Invalid message or device not recognized'), findsOneWidget);

    // Test LocationHistoryPage with device selection, filter, and clear history
    await tester.pumpWidget(MaterialApp(home: LocationHistoryPage()));
    await tester.pump();
    expect(find.text('Location History'), findsOneWidget);
    expect(find.text('Device: Wristband 1'), findsNWidgets(2));
    expect(find.text('Device: Wristband 2'), findsOneWidget);
    expect(find.text('Latitude: 37.7749, Longitude: -122.4194'), findsOneWidget);
    expect(find.text('Latitude: 40.7128, Longitude: -74.0060'), findsOneWidget);
    expect(find.text('Latitude: 34.0522, Longitude: -118.2437'), findsOneWidget);
    expect(find.textContaining('Entry 1 • 2025-08-05 10:00:00'), findsOneWidget);
    expect(find.textContaining('Entry 2 • 2025-08-05 12:00:00'), findsOneWidget);
    expect(find.textContaining('Entry 3 • 2025-08-05 14:00:00'), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
    expect(find.byIcon(Icons.filter_alt), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);

    // Test device selection
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('Select Device'), findsOneWidget);
    expect(find.text('Wristband 1'), findsOneWidget);
    expect(find.text('Wristband 2'), findsOneWidget);
    await tester.tap(find.text('Wristband 1'));
    await tester.pumpAndSettle();
    expect(find.text('Device: Wristband 1'), findsNWidgets(2));
    expect(find.text('Device: Wristband 2'), findsNothing);
    expect(find.text('Latitude: 37.7749, Longitude: -122.4194'), findsOneWidget);
    expect(find.text('Latitude: 34.0522, Longitude: -118.2437'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show All'));
    await tester.pumpAndSettle();
    expect(find.text('Device: Wristband 1'), findsNWidgets(2));
    expect(find.text('Device: Wristband 2'), findsOneWidget);

    // Test filter dialog with device selection
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wristband 1'));
    await tester.pumpAndSettle();
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
    expect(find.text('Device: Wristband 1'), findsNWidgets(2));
    expect(find.text('Device: Wristband 2'), findsNothing);

    // Test clear history with warning dialog
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();
    expect(find.text('Clear Location History'), findsOneWidget);
    expect(find.text('Are you sure you want to clear all location history? This action cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Device: Wristband 1'), findsNWidgets(2));
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
    expect(find.text('Delete Device'), findsOneWidget);
    expect(find.text('Device Details'), findsOneWidget);
    expect(find.byType(FloatingTextFieldWidget), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.delete), findsOneWidget);
    expect(find.byIcon(Icons.info), findsOneWidget);

    // Test Add Device dialog with Generate Random Key
    await tester.pumpWidget(MaterialApp(home: ManageDevicesPage()));
    await tester.pump();
    await tester.tap(find.text('Add Device'));
    await tester.pumpAndSettle();
    expect(find.text('Add Device'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Wristband 3');
    await tester.enterText(find.byType(TextField).at(1), '1112223333');
    await tester.tap(find.byIcon(Icons.refresh)); // Generate random key
    await tester.pumpAndSettle();
    expect((find.byType(TextField).at(2).evaluate().single.widget as TextField).controller!.text, isNotEmpty);
    await tester.enterText(find.byType(TextField).at(2), 'key789'); // Overwrite for consistency
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device Details'));
    await tester.pumpAndSettle();
    expect(find.text('Device Details'), findsOneWidget);
    expect(find.text('Wristband 1'), findsOneWidget);
    expect(find.text('Wristband 2'), findsOneWidget);
    expect(find.text('Wristband 3'), findsOneWidget);
    expect(find.text('SIM: 1234567890\nKey: key123'), findsOneWidget);
    expect(find.text('SIM: 0987654321\nKey: key456'), findsOneWidget);
    expect(find.text('SIM: 1112223333\nKey: key789'), findsOneWidget);

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

    // Test Delete Device
    await tester.pumpWidget(MaterialApp(home: ManageDevicesPage()));
    await tester.pump();
    await tester.tap(find.text('Delete Device'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Device'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.delete).at(0)); // Delete Wristband 1
    await tester.pumpAndSettle();
    expect(find.text('Confirm Delete'), findsOneWidget);
    expect(find.text('Are you sure you want to delete Wristband 1? This action cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete).at(0)); // Delete Wristband 1 again
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device Details'));
    await tester.pumpAndSettle();
    expect(find.text('Wristband 1'), findsNothing);
    expect(find.text('Wristband 2'), findsOneWidget);
    expect(find.text('Wristband 3'), findsOneWidget);

    // Test Delete Device with no devices
    SharedPreferences.setMockInitialValues({'devices': jsonEncode([])});
    await tester.pumpWidget(MaterialApp(home: ManageDevicesPage()));
    await tester.pump();
    await tester.tap(find.text('Delete Device'));
    await tester.pumpAndSettle();
    expect(find.text('No devices to delete'), findsOneWidget);
    await tester.tap(find.text('Device Details'));
    await tester.pumpAndSettle();
    expect(find.text('No devices added'), findsOneWidget);

    // Test LocationHistoryPage with no devices
    SharedPreferences.setMockInitialValues({'devices': jsonEncode([]), 'location_history': []});
    await tester.pumpWidget(MaterialApp(home: LocationHistoryPage()));
    await tester.pump();
    expect(find.text('No location history available'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    expect(find.text('No devices available'), findsOneWidget);
  });
}