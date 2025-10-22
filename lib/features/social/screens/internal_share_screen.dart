import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/auth/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class InternalShareScreen extends StatefulWidget {
  final Map<String, dynamic> productData;

  const InternalShareScreen({super.key, required this.productData});

  @override
  State<InternalShareScreen> createState() => _InternalShareScreenState();
}

class _InternalShareScreenState extends State<InternalShareScreen> {
  final TextEditingController descriptionController = TextEditingController();
  bool isLoading = false;
  int currentImageIndex = 0;

  Future<void> shareProduct() async {
    final data = widget.productData;
    setState(() => isLoading = true);

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final accessToken = await authController.authServiceInterface.getSocialAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        _showSnackBar('Token mạng xã hội không hợp lệ, vui lòng đăng nhập lại.', isError: true);
        setState(() => isLoading = false);
        return;
      }

      final String url = 'https://social.vnshop247.com/api/create-product?access_token=$accessToken';
      print('🪪 Gửi yêu cầu tới: $url');

      var request = http.MultipartRequest('POST', Uri.parse(url));

      request.fields['server_key'] = AppConstants.socialServerKey;
      request.fields['product_title'] = data['product_title'] ?? '';
      request.fields['product_category'] = data['product_category']?.toString() ?? '';
      request.fields['product_description'] = descriptionController.text.trim();
      request.fields['product_location'] = data['product_location'] ?? '';
      request.fields['product_price'] = data['product_price']?.toString() ?? '';

      if (data['images'] != null && data['images'] is List) {
        for (String imageUrl in data['images']) {
          File? imageFile = await _downloadFile(imageUrl);
          if (imageFile != null) {
            request.files.add(await http.MultipartFile.fromPath(
              'images[]',
              imageFile.path,
              contentType: MediaType('image', 'jpeg'),
            ));
          }
        }
      }

      final response = await request.send();
      final res = await http.Response.fromStream(response);

      print('📥 Kết quả API: ${res.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(res.body);

        if (responseData['api_status'] == 200 &&
            responseData['product_id'] != null &&
            responseData['product_post_id'] != null) {
          _showSnackBar('Chia sẻ thành công! ID: ${responseData['product_id']}', isSuccess: true);
          Navigator.pop(context, true);
        } else {
          _showSnackBar('API trả về lỗi: ${responseData['errors']?['error_text'] ?? 'Không xác định'}', isError: true);
        }
      } else {
        _showSnackBar('HTTP lỗi ${response.statusCode}: ${res.body}', isError: true);
      }
    } catch (e) {
      _showSnackBar('Lỗi gửi POST: $e', isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false, bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : (isError ? Icons.error : Icons.info),
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green : (isError ? Colors.red : Colors.blue),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<File?> _downloadFile(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;
    final images = data['images'] as List?;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.blue),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Chia sẻ sản phẩm',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image Gallery
            if (images != null && images.isNotEmpty)
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    SizedBox(
                      height: 320,
                      child: PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() => currentImageIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (images.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            images.length,
                                (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: currentImageIndex == index ? 24 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: currentImageIndex == index ? Colors.blue : Colors.blue[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // Product Info Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['product_title'] ?? 'Không có tên',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.attach_money, 'Giá', '${data['product_price']} ₫'),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.store, 'Cửa hàng', data['product_location'] ?? 'Chưa cập nhật'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description Input
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.edit_note, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Thêm mô tả',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Viết mô tả về sản phẩm...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[200]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Share Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isLoading ? null : shareProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.blue[200],
                  shadowColor: Colors.blue.withOpacity(0.3),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.send_rounded, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Đăng chia sẻ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: Colors.blue),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}