import 'package:flutter/material.dart';
import '../models/comment.dart';
import '../services/api_service.dart';

class CommentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Comment> _comments = [];
  List<Comment> _userComments = [];
  List<Comment> get userComments => _userComments;
  bool _isLoading = false;
  String? _errorMessage;

  List<Comment> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch comments for a specific ad
  Future<void> fetchCommentsByAdId(int adId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getCommentsByAdId(adId);
      _comments = response.map((json) => Comment.fromJson(json)).toList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'خطا در دریافت کامنت‌ها: $e';
      notifyListeners();
    }
  }

  // Fetch all comments or comments for a specific ad
  Future<void> fetchComments(int? adId, {int offset = 0}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _comments = await _apiService.getComments(adId, offset: offset);
      print(
          '---> fetchComments: Loaded ${_comments.length} comments for adId: $adId');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'خطا در دریافت کامنت‌ها: $e';
      print('fetchComments error: $e');
      notifyListeners();
    }
  }

Future<void> fetchUserComments(String userPhoneNumber, {String? adType}) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    _userComments = await _apiService.getUserComments(userPhoneNumber, adType: adType);
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    _isLoading = false;
    _errorMessage = 'خطا در دریافت کامنت‌های کاربر: $e';
    notifyListeners();
  }
}
  Future<void> postComment({
    required int adId,
    required String userPhoneNumber,
    required String content,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.postComment(
        adId: adId,
        userPhoneNumber: userPhoneNumber,
        content: content,
      );
      // Correct: adId is int, fetchComments accepts int?
      await fetchComments(adId, offset: 0);
      _isLoading = false;
      notifyListeners();

    } catch (e) {
      _isLoading = false;
      _errorMessage = 'خطا در ارسال کامنت: $e';
      notifyListeners();
    }
  }
}
