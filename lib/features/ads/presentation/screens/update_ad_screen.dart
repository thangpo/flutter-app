import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/countries.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/services/ads_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';

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
      'gender': _mapGenderToVietnamese(ad['gender']),
      'location': ad['location'] ?? '',
      'page': ad['page'] ?? 'vnshop247page',
      'countries': _parseCountryIds(ad['country_ids']),
    };

    _oldMediaUrl = ad['ad_media'];
    _mediaPath = null;
    _isLoading = false;
  }

  String _mapGenderToVietnamese(String? gender) {
    switch (gender) {
      case 'male': return 'Nam';
      case 'female': return 'Nữ';
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
          content: const Text('Cập nhật thành công!'),
          backgroundColor: Colors.green.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(child: CircularProgressIndicator(color: Color(0xFF667eea))),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Chỉnh sửa quảng cáo', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.7),
                    Colors.white.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.5),
                ),
              ),
            ),
          ),
        ),
        foregroundColor: Colors.black87,
      ),
      body: Container(
        decoration: _buildGradientBackground(),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Thông tin cơ bản', Icons.info_outline),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['name'],
                          label: 'Tên chiến dịch',
                          icon: Icons.campaign,
                          onChanged: (v) => _formData['name'] = v,
                          validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['website'],
                          label: 'Website',
                          icon: Icons.language,
                          onChanged: (v) => _formData['website'] = v,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['headline'],
                          label: 'Tiêu đề',
                          icon: Icons.title,
                          onChanged: (v) => _formData['headline'] = v,
                          validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['description'],
                          label: 'Mô tả',
                          icon: Icons.description,
                          maxLines: 3,
                          onChanged: (v) => _formData['description'] = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Cài đặt chiến dịch', Icons.settings),
                        const SizedBox(height: 16),
                        _buildGlassDropdown<String>(
                          value: _formData['bidding'],
                          label: 'Đấu thầu theo',
                          icon: Icons.monetization_on,
                          items: ['clicks', 'views']
                              .map((b) => DropdownMenuItem(
                            value: b,
                            child: Text(b == 'clicks' ? 'Mỗi click' : 'Mỗi lượt xem'),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _formData['bidding'] = v),
                        ),
                        const SizedBox(height: 16),
                        _buildGlassDropdown<String>(
                          value: _formData['appears'],
                          label: 'Vị trí hiển thị',
                          icon: Icons.place,
                          items: ['post', 'sidebar', 'story', 'entire', 'jobs', 'forum', 'movies', 'offer', 'funding']
                              .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(_getAppearsLabel(a)),
                          ))
                              .toList(),
                          onChanged: (v) => setState(() => _formData['appears'] = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Đối tượng mục tiêu', Icons.people),
                        const SizedBox(height: 16),
                        _buildCountrySection(),
                        const SizedBox(height: 16),
                        _buildGlassDropdown<String>(
                          value: _formData['gender'],
                          label: 'Giới tính',
                          icon: Icons.wc,
                          items: ['all', 'Nam', 'Nữ']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (v) => setState(() => _formData['gender'] = v),
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['location'],
                          label: 'Vị trí (tỉnh/thành phố)',
                          icon: Icons.location_on,
                          onChanged: (v) => _formData['location'] = v,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Thời gian & Ngân sách', Icons.schedule),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['start'],
                          label: 'Ngày bắt đầu (YYYY-MM-DD)',
                          icon: Icons.calendar_today,
                          onChanged: (v) => _formData['start'] = v,
                          validator: (v) => v!.length == 10 ? null : 'Sai định dạng',
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['end'],
                          label: 'Ngày kết thúc (YYYY-MM-DD)',
                          icon: Icons.event,
                          onChanged: (v) => _formData['end'] = v,
                          validator: (v) => v!.length == 10 ? null : 'Sai định dạng',
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['budget'],
                          label: 'Ngân sách (đ)',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _formData['budget'] = v,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Ngân sách phải > 0';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildGlassTextField(
                          initialValue: _formData['page'],
                          label: 'Page ID',
                          icon: Icons.pages,
                          onChanged: (v) => _formData['page'] = v,
                          validator: (v) => v!.isEmpty ? 'Bắt buộc' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Hình ảnh quảng cáo', Icons.image),
                        const SizedBox(height: 16),
                        _buildImageSection(),
                        const SizedBox(height: 16),
                        _buildGlassButton(
                          onPressed: _pickImage,
                          icon: Icons.photo_library,
                          label: 'Chọn ảnh mới',
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFF5F5F5),
          const Color(0xFFE8E8E8),
          const Color(0xFFF0F0F0),
          const Color(0xFFEEEEEE),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.8),
                Colors.white.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.9),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF667eea).withOpacity(0.8),
                const Color(0xFF764ba2).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
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
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            initialValue: initialValue,
            style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 15),
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              errorStyle: const TextStyle(color: Colors.red),
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
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 15),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(icon, color: const Color(0xFF667eea)),
              border: InputBorder.none,
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF667eea)),
          ),
        ),
      ),
    );
  }

  Widget _buildCountrySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quốc gia nhắm đến',
          style: TextStyle(
            color: Colors.grey.shade700,
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
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667eea).withOpacity(0.15),
                          const Color(0xFF764ba2).withOpacity(0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF667eea).withOpacity(0.3)),
                    ),
                    child: Chip(
                      label: Text(c.name, style: const TextStyle(color: Color(0xFF2C3E50))),
                      deleteIcon: const Icon(Icons.close, color: Color(0xFF667eea), size: 18),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      onDeleted: () {
                        setState(() {
                          _formData['countries'].remove(c);
                        });
                      },
                    ),
                  ),
                ),
              );
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
              ),
            );

            if (selected != null) {
              setState(() {
                _formData['countries'] = selected;
              });
            }
          },
          icon: Icons.add_location_alt,
          label: 'Thêm quốc gia',
          color: Colors.teal,
        ),
      ],
    );
  }

  Widget _buildImageSection() {
    if (_mediaPath != null) {
      return _buildImagePreview(File(_mediaPath!), isNew: true);
    } else if (_oldMediaUrl != null && _oldMediaUrl!.isNotEmpty) {
      return _buildImagePreview(_oldMediaUrl!, isNew: false);
    }
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 8),
            Text('Chưa có ảnh', style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(dynamic image, {required bool isNew}) {
    return Column(
      children: [
        Text(
          isNew ? 'Ảnh mới:' : 'Ảnh hiện tại:',
          style: const TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
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

  Widget _buildSubmitButton() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3 + (_animationController.value * 0.2)),
                blurRadius: 20 + (_animationController.value * 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.green.withOpacity(0.7),
                      Colors.teal.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isSubmitting ? null : _updateCampaign,
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: _isSubmitting
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'CẬP NHẬT QUẢNG CÁO',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
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

  String _getAppearsLabel(String appears) {
    final map = {
      'post': 'Bưu kiện',
      'sidebar': 'Thanh bên',
      'story': 'Câu chuyện',
      'entire': 'Toàn bộ trang',
      'jobs': 'Việc làm',
      'forum': 'Diễn đàn',
      'movies': 'Phim',
      'offer': 'Ưu đãi',
      'funding': 'Gây quỹ',
    };
    return map[appears] ?? appears;
  }
}

class CountrySelectionDialog extends StatefulWidget {
  final List<Country> countries;
  final List<Country> selectedCountries;

  const CountrySelectionDialog({
    Key? key,
    required this.countries,
    required this.selectedCountries,
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
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          title: const Text('Chọn quốc gia', style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
          content: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            width: double.maxFinite,
            height: 400,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.builder(
                itemCount: widget.countries.length,
                itemBuilder: (ctx, i) {
                  final country = widget.countries[i];
                  final isSelected = _selected.any((c) => c.value == country.value);

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF667eea).withOpacity(0.1)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF667eea).withOpacity(0.4)
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        country.name,
                        style: TextStyle(
                          color: const Color(0xFF2C3E50),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      value: isSelected,
                      activeColor: const Color(0xFF667eea),
                      checkColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade400),
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
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Hủy', style: TextStyle(color: Color(0xFF2C3E50))),
                  ),
                ),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667eea).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text('Chọn', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}