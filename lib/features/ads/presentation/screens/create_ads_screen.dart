import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/countries.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/services/ads_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class CreateAdsScreen extends StatefulWidget {
  const CreateAdsScreen({super.key});

  @override
  State<CreateAdsScreen> createState() => _CreateAdsScreenState();
}

class _CreateAdsScreenState extends State<CreateAdsScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final PageController _pageController = PageController();
  final AdsService _adsService = AdsService();

  int _currentStep = 0;
  bool _isSubmitting = false;

  late AnimationController _shimmerController;
  late AnimationController _glowController;

  File? _mediaFile;
  final _nameCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _websiteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  List<Country> _selectedCountries = [];
  String? _gender;
  String? _appears;
  final _budgetCtrl = TextEditingController();
  String _biddingStrategy = 'Clicks';

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    _glowController.dispose();
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() {
        _mediaFile = File(image.path);
      });
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: const Color(0xFF007AFF),
              surface: Colors.grey[900]!,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _next() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      _showError('Vui lòng điền đầy đủ thông tin!');
      return;
    }

    if (_mediaFile == null) {
      _showError('Vui lòng chọn hình ảnh!');
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showError('Vui lòng chọn ngày bắt đầu và kết thúc!');
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      _showError('Ngày bắt đầu phải trước ngày kết thúc!');
      return;
    }

    if (_selectedCountries.isEmpty) {
      _showError('Vui lòng chọn ít nhất 1 quốc gia!');
      return;
    }

    if (_appears == null) {
      _showError('Vui lòng chọn vị trí hiển thị!');
      return;
    }

    final budget = int.tryParse(_budgetCtrl.text.trim());
    if (budget == null || budget <= 0) {
      _showError('Ngân sách phải là số dương!');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();
      if (accessToken == null || accessToken.isEmpty) throw Exception('Đăng nhập lại');

      String genderValue() {
        if (_gender == 'Nam') return 'male';
        if (_gender == 'Nữ') return 'female';
        return 'all';
      }

      String appearsFixed = _appears ?? 'post';
      if (appearsFixed == 'entire') {
        appearsFixed = 'post';
      }

      final formData = {
        'name': _nameCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'headline': _headlineCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'start': _formatDate(_startDate!),
        'end': _formatDate(_endDate!),
        'budget': budget,
        'bidding': _biddingStrategy.toLowerCase(),
        'appears': appearsFixed,
        'countries': _selectedCountries,
        'gender': genderValue(),
        'location': _locationCtrl.text.trim(),
      };

      final response = await _adsService.createCampaign(
        accessToken: accessToken,
        formData: formData,
        mediaPath: _mediaFile!.path,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccess('Tạo chiến dịch thành công!');
        await Future.delayed(const Duration(milliseconds: 1200));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Lỗi: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tạo chiến dịch',
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[50]!,
                  Colors.white,
                ],
              ),
            ),
          ),

          Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 100),
                _buildCameraControlStepper(),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentStep = i),
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Step1Widget(
                        mediaFile: _mediaFile,
                        nameCtrl: _nameCtrl,
                        onPickImage: _pickImage,
                      ),
                      Step2Widget(
                        headlineCtrl: _headlineCtrl,
                        descCtrl: _descCtrl,
                        startDate: _startDate,
                        endDate: _endDate,
                        websiteCtrl: _websiteCtrl,
                        onPickStartDate: () => _pickDate(true),
                        onPickEndDate: () => _pickDate(false),
                      ),
                      Step3Widget(
                        locationCtrl: _locationCtrl,
                        budgetCtrl: _budgetCtrl,
                        selectedCountries: _selectedCountries,
                        onCountriesChanged: (list) => setState(() => _selectedCountries = list),
                        gender: _gender,
                        onGenderChanged: (v) => setState(() => _gender = v),
                        appears: _appears,
                        onAppearsChanged: (v) => setState(() => _appears = v),
                        biddingStrategy: _biddingStrategy,
                        onBiddingChanged: (v) => setState(() => _biddingStrategy = v ?? 'Clicks'),
                      ),
                    ],
                  ),
                ),

                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControlStepper() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCameraButton(index),
              );
            }),
          ),

          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: constraints.maxWidth * ((_currentStep + 1) / 3),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraButton(int index) {
    final isActive = index == _currentStep;
    final isPassed = index < _currentStep;

    final icons = [
      Icons.photo_camera_outlined,
      Icons.description_outlined,
      Icons.settings_outlined,
    ];

    final labels = ['MEDIA', 'CONTENT', 'TARGETING'];

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 64,
          height: 64,
          child: Stack(
            children: [
              // Glass Background
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: isActive
                          ? const Color(0xFF007AFF).withOpacity(0.1)
                          : isPassed
                          ? Colors.green.withOpacity(0.1)
                          : Colors.white.withOpacity(0.8),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF007AFF).withOpacity(0.5)
                            : isPassed
                            ? Colors.green.withOpacity(0.5)
                            : Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        if (isActive)
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Icon
              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: isPassed
                      ? const Icon(
                    Icons.check_rounded,
                    color: Colors.green,
                    size: 28,
                  )
                      : Icon(
                    icons[index],
                    color: isActive ? const Color(0xFF007AFF) : Colors.grey[600],
                    size: 28,
                  ),
                ),
              ),

              if (isActive)
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.3 * _glowController.value),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          labels[index],
          style: TextStyle(
            color: isActive
                ? const Color(0xFF007AFF)
                : isPassed
                ? Colors.green
                : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        topRight: Radius.circular(24),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: _buildGlassButton(
                      onPressed: _isSubmitting ? null : _prev,
                      label: 'Quay lại',
                      isPrimary: false,
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: _buildGlassButton(
                    onPressed: _isSubmitting ? null : _next,
                    label: _currentStep == 2 ? 'Tạo chiến dịch' : 'Tiếp theo',
                    isPrimary: true,
                    isLoading: _isSubmitting,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassButton({
    required VoidCallback? onPressed,
    required String label,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isPrimary
                ? const LinearGradient(
              colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
            )
                : null,
            color: isPrimary ? null : Colors.grey[200],
            border: Border.all(
              color: isPrimary ? Colors.transparent : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  label,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : Colors.grey[800],
                    fontSize: 16,
                    fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Step1Widget extends StatelessWidget {
  final File? mediaFile;
  final TextEditingController nameCtrl;
  final VoidCallback onPickImage;

  const Step1Widget({
    super.key,
    required this.mediaFile,
    required this.nameCtrl,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEDIA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: onPickImage,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: mediaFile != null
                          ? const Color(0xFF007AFF).withOpacity(0.5)
                          : Colors.white.withOpacity(0.1),
                      width: 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      if (mediaFile != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.file(
                            mediaFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFF007AFF).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: Color(0xFF007AFF),
                                  size: 40,
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Chọn hình ảnh',
                                style: TextStyle(
                                  color: Color(0xFF007AFF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'JPG, PNG • Tối đa 5MB',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          _buildGlassTextField(
            controller: nameCtrl,
            label: 'TÊN CÔNG TY',
            icon: Icons.business_outlined,
            validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: TextStyle(color: Colors.grey[900], fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: 'Nhập $label',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                  ),
                ),
                validator: validator,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Step2Widget extends StatelessWidget {
  final TextEditingController headlineCtrl, descCtrl, websiteCtrl;
  final DateTime? startDate, endDate;
  final VoidCallback onPickStartDate, onPickEndDate;

  const Step2Widget({
    super.key,
    required this.headlineCtrl,
    required this.descCtrl,
    required this.startDate,
    required this.endDate,
    required this.websiteCtrl,
    required this.onPickStartDate,
    required this.onPickEndDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CONTENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          _buildGlassTextField(
            controller: headlineCtrl,
            label: 'TIÊU ĐỀ',
            icon: Icons.title_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          _buildGlassTextField(
            controller: descCtrl,
            label: 'MÔ TẢ',
            icon: Icons.description_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 20),

          _buildDateField(
            context: context,
            label: 'NGÀY BẮT ĐẦU',
            date: startDate,
            onTap: onPickStartDate,
          ),
          const SizedBox(height: 20),

          _buildDateField(
            context: context,
            label: 'NGÀY KẾT THÚC',
            date: endDate,
            onTap: onPickEndDate,
          ),
          const SizedBox(height: 20),

          _buildGlassTextField(
            controller: websiteCtrl,
            label: 'WEBSITE URL',
            icon: Icons.link_outlined,
            keyboardType: TextInputType.url,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: TextStyle(color: Colors.grey[900], fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: 'Nhập $label',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                  if (keyboardType == TextInputType.url) {
                    if (!v.startsWith('http://') && !v.startsWith('https://')) {
                      return 'URL phải bắt đầu bằng http:// hoặc https://';
                    }
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      color: Color(0xFF007AFF),
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      date != null
                          ? '${date.day}/${date.month}/${date.year}'
                          : 'Chọn ngày',
                      style: TextStyle(
                        color: date != null ? Colors.grey[900] : Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class Step3Widget extends StatelessWidget {
  final TextEditingController locationCtrl, budgetCtrl;
  final List<Country> selectedCountries;
  final Function(List<Country>) onCountriesChanged;
  final String? gender, appears;
  final Function(String?) onGenderChanged, onAppearsChanged;
  final String biddingStrategy;
  final Function(String?) onBiddingChanged;

  const Step3Widget({
    super.key,
    required this.locationCtrl,
    required this.budgetCtrl,
    required this.selectedCountries,
    required this.onCountriesChanged,
    required this.gender,
    required this.onGenderChanged,
    required this.appears,
    required this.onAppearsChanged,
    required this.biddingStrategy,
    required this.onBiddingChanged,
  });

  final List<Map<String, String>> placementOptions = const [
    {'value': 'entire', 'label': 'Toàn bộ trang'},
    {'value': 'post', 'label': 'Bưu kiện'},
    {'value': 'sidebar', 'label': 'Thanh bên'},
    {'value': 'jobs', 'label': 'Việc làm'},
    {'value': 'forum', 'label': 'Diễn đàn'},
    {'value': 'movies', 'label': 'Phim'},
    {'value': 'offer', 'label': 'Lời đề nghị'},
    {'value': 'funding', 'label': 'Kinh phí'},
    {'value': 'story', 'label': 'Câu chuyện'},
  ];

  void _showCountryPicker(BuildContext context) {
    List<Country> temp = List.from(selectedCountries);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Chọn quốc gia',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        setStateDialog(() {
                          temp = countries.where((c) => c.value != "0").toList();
                        });
                      },
                      child: const Text(
                        'Chọn tất cả',
                        style: TextStyle(color: Color(0xFF007AFF)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setStateDialog(() => temp.clear());
                      },
                      child: const Text(
                        'Bỏ chọn',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView.builder(
                    itemCount: countries.length - 1,
                    itemBuilder: (ctx, i) {
                      final country = countries[i + 1];
                      final checked = temp.contains(country);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(
                          country.toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                        value: checked,
                        activeColor: const Color(0xFF007AFF),
                        checkColor: Colors.white,
                        onChanged: (v) {
                          setStateDialog(() {
                            if (v == true) {
                              temp.add(country);
                            } else {
                              temp.remove(country);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                onCountriesChanged(temp);
                Navigator.pop(ctx);
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TARGETING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          _buildGlassTextField(
            controller: locationCtrl,
            label: 'ĐỊA ĐIỂM',
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 20),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QUỐC GIA',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showCountryPicker(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.public_outlined,
                                color: Color(0xFF007AFF),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                selectedCountries.isEmpty
                                    ? 'Chọn quốc gia'
                                    : '${selectedCountries.length} quốc gia',
                                style: TextStyle(
                                  color: selectedCountries.isEmpty
                                      ? Colors.grey[400]
                                      : Colors.grey[900],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (selectedCountries.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedCountries.take(3).map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF007AFF).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        c.toString(),
                        style: const TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          _buildGlassDropdown(
            label: 'GIỚI TÍNH',
            icon: Icons.people_outline,
            value: gender,
            items: ['Nam', 'Nữ', 'Cả hai'],
            onChanged: onGenderChanged,
            hint: 'Chọn giới tính',
          ),
          const SizedBox(height: 20),

          _buildGlassDropdown(
            label: 'VỊ TRÍ HIỂN THỊ',
            icon: Icons.visibility_outlined,
            value: appears,
            items: placementOptions.map((e) => e['value']!).toList(),
            itemLabels: placementOptions.map((e) => e['label']!).toList(),
            onChanged: onAppearsChanged,
            hint: 'Chọn vị trí',
          ),
          const SizedBox(height: 20),

          _buildGlassTextField(
            controller: budgetCtrl,
            label: 'NGÂN SÁCH (₫)',
            icon: Icons.attach_money_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),

          _buildGlassDropdown(
            label: 'HÌNH THỨC ĐẤU THẦU',
            icon: Icons.trending_up_outlined,
            value: biddingStrategy,
            items: ['Clicks', 'Views'],
            itemLabels: ['Clicks (mỗi click)', 'Views (mỗi hiển thị)'],
            onChanged: onBiddingChanged,
            hint: 'Chọn hình thức',
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                style: TextStyle(color: Colors.grey[900], fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: 'Nhập $label',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Bắt buộc';
                  if (keyboardType == TextInputType.number) {
                    if (int.tryParse(v) == null) return 'Phải là số';
                    if (int.parse(v) <= 0) return 'Phải lớn hơn 0';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassDropdown({
    required String label,
    required IconData icon,
    required String? value,
    required List<String> items,
    List<String>? itemLabels,
    required Function(String?) onChanged,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: value,
                dropdownColor: Colors.white,
                style: TextStyle(color: Colors.grey[900], fontSize: 16),
                icon: Icon(
                  Icons.arrow_drop_down_rounded,
                  color: Colors.grey[600],
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 15,
                  ),
                ),
                items: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final displayLabel = itemLabels != null ? itemLabels[index] : item;
                  return DropdownMenuItem(
                    value: item,
                    child: Text(displayLabel),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}