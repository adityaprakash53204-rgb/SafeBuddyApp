import 'package:flutter/material.dart';
import 'sms_reader.dart';

class FloatingTextFieldWidget extends StatelessWidget {
  final SmsReader _smsReader = SmsReader();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 80.0, // Above other FABs
      right: 16.0,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _smsReader.getController(),
                decoration: InputDecoration(
                  labelText: 'Enter SMS (e.g., Location: 37.7749,-122.4194 or Battery: 75 or Ring: on)',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  _smsReader.updateMessage(value);
                },
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                _smsReader.updateMessage(_smsReader.getController().text);
              },
            ),
          ],
        ),
      ),
    );
  }
}