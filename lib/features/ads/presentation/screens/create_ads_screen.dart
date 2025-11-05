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

  final _nameCtrl = TextEditingController();
  final _headlineCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _pageCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();

  File? _mediaFile;
  String? _appears;
  String? _gender;
  String _bidding = 'CPM';
  final List<String> _audienceList = [];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headlineCtrl.dispose();
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _pageCtrl.dispose();
    _locationCtrl.dispose();
    _audienceCtrl.dispose();
    super.dispose();
  }

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

  void _addAudience() {
    final text = _audienceCtrl.text.trim();
    if (text.isNotEmpty && !_audienceList.contains(text)) {
      setState(() {
        _audienceList.add(text);
        _audienceCtrl.clear();
      });
    }
  }

  void _removeAudience(int index) {
    setState(() => _audienceList.removeAt(index));
  }

  void _submit() {
    if (_formKey.currentState!.validate() && _mediaFile != null) {
      // TODO: Gọi API tạo chiến dịch ở đây

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo chiến dịch thành công!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } else if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn hình ảnh'), backgroundColor: Colors.red),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePicker(isDark),
                const SizedBox(height: 20),
                _buildTextField(_nameCtrl, 'Tên công ty *', Icons.business),
                _buildTextField(_headlineCtrl, 'Tiêu đề chiến dịch *', Icons.title, maxLines: 2),
                _buildTextField(_descCtrl, 'Mô tả chiến dịch *', Icons.description, maxLines: 4),
                _buildTextField(_websiteCtrl, 'URL trang web *', Icons.link, keyboardType: TextInputType.url),
                _buildTextField(_pageCtrl, 'Trang của tôi *', Icons.pageview),
                _buildTextField(_locationCtrl, 'Địa điểm *', Icons.location_on),

                const SizedBox(height: 16),
                const Text('Vị trí hiển thị *', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDropdown(
                  value: _appears,
                  items: const ['News Feed', 'Stories', 'Reels', 'Tất cả'],
                  onChanged: (v) => setState(() => _appears = v),
                ),

                const SizedBox(height: 16),
                const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _buildRadio('Nam', ' BH'),
                    _buildRadio('Nữ', 'female'),
                    _buildRadio('Cả hai', 'both'),
                  ],
                ),

                const SizedBox(height: 16),
                const Text('Đối tượng tiếp cận', style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _audienceCtrl,
                        decoration: InputDecoration(
                          hintText: 'VD: Người yêu thời trang',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                        ),
                        onSubmitted: (_) => _addAudience(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addAudience,
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
                  children: _audienceList.asMap().entries.map((e) {
                    return Chip(
                      label: Text(e.value),
                      backgroundColor: Colors.blue.shade50,
                      deleteIconColor: Colors.blue.shade700,
                      onDeleted: () => _removeAudience(e.key),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                const Text('Hình thức đấu thầu', style: TextStyle(fontWeight: FontWeight.bold)),
                _buildDropdown(
                  value: _bidding,
                  items: const ['CPM', 'CPC', 'CPA'],
                  onChanged: (v) => setState(() => _bidding = v!),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 3,
                    ),
                    child: const Text(
                      'TẠO CHIẾN DỊCH',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hình ảnh chiến dịch *', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? Colors.grey[800] : Colors.grey[100],
            ),
            child: _mediaFile != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_mediaFile!, fit: BoxFit.cover),
            )
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
      ],
    );
  }

  Widget _buildTextField(
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
          fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
        ),
        validator: (v) => v!.trim().isEmpty ? 'Bắt buộc' : null,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[50],
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Chọn một mục' : null,
    );
  }

  Widget _buildRadio(String label, String value) {
    return Expanded(
      child: RadioListTile<String>(
        dense: true,
        contentPadding: EdgeInsets.zero,
        title: Text(label, style: const TextStyle(fontSize: 14)),
        value: value,
        groupValue: _gender,
        onChanged: (v) => setState(() => _gender = v),
        activeColor: Colors.blue.shade700,
      ),
    );
  }
}