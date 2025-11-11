//branch huydev
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/social_chat_repository.dart';

class SocialChatController extends GetxController {
  final SocialChatRepository repo;
  SocialChatController(this.repo);

  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final isPolling = false.obs;

  /// Luôn giữ invariant: messages sắp xếp **tăng dần theo id**
  /// => tin mới nhất nằm **dưới cùng**
  final messages = <Map<String, dynamic>>[].obs;

  String? _token;
  String? _peerId;

  // incremental state
  int? _lastId; // id lớn nhất đã có (đang ở tail)
  bool _fetching = false;
  bool _fetchingMore = false;

  // polling
  Timer? _pollTimer;
  Duration _pollInterval = const Duration(seconds: 7);
  int _pollErrorCount = 0;

  // debounce read
  Timer? _readDebounce;

  // ===== Public API =====

  Future<void> loadMessages(String token, String peerUserId) async {
    _token = token;
    _peerId = peerUserId;

    // reset thread state
    _stopPolling();
    _lastId = null;
    messages.clear();

    isLoading.value = true;
    try {
      final list = await repo.getUserMessages(
        token: token,
        peerUserId: peerUserId,
        limit: 25,
      );

      // Sắp xếp tăng dần theo id
      list.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
      messages.assignAll(list);

      _updateLastIdFromTail();
      _debouncedMarkRead();
      _startPolling();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (_fetchingMore || isLoadingMore.value) return;
    if (_token == null || _peerId == null) return;
    if (messages.isEmpty) return;

    _fetchingMore = true;
    isLoadingMore.value = true;
    try {
      final beforeId = _msgIdStr(messages.first);
      if (beforeId.isEmpty) return;

      final older = await repo.getUserMessages(
        token: _token!,
        peerUserId: _peerId!,
        beforeMessageId: beforeId,
        limit: 25,
      );
      if (older.isEmpty) return;

      // Incoming đã cũ -> sort tăng dần
      older.sort((a, b) => _msgId(a).compareTo(_msgId(b)));

      // Prepend mà KHÔNG re-sort toàn bộ list
      _mergeIncoming(older, toTail: false);
      // _lastId không đổi khi prepend
    } finally {
      isLoadingMore.value = false;
      _fetchingMore = false;
    }
  }

  Future<void> sendMessage(String token, String peerUserId, String text) async {
    final m = await repo.sendMessage(
      token: token,
      peerUserId: peerUserId,
      text: text,
    );
    if (m != null) {
      _mergeIncoming([m], toTail: true);
      _updateLastIdFromTail();
      _debouncedMarkRead();
    }
  }

  Future<void> sendGif(String token, String peerUserId, String gifUrl) async {
    final m = await repo.sendMessage(
      token: token,
      peerUserId: peerUserId,
      gifUrl: gifUrl,
    );
    if (m != null) {
      _mergeIncoming([m], toTail: true);
      _updateLastIdFromTail();
      _debouncedMarkRead();
    }
  }

  Future<void> sendFile(
      String token, String peerUserId, String filePath) async {
    final m = await repo.sendMessage(
      token: token,
      peerUserId: peerUserId,
      filePath: filePath,
    );
    if (m != null) {
      _mergeIncoming([m], toTail: true);
      _updateLastIdFromTail();
      _debouncedMarkRead();
    }
  }

  // ===== Internal =====

  void _startPolling() {
    _stopPolling();
    _pollErrorCount = 0;
    isPolling.value = true;

    _pollTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
  }

  void _stopPolling() {
    isPolling.value = false;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _pollOnce() async {
    if (_fetching) return;
    if (_token == null || _peerId == null) return;

    _fetching = true;
    try {
      final fresh = await repo.getUserMessages(
        token: _token!,
        peerUserId: _peerId!,
        limit: 25,
        afterMessageId: _lastId == null ? null : _lastId!.toString(),
      );

      if (fresh.isNotEmpty) {
        // Tin mới -> sort tăng dần
        fresh.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
        _mergeIncoming(fresh, toTail: true);
        _updateLastIdFromTail();
        _debouncedMarkRead();
      }

      // reset backoff
      _pollErrorCount = 0;
      _ensurePollInterval(const Duration(seconds: 7));
    } catch (_) {
      _pollErrorCount++;
      if (_pollErrorCount >= 3) {
        _ensurePollInterval(const Duration(seconds: 12));
      }
    } finally {
      _fetching = false;
    }
  }

  void _ensurePollInterval(Duration want) {
    if (_pollInterval == want) return;
    _pollInterval = want;
    if (_pollTimer != null) {
      _startPolling(); // restart với interval mới
    }
  }

  void _updateLastIdFromTail() {
    if (messages.isEmpty) {
      _lastId = null;
      return;
    }
    // Do luôn giữ tăng dần theo id, phần tử cuối là id lớn nhất
    final tail = messages.last;
    final lid = _msgId(tail);
    if (lid > 0) _lastId = lid;
  }

  /// Gộp tin mới mà **không phá vỡ** thứ tự đang có.
  /// - toTail = true  : append vào cuối nếu tất cả `incoming.id > currentMaxId`,
  ///                    ngược lại fallback về merge + sort cục bộ.
  /// - toTail = false : prepend vào đầu nếu tất cả `incoming.id < currentMinId`,
  ///                    ngược lại fallback về merge + sort cục bộ.
  void _mergeIncoming(List<Map<String, dynamic>> incoming,
      {required bool toTail}) {
    if (incoming.isEmpty) return;

    final existIds = messages.map(_msgIdStr).where((e) => e.isNotEmpty).toSet();

    // lọc trùng id/null id
    final filtered = <Map<String, dynamic>>[];
    for (final m in incoming) {
      final id = _msgIdStr(m);
      if (id.isEmpty || existIds.contains(id)) continue;
      filtered.add(m);
    }
    if (filtered.isEmpty) return;

    // Nếu list đang rỗng, gán luôn
    if (messages.isEmpty) {
      messages
          .assignAll(filtered..sort((a, b) => _msgId(a).compareTo(_msgId(b))));
      return;
    }

    final currentMin = _msgId(messages.first);
    final currentMax = _msgId(messages.last);

    final incMin = _msgId(filtered.first);
    final incMax = _msgId(filtered.last);

    if (toTail) {
      // Case thường: fresh/push => mọi id đều > currentMax
      if (incMin > currentMax) {
        messages.addAll(filtered);
        // Không sort lại: giữ invariant tăng dần vì incoming đã tăng dần
        return;
      }
    } else {
      // Case loadMore: older => mọi id đều < currentMin
      if (incMax < currentMin) {
        messages.insertAll(0, filtered);
        // Không sort lại
        return;
      }
    }

    // Fallback hiếm: có id chen giữa (do API trả không chuẩn)
    // -> gộp và sort 1 lần để tái lập invariant
    messages.addAll(filtered);
    messages.sort((a, b) => _msgId(a).compareTo(_msgId(b)));
  }

  void _debouncedMarkRead() {
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 600), () async {
      if (_token == null || _peerId == null) return;
      try {
        await repo.readChats(token: _token!, peerUserId: _peerId!);
      } catch (_) {}
    });
  }

  int _msgId(Map<String, dynamic> m) => int.tryParse(_msgIdStr(m)) ?? 0;
  String _msgIdStr(Map<String, dynamic> m) =>
      '${m['id'] ?? m['message_id'] ?? m['msg_id'] ?? ''}';

  // time chỉ dùng khi cần, nhưng thứ tự chuẩn theo id
  int _msgTime(Map<String, dynamic> m) =>
      int.tryParse('${m['time'] ?? m['timestamp'] ?? '0'}') ?? 0;

  // ===== Lifecycle =====

  @override
  void onClose() {
    _stopPolling();
    _readDebounce?.cancel();
    super.onClose();
  }
}
