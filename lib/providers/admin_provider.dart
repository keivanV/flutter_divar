import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import './auth_provider.dart';

class AdminProvider with ChangeNotifier {
  final String _apiBaseUrl = 'http://localhost:5000/api';
  bool _isLoading = false;
  String? _errorMessage;
  int? _totalUsers;
  List<Map<String, dynamic>> _adsCount = [];
  List<Map<String, dynamic>> _commentsCount = [];
  Map<String, dynamic>? _topCommentedAd;
  List<Map<String, dynamic>> _userStats = [];
  List<Map<String, dynamic>> _adStats = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get totalUsers => _totalUsers;
  List<Map<String, dynamic>> get adsCount => _adsCount;
  List<Map<String, dynamic>> get commentsCount => _commentsCount;
  Map<String, dynamic>? get topCommentedAd => _topCommentedAd;
  List<Map<String, dynamic>> get userStats => _userStats;
  List<Map<String, dynamic>> get adStats => _adStats;

  Future<void> fetchUsersCount(BuildContext context,
      {String timePeriod = 'day'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/admin/users/count?time_period=$timePeriod'),
        headers: {'x-admin-id': adminId.toString()},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _totalUsers = data['totalUsers'];
        _userStats = List<Map<String, dynamic>>.from(data['stats']);
      } else {
        _errorMessage = jsonDecode(response.body)['message'];
      }
    } catch (e) {
      _errorMessage = 'خطا در دریافت تعداد کاربران: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAdsCount(BuildContext context,
      {String? adType, String timePeriod = 'day'}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');
      final query = adType != null ? 'ad_type=$adType&' : '';
      final response = await http.get(
        Uri.parse(
            '$_apiBaseUrl/admin/ads/count?${query}time_period=$timePeriod'),
        headers: {'x-admin-id': adminId.toString()}, // اصلاح: همیشه adminId
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _adsCount = List<Map<String, dynamic>>.from(data['adCounts']);
        _adStats = List<Map<String, dynamic>>.from(data['stats']);
      } else {
        _errorMessage = jsonDecode(response.body)['message'];
      }
    } catch (e) {
      _errorMessage = 'خطا در دریافت تعداد آگهی‌ها: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchCommentsCount(BuildContext context,
      {String? adType}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');
      final query = adType != null ? '?ad_type=$adType' : '';
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/admin/comments/count$query'),
        headers: {'x-admin-id': adminId.toString()},
      );
      if (response.statusCode == 200) {
        _commentsCount =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        _errorMessage = jsonDecode(response.body)['message'];
      }
    } catch (e) {
      _errorMessage = 'خطا در دریافت تعداد نظرات: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchTopCommentedAd(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/admin/comments/top-ad'),
        headers: {'x-admin-id': adminId.toString()},
      );
      if (response.statusCode == 200) {
        _topCommentedAd = jsonDecode(response.body);
      } else {
        _errorMessage = jsonDecode(response.body)['message'];
      }
    } catch (e) {
      _errorMessage = 'خطا در دریافت آگهی پرنظر: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteAd(BuildContext context, int adId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/admin/ads/$adId'),
        headers: {'x-admin-id': adminId.toString()},
      );
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطا در حذف آگهی: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteComment(BuildContext context, int commentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/admin/comments/$commentId'),
        headers: {'x-admin-id': adminId.toString()},
      );
      if (response.statusCode == 200) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'];
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطا در حذف نظر: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
