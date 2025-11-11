import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/domain/models/countries.dart';
import 'package:flutter_sixvalley_ecommerce/features/ads/services/ads_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
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
  String _biddingStrategy = 'clicks';

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
    final theme = Provider.of<ThemeController>(context, listen: false);
    final isDark = theme.darkTheme;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme(
              primary: const Color(0xFF007AFF),
              surface: isDark ? Colors.grey[900]! : Colors.white,
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.white : Colors.black87,
              brightness: isDark ? Brightness.dark : Brightness.light,
              secondary: const Color(0xFF007AFF),
              onSecondary: Colors.white,
              error: Colors.red,
              onError: Colors.white,
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
      _showError(getTranslated('fill_all_fields', context) ?? 'Vui lòng điền đầy đủ thông tin!');
      return;
    }

    if (_mediaFile == null) {
      _showError(getTranslated('select_image', context) ?? 'Vui lòng chọn hình ảnh!');
      return;
    }

    if (_startDate == null || _endDate == null) {
      _showError(getTranslated('select_dates', context) ?? 'Vui lòng chọn ngày bắt đầu và kết thúc!');
      return;
    }

    if (_startDate!.isAfter(_endDate!)) {
      _showError(getTranslated('start_before_end', context) ?? 'Ngày bắt đầu phải trước ngày kết thúc!');
      return;
    }

    if (_selectedCountries.isEmpty) {
      _showError(getTranslated('select_country', context) ?? 'Vui lòng chọn ít nhất 1 quốc gia!');
      return;
    }

    if (_appears == null) {
      _showError(getTranslated('select_placement', context) ?? 'Vui lòng chọn vị trí hiển thị!');
      return;
    }

    final budget = int.tryParse(_budgetCtrl.text.trim());
    if (budget == null || budget <= 0) {
      _showError(getTranslated('budget_positive', context) ?? 'Ngân sách phải là số dương!');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<AuthController>(context, listen: false);
      final accessToken = await auth.authServiceInterface.getSocialAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception(getTranslated('login_again', context) ?? 'Đăng nhập lại');
      }

      String genderValue() {
        if (_gender == getTranslated('male', context) || _gender == 'Nam') return 'male';
        if (_gender == getTranslated('female', context) || _gender == 'Nữ') return 'female';
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
        _showSuccess(getTranslated('campaign_created', context) ?? 'Tạo chiến dịch thành công!');
        await Future.delayed(const Duration(milliseconds: 1200));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('${getTranslated('error', context) ?? 'Lỗi'}: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: isDark ? Colors.white : Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          getTranslated('create_campaign', context) ?? 'Tạo chiến dịch',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey[900],
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
                colors: isDark
                    ? [Colors.grey[900]!, Colors.black]
                    : [Colors.grey[50]!, Colors.white],
              ),
            ),
          ),

          Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 100),
                _buildCameraControlStepper(isDark),

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
                        isDark: isDark,
                      ),
                      Step2Widget(
                        headlineCtrl: _headlineCtrl,
                        descCtrl: _descCtrl,
                        startDate: _startDate,
                        endDate: _endDate,
                        websiteCtrl: _websiteCtrl,
                        onPickStartDate: () => _pickDate(true),
                        onPickEndDate: () => _pickDate(false),
                        isDark: isDark,
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
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                _buildBottomNavigation(isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControlStepper(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildCameraButton(index, isDark),
              );
            }),
          ),

          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
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

  Widget _buildCameraButton(int index, bool isDark) {
    final isActive = index == _currentStep;
    final isPassed = index < _currentStep;

    final icons = [
      Icons.photo_camera_outlined,
      Icons.description_outlined,
      Icons.settings_outlined,
    ];

    final labels = [
      getTranslated('media', context)?.toUpperCase() ?? 'MEDIA',
      getTranslated('content', context)?.toUpperCase() ?? 'CONTENT',
      getTranslated('targeting', context)?.toUpperCase() ?? 'TARGETING'
    ];

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 64,
          height: 64,
          child: Stack(
            children: [
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
                          : isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.8),
                      border: Border.all(
                        color: isActive
                            ? const Color(0xFF007AFF).withOpacity(0.5)
                            : isPassed
                            ? Colors.green.withOpacity(0.5)
                            : isDark
                            ? Colors.white.withOpacity(0.3)
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
                    color: isActive
                        ? const Color(0xFF007AFF)
                        : isDark
                        ? Colors.white70
                        : Colors.grey[600],
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
                : isDark
                ? Colors.white70
                : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
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
            color: isDark
                ? Colors.grey[850]!.withOpacity(0.9)
                : Colors.white.withOpacity(0.9),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                      label: getTranslated('back', context) ?? 'Quay lại',
                      isPrimary: false,
                      isDark: isDark,
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: _buildGlassButton(
                    onPressed: _isSubmitting ? null : _next,
                    label: _currentStep == 2
                        ? (getTranslated('create_campaign', context) ?? 'Tạo chiến dịch')
                        : (getTranslated('next', context) ?? 'Tiếp theo'),
                    isPrimary: true,
                    isLoading: _isSubmitting,
                    isDark: isDark,
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
    required bool isDark,
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
            color: isPrimary ? null : isDark ? Colors.grey[800] : Colors.grey[200],
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.3),
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
                    color: isPrimary
                        ? Colors.white
                        : isDark
                        ? Colors.white
                        : Colors.grey[800],
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
  final bool isDark;

  const Step1Widget({
    super.key,
    required this.mediaFile,
    required this.nameCtrl,
    required this.onPickImage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated('media', context)?.toUpperCase() ?? 'MEDIA',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[800],
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
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white.withOpacity(0.5),
                    border: Border.all(
                      color: mediaFile != null
                          ? const Color(0xFF007AFF).withOpacity(0.5)
                          : isDark
                          ? Colors.white.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.3),
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
                              Text(
                                getTranslated('select_image', context) ?? 'Chọn hình ảnh',
                                style: const TextStyle(
                                  color: Color(0xFF007AFF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'JPG, PNG • ${getTranslated('max_5mb', context) ?? 'Tối đa 5MB'}',
                                style: TextStyle(
                                  color: isDark ? Colors.white54 : Colors.grey[600],
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
            context: context,
            controller: nameCtrl,
            label: getTranslated('company_name', context)?.toUpperCase() ?? 'TÊN CÔNG TY',
            icon: Icons.business_outlined,
            validator: (v) => v == null || v.trim().isEmpty
                ? (getTranslated('required', context) ?? 'Bắt buộc')
                : null,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
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
            color: isDark ? Colors.white70 : Colors.grey[800],
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
                color: isDark ? Colors.grey[850] : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[900],
                    fontSize: 16
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: '${getTranslated('enter', context) ?? 'Nhập'} $label',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
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
  final bool isDark;

  const Step2Widget({
    super.key,
    required this.headlineCtrl,
    required this.descCtrl,
    required this.startDate,
    required this.endDate,
    required this.websiteCtrl,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            getTranslated('content', context)?.toUpperCase() ?? 'CONTENT',
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[800],
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          _buildGlassTextField(
            context: context,
            controller: headlineCtrl,
            label: getTranslated('headline', context)?.toUpperCase() ?? 'TIÊU ĐỀ',
            icon: Icons.title_outlined,
            maxLines: 2,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          _buildGlassTextField(
            context: context,
            controller: descCtrl,
            label: getTranslated('description', context)?.toUpperCase() ?? 'MÔ TẢ',
            icon: Icons.description_outlined,
            maxLines: 4,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          _buildDateField(
            context: context,
            label: getTranslated('start_date', context)?.toUpperCase() ?? 'NGÀY BẮT ĐẦU',
            date: startDate,
            onTap: onPickStartDate,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          _buildDateField(
            context: context,
            label: getTranslated('end_date', context)?.toUpperCase() ?? 'NGÀY KẾT THÚC',
            date: endDate,
            onTap: onPickEndDate,
            isDark: isDark,
          ),
          const SizedBox(height: 20),

          _buildGlassTextField(
            context: context,
            controller: websiteCtrl,
            label: getTranslated('website_url', context)?.toUpperCase() ?? 'WEBSITE URL',
            icon: Icons.link_outlined,
            keyboardType: TextInputType.url,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[800],
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
                color: isDark ? Colors.grey[850] : Colors.white,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextFormField(
                controller: controller,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.grey[900],
                    fontSize: 16
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: const Color(0xFF007AFF), size: 22),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  hintText: '${getTranslated('enter', context) ?? 'Nhập'} $label',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey[400],
                    fontSize: 15,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return getTranslated('required', context) ?? 'Bắt buộc';
                  }
                  if (keyboardType == TextInputType.url) {
                    if (!v.startsWith('http://') && !v.startsWith('https://')) {
                      return getTranslated('url_must_start', context) ??
                          'URL phải bắt đầu bằng http:// hoặc https://';
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
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.grey[800],
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
                  color: isDark ? Colors.grey[850] : Colors.white,
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.3),
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
                          : (getTranslated('select_date', context) ?? 'Chọn ngày'),
                      style: TextStyle(
                        color: date != null
                            ? (isDark ? Colors.white : Colors.grey[900])
                            : (isDark ? Colors.white38 : Colors.grey[400]),
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
  final bool isDark;

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
    required this.isDark,
  });

  static const List<Map<String, String>> _placementOptions = [
    {'value': 'entire', 'label': 'targeting_placement_entire'},     // Toàn bộ trang
    {'value': 'post', 'label': 'targeting_placement_post'},         // Trong bài viết
    {'value': 'sidebar', 'label': 'targeting_placement_sidebar'},   // Thanh bên
    {'value': 'story', 'label': 'targeting_placement_story'},       // Stories
    {'value': 'offer', 'label': 'targeting_placement_offer'},       // Ưu đãi
    {'value': 'jobs', 'label': 'targeting_placement_jobs'},         // Việc làm
    {'value': 'forum', 'label': 'targeting_placement_forum'},       // Diễn đàn
    {'value': 'funding', 'label': 'targeting_placement_funding'},   // Kêu gọi vốn
  ];

  void _showCountryPicker(BuildContext context) {
    List<Country> temp = List.from(selectedCountries);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            getTranslated('select_countries', context) ?? 'Chọn quốc gia',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 460,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => setStateDialog(() {
                          temp = countries.where((c) => c.value != "0").toList();
                        }),
                        child: Text(
                          getTranslated('select_all', context) ?? 'Chọn tất cả',
                          style: const TextStyle(color: Color(0xFFFF6B00), fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setStateDialog(() => temp.clear()),
                        child: Text(
                          getTranslated('clear', context) ?? 'Bỏ chọn',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white24),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.builder(
                    itemCount: countries.length - 1,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (ctx, i) {
                      final country = countries[i + 1];
                      final checked = temp.contains(country);
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          country.toString(),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[800],
                            fontSize: 15,
                          ),
                        ),
                        value: checked,
                        activeColor: const Color(0xFFFF6B00),
                        checkColor: Colors.white,
                        side: BorderSide(color: Colors.grey.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onChanged: (v) => setStateDialog(() {
                          if (v == true) {
                            temp.add(country);
                          } else {
                            temp.remove(country);
                          }
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                getTranslated('cancel', context) ?? 'Hủy',
                style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600], fontSize: 16),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B00),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                onCountriesChanged(temp);
                Navigator.pop(ctx);
              },
              child: Text(
                getTranslated('confirm', context) ?? 'Xác nhận',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(getTranslated('targeting', context) ?? 'ĐỐI TƯỢNG MỤC TIÊU', isDark),
          const SizedBox(height: 28),

          _glassField(
            controller: locationCtrl,
            label: getTranslated('location', context) ?? 'KHU VỰC HIỂN THỊ',
            hint: getTranslated('enter_city_or_province', context) ?? 'Hà Nội, TP.HCM, Đà Nẵng...',
            icon: Icons.location_on_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 28),

          // Quốc gia
          _glassPicker(
            label: getTranslated('countries', context) ?? 'QUỐC GIA',
            value: selectedCountries.isEmpty
                ? (getTranslated('select_countries', context) ?? 'Chọn quốc gia')
                : '${selectedCountries.length} ${getTranslated('countries_selected', context) ?? 'quốc gia'}',
            icon: Icons.public_rounded,
            onTap: () => _showCountryPicker(context),
            isDark: isDark,
          ),

          // Hiển thị chip các quốc gia đã chọn
          if (selectedCountries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: selectedCountries.take(6).map((c) => Chip(
                label: Text(
                  c.toString(),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFFFF6B00).withOpacity(isDark ? 0.18 : 0.12),
                labelStyle: const TextStyle(color: Color(0xFFFF6B00)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                side: BorderSide(color: const Color(0xFFFF6B00).withOpacity(0.5), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              )).toList(),
            ),
            if (selectedCountries.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${selectedCountries.length - 6} ${getTranslated('more_countries', context) ?? 'quốc gia khác'}',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600], fontSize: 13.5),
                ),
              ),
          ],
          const SizedBox(height: 28),

          // Giới tính
          _glassDropdown(
            label: getTranslated('gender', context) ?? 'GIỚI TÍNH',
            icon: Icons.people_alt_rounded,
            value: gender,
            items: ['Nam', 'Nữ', 'Cả hai'],
            itemLabels: [
              getTranslated('male', context) ?? 'Nam',
              getTranslated('female', context) ?? 'Nữ',
              getTranslated('both', context) ?? 'Cả hai',
            ],
            onChanged: onGenderChanged,
            hint: getTranslated('select_gender', context) ?? 'Chọn giới tính',
            isDark: isDark,
          ),
          const SizedBox(height: 28),

          // Vị trí hiển thị
          _glassDropdown(
            label: getTranslated('placement', context) ?? 'VỊ TRÍ HIỂN THỊ',
            icon: Icons.visibility_rounded,
            value: appears,
            items: _placementOptions.map((e) => e['value']!).toList(),
            itemLabels: _placementOptions.map((e) => getTranslated(e['label']!, context) ?? e['label']!).toList(),
            onChanged: onAppearsChanged,
            hint: getTranslated('select_placement', context) ?? 'Chọn vị trí hiển thị',
            isDark: isDark,
          ),
          const SizedBox(height: 28),

          // Ngân sách
          _glassField(
            controller: budgetCtrl,
            label: getTranslated('budget', context) ?? 'NGÂN SÁCH (₫)',
            hint: '500,000',
            icon: Icons.paid_rounded,
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return getTranslated('required', context);
              final num = int.tryParse(v.replaceAll(RegExp(r'[^\d]'), ''));
              if (num == null || num <= 0) return getTranslated('budget_must_be_positive', context) ?? 'Ngân sách phải lớn hơn 0';
              return null;
            },
            isDark: isDark,
          ),
          const SizedBox(height: 28),

          // Hình thức đấu thầu
          _glassDropdown(
            label: getTranslated('bidding_strategy', context) ?? 'HÌNH THỨC ĐẤU THẦU',
            icon: Icons.trending_up_rounded,
            value: biddingStrategy,
            items: const ['clicks', 'views'],
            itemLabels: [
              getTranslated('bidding_clicks', context) ?? 'Mỗi click',
              getTranslated('bidding_views', context) ?? 'Mỗi lượt hiển thị',
            ],
            onChanged: onBiddingChanged,
            hint: getTranslated('select_bidding', context) ?? 'Chọn hình thức',
            isDark: isDark,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

Widget _sectionTitle(String text, bool isDark) {
  return Text(
    text,
    style: TextStyle(
      color: isDark ? Colors.white70 : Colors.grey[700],
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 2.0,
    ),
  );
}

Widget _glassField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
  int maxLines = 1,
  required bool isDark,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[800], fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? Colors.white.withOpacity(0.09) : Colors.white,
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.08), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[900], fontSize: 16.5),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: const Color(0xFFFF6B00), size: 24),
                hintText: hint,
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[400], fontSize: 15),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              validator: validator,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _glassDropdown({
  required String label,
  required IconData icon,
  required String? value,
  required List<String> items,
  required List<String> itemLabels,
  required Function(String?) onChanged,
  required String hint,
  required bool isDark,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[800], fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isDark ? Colors.white.withOpacity(0.09) : Colors.white,
              border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.2),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              dropdownColor: isDark ? Colors.grey[900] : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.grey[900], fontSize: 16.5),
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white70 : Colors.grey[600], size: 28),
              decoration: InputDecoration(
                prefixIcon: Icon(icon, color: const Color(0xFFFF6B00), size: 24),
                hintText: hint,
                hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
              items: items.asMap().entries.map((e) {
                return DropdownMenuItem(value: e.value, child: Text(itemLabels[e.key]));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ],
  );
}

Widget _glassPicker({
  required String label,
  required String value,
  required IconData icon,
  required VoidCallback onTap,
  required bool isDark,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[800], fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isDark ? Colors.white.withOpacity(0.09) : Colors.white,
                border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.2),
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFFFF6B00), size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.grey[900],
                        fontSize: 16.5,
                        fontWeight: value.contains('Chọn') ? FontWeight.w500 : FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, color: isDark ? Colors.white54 : Colors.grey[500], size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}