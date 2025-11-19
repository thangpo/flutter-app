// lib/features/social/screens/family_requests_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_sixvalley_ecommerce/localization/language_constrants.dart';

/// Đơn giản hóa model 1 yêu cầu gia đình.
/// Sau này nếu có API thật thì map JSON -> FamilyRequest là xong.
class FamilyRequest {
  final String requestId; // id bản ghi (nếu có)
  final String userId;
  final String displayName;
  final String userName;
  final String avatarUrl;
  final String relationshipKey;   // vd: "mother", "father"
  final String relationshipLabel; // text đã dịch hiển thị

  FamilyRequest({
    required this.requestId,
    required this.userId,
    required this.displayName,
    required this.userName,
    required this.avatarUrl,
    required this.relationshipKey,
    required this.relationshipLabel,
  });
}

class FamilyRequestsScreen extends StatefulWidget {
  const FamilyRequestsScreen({Key? key}) : super(key: key);

  @override
  State<FamilyRequestsScreen> createState() => _FamilyRequestsScreenState();
}

class _FamilyRequestsScreenState extends State<FamilyRequestsScreen> {
  bool _loading = true;
  bool _error = false;
  List<FamilyRequest> _items = const [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      // TODO: gọi API thật để lấy danh sách yêu cầu gia đình.
      //
      // Ví dụ sau này:
      // final sc = context.read<SocialController>();
      // final items = await sc.fetchFamilyRequests();
      //
      // Tạm thời mock vài item cho dễ test UI, khi nối API chỉ cần
      // thay đoạn dưới bằng dữ liệu thật.

      await Future.delayed(const Duration(milliseconds: 400));

      final mock = <FamilyRequest>[
        // Xoá block mock này khi nối với API thật
        // FamilyRequest(
        //   requestId: '1',
        //   userId: '100',
        //   displayName: 'giangthang99',
        //   userName: 'giangthang99',
        //   avatarUrl: '',
        //   relationshipKey: 'sister',
        //   relationshipLabel: 'Sister',
        // ),
      ];

      setState(() {
        _items = mock;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  Future<void> _handleAction(
      FamilyRequest item, {
        required bool accept,
      }) async {
    // TODO: gọi API accept / reject:
    //
    // if (accept) {
    //   await sc.acceptFamilyRequest(item.requestId);
    // } else {
    //   await sc.rejectFamilyRequest(item.requestId);
    // }
    //
    // Ở đây tạm thời chỉ xoá khỏi list + show SnackBar.

    setState(() {
      _items = _items.where((e) => e.requestId != item.requestId).toList();
    });

    if (!mounted) return;

    final text = accept
        ? (getTranslated('family_request_accepted', context) ??
        'Đã chấp nhận yêu cầu.')
        : (getTranslated('family_request_declined', context) ??
        'Đã từ chối yêu cầu.');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        getTranslated('family_requests_title', context) ?? 'Yêu cầu gia đình';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadRequests,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40),
              const SizedBox(height: 12),
              Text(
                getTranslated('family_requests_error', context) ??
                    'Không tải được danh sách yêu cầu.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadRequests,
                child: Text(
                  getTranslated('retry', context) ?? 'Thử lại',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                getTranslated('family_requests_empty', context) ??
                    'Hiện tại bạn chưa có yêu cầu gia đình nào.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, index) {
        final item = _items[index];
        return _FamilyRequestCard(
          item: item,
          onAccept: () => _handleAction(item, accept: true),
          onReject: () => _handleAction(item, accept: false),
        );
      },
    );
  }
}

class _FamilyRequestCard extends StatelessWidget {
  final FamilyRequest item;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _FamilyRequestCard({
    Key? key,
    required this.item,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage:
                  (item.avatarUrl.isNotEmpty) ? NetworkImage(item.avatarUrl) : null,
                  child: item.avatarUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${item.userName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color
                              ?.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.relationshipLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      getTranslated('family_request_accept', context) ??
                          'Chấp nhận',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      getTranslated('family_request_reject', context) ??
                          'Xóa bỏ',
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
