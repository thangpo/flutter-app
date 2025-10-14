import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BookingSuccessPage extends StatefulWidget {
  final Map<String, dynamic> bookingInfo;

  const BookingSuccessPage({super.key, required this.bookingInfo});

  @override
  State<BookingSuccessPage> createState() => _BookingSuccessPageState();
}

class _BookingSuccessPageState extends State<BookingSuccessPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Đặt tour thành công', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.teal.shade600, Colors.cyan.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.teal.shade600,
                        size: 80,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        const Text(
                          'Đặt tour thành công!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cảm ơn bạn đã tin tưởng dịch vụ của chúng tôi',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade600, Colors.cyan.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.shade300.withOpacity(0.5),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'MÃ ĐẶT TOUR',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                widget.bookingInfo['code'] ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: widget.bookingInfo['code'] ?? ''),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white),
                                        SizedBox(width: 8),
                                        Text('Đã sao chép mã đặt tour'),
                                      ],
                                    ),
                                    backgroundColor: Colors.teal.shade700,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Vui lòng lưu mã này để tra cứu booking',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildInfoCard(
                    icon: Icons.person,
                    title: 'Thông tin khách hàng',
                    children: [
                      _buildInfoRow(
                        Icons.account_circle,
                        'Họ tên',
                        '${widget.bookingInfo['first_name'] ?? ''} ${widget.bookingInfo['last_name'] ?? ''}',
                      ),
                      _buildInfoRow(
                        Icons.email,
                        'Email',
                        widget.bookingInfo['email'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.phone,
                        'Số điện thoại',
                        widget.bookingInfo['phone'] ?? 'N/A',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  _buildInfoCard(
                    icon: Icons.event_note,
                    title: 'Chi tiết đặt tour',
                    children: [
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Ngày bắt đầu',
                        widget.bookingInfo['start_date'] ?? 'N/A',
                      ),
                      _buildInfoRow(
                        Icons.event,
                        'Ngày kết thúc',
                        widget.bookingInfo['end_date'] ?? 'N/A',
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.people,
                        'Tổng số khách',
                        '${widget.bookingInfo['total_guests'] ?? 'N/A'} người',
                        highlight: true,
                      ),
                      _buildInfoRow(
                        Icons.payments,
                        'Tổng tiền',
                        '${widget.bookingInfo['total'] ?? 'N/A'} ₫',
                        highlight: true,
                        isPrice: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Thông tin chi tiết đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư.',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {

                          },
                          icon: Icon(Icons.receipt_long, color: Colors.teal.shade600),
                          label: const Text('Chi tiết'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.teal.shade600,
                            side: BorderSide(color: Colors.teal.shade300, width: 2),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          icon: const Icon(Icons.home, color: Colors.white),
                          label: const Text('Về trang chủ'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.shade100.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.teal.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade900,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon,
      String label,
      String value, {
        bool highlight = false,
        bool isPrice = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: highlight ? Colors.teal.shade700 : Colors.grey.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isPrice ? 20 : 16,
                    fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                    color: highlight ? Colors.teal.shade700 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}