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
  String _currentFetch = 'events';
  String get currentFetch => _currentFetch;
  SocialEvent? currentEventDetail;
  bool detailLoading = false;
  bool creating = false;
  bool deleting = false;
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
    error = null;
    _currentFetch = fetch;
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

  Future<SocialEvent?> fetchEventById(String id) async {
    detailLoading = true;
    notifyListeners();

    await _ensureToken();
    if (_accessToken == null) {
      detailLoading = false;
      notifyListeners();
      return null;
    }

    final event = await repo.getEventById(_accessToken!, id);
    currentEventDetail = event;

    detailLoading = false;
    notifyListeners();
    return event;
  }

  Future<bool> toggleInterestEvent(String eventId) async {
    await _ensureToken();
    final success = await repo.interestEvent(_accessToken!, eventId);
    if (!success) {
      error = 'Lỗi khi cập nhật sự kiện';
      return false;
    }
    // Tìm vị trí event — KHÔNG TẠO THÊM HÀM
    final index = events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      events[index].isInterested = !events[index].isInterested;
      notifyListeners();
    }
    return true;
  }

  Future<bool> toggleEventGoing(String eventId) async {
    await _ensureToken();
    final success = await repo.goToEvent(_accessToken!, eventId);
    if (!success) {
      error = 'Lỗi khi tham gia sự kiện';
      return false;
    }
    final index = events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      events[index].isGoing = !events[index].isGoing;
      notifyListeners();
    }
    return true;
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
  Future<bool> editEvent({
    required String id,
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
      error = 'Tiêu đề phải nhiều hơn 5 ký tự';
      notifyListeners();
      return false;
    }
    if (description.trim().length < 10) {
      error = 'Mô tả phải nhiều hơn 10 ký tự';
      notifyListeners();
      return false;
    }

    creating = true;
    notifyListeners();

    try {
      await _ensureToken();
      if (_accessToken == null) {
        creating = false;
        error = 'Chưa có access token';
        notifyListeners();
        return false;
      }

      final ok = await repo.editEvent(
        accessToken: _accessToken!,
        eventId: id,
        name: name.trim(),
        location: location.trim(),
        description: description.trim(),
        startDate: startDate.trim(),
        endDate: endDate.trim(),
        startTime: startTime.trim(),
        endTime: endTime.trim(),
        coverFile: coverFile,
      );

      creating = false;

      if (!ok) {
        error = 'Sửa sự kiện thất bại';
      }

      // Nếu muốn sau khi sửa tự refresh list:
      if (ok) {
        await getEvents(fetch: _currentFetch);
      }

      notifyListeners();
      return ok;
    } catch (e) {
      creating = false;
      error = e.toString();
      notifyListeners();
      return false;
    }
  }
  Future<bool> deleteEvent(String eventId) async {
    await _ensureToken();
    if (_accessToken == null) return false;

    deleting = true;
    error = null;
    notifyListeners();

    final ok = await repo.deleteEvent(
      accessToken: _accessToken!,
      id: eventId,
    );

    deleting = false;

    if (ok) {
      events.removeWhere((e) => e.id == eventId);
      myEvents.removeWhere((e) => e.id == eventId);
      going.removeWhere((e) => e.id == eventId);
      interested.removeWhere((e) => e.id == eventId);
      invited.removeWhere((e) => e.id == eventId);
      past.removeWhere((e) => e.id == eventId);
      if (currentEventDetail?.id == eventId) {
        currentEventDetail = null;
      }
      notifyListeners();
      return true;
    } else {
      error = 'Xóa sự kiện thất bại';
      notifyListeners();
      return false;
    }
  }
  Future<void> refresh() async {
    _accessToken = null;
    await getEvents(fetch: _currentFetch);
  }
}

