// lib/features/social/screens/create_event_screen.dart
import 'dart:ui'; // for ImageFilter
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart'; // for image picker
import 'dart:io';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/event_controller.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _startDateCtrl = TextEditingController();
  final _endDateCtrl = TextEditingController();
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  File? _selectedImage; // for selected image

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endTimeCtrl.dispose();
    super.dispose();
  }

  // ================== IMAGE PICKER ==================

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path); // Save the picked image
      });
    }
  }

  // ================== DATE & TIME PICKER ==================

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _startDateCtrl.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final base = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? base,
      firstDate: base,
      lastDate: base.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _endDateCtrl.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickStartTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? now,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        _startTimeCtrl.text = _formatTime(picked);
      });
    }
  }

  Future<void> _pickEndTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? now,
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        _endTimeCtrl.text = _formatTime(picked);
      });
    }
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  // ================== SUBMIT ==================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final eventCtrl = context.read<EventController>();

    try {
      await eventCtrl.createEvent(
        name: _nameCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        startDate: _startDateCtrl.text.trim(),
        endDate: _endDateCtrl.text.trim(),
        startTime: _startTimeCtrl.text.trim(),
        endTime: _endTimeCtrl.text.trim(),
        coverFile: _selectedImage, // Send the selected image file
      );

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo sự kiện: $e')),
      );
    }
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final eventCtrl = context.watch<EventController>();

    final tCreateEvent =
        getTranslated('create_event', context) ?? 'Create Event';
    final tEventName =
        getTranslated('event_name', context) ?? 'Event Name';
    final tEventLocation =
        getTranslated('event_location', context) ?? 'Event Location';
    final tEventDesc =
        getTranslated('event_description', context) ?? 'Event Description';
    final tStartDate =
        getTranslated('start_date', context) ?? 'Start Date';
    final tEndDate = getTranslated('end_date', context) ?? 'End Date';
    final tStartTime =
        getTranslated('start_time', context) ?? 'Start Time';
    final tEndTime = getTranslated('end_time', context) ?? 'End Time';

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tCreateEvent),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPillField(
                  label: tEventName,
                  controller: _nameCtrl,
                  icon: Icons.edit_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nhập tên sự kiện'
                      : null,
                ),
                const SizedBox(height: 12),
                _buildPillField(
                  label: tEventLocation,
                  controller: _locationCtrl,
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 12),
                _buildPillField(
                  label: tEventDesc,
                  controller: _descCtrl,
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Hiển thị ảnh đã chọn
                GestureDetector(
                  onTap: _pickImage,
                  child: _selectedImage == null
                      ? Container(
                    height: 150,
                    color: Colors.grey.shade300,
                    child: Center(child: Text('Chọn ảnh cho sự kiện')),
                  )
                      : Container(
                    height: 150,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Date row
                Row(
                  children: [
                    Expanded(
                      child: _buildPillField(
                        label: '$tStartDate (yyyy-MM-dd)',
                        controller: _startDateCtrl,
                        icon: Icons.calendar_today_outlined,
                        readOnly: true,
                        onTap: _pickStartDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPillField(
                        label: '$tEndDate (yyyy-MM-dd)',
                        controller: _endDateCtrl,
                        icon: Icons.calendar_month_outlined,
                        readOnly: true,
                        onTap: _pickEndDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Time row
                Row(
                  children: [
                    Expanded(
                      child: _buildPillField(
                        label: '$tStartTime (HH:mm)',
                        controller: _startTimeCtrl,
                        icon: Icons.access_time_outlined,
                        readOnly: true,
                        onTap: _pickStartTime,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPillField(
                        label: '$tEndTime (HH:mm)',
                        controller: _endTimeCtrl,
                        icon: Icons.timelapse_outlined,
                        readOnly: true,
                        onTap: _pickEndTime,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Nút tạo sự kiện
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: eventCtrl.creating ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: eventCtrl.creating
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : Text(
                      tCreateEvent,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget field kiểu “giọt nước” (Glassmorphism)
  Widget _buildPillField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final glassColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.25);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.5);

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: TextFormField(
            controller: controller,
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            validator: validator,
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, size: 20) : null,
              labelText: label,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
