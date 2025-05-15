
import 'package:flutter/foundation.dart';
import '../models/ad.dart';
import '../services/api_service.dart';

class BookmarkProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<Ad> _bookmarkedAds = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Ad> get bookmarkedAds => _bookmarkedAds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBookmarks(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Fetching bookmarks for phoneNumber: $phoneNumber');
      _bookmarkedAds = await _apiService.fetchBookmarks(phoneNumber);
      print('Fetched ${_bookmarkedAds.length} bookmarked ads');
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching bookmarks: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> isBookmarked(String phoneNumber, int adId) async {
    try {
      print('Checking if adId: $adId is bookmarked for phoneNumber: $phoneNumber');
      final bookmarks = await _apiService.fetchBookmarks(phoneNumber);
      final isBookmarked = bookmarks.any((ad) => ad.adId == adId);
      print('AdId: $adId isBookmarked: $isBookmarked');
      return isBookmarked;
    } catch (e) {
      print('Error checking bookmark status: $e');
      return false;
    }
  }

  Future<void> toggleBookmark(String phoneNumber, int adId, {bool skipNotify = false}) async {
    _isLoading = true;
    _errorMessage = null;
    if (!skipNotify) notifyListeners();

    try {
      print('Toggling bookmark for adId: $adId with phoneNumber: $phoneNumber');
      final isCurrentlyBookmarked = await isBookmarked(phoneNumber, adId);
      if (isCurrentlyBookmarked) {
        final bookmark = _bookmarkedAds.firstWhere(
          (ad) => ad.adId == adId,
          orElse: () => throw Exception('Bookmark not found in local list'),
        );
        if (bookmark.bookmarkId != null) {
          await _apiService.removeBookmark(bookmark.bookmarkId!);
          print('Bookmark removed for adId: $adId, bookmarkId: ${bookmark.bookmarkId}');
          _bookmarkedAds.removeWhere((ad) => ad.adId == adId);
        } else {
          throw Exception('Bookmark ID is null');
        }
      } else {
        final bookmarkId = await _apiService.addBookmark(phoneNumber, adId);
        final ad = await _apiService.fetchAdById(adId);
        ad.bookmarkId = bookmarkId; // Set bookmarkId on the Ad
        print('Bookmark added: ${ad.toJson()}');
        _bookmarkedAds.add(ad);
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error toggling bookmark: $_errorMessage');
      rethrow; // Rethrow to show error in UI
    } finally {
      _isLoading = false;
      if (!skipNotify) notifyListeners();
    }
  }

  Future<void> addBookmark(String phoneNumber, int adId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Adding bookmark for adId: $adId with phoneNumber: $phoneNumber');
      final bookmarkId = await _apiService.addBookmark(phoneNumber, adId);
      final ad = await _apiService.fetchAdById(adId);
      ad.bookmarkId = bookmarkId; // Set bookmarkId on the Ad
      print('Bookmark added: ${ad.toJson()}');
      _bookmarkedAds.add(ad);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error adding bookmark: $_errorMessage');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeBookmark(int bookmarkId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Removing bookmark_id: $bookmarkId');
      await _apiService.removeBookmark(bookmarkId);
      print('Bookmark removed: $bookmarkId');
      _bookmarkedAds.removeWhere((ad) => ad.bookmarkId == bookmarkId);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error removing bookmark: $_errorMessage');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
