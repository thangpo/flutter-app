import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';
import 'package:flutter_sixvalley_ecommerce/theme/controllers/theme_controller.dart';
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _balanceScaleAnim = CurvedAnimation(
      parent: _balanceAnimController,
      curve: Curves.easeOut,
    );
    _buttonScaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
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
        _showSnackBar(getTranslated('load_friends_failed', context) ?? 'Không thể tải danh sách bạn bè', const Color(0xFFFF9500));
      }
    }
  }

  Future<void> _loadUserInfoById(int userId) async {
    if (userId == widget.userId) {
      _showSnackBar(getTranslated('cannot_self_transfer', context) ?? 'Không thể chuyển tiền cho chính mình', const Color(0xFFFF3B30));
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

      _showSnackBar(getTranslated('receiver_info_loaded', context) ?? 'Đã tải thông tin người nhận', const Color(0xFF34C759));
    } catch (e) {
      setState(() => _isLoadingUserInfo = false);
      _showSnackBar(getTranslated('load_user_failed', context) ?? 'Không thể tải thông tin người dùng', const Color(0xFFFF3B30));
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
        _showSnackBar(getTranslated('invalid_qr_code', context) ?? 'Mã QR không hợp lệ', const Color(0xFFFF3B30));
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
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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


  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeController>(context);
    final isDark = theme.darkTheme;
    final Color backgroundColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final Color cardColor = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final Color textSecondary = isDark ? Colors.white70 : const Color(0xFF8E8E93);
    final Color textHint = isDark ? Colors.white54 : const Color(0xFFD1D1D6);
    final Color dividerColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E5EA);
    final Color shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05);
    final Color primaryColor = const Color(0xFF007AFF);

    void showFriendSelectionSheet() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(2.5)),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          getTranslated('select_recipient', context) ?? 'Chọn người nhận',
                          style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(color: dividerColor, borderRadius: BorderRadius.circular(16)),
                          child: Icon(Icons.close, size: 18, color: textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoadingFriends
                      ? Center(child: CircularProgressIndicator(color: primaryColor))
                      : _followingList.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: textHint),
                        SizedBox(height: 12),
                        Text(
                          getTranslated('no_friends', context) ?? 'Chưa có bạn bè',
                          style: TextStyle(color: textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _followingList.length,
                    itemBuilder: (_, index) {
                      final user = _followingList[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(14)),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedUser = user);
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: dividerColor,
                                    backgroundImage: user['avatar']?.isNotEmpty == true ? NetworkImage(user['avatar']) : null,
                                    child: user['avatar']?.isEmpty ?? true ? Icon(Icons.person, size: 24, color: textSecondary) : null,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user['username'] ?? getTranslated('unknown_name', context) ?? 'Không rõ tên',
                                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16),
                                        ),
                                        Text('ID: ${user['user_id']}', style: TextStyle(color: textSecondary, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right, size: 20, color: textHint),
                                ],
                              ),
                            ),
                          ),
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

    Future<void> showSuccessDialog({
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34C759).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, color: Color(0xFF34C759), size: 48),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(color: textSecondary, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text('Số tiền', style: TextStyle(fontSize: 13, color: textSecondary)),
                      const SizedBox(height: 4),
                      Text('${_formatMoney(amount.toDouble())} đ', style: TextStyle(color: primaryColor, fontSize: 28, fontWeight: FontWeight.w700)),
                      if (_selectedUser != null) ...[
                        const Divider(height: 24, color: Colors.transparent),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: dividerColor,
                              backgroundImage: _selectedUser!['avatar']?.isNotEmpty == true
                                  ? NetworkImage(_selectedUser!['avatar'])
                                  : null,
                              child: _selectedUser!['avatar']?.isEmpty ?? true
                                  ? Icon(Icons.person, size: 20, color: textSecondary)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedUser!['username'], style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
                                  Text('ID: ${_selectedUser!['user_id']}', style: TextStyle(color: textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(getTranslated('done', context) ?? 'Hoàn tất'),
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
        _showSnackBar(getTranslated('select_receiver_prompt', context) ?? 'Vui lòng chọn người nhận', const Color(0xFFFF9500));
        return;
      }

      final inputText = _amountController.text.replaceAll('.', '');
      final amount = int.tryParse(inputText);
      if (amount == null || amount <= 0) {
        _showSnackBar(getTranslated('invalid_amount', context) ?? 'Vui lòng nhập số tiền hợp lệ', const Color(0xFFFF9500));
        return;
      }

      if (amount > widget.walletBalance) {
        _showSnackBar(getTranslated('insufficient_balance_error', context) ?? 'Số dư không đủ', const Color(0xFFFF3B30));
        return;
      }

      final recipientId = int.tryParse(_selectedUser!['user_id'].toString());
      if (recipientId == null) {
        _showSnackBar(getTranslated('invalid_recipient', context) ?? 'ID người nhận không hợp lệ', const Color(0xFFFF3B30));
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
          await showSuccessDialog(
            title: getTranslated('success', context) ?? 'Chuyển tiền thành công!',
            message: result['message'] ?? '${getTranslated('money_sent_to', context)} ${_selectedUser!['username']}',
            amount: amount,
          );
          if (mounted) {
            Navigator.pop(context, true);
          }
        } else {
          final errorMsg = result?['errors']?['error_text'] ??
              result?['message'] ??
              getTranslated('transfer_failed', context) ?? 'Chuyển tiền thất bại. Vui lòng thử lại.';
          _showSnackBar(errorMsg, const Color(0xFFFF3B30));
        }
      } catch (e) {
        final errorText = getTranslated('connection_error', context);
        _showSnackBar('$errorText: $e', const Color(0xFFFF3B30));
      } finally {
        if (mounted) {
          setState(() => _isTransferring = false);
        }
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          getTranslated('transfer_money', context) ?? 'Chuyển tiền',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: backgroundColor,
        foregroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_selectedUser != null)
            IconButton(
              icon: const Icon(Icons.person_remove_outlined, size: 22),
              onPressed: () {
                setState(() => _selectedUser = null);
                _showSnackBar(getTranslated('receiver_deleted', context) ?? 'Đã xóa người nhận', const Color(0xFF007AFF));
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              if (_isCameraActive && _scannerController != null)
                Container(
                  height: 280,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
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
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor, width: 3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: _toggleCamera,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
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
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Color(0xFF007AFF),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      getTranslated('processing', context) ?? 'Đang xử lý...',
                                      style: TextStyle(color: textPrimary, fontSize: 15, fontWeight: FontWeight.w500),
                                    ),
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
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.account_balance_wallet_outlined, color: primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getTranslated('available_balance', context) ?? 'Số dư khả dụng',
                              style: TextStyle(fontSize: 13, color: textSecondary, letterSpacing: -0.2),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatMoney(widget.walletBalance)} đ',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFF2F2F7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ID: ${widget.userId}',
                          style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: showFriendSelectionSheet,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: _selectedUser == null
                                  ? Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.person_add_outlined,
                                      color: Color(0xFF007AFF),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslated('recipient', context) ?? 'Người nhận',
                                          style: TextStyle(color: textSecondary, fontSize: 13),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          getTranslated('select_from_list', context) ?? 'Chọn từ danh sách',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: -0.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: Color(0xFFD1D1D6),
                                  ),
                                ],
                              )
                                  : Row(
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFFE5E5EA),
                                    backgroundImage: _selectedUser!['avatar'] != null && _selectedUser!['avatar'].isNotEmpty
                                        ? NetworkImage(_selectedUser!['avatar'])
                                        : null,
                                    child: _selectedUser!['avatar'] == null || _selectedUser!['avatar'].isEmpty
                                        ? const Icon(Icons.person, size: 24, color: Color(0xFF8E8E93))
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          getTranslated('recipient', context) ?? 'Người nhận',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _selectedUser!['username'] ?? getTranslated('unknown_name', context) ?? 'Không rõ tên',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            letterSpacing: -0.3,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'ID: ${_selectedUser!['user_id']}',
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF34C759),
                                    size: 24,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.attach_money,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    getTranslated('amount', context) ?? 'Số tiền',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.3,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                  letterSpacing: -0.5,
                                ),
                                decoration: InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    color: textHint,
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  suffixText: 'đ',
                                  suffixStyle: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: textSecondary,
                                  ),
                                  contentPadding: EdgeInsets.zero,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!_isCameraActive)
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: primaryColor.withOpacity(isDark ? 0.2 : 0.1), blurRadius: 10, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _toggleCamera,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.qr_code_scanner, color: primaryColor, size: 22),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      getTranslated('scan_qr_code', context) ?? 'Quét mã QR',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primaryColor),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: _isTransferring
                                  ? const Color(0xFFD1D1D6)
                                  : const Color(0xFF007AFF),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: _isTransferring
                                  ? []
                                  : [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isTransferring
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  getTranslated('processing', context) ?? 'Đang xử lý...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  getTranslated('transfer_money', context) ?? 'Chuyển tiền',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (_isTransferring)
            Container(
              color: Colors.black.withOpacity(isDark ? 0.7 : 0.4),
              child: Center(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Center(child: CircularProgressIndicator(color: primaryColor, strokeWidth: 3)),
                      ),
                      const SizedBox(height: 20),
                      Text(getTranslated('transferring', context) ?? 'Đang chuyển tiền...', style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(getTranslated('please_wait', context) ?? 'Vui lòng đợi trong giây lát', style: TextStyle(color: textSecondary, fontSize: 14)),
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