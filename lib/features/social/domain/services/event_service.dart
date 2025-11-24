import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';

class EventService {
  Future<http.Response> fetchEvents({
    required String accessToken,
    required String fetch,
    int offset = 0,
    int limit = 20,
  }) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialGetEventUri}?access_token=$accessToken',
    );

    final req = http.MultipartRequest('POST', url)
      ..fields['server_key'] = AppConstants.socialServerKey
      ..fields['fetch'] = fetch
      ..fields['offset'] = offset.toString()
      ..fields['limit'] = limit.toString();

    final res = await req.send();
    return http.Response.fromStream(res);
  }
  /// 🔹 NEW: lấy chi tiết sự kiện theo id
  Future<http.Response> fetchEventById({
    required String accessToken,
    required String id,
  }) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialGetEventByIdUri}?access_token=$accessToken',
    );

    final req = http.MultipartRequest('POST', url)
      ..fields['server_key'] = AppConstants.socialServerKey
      ..fields['id'] = id;

    final res = await req.send();
    return http.Response.fromStream(res);
  }
  Future<http.Response> interestEvent(String accessToken, String eventId) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialInterestEventUri}?access_token=$accessToken',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['server_key'] = AppConstants.socialServerKey
      ..fields['event_id'] = eventId;

    final res = await request.send();
    return http.Response.fromStream(res);
  }
  Future<http.Response> goToEvent(String accessToken, String eventId) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialGoToEventUri}?access_token=$accessToken',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['server_key'] = AppConstants.socialServerKey
      ..fields['event_id'] = eventId;

    final res = await request.send();
    return http.Response.fromStream(res);
  }


  Future<http.Response> createEvent({
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
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialCreateEventUri}?access_token=$accessToken',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields.addAll({
        'server_key': AppConstants.socialServerKey,
        'event_name': name,
        'event_location': location,
        'event_description': description,
        'event_start_date': startDate,
        'event_end_date': endDate,
        'event_start_time': startTime,
        'event_end_time': endTime,
      });

    if (coverFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'event_cover',
          coverFile.path,
        ),
      );
    }

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }
  Future<http.Response> editEvent({
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
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialEditOrDeleteEventUri}?access_token=$accessToken',
    );
    final request = http.MultipartRequest('POST', url)
      ..fields.addAll({
        'server_key': AppConstants.socialServerKey,
        'type': 'edit',
        'event_id': eventId,
        'event_name': name,
        'event_location': location,
        'event_description': description,
        'event_start_date': startDate,
        'event_end_date': endDate,
        'event_start_time': startTime,
        'event_end_time': endTime,
      });
    if (coverFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'event-cover',            // 🔹 theo curl: event-cover
          coverFile.path,
        ),
      );
    }
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }
  Future<http.Response> deleteEvent({
    required String accessToken,
    required String eventId,
  }) async {
    final url = Uri.parse(
      '${AppConstants.socialBaseUrl}${AppConstants.socialEditOrDeleteEventUri}?access_token=$accessToken',
    );

    final request = http.MultipartRequest('POST', url)
      ..fields.addAll({
        'server_key': AppConstants.socialServerKey,
        'type': 'delete',
        'event_id': eventId,
      });

    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }
}

