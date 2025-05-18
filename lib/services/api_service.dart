import 'dart:convert';
import 'dart:io';
import 'package:divar_app/models/city.dart';
import 'package:divar_app/models/comment.dart';
import 'package:divar_app/models/province.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';
import '../models/ad.dart';

class ApiService {
  static const String apiBaseUrl = 'http://localhost:5000/api';

  Future<List<Ad>> fetchAds({
    String? adType,
    int? provinceId,
    int? cityId,
    String? sortBy,
  }) async {
    try {
      final queryParams = {
        if (adType != null) 'ad_type': adType,
        if (provinceId != null) 'province_id': provinceId.toString(),
        if (cityId != null) 'city_id': cityId.toString(),
        if (sortBy != null) 'sort_by': sortBy,
      };

      final uri =
          Uri.parse('$apiBaseUrl/ads').replace(queryParameters: queryParams);
      print('Fetching ads from: $uri');
      final response = await http.get(uri);

      print('Fetch ads status: ${response.statusCode}');
      print('Fetch ads body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Parsed ads data: $data');
        return data.map((json) => Ad.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load ads: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching ads: $e');
      throw Exception('Failed to load ads: $e');
    }
  }

  Future<void> updateAd({
    required int adId,
    required String title,
    required String description,
    int? price,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/ads/$adId');
    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'price': price,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to update ad: ${response.statusCode} ${response.body}');
    }
  }

  Future<List<Ad>> fetchUserAds(String phoneNumber) async {
    final uri = Uri.parse('$apiBaseUrl/users/$phoneNumber/ads');
    print('Fetching user ads from: $uri for phone: $phoneNumber');
    try {
      final response = await http.get(uri);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        print('Fetched ${jsonList.length} user ads for phone: $phoneNumber');
        return jsonList.map((json) => Ad.fromJson(json)).toList();
      } else {
        print(
            'Failed to fetch user ads: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Failed to load user ads: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching user ads for phone: $phoneNumber - $e');
      rethrow;
    }
  }

  Future<List<Ad>> fetchBookmarks(String phoneNumber) async {
    final uri = Uri.parse('$apiBaseUrl/bookmarks/$phoneNumber');
    print('Fetching bookmarks from: $uri');
    final response = await http.get(uri);
    print('Fetch bookmarks status: ${response.statusCode}');
    print('Fetch bookmarks body: ${response.body}');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Ad.fromJson(json)).toList();
    } else {
      throw Exception(
          'Failed to load bookmarks: ${response.statusCode} ${response.body}');
    }
  }

  Future<Ad> fetchAdById(int adId) async {
    final uri = Uri.parse('$apiBaseUrl/ads/$adId');
    print('Fetching ad from: $uri');
    final response = await http.get(uri);
    print('Fetch ad status: ${response.statusCode}');
    print('Fetch ad body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Ad.fromJson(data);
    } else {
      throw Exception(
          'Failed to load ad: ${response.statusCode} ${response.body}');
    }
  }

  Future<int> addBookmark(String phoneNumber, int adId) async {
    final uri = Uri.parse('$apiBaseUrl/bookmarks');
    final body = jsonEncode({'user_phone_number': phoneNumber, 'ad_id': adId});
    print('Adding bookmark to: $uri with body: $body');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
    print('Add bookmark status: ${response.statusCode}');
    print('Add bookmark body: ${response.body}');
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('Parsed bookmark response: $data');
      final bookmarkId = data['bookmark_id'] as int?;
      if (bookmarkId == null) {
        throw Exception('Bookmark ID not found in response');
      }
      return bookmarkId;
    } else {
      throw Exception(
          'Failed to add bookmark: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> removeBookmark(int bookmarkId) async {
    final uri = Uri.parse('$apiBaseUrl/bookmarks/$bookmarkId');
    print('Removing bookmark from: $uri');
    final response = await http.delete(uri);
    print('Remove bookmark status: ${response.statusCode}');
    print('Remove bookmark body: ${response.body}');
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to remove bookmark: ${response.statusCode} ${response.body}');
    }
  }

  Future<void> deleteAd(int adId) async {
    final uri = Uri.parse('$apiBaseUrl/ads/$adId');
    final response = await http.delete(uri);

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to delete ad: ${response.statusCode} ${response.body}');
    }
  }

  Future<Map<String, dynamic>> fetchUserProfile(String phoneNumber) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/users/$phoneNumber');
      print('Fetching user profile from: $uri');
      final response = await http.get(uri);

      print('Fetch user profile status: ${response.statusCode}');
      print('Fetch user profile body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
            'کاربر یافت نشد: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      throw Exception('کاربر یافت نشد: $e');
    }
  }

  Future<void> registerUser(Map<String, dynamic> userData) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/users');
      print('Registering user to: $uri with data: $userData');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      print('Register user status: ${response.statusCode}');
      print('Register user body: ${response.body}');

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to register user: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error registering user: $e');
      throw Exception('Failed to register user: $e');
    }
  }

  Future<List<Ad>> searchAds(String query) async {
    try {
      final uri = Uri.parse(
          '$apiBaseUrl/ads/search?query=${Uri.encodeQueryComponent(query)}');
      print('Searching ads from: $uri');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json; charset=utf-8'},
      );
      print('Search ads status: ${response.statusCode}');
      print('Search ads body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('Parsed search ads data: $data');
        return data.map((json) => Ad.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        print('No ads found for query: $query');
        return []; // Treat 404 as empty result
      } else {
        throw Exception(
            'Failed to search ads: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error searching ads: $e');
      throw Exception('Failed to search ads: $e');
    }
  }

  Future<List<Province>> getProvinces() async {
    try {
      final uri = Uri.parse('$apiBaseUrl/provinces');
      print('Fetching provinces from: $uri');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json; charset=utf-8'},
      );
      print('Get provinces status: ${response.statusCode}');
      print('Get provinces body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Province.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load provinces');
      }
    } catch (e) {
      print('Error fetching provinces: $e');
      throw Exception('Failed to fetch provinces: $e');
    }
  }

  Future<List<City>> getCities(int provinceId) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/cities?province_id=$provinceId');
      print('Fetching cities from: $uri');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json; charset=utf-8'},
      );
      print('Get cities status: ${response.statusCode}');
      print('Get cities body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => City.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cities');
      }
    } catch (e) {
      print('Error fetching cities: $e');
      throw Exception('Failed to fetch cities: $e');
    }
  }

  Future<void> postComment({
    required int adId,
    required String userPhoneNumber,
    required String content,
  }) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/ads/$adId/comments');
      print(
          'Posting comment to: $uri with data: {adId: $adId, user_phone_number: $userPhoneNumber, content: $content}');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_phone_number': userPhoneNumber,
          'content': content,
        }),
      );

      print('Post comment status: ${response.statusCode}');
      print('Post comment body: ${response.body}');

      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception(
            'Failed to post comment: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error posting comment: $e');
      throw Exception('Failed to post comment: $e');
    }
  }

  Future<List<Comment>> getComments(int adId) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/ads/$adId/comments');
      print('Fetching comments from: $uri');
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json; charset=utf-8'},
      );

      print('Get comments status: ${response.statusCode}');
      print('Get comments body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load comments: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching comments: $e');
      throw Exception('Failed to fetch comments: $e');
    }
  }

  Future<void> postAd(Map<String, dynamic> adData, List<File> images) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/ads');
      print(
          'Posting ad to: $uri with data: $adData and ${images.length} images');
      final request = http.MultipartRequest('POST', uri);

      // Add text fields
      adData.forEach((key, value) {
        if (value != null) {
          if (value is List) {
            request.fields[key] = jsonEncode(value);
          } else if (value is bool) {
            request.fields[key] = value.toString();
          } else {
            request.fields[key] = value.toString();
          }
        }
      });
      print('Request fields: ${request.fields}');

      // Add image files
      for (var image in images) {
        final fileExtension = image.path.split('.').last.toLowerCase();
        if (!['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
          throw Exception('فقط تصاویر JPEG، PNG و GIF مجاز هستند');
        }
        final mimeType = fileExtension == 'jpg' || fileExtension == 'jpeg'
            ? 'image/jpeg'
            : fileExtension == 'png'
                ? 'image/png'
                : 'image/gif';
        final file = await http.MultipartFile.fromPath(
          'images',
          image.path,
          contentType: MediaType('image', mimeType.split('/')[1]),
        );
        request.files.add(file);
        print(
            'Added image: ${image.path}, extension: $fileExtension, MIME: $mimeType');
      }
      print('Request files: ${request.files.map((f) => f.filename).toList()}');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Post ad status: ${response.statusCode}');
      print('Post ad body: $responseBody');

      if (response.statusCode == 201) {
        return;
      } else {
        try {
          final errorData = jsonDecode(responseBody);
          throw Exception(
              'ثبت آگهی ناموفق: ${errorData['message'] ?? responseBody}');
        } catch (e) {
          throw Exception('ثبت آگهی ناموفق: $responseBody');
        }
      }
    } catch (e) {
      print('Error posting ad: $e');
      throw Exception('Error posting ad: $e');
    }
  }

  Future<String> uploadImage(dynamic imageFile) async {
    try {
      final fileExtension = imageFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        throw Exception('فقط تصاویر JPEG و PNG مجاز هستند');
      }

      final uri = Uri.parse('$apiBaseUrl/upload');
      print('Uploading image to: $uri');
      var request = http.MultipartRequest('POST', uri);

      final mimeType = fileExtension == 'png' ? 'image/png' : 'image/jpeg';
      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', mimeType.split('/')[1]),
      );
      request.files.add(multipartFile);

      final response = await request.send();
      final responseData = await http.Response.fromStream(response);

      print('Upload image status: ${response.statusCode}');
      print('Upload image body: ${responseData.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData.body);
        if (data['imageUrl'] == null) {
          throw Exception('No image URL returned from server');
        }
        return data['imageUrl'];
      } else {
        throw Exception(
            'Failed to upload image: ${response.statusCode} ${responseData.body}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Error uploading image: $e');
    }
  }
}
