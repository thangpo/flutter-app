// lib/features/social/screens/edit_event_screen.dart
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:flutter_sixvalley_ecommerce/features/social/controllers/event_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

class EditEventScreen extends StatefulWidget {
  final SocialEvent event;

  const EditEventScreen({super.key, required this.event});

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
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

  File? _selectedImage; // Ảnh mới (nếu chọn lại)
  String? _existingCoverUrl; // Ảnh cũ

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final e = widget.event;

    _nameCtrl.text = e.name ?? '';
    _locationCtrl.text = e.location ?? '';
    _descCtrl.text = e.description ?? '';

    _existingCoverUrl = e.cover;

    // Date / time từ API (yyyy-MM-dd, HH:mm:ss)
    _startDateCtrl.text = e.startDate ?? '';
    _endDateCtrl.text = e.endDate ?? '';
    _startTimeCtrl.text = e.startTime ?? '';
    _endTimeCtrl.text = e.endTime ?? '';

    _startDate = _tryParseDate(e.startDate);
    _endDate = _tryParseDate(e.endDate);
    _startTime = _tryParseTime(e.startTime);
    _endTime = _tryParseTime(e.endTime);
  }

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

  // ================== PARSE / FORMAT ==================

  DateTime? _tryParseDate(String? s) {
    if (s == null || s.isEmpty || s == '0000-00-00') return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _tryParseTime(String? s) {
    if (s == null || s.isEmpty || s == '00:00:00') return null;
    try {
      final parts = s.split(':');
      if (parts.length < 2) return null;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return TimeOfDay(hour: h, minute: m);
    } catch (_) {
      return null;
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

  // ================== PICKERS ==================

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
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

  // ================== SUBMIT ==================

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final eventCtrl = context.read<EventController>();

    final ok = await eventCtrl.editEvent(
      id: widget.event.id.toString(),
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      startDate: _startDateCtrl.text.trim(),
      endDate: _endDateCtrl.text.trim(),
      startTime: _startTimeCtrl.text.trim(),
      endTime: _endTimeCtrl.text.trim(),
      coverFile: _selectedImage, // chỉ gửi nếu chọn ảnh mới
    );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true); // có thể pop với result để refresh detail
    } else {
      final msg =
          eventCtrl.error ?? 'Sửa sự kiện thất bại, vui lòng thử lại.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  // ================== UI ==================

  @override
  Widget build(BuildContext context) {
    final eventCtrl = context.watch<EventController>();
    final theme = Theme.of(context);

    final tEditEvent =
        getTranslated('edit_event', context) ?? 'Chỉnh sửa sự kiện';
    final tEventName =
        getTranslated('event_name', context) ?? 'Event Name';
    final tEventLocation =
        getTranslated('event_location', context) ?? 'Event Location';
    final tEventDesc =
        getTranslated('event_description', context) ?? 'Event Description';
    final tStartDate =
        getTranslated('start_date', context) ?? 'Start Date';
    final tEndDate =
        getTranslated('end_date', context) ?? 'End Date';
    final tStartTime =
        getTranslated('start_time', context) ?? 'Start Time';
    final tEndTime =
        getTranslated('end_time', context) ?? 'End Time';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(tEditEvent),
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

                // Ảnh: ưu tiên ảnh mới, nếu không có thì ảnh cũ
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      image: _selectedImage != null
                          ? DecorationImage(
                        image: FileImage(_selectedImage!),
                        fit: BoxFit.cover,
                      )
                          : (_existingCoverUrl != null &&
                          _existingCoverUrl!.isNotEmpty)
                          ? DecorationImage(
                        image: NetworkImage(_existingCoverUrl!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: (_selectedImage == null &&
                        (_existingCoverUrl == null ||
                            _existingCoverUrl!.isEmpty))
                        ? const Center(child: Text('Chọn ảnh cho sự kiện'))
                        : null,
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

                // Nút lưu
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
                        : const Text(
                      'Lưu thay đổi',
                      style: TextStyle(
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

  // Giống _buildPillField trong CreateEventScreen
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
