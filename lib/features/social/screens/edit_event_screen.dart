// lib/features/social/screens/edit_event_screen.dart
import 'dart:io';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
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

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  File? _selectedImage;
  String? _existingCoverUrl;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadEventData();
  }

  void _loadEventData() {
    final e = widget.event;
    _nameCtrl.text = e.name ?? '';
    _locationCtrl.text = e.location ?? '';
    _descCtrl.text = e.description ?? '';
    _existingCoverUrl = e.cover;

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
    super.dispose();
  }

  // ================== PARSERS & FORMATTERS ==================
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
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  String _displayDate(BuildContext context, DateTime? d) {
    if (d == null) {
      return getTranslated('select_date', context) ?? 'Chọn ngày';
    }
    return '${d.day}/${d.month}/${d.year}';
  }

  String _displayTime(BuildContext context, TimeOfDay? t) {
    if (t == null) {
      return getTranslated('select_time', context) ?? 'Chọn giờ';
    }
    return t.format(context);
  }

  // ================== PICKERS ==================
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
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
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final baseDate = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? baseDate,
      firstDate: baseDate,
      lastDate: baseDate.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  // ================== SUBMIT ==================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final tTimeRequired =
        getTranslated('event_time_required', context) ??
            'Vui lòng chọn đầy đủ thời gian diễn ra sự kiện';

    if (_startDate == null ||
        _endDate == null ||
        _startTime == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tTimeRequired)),
      );
      return;
    }

    final eventCtrl = context.read<EventController>();

    final ok = await eventCtrl.editEvent(
      id: widget.event.id.toString(),
      name: _nameCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      startDate: _formatDate(_startDate!),
      endDate: _formatDate(_endDate!),
      startTime: _formatTime(_startTime!),
      endTime: _formatTime(_endTime!),
      coverFile: _selectedImage,
    );

    if (!mounted) return;

    final tSuccess =
        getTranslated('event_update_success', context) ??
            'Cập nhật sự kiện thành công!';
    final tFailed =
        getTranslated('event_update_failed', context) ??
            'Cập nhật sự kiện thất bại.';

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tSuccess)),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(eventCtrl.error ?? tFailed)),
      );
    }
  }

  // ================== UI WIDGETS ==================
  @override
  Widget build(BuildContext context) {
    final eventCtrl = context.watch<EventController>();
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final tEditEvent =
        getTranslated('edit_event', context) ?? 'Chỉnh sửa sự kiện';
    final tEventName =
        getTranslated('event_name', context) ?? 'Tên sự kiện';
    final tEventLocation =
        getTranslated('event_location', context) ?? 'Địa điểm';
    final tEventDesc =
        getTranslated('event_description', context) ?? 'Mô tả';
    final tSaveChanges =
        getTranslated('save_changes', context) ?? 'Lưu thay đổi';
    final tNameRequired =
        getTranslated('event_name_required', context) ??
            'Bạn chưa nhập tên sự kiện';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          tEditEvent,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          _buildDecorativeBackground(isDarkMode),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 56),
                    _buildImagePicker(isDarkMode),
                    const SizedBox(height: 20),
                    _buildGlassTextField(
                      isDarkMode: isDarkMode,
                      controller: _nameCtrl,
                      label: tEventName,
                      icon: Icons.festival_outlined,
                      validator: (v) =>
                      (v == null || v.trim().isEmpty)
                          ? tNameRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    _buildGlassTextField(
                      isDarkMode: isDarkMode,
                      controller: _locationCtrl,
                      label: tEventLocation,
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    _buildGlassTextField(
                      isDarkMode: isDarkMode,
                      controller: _descCtrl,
                      label: tEventDesc,
                      icon: Icons.notes_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 20),
                    _buildDateTimePickerSection(isDarkMode),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: eventCtrl.creating ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          disabledBackgroundColor:
                          theme.primaryColor.withOpacity(0.5),
                        ),
                        child: eventCtrl.creating
                            ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          tSaveChanges.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeBackground(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.black : const Color(0xFFF2F5F9),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDarkMode
                    ? Colors.purple.shade900
                    : Colors.blue.shade200)
                    .withOpacity(0.5),
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -150,
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDarkMode
                    ? Colors.teal.shade900
                    : Colors.purple.shade200)
                    .withOpacity(0.5),
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(bool isDarkMode) {
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_existingCoverUrl != null &&
        _existingCoverUrl!.isNotEmpty) {
      imageProvider = CachedNetworkImageProvider(_existingCoverUrl!);
    }
    final hasImage = imageProvider != null;

    final tChangeCover =
        getTranslated('change_cover_image', context) ??
            'Thay đổi ảnh bìa';

    return GestureDetector(
      onTap: _pickImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: _getGlassmorphismDecoration(context).copyWith(
              image: hasImage
                  ? DecorationImage(
                image: imageProvider!,
                fit: BoxFit.cover,
              )
                  : null,
            ),
            child: !hasImage
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: isDarkMode
                        ? Colors.white70
                        : Colors.black54,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tChangeCover,
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
                : Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white70,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePickerSection(bool isDarkMode) {
    final tStart =
        getTranslated('event_start', context) ?? 'Bắt đầu';
    final tEnd = getTranslated('event_end', context) ?? 'Kết thúc';

    return _buildGlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateTimeRow(
            isDarkMode: isDarkMode,
            icon: Icons.calendar_today_outlined,
            label: tStart,
            dateText: _displayDate(context, _startDate),
            timeText: _displayTime(context, _startTime),
            onDateTap: _pickStartDate,
            onTimeTap: _pickStartTime,
          ),
          Divider(
            color: (isDarkMode ? Colors.white : Colors.black)
                .withOpacity(0.2),
            height: 1,
          ),
          _buildDateTimeRow(
            isDarkMode: isDarkMode,
            icon: Icons.calendar_month_outlined,
            label: tEnd,
            dateText: _displayDate(context, _endDate),
            timeText: _displayTime(context, _endTime),
            onDateTap: _pickEndDate,
            onTimeTap: _pickEndTime,
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeRow({
    required bool isDarkMode,
    required IconData icon,
    required String label,
    required String dateText,
    required String timeText,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    final textColor =
    isDarkMode ? Colors.white : Colors.black87;
    final labelColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.6);
    final iconColor =
    isDarkMode ? Colors.white70 : Colors.black54;

    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Icon(icon, size: 22, color: iconColor),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style:
                  TextStyle(color: labelColor, fontSize: 12)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: GestureDetector(
                      onTap: onDateTap,
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        child: Text(
                          dateText,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: onTimeTap,
                      child: Container(
                        color: Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 8),
                        child: Text(
                          timeText,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: _getGlassmorphismDecoration(context),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required bool isDarkMode,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final textColor =
    isDarkMode ? Colors.white : Colors.black87;
    final labelColor = isDarkMode
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.6);
    final iconColor =
    isDarkMode ? Colors.white70 : Colors.black54;

    return _buildGlassContainer(
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 22, color: iconColor),
          labelText: label,
          labelStyle: TextStyle(color: labelColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          floatingLabelBehavior: FloatingLabelBehavior.never,
        ),
      ),
    );
  }

  BoxDecoration _getGlassmorphismDecoration(BuildContext context) {
    final isDarkMode =
        Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDarkMode
        ? Colors.white.withOpacity(0.1)
        : Colors.white.withOpacity(0.6);
    final borderColor = isDarkMode
        ? Colors.white.withOpacity(0.2)
        : Colors.white.withOpacity(0.7);

    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          glassColor.withOpacity(0.8),
          glassColor.withOpacity(0.5),
        ],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}
