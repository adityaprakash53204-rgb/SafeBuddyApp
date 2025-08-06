import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'sms_reader.dart';
import 'floating_text_field_widget.dart';

class RingDevicePage extends StatefulWidget {
  final String smsMessage;

  RingDevicePage({required this.smsMessage});

  @override
  _RingDevicePageState createState() => _RingDevicePageState();
}

class _RingDevicePageState extends State<RingDevicePage> with SingleTickerProviderStateMixin {
  final SmsReader _smsReader = SmsReader();
  bool _isValid = false;
  String _deviceName = '';
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _parseMessage(widget.smsMessage);
    _smsReader.getController().addListener(_onMessageChanged);
    _startRetryCycle();
  }

  void _onMessageChanged() {
    if (_smsReader.getLatestMessage() != widget.smsMessage) {
      _parseMessage(_smsReader.getLatestMessage());
    }
  }

  void _parseMessage(String message) async {
    final parsed = await _smsReader.parseMessage(message);
    if (parsed != null && _smsReader.isValidMessage(message)) {
      final parts = message.split('|');
      if (parts[1] == 'Ring') {
        setState(() {
          _isValid = true;
          _deviceName = parsed['deviceName'];
        });
      } else {
        setState(() {
          _isValid = false;
          _deviceName = '';
        });
      }
    } else {
      setState(() {
        _isValid = false;
        _deviceName = '';
      });
    }
  }

  void _startRetryCycle() {
    Future.delayed(Duration(seconds: 10), () {
      if (!_isValid && mounted) {
        setState(() {});
        _startRetryCycle();
      }
    });
  }

  @override
  void dispose() {
    _smsReader.getController().removeListener(_onMessageChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ring Device'),
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
            child: _isValid
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Icon(
                    Icons.notifications_active,
                    size: 100,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Ringing device...\nDevice: $_deviceName',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20),
                ),
              ],
            )
                : Text(
              _smsReader.getLatestMessage().isEmpty
                  ? 'Waiting for message...'
                  : 'Invalid message or device not recognized',
              style: TextStyle(fontSize: 20),
            ),
          ),
          FloatingTextFieldWidget(),
        ],
      ),
    );
  }
}