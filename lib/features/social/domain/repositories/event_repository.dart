import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/services/event_service.dart';

class EventRepository {
  final EventService service = EventService();

  Future<List<SocialEvent>> getEvents(String accessToken, String fetch, {int offset = 0, int limit = 20}) async {
    final res = await service.fetchEvents(
      accessToken: accessToken,
      fetch: fetch,
      offset: offset,
      limit: limit,
    );

    final data = jsonDecode(res.body);
    if (data['api_status'] != 200) return [];

    final list = data['events'] as List<dynamic>? ?? [];
    return list.map((e) => SocialEvent.fromJson(e)).toList();
  }

  Future<String?> toggleInterestEvent({
    required String accessToken,
    required String eventId,
  }) async {
    final res = await service.toggleInterestEvent(
      accessToken: accessToken,
      eventId: eventId,
    );

    final data = jsonDecode(res.body);
    if (data['api_status'] == 200) {
      return data['interest_status'];
    } else {
      return null;
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
    final msg = data['error_message'] ?? data['errors'] ?? 'Tạo sự kiện thất bại';
    throw Exception(msg);
  }
}

