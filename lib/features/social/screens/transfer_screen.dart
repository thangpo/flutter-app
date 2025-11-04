import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/sepay_service.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/social_user_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class TransferScreen extends StatefulWidget {
  final double walletBalance;
  final int userId;
  final String accessToken;

  const TransferScreen({
    super.key,
    required this.walletBalance,
    required this.userId,
    required this.accessToken,
  });

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  late final MobileScannerController _scannerController;
  final TextEditingController _amountController = TextEditingController();
  Map<String, dynamic>? _selectedUser;
  bool _isLoadingFriends = false;
  bool _isLoadingUserInfo = false;
  bool _isTransferring = false;
  bool _isCameraActive = true;
  bool _isProcessing = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  List<dynamic> _followingList = [];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
    );
    _loadFollowingUsers();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowingUsers() async {
    setState(() => _isLoadingFriends = true);

    final sepayService = SepayService();
    final result = await sepayService.getFollowingUsers(
      context: context,
      userId: widget.userId,
      limit: 50,
    );

    if (result != null && result['api_status'] == 200) {
      setState(() {
        _followingList = result['data']['following'] ?? [];
        _isLoadingFriends = false;
      });
    } else {
      setState(() => _isLoadingFriends = false);
      if (mounted) {
        _showSnackBar(
          'Không thể tải danh sách bạn bè',
          Colors.orange,
        );
      }
    }
  }

  Future<void> _loadUserInfoById(int userId) async {
    if (userId == widget.userId) {
      _showSnackBar('Không thể chuyển tiền cho chính mình', Colors.red);
      return;
    }

    setState(() => _isLoadingUserInfo = true);

    try {
      final socialUserService = SocialUserService();
      final userData = await socialUserService.getWalletBalance(
        accessToken: widget.accessToken,
        userId: userId,
      );

      setState(() {
        _selectedUser = {
          'user_id': userData['user_id'] ?? userId.toString(),
          'username': userData['username'] ?? 'Người dùng',
          'avatar': userData['avatar'] ?? '',
          'email': userData['email'] ?? '',
        };
        _isLoadingUserInfo = false;
      });

      _showSnackBar('Đã tải thông tin người nhận', Colors.green);
    } catch (e) {
      setState(() => _isLoadingUserInfo = false);
      _showSnackBar('Không thể tải thông tin người dùng', Colors.red);
    }
  }

  Future<void> _scanQrCode(String code) async {
    final now = DateTime.now();
    if (_lastScannedCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(seconds: 3)) {
      return;
    }

    _lastScannedCode = code;
    _lastScanTime = now;

    setState(() => _isProcessing = true);

    try {
      final userId = int.tryParse(code);
      if (userId != null) {
        await _loadUserInfoById(userId);
      } else {
        _showSnackBar('Mã QR không hợp lệ', Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleCamera() {
    setState(() {
      _isCameraActive = !_isCameraActive;
    });
  }

  void _showFriendSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(Icons.people, color: Colors.purple),
                  SizedBox(width: 12),
                  Text(
                    'Chọn người nhận',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: _isLoadingFriends
                  ? Center(child: CircularProgressIndicator())
                  : _followingList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Chưa có bạn bè',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                controller: scrollController,
                itemCount: _followingList.length,
                itemBuilder: (context, index) {
                  final user = _followingList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(
                        user['avatar'] ?? '',
                      ),
                      onBackgroundImageError: (_, __) {},
                      child: user['avatar'] == null || user['avatar'].isEmpty
                          ? Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      user['username'] ?? 'Không rõ tên',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text('ID: ${user['user_id']}'),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      setState(() => _selectedUser = user);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    required int amount,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(message, style: TextStyle(fontSize: 14)),
              SizedBox(height: 12),
              Text(
                'Số tiền: ${_formatMoney(amount.toDouble())} đ',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.purple),
              ),
              if (_selectedUser != null) ...[
                SizedBox(height: 8),
                Text('Người nhận: ${_selectedUser!['username']}', overflow: TextOverflow.ellipsis),
                Text('ID: ${_selectedUser!['user_id']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
    );
  }

  void _handleTransfer() async {
    if (_isTransferring) return; // Ngăn nhấn nhiều lần

    if (_selectedUser == null) {
      _showSnackBar('Vui lòng chọn người nhận', Colors.orange);
      return;
    }

    final inputText = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(inputText);
    if (amount == null || amount <= 0) {
      _showSnackBar('Vui lòng nhập số tiền hợp lệ', Colors.orange);
      return;
    }

    if (amount > widget.walletBalance) {
      _showSnackBar('Số dư không đủ', Colors.red);
      return;
    }

    final recipientId = int.tryParse(_selectedUser!['user_id'].toString());
    if (recipientId == null) {
      _showSnackBar('ID người nhận không hợp lệ', Colors.red);
      return;
    }

    // BẬT LOADING TOÀN MÀN HÌNH
    setState(() => _isTransferring = true);

    try {
      final sepayService = SepayService();
      final result = await sepayService.sendMoney(
        context: context,
        amount: amount,
        userId: recipientId,
      );

      if (result != null && result['api_status'] == 200) {
        // HIỂN THỊ DIALOG THÀNH CÔNG
        await _showSuccessDialog(
          title: 'Chuyển tiền thành công!',
          message: result['message'] ?? 'Tiền đã được gửi đến ${_selectedUser!['username']}',
          amount: amount,
        );

        // QUAY LẠI WALLET SCREEN + TẢI LẠI DỮ LIỆU
        if (mounted) {
          Navigator.pop(context, true); // true = cần reload
        }
      } else {
        final errorMsg = result?['errors']?['error_text'] ??
            result?['message'] ??
            'Chuyển tiền thất bại. Vui lòng thử lại.';
        _showSnackBar(errorMsg, Colors.red);
      }
    } catch (e) {
      _showSnackBar('Lỗi kết nối: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isTransferring = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTranslated('transfer_money', context) ?? 'Chuyển tiền'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isCameraActive ? Icons.camera_alt : Icons.camera_alt_outlined),
            onPressed: _toggleCamera,
            tooltip: _isCameraActive ? 'Tắt camera' : 'Bật camera',
          ),
          if (_selectedUser != null)
            IconButton(
              icon: Icon(Icons.person_remove),
              onPressed: () {
                setState(() => _selectedUser = null);
                _showSnackBar('Đã xóa người nhận', Colors.blue);
              },
              tooltip: 'Xóa người nhận',
            ),
        ],
      ),
      body: Stack(
        children: [
          // === NỘI DUNG CHÍNH (trong Column) ===
          Column(
            children: [
              // Camera
              if (_isCameraActive)
                Expanded(
                  flex: 2,
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        onDetect: (BarcodeCapture capture) {
                          if (_isProcessing) return;
                          final barcode = capture.barcodes.first;
                          if (barcode.rawValue != null) {
                            _scanQrCode(barcode.rawValue!.trim());
                          }
                        },
                      ),
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white, width: 3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      if (_isProcessing || _isLoadingUserInfo)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(),
                                    SizedBox(height: 16),
                                    Text('Đang xử lý...'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

              // Wallet Info
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey[200],
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.purple),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Số dư khả dụng',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          Text(
                            '${_formatMoney(widget.walletBalance)} đ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Sửa overflow cho ID
                    Flexible(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ID: ${widget.userId}',
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                flex: _isCameraActive ? 1 : 3,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Thông tin chuyển tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),

                      // Card chọn người nhận
                      Card(
                        elevation: 2,
                        child: InkWell(
                          onTap: _showFriendSelectionSheet,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: _selectedUser == null
                                ? Row(
                              children: [
                                Icon(Icons.person_search, color: Colors.grey, size: 40),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Người nhận', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      SizedBox(height: 4),
                                      Text('Chọn từ danh sách bạn bè', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                                    ],
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                              ],
                            )
                                : Row(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: NetworkImage(_selectedUser!['avatar'] ?? ''),
                                  onBackgroundImageError: (_, __) {},
                                  child: _selectedUser!['avatar'] == null || _selectedUser!['avatar'].isEmpty
                                      ? Icon(Icons.person, size: 30)
                                      : null,
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Người nhận', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      SizedBox(height: 4),
                                      Text(
                                        _selectedUser!['username'] ?? 'Không rõ tên',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'ID: ${_selectedUser!['user_id']}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.check_circle, color: Colors.green, size: 24),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Input số tiền
                      Text('Số tiền', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                      SizedBox(height: 8),
                      Card(
                        elevation: 2,
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            hintText: '0',
                            suffixText: 'đ',
                            suffixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          onChanged: (value) {
                            final text = value.replaceAll('.', '');
                            if (text.isNotEmpty) {
                              final formatted = _formatMoney(double.parse(text));
                              _amountController.value = TextEditingValue(
                                text: formatted,
                                selection: TextSelection.collapsed(offset: formatted.length),
                              );
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 24),

                      // Nút chuyển tiền
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isTransferring ? null : _handleTransfer, // Vô hiệu hóa khi đang loading
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 3,
                          ),
                          child: _isTransferring
                              ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Đang xử lý...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          )
                              : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 20),
                              SizedBox(width: 8),
                              Text('Chuyển tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),

                      if (!_isCameraActive) ...[
                        SizedBox(height: 16),
                        Center(
                          child: TextButton.icon(
                            onPressed: _toggleCamera,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Bật camera để quét QR'),
                            style: TextButton.styleFrom(foregroundColor: Colors.purple),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // === LOADING OVERLAY ===
          if (_isTransferring)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                          strokeWidth: 5,
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Đang chuyển tiền...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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

  String _formatMoney(double amount) {
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }
}