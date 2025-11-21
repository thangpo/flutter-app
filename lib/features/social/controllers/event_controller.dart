import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sixvalley_ecommerce/utill/app_constants.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/models/social_event.dart';
import 'package:flutter_sixvalley_ecommerce/features/social/domain/repositories/event_repository.dart';

class EventController extends ChangeNotifier {
  final EventRepository repo;

  EventController({required this.repo});

  bool loading = false;
  List<SocialEvent> events = [];
  List<SocialEvent> myEvents = [];
  List<SocialEvent> going = [];
  List<SocialEvent> interested = [];
  List<SocialEvent> invited = [];
  List<SocialEvent> past = [];
  bool creating = false;
  String? error;
  String? _accessToken;

  Future<void> _ensureToken() async {
    if (_accessToken == null) {
      final sp = await SharedPreferences.getInstance();
      _accessToken = sp.getString(AppConstants.socialAccessToken);
    }
  }

  Future<void> getEvents({String fetch = 'events'}) async {
    loading = true;
    notifyListeners();

    await _ensureToken();
    final list = await repo.getEvents(_accessToken!, fetch);
    events = list;

    // Phân loại sự kiện
    myEvents = events.where((event) => event.isOwner).toList();
    going = events.where((event) => event.isGoing).toList();
    interested = events.where((event) => event.isInterested).toList();
    invited = events.where((event) => event.isInvited).toList();
    past = events.where((event) => event.isPast).toList();

    loading = false;
    notifyListeners();
  }

  Future<void> toggleInterest(String eventId) async {
    loading = true;
    notifyListeners();

    try {
      final interestStatus = await repo.toggleInterestEvent(
        accessToken: _accessToken!,
        eventId: eventId,
      );

      if (interestStatus != null) {
        // Cập nhật trạng thái sự kiện (thích / không thích)
        final event = events.firstWhere((e) => e.id == eventId);
        event.isInterested = interestStatus == '1';
        notifyListeners();
      } else {
        error = 'Lỗi khi cập nhật trạng thái thích sự kiện';
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<SocialEvent?> createEvent({
    required String name,
    required String location,
    required String description,
    required String startDate,
    required String endDate,
    required String startTime,
    required String endTime,
    File? coverFile,
  }) async {
    if (name.trim().length < 5) {
      throw Exception('Tiêu đề phải nhiều hơn 5 ký tự');
    }
    if (description.trim().length < 10) {
      throw Exception('Mô tả phải nhiều hơn 10 ký tự');
    }

    creating = true;
    notifyListeners();

    try {
      await _ensureToken();
      final event = await repo.createEvent(
        accessToken: _accessToken!,
        name: name.trim(),
        location: location.trim(),
        description: description.trim(),
        startDate: startDate.trim(),
        endDate: endDate.trim(),
        startTime: startTime.trim(),
        endTime: endTime.trim(),
        coverFile: coverFile,
      );

      if (event != null) {
        events.insert(0, event);
      }

      creating = false;
      notifyListeners();
      return event;
    } catch (e) {
      creating = false;
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> refresh() async {
    _accessToken = null;
    await getEvents();
  }
}

