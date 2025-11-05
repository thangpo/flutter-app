import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:image_picker/image_picker.dart';

class CreateAdsScreen extends StatefulWidget {
  const CreateAdsScreen({super.key});

  @override
  State<CreateAdsScreen> createState() => _CreateAdsScreenState();
}

class _CreateAdsScreenState extends State<CreateAdsScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  final PageController _pageCtrl = PageController();

  int _currentStep = 0;

  // === DỮ LIỆU CHUNG ===
  File? _mediaFile;
  final _nameCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  final _websiteCtrl = TextEditingController();
  final _pageCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final List<String> _audienceList = [];
  final _audienceCtrl = TextEditingController();
  String? _gender;
  String? _appears;
  final _budgetCtrl = TextEditingController();
  String _bidding = 'CPM';

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _pageCtrl.dispose();
    _locationCtrl.dispose();
    _audienceCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  // === CHỌN ẢNH ===
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() => _mediaFile = File(image.path));
    }
  }

  // === CHỌN NGÀY ===
  Future<void> _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        if (isStart) _startDate = date;
        else _endDate = date;
      });
    }
  }

  // === CHUYỂN BƯỚC ===
  void _next() {
    if (_currentStep < 2) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      _submit();
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _mediaFile != null && _startDate != null && _endDate != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo chiến dịch thành công!'), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng điền đầy đủ'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Hero(
      tag: 'create_ads_button',
      child: Scaffold(
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
              // === TIẾN ĐỘ ===
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => _buildStepIndicator(i)),
                ),
              ),

              // === NỘI DUNG 3 BƯỚC ===
              Expanded(
                child: PageView(
                  controller: _pageCtrl,
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
                      pageCtrl: _pageCtrl,
                      onPickStartDate: () => _pickDate(true),
                      onPickEndDate: () => _pickDate(false),
                      isDark: isDark,
                    ),
                    Step3Widget(
                      locationCtrl: _locationCtrl,
                      audienceList: _audienceList,
                      audienceCtrl: _audienceCtrl,
                      onAddAudience: () {
                        final text = _audienceCtrl.text.trim();
                        if (text.isNotEmpty && !_audienceList.contains(text)) {
                          setState(() {
                            _audienceList.add(text);
                            _audienceCtrl.clear();
                          });
                        }
                      },
                      onRemoveAudience: (i) => setState(() => _audienceList.removeAt(i)),
                      gender: _gender,
                      onGenderChanged: (v) => setState(() => _gender = v),
                      appears: _appears,
                      onAppearsChanged: (v) => setState(() => _appears = v),
                      budgetCtrl: _budgetCtrl,
                      bidding: _bidding,
                      onBiddingChanged: (v) => setState(() => _bidding = v!),
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              // === NÚT ĐIỀU KHIỂN ===
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _prev,
                          child: const Text('Quay lại'),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_currentStep == 2 ? 'TẠO CHIẾN DỊCH' : 'Tiếp theo'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step) {
    final isActive = _currentStep == step;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 32 : 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade700 : Colors.grey.shade400,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ====================================================================
// WIDGET 1: HÌNH ẢNH + TÊN CÔNG TY
// ====================================================================
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
          const Text('Hình ảnh chiến dịch *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.grey[800] : Colors.grey[100],
              ),
              child: mediaFile != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(mediaFile!, fit: BoxFit.cover))
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text('Nhấn để chọn ảnh', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(
              labelText: 'Tên công ty *',
              prefixIcon: const Icon(Icons.business),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
            ),
            validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null,
          ),
        ],
      ),
    );
  }
}

// ====================================================================
// WIDGET 2: NỘI DUNG CHIẾN DỊCH
// ====================================================================
class Step2Widget extends StatelessWidget {
  final TextEditingController headlineCtrl, descCtrl, websiteCtrl, pageCtrl;
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
    required this.pageCtrl,
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
          _buildField(headlineCtrl, 'Tiêu đề chiến dịch *', Icons.title, maxLines: 2),
          _buildField(descCtrl, 'Mô tả chiến dịch *', Icons.description, maxLines: 4),
          _buildDateField('Ngày bắt đầu *', startDate, onPickStartDate),
          _buildDateField('Ngày kết thúc *', endDate, onPickEndDate),
          _buildField(websiteCtrl, 'URL trang web *', Icons.link, keyboardType: TextInputType.url),
          _buildField(pageCtrl, 'Trang của tôi *', Icons.pageview),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {int maxLines = 1, TextInputType? keyboardType}) {
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
          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
        ),
        validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null,
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.calendar_today),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
          ),
          child: Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'Chọn ngày'),
        ),
      ),
    );
  }
}

// ====================================================================
// WIDGET 3: ĐỊA ĐIỂM, ĐỐI TƯỢNG, NGÂN SÁCH...
// ====================================================================
class Step3Widget extends StatelessWidget {
  final TextEditingController locationCtrl, audienceCtrl, budgetCtrl;
  final List<String> audienceList;
  final VoidCallback onAddAudience;
  final Function(int) onRemoveAudience;
  final String? gender, appears;
  final Function(String?) onGenderChanged, onAppearsChanged;
  final String bidding;
  final Function(String) onBiddingChanged;
  final bool isDark;

  const Step3Widget({
    super.key,
    required this.locationCtrl,
    required this.audienceList,
    required this.audienceCtrl,
    required this.onAddAudience,
    required this.onRemoveAudience,
    required this.gender,
    required this.onGenderChanged,
    required this.appears,
    required this.onAppearsChanged,
    required this.budgetCtrl,
    required this.bidding,
    required this.onBiddingChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildField(locationCtrl, 'Địa điểm *', Icons.location_on),
          const SizedBox(height: 16),
          const Text('Đối tượng tiếp cận', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: audienceCtrl,
                  decoration: InputDecoration(
                    hintText: 'VD: Người yêu thời trang',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                  ),
                  onSubmitted: (_) => onAddAudience(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: onAddAudience,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: audienceList.asMap().entries.map((e) {
              return Chip(
                label: Text(e.value),
                backgroundColor: Colors.blue.shade50,
                deleteIconColor: Colors.blue.shade700,
                onDeleted: () => onRemoveAudience(e.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            _buildRadio('Nam', 'male', gender, onGenderChanged),
            _buildRadio('Nữ', 'female', gender, onGenderChanged),
            _buildRadio('Cả hai', 'both', gender, onGenderChanged),
          ]),
          const SizedBox(height: 16),
          const Text('Vị trí hiển thị *', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildDropdown(appears, ['News Feed', 'Stories', 'Reels', 'Tất cả'], onAppearsChanged),
          const SizedBox(height: 16),
          _buildField(budgetCtrl, 'Ngân sách chiến dịch (đ) *', Icons.attach_money, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          const Text('Hình thức đấu thầu', style: TextStyle(fontWeight: FontWeight.bold)),
          _buildDropdown(bidding, ['CPM', 'CPC', 'CPA'], (v) => onBiddingChanged(v!)),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboardType}) {
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
          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
        ),
        validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null,
      ),
    );
  }

  Widget _buildDropdown(String? value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Chọn một mục' : null,
    );
  }

  Widget _buildRadio(String label, String value, String? group, Function(String?) onChanged) {
    return Expanded(
      child: RadioListTile<String>(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 14)),
        value: value,
        groupValue: group,
        onChanged: onChanged,
        activeColor: Colors.blue.shade700,
      ),
    );
  }
}