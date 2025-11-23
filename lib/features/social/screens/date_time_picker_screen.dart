import 'package:flutter/material.dart';

class DateTimePickerScreen extends StatefulWidget {
  const DateTimePickerScreen({super.key});

  @override
  DateTimePickerScreenState createState() => DateTimePickerScreenState();
}

class DateTimePickerScreenState extends State<DateTimePickerScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  Future<void> _pickDate() async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    ) ?? DateTime.now();
    setState(() {
      _selectedDate = picked;
    });
  }

  Future<void> _pickStartTime() async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ) ?? TimeOfDay.now();
    setState(() {
      _selectedStartTime = picked;
    });
  }

  Future<void> _pickEndTime() async {
    final TimeOfDay picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ) ?? TimeOfDay.now();
    setState(() {
      _selectedEndTime = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn thời gian sự kiện'),
      ),
      body: Column(
        children: [
          ListTile(
            title: Text('Ngày bắt đầu'),
            subtitle: Text(_selectedDate != null ? _selectedDate!.toString() : 'Chưa chọn'),
            onTap: _pickDate,
          ),
          ListTile(
            title: Text('Giờ bắt đầu'),
            subtitle: Text(_selectedStartTime != null ? _selectedStartTime!.format(context) : 'Chưa chọn'),
            onTap: _pickStartTime,
          ),
          ListTile(
            title: Text('Giờ kết thúc'),
            subtitle: Text(_selectedEndTime != null ? _selectedEndTime!.format(context) : 'Chưa chọn'),
            onTap: _pickEndTime,
          ),
        ],
      ),
    );
  }
}

