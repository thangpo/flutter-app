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

  GlobalKey? _imageHeroKey;
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _isTransitioning = false;

  // Animation Controllers
  late AnimationController _shimmerController;

  File? _mediaFile;
  final _nameCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _websiteCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  List<Country> _selectedCountries = [];
  final _audienceCtrl = TextEditingController();
  String? _gender;
  String? _appears;
  final _budgetCtrl = TextEditingController();
  String _biddingStrategy = 'Clicks';
  int _ageFrom = 18;
  int _ageTo = 65;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _locationCtrl.dispose();
    _audienceCtrl.dispose();
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
      final tempFile = File(image.path);
      final GlobalKey heroKey = GlobalKey();

      await Navigator.of(context).push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black.withOpacity(0.9),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, animation, ___) {
            return _ImagePreviewScreen(
              imageFile: tempFile,
              heroKey: heroKey,
              onClose: () => Navigator.of(context).pop(),
            );
          },
        ),
      );

      if (mounted) {
        setState(() {
          _mediaFile = tempFile;
          _imageHeroKey = heroKey;
        });
      }
    }
  }

  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
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
      setState(() => _isTransitioning = true);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ).then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _isTransitioning = false);
          }
        });
      });
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      setState(() => _isTransitioning = true);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      ).then((_) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() => _isTransitioning = false);
          }
        });
      });
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
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
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

      final audienceList = _selectedCountries
          .map((c) => c.value)
          .where((v) => v != "0" && v.isNotEmpty)
          .join(',');
      if (audienceList.isEmpty) throw Exception('Quốc gia không hợp lệ');

      String appearsFixed = _appears ?? 'post';
      if (appearsFixed == 'entire') {
        appearsFixed = 'post';
        debugPrint('⚠️ appears=entire → tự chuyển thành post (ảnh không hỗ trợ entire)');
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
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi tạo chiến dịch: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showError('Lỗi: ${e.toString().replaceAll('Exception: ', '')}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(getTranslated('withdraw', context) ?? 'Tạo chiến dịch'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // iOS 18 Style Liquid Glass Stepper
            _buildIOSGlassStepper(isDark),

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
                    ageFrom: _ageFrom,
                    ageTo: _ageTo,
                    onAgeChanged: (from, to) => setState(() {
                      _ageFrom = from;
                      _ageTo = to;
                    }),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _prev,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.blue.shade700),
                        ),
                        child: const Text('Quay lại'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor: Colors.grey.shade400,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        _currentStep == 2 ? 'TẠO CHIẾN DỊCH' : 'Tiếp theo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSGlassStepper(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // 3 Glass Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _buildGlassPill(index, isDark),
              );
            }),
          ),

          const SizedBox(height: 20),

          // iOS Style Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    width: constraints.maxWidth * ((_currentStep + 1) / 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF007AFF), // iOS Blue
                          const Color(0xFF5856D6), // iOS Purple
                        ],
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

  Widget _buildGlassPill(int index, bool isDark) {
    final isActive = index == _currentStep;
    final isPassed = index < _currentStep;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      width: 56,
      height: 56,
      child: Stack(
        children: [
          // iOS Glass Background with Blur
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isActive
                        ? [
                      const Color(0xFF007AFF).withOpacity(0.25),
                      const Color(0xFF5856D6).withOpacity(0.25),
                    ]
                        : isPassed
                        ? [
                      const Color(0xFF34C759).withOpacity(0.25),
                      const Color(0xFF30D158).withOpacity(0.25),
                    ]
                        : [
                      Colors.white.withOpacity(isDark ? 0.15 : 0.3),
                      Colors.white.withOpacity(isDark ? 0.1 : 0.2),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(isDark ? 0.2 : 0.4),
                    width: 0.5,
                  ),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: const Color(0xFF007AFF).withOpacity(0.4),
                        blurRadius: 16,
                        spreadRadius: 0,
                      ),
                    if (isPassed)
                      BoxShadow(
                        color: const Color(0xFF34C759).withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Shimmer Effect (only active)
          if (isActive)
            ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1 + (_shimmerController.value * 2), -1),
                        end: Alignment(1 + (_shimmerController.value * 2), 1),
                        colors: [
                          Colors.transparent,
                          Colors.white.withOpacity(0.15),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Number/Checkmark
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: isPassed
                  ? const Icon(
                Icons.check_rounded,
                key: ValueKey('check'),
                color: Color(0xFF34C759),
                size: 28,
              )
                  : Text(
                '${index + 1}',
                key: ValueKey('number_$index'),
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF007AFF)
                      : isDark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.6),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Glass Reflection
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 28,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// _ImagePreviewScreen remains the same
class _ImagePreviewScreen extends StatefulWidget {
  final File imageFile;
  final GlobalKey heroKey;
  final VoidCallback onClose;

  const _ImagePreviewScreen({
    required this.imageFile,
    required this.heroKey,
    required this.onClose,
  });

  @override
  State<_ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<_ImagePreviewScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _controller.forward().then((_) {
          widget.onClose();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _controller.forward().then((_) => widget.onClose());
              },
              child: AnimatedBuilder(
                animation: _opacityAnimation,
                builder: (context, child) {
                  return Container(color: Colors.black.withOpacity(0.9 * _opacityAnimation.value));
                },
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Hero(
                      tag: 'selected_ad_image',
                      key: widget.heroKey,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          widget.imageFile,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: GestureDetector(
              onTap: () {
                _controller.forward().then((_) => widget.onClose());
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Step Widgets (copy from your original code)
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hình ảnh chiến dịch *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPickImage,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                  color: mediaFile != null ? Colors.blue.shade700 : Colors.grey.shade400,
                  width: mediaFile != null ? 3 : 2,
                ),
                borderRadius: BorderRadius.circular(20),
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: mediaFile != null
                        ? Colors.blue.shade700.withOpacity(0.4)
                        : Colors.transparent,
                    blurRadius: 25,
                    spreadRadius: 5,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    if (mediaFile != null)
                      AnimatedScale(
                        scale: mediaFile != null ? 1.0 : 0.8,
                        duration: const Duration(milliseconds: 700),
                        curve: Curves.easeOutBack,
                        child: AnimatedOpacity(
                          opacity: mediaFile != null ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          child: Image.file(
                            mediaFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                    if (mediaFile == null)
                      Container(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: 1.2,
                              duration: const Duration(milliseconds: 500),
                              child: Icon(
                                Icons.add_a_photo_outlined,
                                size: 56,
                                color: Colors.blue.shade600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nhấn để chọn ảnh',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'JPG, PNG • Tối đa 5MB • Tỷ lệ đẹp nhất 1:1',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: onPickImage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildTextField(context, nameCtrl, 'Tên công ty *', Icons.business),
        ],
      ),
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController ctrl, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
          ),
        ),
        validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
      ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(context, headlineCtrl, 'Tiêu đề chiến dịch *', Icons.title, maxLines: 2),
          _buildField(context, descCtrl, 'Mô tả chiến dịch *', Icons.description, maxLines: 4),
          _buildDateField(context, 'Ngày bắt đầu *', startDate, onPickStartDate),
          _buildDateField(context, 'Ngày kết thúc *', endDate, onPickEndDate),
          _buildField(context, websiteCtrl, 'URL trang web *', Icons.link, keyboardType: TextInputType.url),
        ],
      ),
    );
  }

  Widget _buildField(
      BuildContext context,
      TextEditingController ctrl,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType? keyboardType,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
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
    );
  }

  Widget _buildDateField(BuildContext context, String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
          ),
          child: Text(
            date != null ? '${date.day}/${date.month}/${date.year}' : 'Chọn ngày',
            style: TextStyle(color: date == null ? Colors.grey : null),
          ),
        ),
      ),
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
  final int ageFrom, ageTo;
  final Function(int, int) onAgeChanged;
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
    required this.ageFrom,
    required this.ageTo,
    required this.onAgeChanged,
    required this.isDark,
  });

  final List<Map<String, String>> placementOptions = const [
    {'value': 'post', 'label': 'Bưu kiện (Định dạng tệp hình ảnh)'},
    {'value': 'sidebar', 'label': 'Thanh bên (Định dạng tệp hình ảnh)'},
    {'value': 'jobs', 'label': 'Việc làm (Định dạng tệp hình ảnh)'},
    {'value': 'forum', 'label': 'Diễn đàn (Định dạng tệp hình ảnh)'},
    {'value': 'movies', 'label': 'Phim (Định dạng tệp hình ảnh)'},
    {'value': 'offer', 'label': 'Lời đề nghị (Định dạng tệp hình ảnh)'},
    {'value': 'funding', 'label': 'Kinh phí (Định dạng tệp hình ảnh)'},
    {'value': 'story', 'label': 'Câu chuyện (Định dạng tệp hình ảnh)'},
  ];

  void _showCountryPicker(BuildContext context) {
    List<Country> temp = List.from(selectedCountries);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Chọn quốc gia'),
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
                      child: const Text('Chọn tất cả'),
                    ),
                    TextButton(
                      onPressed: () {
                        setStateDialog(() => temp.clear());
                      },
                      child: const Text('Bỏ chọn tất cả'),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: countries.length - 1,
                    itemBuilder: (ctx, i) {
                      final country = countries[i + 1];
                      final checked = temp.contains(country);
                      return CheckboxListTile(
                        dense: true,
                        title: Text(country.toString()),
                        value: checked,
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(context, locationCtrl, 'Địa điểm *', Icons.location_on),
          const SizedBox(height: 16),
          const Text('Quốc gia tiếp cận *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showCountryPicker(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.grey[800] : Colors.grey[50],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedCountries.isEmpty
                          ? 'Chọn quốc gia (có thể chọn nhiều)'
                          : '${selectedCountries.length} quốc gia được chọn',
                      style: TextStyle(color: selectedCountries.isEmpty ? Colors.grey[600] : null),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: selectedCountries.map((c) {
              return Chip(
                label: Text(c.toString(), style: const TextStyle(fontSize: 12)),
                backgroundColor: Colors.blue.shade50,
                deleteIconColor: Colors.blue.shade700,
                onDeleted: () {
                  onCountriesChanged(selectedCountries.where((e) => e != c).toList());
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildDropdown(context, gender, ['Nam', 'Nữ', 'Cả hai'], onGenderChanged, hint: 'Chọn giới tính'),
          const SizedBox(height: 16),
          const Text('Vị trí hiển thị *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildPlacementDropdown(context),
          const SizedBox(height: 16),
          _buildField(context, budgetCtrl, 'Ngân sách chiến dịch (đ) *', Icons.attach_money, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          const Text('Hình thức đấu thầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildBiddingDropdown(context),
        ],
      ),
    );
  }

  Widget _buildField(BuildContext context, TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
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
    );
  }

  Widget _buildDropdown(
      BuildContext context,
      String? value,
      List<String> items,
      Function(String?) onChanged, {
        String? hint,
      }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: hint != null ? Text(hint) : null,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildPlacementDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: appears,
      hint: const Text('Chọn vị trí hiển thị'),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: placementOptions.map((item) {
        return DropdownMenuItem(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onAppearsChanged,
      validator: (v) => v == null ? 'Vui lòng chọn vị trí hiển thị' : null,
    );
  }

  Widget _buildBiddingDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: biddingStrategy,
      hint: const Text('Chọn hình thức đấu thầu'),
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: const [
        DropdownMenuItem(value: 'Clicks', child: Text('Clicks (cho mỗi lượt click)')),
        DropdownMenuItem(value: 'Views', child: Text('Views (cho mỗi lần hiển thị)')),
      ],
      onChanged: onBiddingChanged,
      validator: (v) => v == null || v.isEmpty ? 'Vui lòng chọn hình thức đấu thầu' : null,
    );
  }
}