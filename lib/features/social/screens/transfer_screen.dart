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

class _TransferScreenState extends State<TransferScreen> with TickerProviderStateMixin {
  MobileScannerController? _scannerController;
  final TextEditingController _amountController = TextEditingController();
  Map<String, dynamic>? _selectedUser;
  bool _isLoadingFriends = false;
  bool _isLoadingUserInfo = false;
  bool _isTransferring = false;
  bool _isCameraActive = false;
  bool _isProcessing = false;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  List<dynamic> _followingList = [];

  late AnimationController _balanceAnimController;
  late AnimationController _buttonAnimController;
  late Animation<double> _balanceScaleAnim;
  late Animation<double> _buttonScaleAnim;

  @override
  void initState() {
    super.initState();
    _balanceAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _balanceScaleAnim = CurvedAnimation(
      parent: _balanceAnimController,
      curve: Curves.elasticOut,
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );

    _balanceAnimController.forward();
    _loadFollowingUsers();
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    _amountController.dispose();
    _balanceAnimController.dispose();
    _buttonAnimController.dispose();
    super.dispose();
  }

  void _initializeCamera() {
    if (_scannerController == null) {
      _scannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
      );
    }
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
        _showSnackBar('Không thể tải danh sách bạn bè', Colors.orange);
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
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle :
              color == Colors.red ? Icons.error : Icons.info,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(16),
      ),
    );
  }

  void _toggleCamera() {
    setState(() {
      _isCameraActive = !_isCameraActive;
      if (_isCameraActive) {
        _initializeCamera();
      } else {
        _scannerController?.dispose();
        _scannerController = null;
      }
    });
  }

  void _showFriendSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.people, color: Colors.white, size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Chọn người nhận',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _isLoadingFriends
                    ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                  ),
                )
                    : _followingList.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
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
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: _followingList.length,
                  itemBuilder: (context, index) {
                    final user = _followingList[index];
                    return Container(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Hero(
                          tag: 'avatar_${user['user_id']}',
                          child: CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(user['avatar'] ?? ''),
                            onBackgroundImageError: (_, __) {},
                            child: user['avatar'] == null || user['avatar'].isEmpty
                                ? Icon(Icons.person, size: 28)
                                : null,
                          ),
                        ),
                        title: Text(
                          user['username'] ?? 'Không rõ tên',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'ID: ${user['user_id']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        trailing: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.purple,
                          ),
                        ),
                        onTap: () {
                          setState(() => _selectedUser = user);
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(Icons.check, color: Colors.white, size: 48),
              ),
              SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                message,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      'Số tiền',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_formatMoney(amount.toDouble())} đ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: Colors.purple,
                      ),
                    ),
                    if (_selectedUser != null) ...[
                      Divider(height: 24),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(_selectedUser!['avatar'] ?? ''),
                            onBackgroundImageError: (_, __) {},
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedUser!['username'],
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'ID: ${_selectedUser!['user_id']}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Hoàn tất',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTransfer() async {
    if (_isTransferring) return;

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

    setState(() => _isTransferring = true);

    try {
      final sepayService = SepayService();
      final result = await sepayService.sendMoney(
        context: context,
        amount: amount,
        userId: recipientId,
      );

      if (result != null && result['api_status'] == 200) {
        await _showSuccessDialog(
          title: 'Chuyển tiền thành công!',
          message: result['message'] ?? 'Tiền đã được gửi đến ${_selectedUser!['username']}',
          amount: amount,
        );
        if (mounted) {
          Navigator.pop(context, true);
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
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple.shade400, Colors.purple.shade700],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
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
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                if (_isCameraActive && _scannerController != null)
                  Container(
                    height: 300,
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          MobileScanner(
                            controller: _scannerController!,
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
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 3),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: IconButton(
                                icon: Icon(Icons.close, color: Colors.white),
                                onPressed: _toggleCamera,
                              ),
                            ),
                          ),
                          if (_isProcessing || _isLoadingUserInfo)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                                      ),
                                      SizedBox(height: 16),
                                      Text('Đang xử lý...'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                ScaleTransition(
                  scale: _balanceScaleAnim,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Số dư khả dụng',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '${_formatMoney(widget.walletBalance)} đ',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'ID: ${widget.userId}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông tin chuyển tiền',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _showFriendSelectionSheet,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: _selectedUser == null
                                    ? Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.person_search,
                                        color: Colors.purple,
                                        size: 32,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Người nhận',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Chọn từ danh sách bạn bè',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                )
                                    : Row(
                                  children: [
                                    Hero(
                                      tag: 'avatar_${_selectedUser!['user_id']}',
                                      child: CircleAvatar(
                                        radius: 30,
                                        backgroundImage: NetworkImage(_selectedUser!['avatar'] ?? ''),
                                        onBackgroundImageError: (_, __) {},
                                        child: _selectedUser!['avatar'] == null || _selectedUser!['avatar'].isEmpty
                                            ? Icon(Icons.person, size: 30)
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Người nhận',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            _selectedUser!['username'] ?? 'Không rõ tên',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'ID: ${_selectedUser!['user_id']}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),

                        Text(
                          'Số tiền',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _amountController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              hintText: '0',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.attach_money, color: Colors.purple, size: 28),
                              suffixText: 'đ',
                              suffixStyle: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade300,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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

                        if (!_isCameraActive)
                          Container(
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade400, Colors.blue.shade600],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _toggleCamera,
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                                      SizedBox(width: 12),
                                      Text(
                                        'Quét mã QR',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        GestureDetector(
                          onTapDown: (_) => _buttonAnimController.forward(),
                          onTapUp: (_) {
                            _buttonAnimController.reverse();
                            if (!_isTransferring) _handleTransfer();
                          },
                          onTapCancel: () => _buttonAnimController.reverse(),
                          child: ScaleTransition(
                            scale: _buttonScaleAnim,
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isTransferring
                                      ? [Colors.grey.shade400, Colors.grey.shade600]
                                      : [Colors.purple.shade400, Colors.purple.shade700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: _isTransferring
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Đang xử lý...',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send_rounded, color: Colors.white, size: 24),
                                  SizedBox(width: 12),
                                  Text(
                                    'Chuyển tiền',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isTransferring)
            Container(
              color: Colors.black54,
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(32),
                  padding: EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade300, Colors.purple.shade500],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 5,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Đang chuyển tiền...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Vui lòng đợi trong giây lát',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
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

  String _formatMoney(double amount) {
    String formatted = amount.toStringAsFixed(0);
    return formatted.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
    );
  }
}