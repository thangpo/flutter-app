import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/services/ads_service.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/countries.dart';



class UpdateAdScreen extends StatefulWidget {
  final int adId;
  final String accessToken;
  final Map<String, dynamic>? adData;

  const UpdateAdScreen({
    Key? key,
    required this.adId,
    required this.accessToken,
    this.adData,
  }) : super(key: key);

  @override
  State<UpdateAdScreen> createState() => _UpdateAdScreenState();
}

class _UpdateAdScreenState extends State<UpdateAdScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AdsService _adsService = AdsService();
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;

  late Map<String, dynamic> _formData;
  String? _mediaPath;
  String? _oldMediaUrl;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _initializeForm();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    final ad = widget.adData ?? {};

    _formData = {
      'name': ad['name'] ?? '',
      'website': ad['url'] ?? '',
      'headline': ad['headline'] ?? '',
      'description': ad['description'] ?? '',
      'start': ad['start'] ?? '',
      'end': ad['end'] ?? '',
      'budget': ad['budget']?.toString() ?? '',
      'bidding': ad['bidding'] ?? 'clicks',
      'appears': ad['appears'] ?? 'post',
      'gender': _mapGenderToKey(ad['gender']),
      'location': ad['location'] ?? '',
      'page': ad['page'] ?? 'vnshop247page',
      'countries': _parseCountryIds(ad['country_ids']),
    };

    _oldMediaUrl = ad['ad_media'];
    _mediaPath = null;
    _isLoading = false;
  }

  String _mapGenderToKey(String? gender) {
    switch (gender) {
      case 'male': return 'male';
      case 'female': return 'female';
      default: return 'all';
    }
  }

  List<Country> _parseCountryIds(dynamic countryIds) {
    if (countryIds == null || countryIds is! List) return [];

    return (countryIds as List).map((id) {
      final strId = id.toString();
      final country = countries.firstWhere(
            (c) => c.value == strId,
        orElse: () => Country(strId, 'Quốc gia $strId'),
      );
      return country;
    }).toList();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _mediaPath = image.path;
      });
    }
  }

  Future<void> _updateCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await _adsService.updateCampaign(
        accessToken: widget.accessToken,
        adId: widget.adId,
        formData: _formData,
        mediaPath: _mediaPath,
        oldMediaUrl: _oldMediaUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(getTranslated('update_success', context) ?? 'Cập nhật thành công!'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text('${getTranslated('error', context) ?? 'Lỗi'}: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(isDark),
          child: Center(
            child: CircularProgressIndicator(
              color: isDark ? Colors.purple.shade400 : const Color(0xFF667eea),
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: isDark ? Colors.white : Colors.black87,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
              ),
              title: Text(
                getTranslated('edit_ad', context) ?? 'Chỉnh sửa quảng cáo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              centerTitle: true,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: _buildGradientBackground(isDark),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 70, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(getTranslated('basic_info', context) ?? 'Thông tin cơ bản', Icons.info_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['name'],
                          label: getTranslated('campaign_name', context) ?? 'Tên chiến dịch',
                          icon: Icons.campaign_rounded,
                          onChanged: (v) => _formData['name'] = v,
                          validator: (v) => v!.isEmpty ? (getTranslated('required', context) ?? 'Bắt buộc') : null,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['website'],
                          label: getTranslated('website', context) ?? 'Website',
                          icon: Icons.language_rounded,
                          onChanged: (v) => _formData['website'] = v,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['headline'],
                          label: getTranslated('headline', context) ?? 'Tiêu đề',
                          icon: Icons.title_rounded,
                          onChanged: (v) => _formData['headline'] = v,
                          validator: (v) => v!.isEmpty ? (getTranslated('required', context) ?? 'Bắt buộc') : null,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['description'],
                          label: getTranslated('description', context) ?? 'Mô tả',
                          icon: Icons.description_rounded,
                          maxLines: 3,
                          onChanged: (v) => _formData['description'] = v,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(getTranslated('campaign_settings', context) ?? 'Cài đặt chiến dịch', Icons.settings_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildGlassDropdown<String>(
                          value: _formData['bidding'],
                          label: getTranslated('bidding', context) ?? 'Đấu thầu theo',
                          icon: Icons.monetization_on_rounded,
                          items: ['clicks', 'views']
                              .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(b == 'clicks'
                                ? (getTranslated('per_click', context) ?? 'Mỗi click')
                                : (getTranslated('per_view', context) ?? 'Mỗi lượt xem')),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _formData['bidding'] = v),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassDropdown<String>(
                          value: _formData['appears'],
                          label: getTranslated('display_position', context) ?? 'Vị trí hiển thị',
                          icon: Icons.place_rounded,
                          items: ['post', 'sidebar', 'story', 'entire', 'jobs', 'forum', 'movies', 'offer', 'funding']
                              .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(_getAppearsLabel(a, context)),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _formData['appears'] = v),
                          isDark: isDark,
                        ),
                      ],
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(getTranslated('target_audience', context) ?? 'Đối tượng mục tiêu', Icons.people_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildCountrySection(isDark),
                        const SizedBox(height: 16),
                        _buildGlassDropdown<String>(
                          value: _formData['gender'],
                          label: getTranslated('gender', context) ?? 'Giới tính',
                          icon: Icons.wc_rounded,
                          items: ['all', 'male', 'female']
                              .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g == 'all'
                                ? (getTranslated('all', context) ?? 'Tất cả')
                                : g == 'male'
                                ? (getTranslated('male', context) ?? 'Nam')
                                : (getTranslated('female', context) ?? 'Nữ')),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _formData['gender'] = v),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['location'],
                          label: getTranslated('location', context) ?? 'Vị trí (tỉnh/thành phố)',
                          icon: Icons.location_on_rounded,
                          onChanged: (v) => _formData['location'] = v,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(getTranslated('time_budget', context) ?? 'Thời gian & Ngân sách', Icons.schedule_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['start'],
                          label: getTranslated('start_date', context) ?? 'Ngày bắt đầu (YYYY-MM-DD)',
                          icon: Icons.calendar_today_rounded,
                          onChanged: (v) => _formData['start'] = v,
                          validator: (v) => v!.length == 10 ? null : (getTranslated('invalid_format', context) ?? 'Sai định dạng'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['end'],
                          label: getTranslated('end_date', context) ?? 'Ngày kết thúc (YYYY-MM-DD)',
                          icon: Icons.event_rounded,
                          onChanged: (v) => _formData['end'] = v,
                          validator: (v) => v!.length == 10 ? null : (getTranslated('invalid_format', context) ?? 'Sai định dạng'),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['budget'],
                          label: getTranslated('budget', context) ?? 'Ngân sách (đ)',
                          icon: Icons.attach_money_rounded,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _formData['budget'] = v,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return getTranslated('budget_positive', context) ?? 'Ngân sách phải > 0';
                            return null;
                          },
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['page'],
                          label: 'Page ID',
                          icon: Icons.pages_rounded,
                          onChanged: (v) => _formData['page'] = v,
                          validator: (v) => v!.isEmpty ? (getTranslated('required', context) ?? 'Bắt buộc') : null,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(getTranslated('ad_image', context) ?? 'Hình ảnh quảng cáo', Icons.image_rounded, isDark),
                        const SizedBox(height: 16),
                        _buildImageSection(isDark),
                        const SizedBox(height: 16),
                        _buildGlassButton(
                          onPressed: _pickImage,
                          icon: Icons.photo_library_rounded,
                          label: getTranslated('choose_new_image', context) ?? 'Chọn ảnh mới',
                          color: Colors.blue.shade400,
                          isDark: isDark,
                        ),
                      ],
                    ),
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                  _buildSubmitButton(isDark),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground(bool isDark) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [
          const Color(0xFF1A1A1A),
          const Color(0xFF121212),
          Colors.purple.shade900.withOpacity(0.3),
        ]
            : [
          const Color(0xFFF5F7FA),
          const Color(0xFFE8EDF5),
          Colors.blue.shade50.withOpacity(0.3),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required bool isDark}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.7), Colors.white.withOpacity(0.5)],
            ),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.deepOrange.shade400]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassTextField({
    required String? initialValue,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextFormField(
            initialValue: initialValue,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2C3E50), fontSize: 15),
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
              prefixIcon: Icon(icon, color: isDark ? Colors.purple.shade300 : const Color(0xFF667eea)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(18),
              errorStyle: TextStyle(color: Colors.red.shade400),
            ),
            onChanged: onChanged,
            validator: validator,
          ),
        ),
      ),
    );
  }

  Widget _buildGlassDropdown<T>({
    required T value,
    required String label,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required Function(T?) onChanged,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            dropdownColor: isDark ? Colors.grey.shade900 : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : const Color(0xFF2C3E50), fontSize: 15),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey.shade600),
              prefixIcon: Icon(icon, color: isDark ? Colors.purple.shade300 : const Color(0xFF667eea)),
              border: InputBorder.none,
            ),
            icon: Icon(Icons.arrow_drop_down_rounded, color: isDark ? Colors.white70 : const Color(0xFF667eea)),
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          getTranslated('target_countries', context) ?? 'Quốc gia nhắm đến',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (_formData['countries'].isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formData['countries'].map<Widget>((Country c) {
              return _buildGlassChip(c.name, isDark, onDelete: () {
                setState(() {
                  _formData['countries'].remove(c);
                });
              });
            }).toList(),
          ),
        const SizedBox(height: 12),
        _buildGlassButton(
          onPressed: () async {
            final selected = await showDialog<List<Country>>(
              context: context,
              builder: (ctx) => CountrySelectionDialog(
                countries: countries.where((c) => c.value != "0").toList(),
                selectedCountries: _formData['countries'],
                isDark: isDark,
              ),
            );

            if (selected != null) {
              setState(() {
                _formData['countries'] = selected;
              });
            }
          },
          icon: Icons.add_location_alt_rounded,
          label: getTranslated('add_country', context) ?? 'Thêm quốc gia',
          color: Colors.teal.shade400,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildGlassChip(String label, bool isDark, {VoidCallback? onDelete}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withOpacity(isDark ? 0.2 : 0.3),
                Colors.purple.withOpacity(isDark ? 0.1 : 0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(isDark ? 0.3 : 0.4), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(color: isDark ? Colors.white : Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white70 : Colors.white),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isDark) {
    if (_mediaPath != null) {
      return _buildImagePreview(File(_mediaPath!), isNew: true, isDark: isDark);
    } else if (_oldMediaUrl != null && _oldMediaUrl!.isNotEmpty) {
      return _buildImagePreview(_oldMediaUrl!, isNew: false, isDark: isDark);
    }
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_rounded, size: 50, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(getTranslated('no_image', context) ?? 'Chưa có ảnh', style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(dynamic image, {required bool isNew, required bool isDark}) {
    return Column(
      children: [
        Text(
          isNew ? (getTranslated('new_image', context) ?? 'Ảnh mới:') : (getTranslated('current_image', context) ?? 'Ảnh hiện tại:'),
          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF2C3E50), fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: image is File
                    ? Image.file(image, height: 200, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(image, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(isDark ? 0.2 : 0.15), color.withOpacity(isDark ? 0.1 : 0.1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(isDark ? 0.4 : 0.3)),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      label,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.4 + (_animationController.value * 0.2)),
                blurRadius: 25 + (_animationController.value * 15),
                spreadRadius: 3,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [Colors.green.shade600, Colors.teal.shade600]
                        : [Colors.green.shade500, Colors.teal.shade500],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting ? null : _updateCampaign,
                    borderRadius: BorderRadius.circular(30),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: _isSubmitting
                          ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(colors: [Colors.white, Colors.white]).createShader(bounds),
                            child: Text(
                              getTranslated('update_ad', context) ?? 'CẬP NHẬT QUẢNG CÁO',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getAppearsLabel(String appears, BuildContext context) {
    final map = {
      'post': getTranslated('post', context) ?? 'Bưu kiện',
      'sidebar': getTranslated('sidebar', context) ?? 'Thanh bên',
      'story': getTranslated('story', context) ?? 'Câu chuyện',
      'entire': getTranslated('entire_site', context) ?? 'Toàn bộ trang',
      'jobs': getTranslated('jobs', context) ?? 'Việc làm',
      'forum': getTranslated('forum', context) ?? 'Diễn đàn',
      'movies': getTranslated('movies', context) ?? 'Phim',
      'offer': getTranslated('offer', context) ?? 'Ưu đãi',
      'funding': getTranslated('funding', context) ?? 'Gây quỹ',
    };
    return map[appears] ?? appears;
  }
}

class CountrySelectionDialog extends StatefulWidget {
  final List<Country> countries;
  final List<Country> selectedCountries;
  final bool isDark;

  const CountrySelectionDialog({
    Key? key,
    required this.countries,
    required this.selectedCountries,
    required this.isDark,
  }) : super(key: key);

  @override
  State<CountrySelectionDialog> createState() => _CountrySelectionDialogState();
}

class _CountrySelectionDialogState extends State<CountrySelectionDialog> {
  late List<Country> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.selectedCountries);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: AlertDialog(
          backgroundColor: widget.isDark ? Colors.grey.shade900.withOpacity(0.95) : Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: widget.isDark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
          ),
          title: Text(
            getTranslated('select_country', context) ?? 'Chọn quốc gia',
            style: TextStyle(color: widget.isDark ? Colors.white : const Color(0xFF2C3E50), fontWeight: FontWeight.bold),
          ),
          content: Container(
            width: double.maxFinite,
            height: 420,
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ListView.builder(
                itemCount: widget.countries.length,
                itemBuilder: (ctx, i) {
                  final country = widget.countries[i];
                  final isSelected = _selected.any((c) => c.value == country.value);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (widget.isDark ? Colors.purple.shade900.withOpacity(0.3) : const Color(0xFF667eea).withOpacity(0.1))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? (widget.isDark ? Colors.purple.shade400 : const Color(0xFF667eea).withOpacity(0.4))
                            : (widget.isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        country.name,
                        style: TextStyle(
                          color: widget.isDark ? Colors.white : const Color(0xFF2C3E50),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      value: isSelected,
                      activeColor: widget.isDark ? Colors.purple.shade400 : const Color(0xFF667eea),
                      checkColor: Colors.white,
                      side: BorderSide(color: widget.isDark ? Colors.grey.shade600 : Colors.grey.shade400),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selected.add(country);
                          } else {
                            _selected.removeWhere((c) => c.value == country.value);
                          }
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            _buildDialogButton(
              label: getTranslated('cancel', context) ?? 'Hủy',
              onPressed: () => Navigator.pop(context),
              color: widget.isDark ? Colors.grey.shade600 : Colors.grey.shade500,
              isDark: widget.isDark,
            ),
            _buildDialogButton(
              label: getTranslated('select', context) ?? 'Chọn',
              onPressed: () => Navigator.pop(context, _selected),
              color: widget.isDark ? Colors.purple.shade400 : const Color(0xFF667eea),
              isDark: widget.isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required bool isDark,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: TextButton(
            onPressed: onPressed,
            child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}