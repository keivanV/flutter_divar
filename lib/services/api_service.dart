import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../constants.dart';
import '../models/ad.dart';

class ApiService {
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
        // Standardize MIME type
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
      print('Request headers: ${request.headers}');
      print('Content-Type: ${request.headers['content-type']}');

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
