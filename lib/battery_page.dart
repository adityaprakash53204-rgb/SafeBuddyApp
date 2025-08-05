import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'sms_reader.dart';
import 'floating_text_field_widget.dart';

class BatteryPage extends StatefulWidget {
  final String smsMessage;

  BatteryPage({required this.smsMessage});

  @override
  _BatteryPageState createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  String _displayMessage = 'Waiting for message...';
  int? _batteryPercentage;
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

  void _processMessage() {
    String message = _smsReader.getLatestMessage();
    RegExp regex = RegExp(r'Battery: (\d{1,3})');
    Match? match = regex.firstMatch(message);
    if (match != null) {
      int? percentage = int.tryParse(match.group(1)!);
      if (percentage != null && percentage >= 0 && percentage <= 100) {
        setState(() {
          _batteryPercentage = percentage;
          _displayMessage = 'Battery: $_batteryPercentage%';
          _isValidMessage = true;
        });
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
        _batteryPercentage = null;
      });
      await Future.delayed(Duration(seconds: 10));
      if (mounted && !_isValidMessage) {
        setState(() {
          _displayMessage = 'Battery not received, sending request again';
        });
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Battery Status'),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  child: CustomPaint(
                    painter: BatteryPainter(percentage: _batteryPercentage),
                    child: Center(
                      child: Text(
                        _displayMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
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

class BatteryPainter extends CustomPainter {
  final int? percentage;

  BatteryPainter({this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = Colors.grey;

    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 5, paint);

    if (percentage != null) {
      paint.color = percentage! > 50 ? Colors.green : percentage! > 20 ? Colors.orange : Colors.red;
      double sweepAngle = (percentage! / 100) * 2 * 3.14159;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2 - 5),
        -3.14159 / 2,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}