import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import './auth_provider.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType

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
  List<Map<String, dynamic>> _promoAds = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get totalUsers => _totalUsers;
  List<Map<String, dynamic>> get adsCount => _adsCount;
  List<Map<String, dynamic>> get commentsCount => _commentsCount;
  Map<String, dynamic>? get topCommentedAd => _topCommentedAd;
  List<Map<String, dynamic>> get userStats => _userStats;
  List<Map<String, dynamic>> get adStats => _adStats;
  List<Map<String, dynamic>> get promoAds => _promoAds;

  Future<void> fetchPromoAds(BuildContext context) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/admin/promo-ads'),
        headers: {'x-admin-id': adminId.toString()},
      );
      if (response.statusCode == 200) {
        _promoAds = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        _errorMessage =
            jsonDecode(response.body)['message'] ?? 'خطا در دریافت تبلیغ‌ها';
      }
    } catch (e) {
      _errorMessage = 'خطا در دریافت تبلیغ‌ها: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  // جدید: ایجاد تبلیغ
  Future<bool> createPromoAd(
    BuildContext context, {
    required String title,
    required String adType,
    required String price,
    required String details,
    String? imagePath,
  }) async {
    final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final uri = Uri.parse('$_apiBaseUrl/admin/promo-ads');
    var request = http.MultipartRequest('POST', uri);

    // Add text fields
    request.fields['title'] = title;
    request.fields['ad_type'] = adType;
    request.fields['price'] = price;
    request.fields['details'] = details;

    // Add file (if exists)
    if (imagePath != null) {
      try {
        // Determine MIME type based on file extension
        final mimeType =
            lookupMimeType(imagePath) ?? 'application/octet-stream';
        print(
            'Detected MIME type: $mimeType for file: $imagePath'); // Debug log
        if (mimeType != 'image/jpeg' && mimeType != 'image/png') {
          adminProvider._errorMessage = 'فقط تصاویر JPG/PNG مجاز هستند';
          notifyListeners();
          return false;
        }

        final file = await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType:
              MediaType.parse(mimeType), // Use MediaType from http_parser
        );
        request.files.add(file);
        print('File path: $imagePath, MIME type: $mimeType'); // Debug log
      } catch (e) {
        adminProvider._errorMessage = 'خطا در بارگذاری تصویر: $e';
        notifyListeners();
        return false;
      }
    }

    // Add adminId header
    request.headers['x-admin-id'] = adminId.toString();

    try {
      final response = await request.send();
      final responseBody = await http.Response.fromStream(response);

      print(
          'Response status: ${response.statusCode}, Body: ${responseBody.body}'); // Debug log

      if (response.statusCode == 201) {
        adminProvider.fetchPromoAds(context); // Refresh promo ads
        return true;
      } else {
        String errorMessage;
        try {
          final errorData = jsonDecode(responseBody.body);
          errorMessage = errorData['message'] ?? 'خطا در ایجاد تبلیغ';
        } catch (e) {
          errorMessage = 'پاسخ نامعتبر از سرور';
        }
        adminProvider._errorMessage = errorMessage;
        notifyListeners();
        return false;
      }
    } catch (e) {
      adminProvider._errorMessage = 'خطا در ایجاد تبلیغ: $e';
      notifyListeners();
      return false;
    }
  }

  // جدید: ویرایش تبلیغ
  Future<bool> updatePromoAd(
    BuildContext context, {
    required int id,
    String? title,
    String? adType,
    String? price,
    String? details,
    String? imagePath,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');

      var request = http.MultipartRequest(
          'PUT', Uri.parse('$_apiBaseUrl/admin/promo-ads/$id'));
      request.headers['x-admin-id'] = adminId.toString();
      if (title != null) request.fields['title'] = title;
      if (adType != null) request.fields['ad_type'] = adType;
      if (price != null) request.fields['price'] = price;
      if (details != null) request.fields['details'] = details;

      if (imagePath != null) {
        request.files
            .add(await http.MultipartFile.fromPath('image', imagePath));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final updatedAd = jsonDecode(responseBody);
        final index = _promoAds.indexWhere((ad) => ad['id'] == id);
        if (index != -1) {
          _promoAds[index] = updatedAd;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            jsonDecode(responseBody)['message'] ?? 'خطا در ویرایش تبلیغ';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطا در ویرایش تبلیغ: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // جدید: حذف تبلیغ
  Future<bool> deletePromoAd(BuildContext context, int id) async {
    _isLoading = true;
    notifyListeners();
    try {
      final adminId = Provider.of<AuthProvider>(context, listen: false).adminId;
      if (adminId == null) throw Exception('شناسه ادمین وجود ندارد');
      final response = await http.delete(
        Uri.parse('$_apiBaseUrl/admin/promo-ads/$id'),
        headers: {'x-admin-id': adminId.toString()},
      );
      if (response.statusCode == 200) {
        _promoAds.removeWhere((ad) => ad['id'] == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            jsonDecode(response.body)['message'] ?? 'خطا در حذف تبلیغ';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'خطا در حذف تبلیغ: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

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
