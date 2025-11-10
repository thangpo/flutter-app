import 'dart:convert';

import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_comment.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_live_comments_page.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_user.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:http/http.dart' as http;

class SocialLiveRepository {
  final String apiBaseUrl;
  final String serverKey;

  const SocialLiveRepository({
    required this.apiBaseUrl,
    required this.serverKey,
  });

  Future<Map<String, dynamic>> createLive({
    required String accessToken,
    required String streamName,
    String token = '',
  }) async {
    final Uri url = Uri.parse(
      '$apiBaseUrl${AppConstants.socialLiveUri}?access_token=$accessToken',
    );

    final http.Response response = await http.post(url, body: {
      'server_key': serverKey,
      'type': 'create',
      'stream_name': streamName,
      'token': token,
    });

    final Map<String, dynamic> body = _requireOk(
      response,
      defaultMessage: 'Failed to create live stream.',
    );

    final Object? postData = body['post_data'] ?? body['data'];
    if (postData is Map<String, dynamic>) {
      return Map<String, dynamic>.from(postData);
    }
    if (postData is Map) {
      return postData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    throw Exception('Live API response is missing post_data.');
  }

  Future<SocialLiveCommentsPage> fetchLiveComments({
    required String accessToken,
    required String postId,
    String? offset,
    int limit = 25,
    String page = 'live',
  }) async {
    final String trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) {
      throw Exception('postId is required to fetch live comments.');
    }

    final Uri url = Uri.parse(
      '$apiBaseUrl${AppConstants.socialLiveUri}?access_token=$accessToken',
    );

    final Map<String, String> payload = <String, String>{
      'server_key': serverKey,
      'type': 'check_comments',
      'post_id': trimmedPostId,
      'page': page,
      'limit': limit.toString(),
    };
    final String? normalizedOffset = _normalizeString(offset);
    if (normalizedOffset != null && normalizedOffset.isNotEmpty) {
      payload['offset'] = normalizedOffset;
    }

    final http.Response response = await http.post(url, body: payload);
    final Map<String, dynamic> body = _requireOk(
      response,
      defaultMessage: 'Failed to load live comments.',
    );

    final List<SocialComment> comments = <SocialComment>[];
    final Set<String> seenIds = <String>{};

    final List<dynamic> candidates = <dynamic>[
      body['comments'],
      body['comments_data'],
      body['comment_data'],
      body['post_comments'],
      body['data'],
    ];

    for (final dynamic candidate in candidates) {
      _collectComments(candidate, comments, seenIds);
    }

    if (body['data'] is Map<String, dynamic>) {
      final Map<String, dynamic> dataMap = body['data'] as Map<String, dynamic>;
      _collectComments(dataMap['comments'], comments, seenIds);
      _collectComments(dataMap['data'], comments, seenIds);
    }

    comments.sort((SocialComment a, SocialComment b) {
      final DateTime? at = a.createdAt;
      final DateTime? bt = b.createdAt;
      if (at != null && bt != null) {
        return at.compareTo(bt);
      }
      return a.id.compareTo(b.id);
    });

    final String? nextOffset = _determineNextOffset(body, comments);
    final String? resourceId = _normalizeString(
      body['resourceId'] ??
          body['resource_id'] ??
          (body['data'] is Map
              ? (body['data'] as Map)['resourceId'] ??
                  (body['data'] as Map)['resource_id']
              : null),
    );
    final String? sid = _normalizeString(
      body['sid'] ??
          body['session_id'] ??
          (body['data'] is Map
              ? (body['data'] as Map)['sid'] ??
                  (body['data'] as Map)['session_id']
              : null),
    );

    final List<String> fileList = _extractFileList(body);
    final int? viewerCount = _coerceInt(body['count']);
    final String? statusWord = _normalizeString(body['word']);
    final bool? isLive = () {
      final String? normalized = _normalizeString(body['still_live']);
      if (normalized == null) return null;
      final String lower = normalized.toLowerCase();
      if (lower == 'live' || lower == 'online') return true;
      if (lower == 'offline') return false;
      final int? numeric = _coerceInt(normalized);
      if (numeric != null) {
        if (numeric == 1) return true;
        if (numeric == 0) return false;
      }
      return null;
    }();

    final List<SocialUser> joinedUsers = _mergeUsers(<dynamic>[
      body['joined'],
      body['joined_data'],
      if (body['data'] is Map) (body['data'] as Map)['joined'],
      if (body['data'] is Map) (body['data'] as Map)['joined_data'],
    ]);
    final List<SocialUser> leftUsers = _mergeUsers(<dynamic>[
      body['left'],
      body['left_data'],
      if (body['data'] is Map) (body['data'] as Map)['left'],
      if (body['data'] is Map) (body['data'] as Map)['left_data'],
    ]);

    return SocialLiveCommentsPage(
      comments: comments,
      nextOffset: nextOffset,
      resourceId: resourceId,
      sid: sid,
      fileList: fileList,
      viewerCount: viewerCount,
      isLive: isLive,
      statusWord: statusWord,
      joinedUsers: joinedUsers,
      leftUsers: leftUsers,
    );
  }

  Future<Map<String, dynamic>?> endLive({
    required String accessToken,
    required String postId,
    bool permanentlyDelete = false,
  }) async {
    final String trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) {
      return null;
    }

    final Uri url = Uri.parse(
      '$apiBaseUrl${AppConstants.socialLiveUri}?access_token=$accessToken',
    );

    final Map<String, String> payload = <String, String>{
      'server_key': serverKey,
      'type': permanentlyDelete ? 'delete' : 'end',
      'post_id': trimmedPostId,
    };

    final http.Response response = await http.post(url, body: payload);

    final Map<String, dynamic> body = _requireOk(
      response,
      defaultMessage: permanentlyDelete
          ? 'Failed to delete live stream.'
          : 'Failed to end live stream.',
    );

    if (permanentlyDelete) {
      return null;
    }

    Map<String, dynamic>? result;
    final Object? postData = body['post_data'] ?? body['data'];
    if (postData is Map<String, dynamic>) {
      result = Map<String, dynamic>.from(postData);
    } else if (postData is Map) {
      result = postData.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }

    if (body.containsKey('recording_saved')) {
      result ??= <String, dynamic>{};
      result['recording_saved'] = _isTruthy(body['recording_saved']);
    }

    return result;
  }

  Future<void> deleteLive({
    required String accessToken,
    required String postId,
  }) async {
    await endLive(
      accessToken: accessToken,
      postId: postId,
      permanentlyDelete: true,
    );
  }

  Future<void> createLiveThumbnail({
    required String accessToken,
    required String postId,
    required String thumb,
  }) async {
    final String trimmedPostId = postId.trim();
    if (trimmedPostId.isEmpty) {
      throw Exception('postId is required to create live thumbnail.');
    }

    final Uri url = Uri.parse(
      '$apiBaseUrl${AppConstants.socialLiveUri}?access_token=$accessToken',
    );

    final http.Response response = await http.post(url, body: {
      'server_key': serverKey,
      'type': 'create_thumb',
      'post_id': trimmedPostId,
      'thumb': thumb,
    });

    _requireOk(
      response,
      defaultMessage: 'Failed to create live thumbnail.',
    );
  }

  Future<Map<String, dynamic>?> generateAgoraToken({
    required String accessToken,
    required String channelName,
    required int uid,
    String role = 'publisher',
  }) async {
    final List<String> endpoints = <String>{
      AppConstants.socialGenerateAgoraTokenUri,
      if (AppConstants.socialGenerateAgoraTokenUri != '/api/agora')
        '/api/agora',
    }.toList();

    Exception? lastError;
    for (final String path in endpoints) {
      try {
        final Map<String, dynamic>? body = await _requestAgoraToken(
          path: path,
          accessToken: accessToken,
          channelName: channelName,
          uid: uid,
          role: role,
        );
        if (body != null) {
          return body;
        }
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
      }
    }

    if (lastError != null) {
      throw lastError;
    }

    return null;
  }

  Future<Map<String, dynamic>?> _requestAgoraToken({
    required String path,
    required String accessToken,
    required String channelName,
    required int uid,
    required String role,
  }) async {
    final Uri url = Uri.parse('$apiBaseUrl$path?access_token=$accessToken');

    final Map<String, String> payload = <String, String>{
      'server_key': serverKey,
      'channelName': channelName,
      'uid': uid.toString(),
      'role': role,
      'type': 'create',
    };

    final http.Response response = await http.post(url, body: payload);
    if (response.statusCode != 200) {
      throw Exception(
        'generate_agora_token returned status ${response.statusCode} for $path',
      );
    }

    final Map<String, dynamic>? body = _extractJsonBody(response.body);
    if (body == null) {
      throw Exception(
        'generate_agora_token returned invalid response payload.',
      );
    }

    final int? status =
        _coerceInt(body['api_status'] ?? body['status'] ?? body['code']);
    if (status != null && status != 200) {
      final String message =
          _extractError(body) ?? 'generate_agora_token failed.';
      throw Exception(message);
    }

    return body;
  }

  Map<String, dynamic> _requireOk(
    http.Response response, {
    String defaultMessage = 'Live API request failed.',
  }) {
    if (response.statusCode != 200) {
      throw Exception('Live API returned status ${response.statusCode}');
    }
    final Map<String, dynamic>? body = _extractJsonBody(response.body);
    if (body == null) {
      throw Exception('Live API returned invalid response payload.');
    }
    final int status = _coerceInt(body['api_status'] ?? body['status']) ?? 0;
    if (status != 200) {
      final String message = _extractError(body) ?? defaultMessage;
      throw Exception(message);
    }
    return body;
  }

  Map<String, dynamic>? _extractJsonBody(String rawBody) {
    final int start = rawBody.indexOf('{');
    final int end = rawBody.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      return null;
    }
    final String slice = rawBody.substring(start, end + 1);
    final dynamic decoded = json.decode(slice);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  String? _extractError(Map<String, dynamic> body) {
    final String? apiText = _normalizeString(body['api_text']);
    if (apiText != null && apiText.isNotEmpty) {
      return apiText;
    }
    final dynamic errors = body['errors'];
    if (errors is Map) {
      final Object? text =
          errors['error_text'] ?? errors['text'] ?? errors['message'];
      final String? normalized = _normalizeString(text);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    } else if (errors != null) {
      final String? normalized = _normalizeString(errors);
      if (normalized != null && normalized.isNotEmpty) {
        return normalized;
      }
    }
    final String? message = _normalizeString(body['message'] ?? body['msg']);
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return null;
  }

  void _collectComments(
    dynamic candidate,
    List<SocialComment> output,
    Set<String> seenIds,
  ) {
    if (candidate == null) return;

    if (candidate is List) {
      for (final dynamic item in candidate) {
        _collectComments(item, output, seenIds);
      }
      return;
    }

    if (candidate is Map) {
      final Map<String, dynamic> map = candidate is Map<String, dynamic>
          ? candidate
          : Map<String, dynamic>.from(candidate);

      if (_looksLikeComment(map)) {
        final SocialComment? comment = _parseComment(map);
        if (comment != null && !seenIds.contains(comment.id)) {
          seenIds.add(comment.id);
          output.add(comment);
        }
      } else {
        for (final dynamic value in map.values) {
          if (value is Map || value is List) {
            _collectComments(value, output, seenIds);
          }
        }
      }
    }
  }

  SocialComment? _parseComment(Map<String, dynamic> map) {
    final String? id = _normalizeString(
      map['comment_id'] ??
          map['id'] ??
          map['cid'] ??
          map['c_id'] ??
          map['post_id'],
    );
    if (id == null || id.isEmpty) return null;

    final String? text = _normalizeString(
      map['text'] ??
          map['comment'] ??
          map['content'] ??
          map['comment_text'] ??
          map['val'] ??
          map['value'],
    );

    final Map<String, dynamic>? publisher = _pickPublisher(map);
    final String? userName = _normalizeString(
          map['username'] ??
              map['user_name'] ??
              map['author_name'] ??
              publisher?['name'] ??
              publisher?['username'],
        ) ??
        _normalizeString(map['publisher_name']);
    final String? avatar = _normalizeMediaUrl(
      map['avatar'] ??
          map['comment_user_avatar'] ??
          publisher?['avatar'] ??
          publisher?['avatar_full'],
    );
    final String? userId = _normalizeString(
      map['user_id'] ??
          map['uid'] ??
          map['userId'] ??
          publisher?['user_id'] ??
          publisher?['id'],
    );

    final String? timeText = _normalizeString(
      map['time_text'] ??
          map['time_ago'] ??
          map['time_string'] ??
          map['time_formatted'] ??
          map['time_elapsed'] ??
          map['time'],
    );

    DateTime? createdAt;
    final int? timeInt = _coerceInt(
      map['time'] ?? map['time_unix'] ?? map['time_epoch'] ?? map['timestamp'],
    );
    if (timeInt != null) {
      createdAt = _epochToDateTime(timeInt);
    }

    final Map<String, dynamic>? reaction =
        _asMap(map['reaction'] ?? map['reactions']);
    final int reactionCount = _coerceInt(
          reaction?['count'] ??
              reaction?['total'] ??
              map['reaction_count'] ??
              map['like_count'] ??
              map['likes'],
        ) ??
        0;
    String myReaction = '';
    if (reaction != null) {
      if (_isTruthy(reaction['is_reacted'] ?? reaction['is_liked'])) {
        myReaction =
            _normalizeString(reaction['type'] ?? reaction['reaction']) ?? '';
      } else if (reaction['type'] != null) {
        myReaction = reaction['type'].toString();
      }
    }

    final int? repliesCount = _coerceInt(
      map['replies_count'] ?? map['reply_count'] ?? map['replies'],
    );

    final String? imageUrl = _normalizeMediaUrl(
      map['c_file'] ?? map['image'] ?? map['comment_image'],
    );
    final String? audioUrl = _normalizeMediaUrl(
      map['c_file_audio'] ?? map['audio'] ?? map['voice'],
    );

    return SocialComment(
      id: id,
      userId: userId,
      text: text,
      userName: userName,
      userAvatar: avatar,
      timeText: timeText,
      repliesCount: repliesCount,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      reactionCount: reactionCount,
      myReaction: myReaction,
      createdAt: createdAt,
    );
  }

  String? _determineNextOffset(
    Map<String, dynamic> body,
    List<SocialComment> comments,
  ) {
    final List<String?> candidates = <String?>[
      _normalizeString(body['offset']),
      _normalizeString(body['offset_comment']),
      _normalizeString(body['offset_id']),
      _normalizeString(body['comment_offset']),
      _normalizeString(body['last_comment_id']),
    ];
    final dynamic data = body['data'];
    if (data is Map) {
      candidates.add(_normalizeString(data['offset']));
      candidates.add(_normalizeString(data['offset_comment']));
      candidates.add(_normalizeString(data['comment_offset']));
      candidates.add(_normalizeString(data['last_comment_id']));
    }
    for (final String? candidate in candidates) {
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }
    if (comments.isNotEmpty) {
      return comments.last.id;
    }
    return null;
  }

  List<SocialUser> _mergeUsers(List<dynamic> sources) {
    final List<SocialUser> output = <SocialUser>[];
    final Set<String> seen = <String>{};
    for (final dynamic source in sources) {
      for (final SocialUser user in _collectUsers(source)) {
        if (seen.add(user.id)) {
          output.add(user);
        }
      }
    }
    return output;
  }

  Iterable<SocialUser> _collectUsers(dynamic raw) sync* {
    if (raw == null) return;
    if (raw is Iterable) {
      for (final dynamic item in raw) {
        final SocialUser? user = _parseUser(item);
        if (user != null) yield user;
      }
    } else if (raw is Map) {
      for (final dynamic value in raw.values) {
        final SocialUser? user = _parseUser(value);
        if (user != null) {
          yield user;
        }
      }
    }
  }

  SocialUser? _parseUser(dynamic raw) {
    if (raw is! Map) return null;
    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);

    final String? id =
        _normalizeString(map['user_id'] ?? map['id'] ?? map['userId']);
    if (id == null || id.isEmpty) return null;

    String? firstName =
        _normalizeString(map['first_name'] ?? map['fname'] ?? map['firstName']);
    String? lastName =
        _normalizeString(map['last_name'] ?? map['lname'] ?? map['lastName']);
    String? displayName = _normalizeString(map['name'] ??
        map['full_name'] ??
        map['fullname'] ??
        map['display_name']);
    final String? userName =
        _normalizeString(map['username'] ?? map['user_name']);

    if (displayName == null || displayName.isEmpty) {
      final List<String> pieces = <String>[
        if (firstName != null && firstName.isNotEmpty) firstName,
        if (lastName != null && lastName.isNotEmpty) lastName,
      ];
      final String combined = pieces.join(' ').trim();
      if (combined.isNotEmpty) {
        displayName = combined;
      } else if (userName != null && userName.isNotEmpty) {
        displayName = userName;
      } else {
        displayName = id;
      }
    }

    final String? avatar = _normalizeMediaUrl(
      map['avatar_full'] ?? map['avatar'] ?? map['profile_picture'],
    );
    final String? cover = _normalizeMediaUrl(
      map['cover_full'] ?? map['cover'] ?? map['cover_image'],
    );
    final bool isAdmin =
        _isTruthy(map['is_admin'] ?? map['admin'] ?? map['is_moderator']);
    final bool isOwner =
        _isTruthy(map['is_owner'] ?? map['owner'] ?? map['is_creator']);

    return SocialUser(
      id: id,
      displayName: displayName,
      firstName: firstName,
      lastName: lastName,
      userName: userName,
      avatarUrl: avatar,
      coverUrl: cover,
      isAdmin: isAdmin,
      isOwner: isOwner,
    );
  }

  List<String> _extractFileList(Map<String, dynamic> body) {
    final Set<String> output = <String>{};

    void add(dynamic raw) {
      if (raw is List) {
        for (final dynamic item in raw) {
          final String? value = _normalizeString(item);
          if (value != null && value.isNotEmpty) {
            output.add(value);
          }
        }
      }
    }

    add(body['fileList']);
    add(body['files']);
    final dynamic data = body['data'];
    if (data is Map) {
      add(data['fileList']);
      add(data['files']);
    }
    return output.toList();
  }

  Map<String, dynamic>? _pickPublisher(Map<String, dynamic> map) {
    final List<dynamic> candidates = <dynamic>[
      map['publisher'],
      map['publisher_data'],
      map['user_data'],
      map['user'],
      map['owner'],
      map['author'],
      map['comment_user'],
    ];
    for (final dynamic candidate in candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) {
        return Map<String, dynamic>.from(candidate);
      }
    }
    return null;
  }

  bool _looksLikeComment(Map<String, dynamic> map) {
    const List<String> keys = <String>[
      'comment_id',
      'comment',
      'text',
      'cid',
      'c_id',
      'comment_text',
    ];
    for (final String key in keys) {
      if (map.containsKey(key)) return true;
    }
    return false;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  DateTime? _epochToDateTime(int? value) {
    if (value == null || value <= 0) return null;
    if (value > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
        .toLocal();
  }

  int? _coerceInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final String trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      final String normalized = trimmed.replaceAll(RegExp(r'[^0-9\-]'), '');
      if (normalized.isEmpty) return null;
      return int.tryParse(normalized);
    }
    return null;
  }

  String? _normalizeString(dynamic value) {
    if (value == null) return null;
    final String str = value.toString().trim();
    if (str.isEmpty) return null;
    final String lower = str.toLowerCase();
    if (lower == 'null' || lower == 'undefined') return null;
    return str;
  }

  String? _normalizeMediaUrl(dynamic raw) {
    final String? normalized = _normalizeString(raw);
    if (normalized == null) return null;
    final String lower = normalized.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return normalized;
    }
    if (lower.startsWith('//')) {
      return 'https:${normalized.substring(2)}';
    }
    final String base = apiBaseUrl.endsWith('/')
        ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
        : apiBaseUrl;
    if (normalized.startsWith('/')) {
      return '$base$normalized';
    }
    return '$base/$normalized';
  }

  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final String lower = value.toString().toLowerCase();
    return lower == '1' || lower == 'true' || lower == 'yes';
  }
}
