import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/event_service.dart';

class EventRepository {
  final EventService service = EventService();

  Future<List<SocialEvent>> getEvents(
    String accessToken,
    String fetch, {
    int offset = 0,
    int limit = 20,
  }) async {
    final res = await service.fetchEvents(
      accessToken: accessToken,
      fetch: fetch,
      offset: offset,
      limit: limit,
    );

    final data = jsonDecode(res.body);
    if (data['api_status'] != 200) return [];

    // Lấy list theo đúng tên fetch, nếu không có thì fallback về 'events'
    final dynamic rawList = data[fetch] ?? data['events'];

    if (rawList is List) {
      return rawList.map((e) => SocialEvent.fromJson(e)).toList();
    }
    return [];
  }

  Future<SocialEvent?> getEventById(
      String accessToken,
      String id,
      ) async {
    final res = await service.fetchEventById(
      accessToken: accessToken,
      id: id,
    );

    final Map<String, dynamic> data = jsonDecode(res.body);
    // API: "status": 200, "event_data": {...}
    if (data['status'] == 200 && data['event_data'] != null) {
      return SocialEvent.fromJson(data['event_data']);
    }
    return null;
  }

  Future<bool> interestEvent(String accessToken, String eventId) async {
    try {
      final res = await service.interestEvent(accessToken, eventId);
      final data = jsonDecode(res.body);

      if (data['api_status'] == 200) {
        return true; // Thành công
      } else {
        return false; // Thất bại
      }
    } catch (e) {
      return false; // Lỗi khi gọi API
    }
  }

  Future<bool> goToEvent(String accessToken, String eventId) async {
    try {
      final res = await service.goToEvent(accessToken, eventId);
      final data = jsonDecode(res.body);

      if (data['api_status'] == 200) {
        return true; // Thành công
      } else {
        return false; // Thất bại
      }
    } catch (e) {
      return false; // Lỗi khi gọi API
    }
  }

  Future<SocialEvent?> createEvent({
    required String accessToken,
    required String name,
    required String location,
    required String description,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    File? coverFile,
  }) async {
    final res = await service.createEvent(
      accessToken: accessToken,
      name: name,
      location: location,
      description: description,
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      coverFile: coverFile,
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (data['api_status'] == 200 && data['data'] != null) {
      return SocialEvent.fromJson(data['data']);
    }
    final msg =
        data['error_message'] ?? data['errors'] ?? 'Tạo sự kiện thất bại';
    throw Exception(msg);
  }
  Future<bool> editEvent({
    required String accessToken,
    required String eventId,
    required String name,
    required String location,
    required String description,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    File? coverFile,
  }) async {
    final res = await service.editEvent(
      accessToken: accessToken,
      eventId: eventId,
      name: name,
      location: location,
      description: description,
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
      coverFile: coverFile,
    );
    final Map<String, dynamic> data = jsonDecode(res.body);
    if (data['api_status'] == 200) {
      return true;
    }
    return false;
  }
  Future<bool> deleteEvent({
    required String accessToken,
    required String id,
  }) async {
    final res = await service.deleteEvent(
      accessToken: accessToken,
      eventId: id,
    );
    final Map<String, dynamic> data = jsonDecode(res.body);
    if (data['api_status'] == 200) {
      return true;
    }
    return false;
  }
}
