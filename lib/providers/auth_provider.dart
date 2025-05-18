import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  String? _phoneNumber;
  String? _adminToken;
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  int? _adminId;
  String? _errorMessage;
  String? get phoneNumber => _phoneNumber;
  String? get adminToken => _adminToken;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int? get adminId => _adminId;
  static const String _phoneNumberKey = 'phone_number';

  Future<void> adminLogin(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final adminId = await _apiService.adminLogin(username, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('admin_id', adminId);
      _adminId = adminId;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    print('Starting AuthProvider.initialize');
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPhoneNumber = prefs.getString(_phoneNumberKey);
      print('Stored phone number: $storedPhoneNumber');
      if (storedPhoneNumber != null && storedPhoneNumber.isNotEmpty) {
        try {
          // بررسی وجود کاربر در بک‌اند
          await _apiService.fetchUserProfile(storedPhoneNumber);
          _phoneNumber = storedPhoneNumber;
          print('User profile fetched successfully for $storedPhoneNumber');
        } catch (e) {
          // در صورت خطا (مثلاً کاربر حذف شده)، اطلاعات پاک می‌شوند
          print('Error fetching user profile: $e');
          await prefs.remove(_phoneNumberKey);
          _phoneNumber = null;
        }
      } else {
        _phoneNumber = null;
        print('No stored phone number found');
      }
    } catch (e) {
      // مدیریت خطاهای غیرمنتظره در SharedPreferences
      print('Error initializing SharedPreferences: $e');
      _phoneNumber = null;
    }
    print('AuthProvider.initialize completed, phoneNumber: $_phoneNumber');
    notifyListeners();
  }

  Future<void> login(String phoneNumber) async {
    try {
      // بررسی وجود کاربر در بک‌اند
      await _apiService.fetchUserProfile(phoneNumber);
      _phoneNumber = phoneNumber;
      // ذخیره شماره موبایل در shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_phoneNumberKey, phoneNumber);
      print('Login successful, stored phone number: $phoneNumber');
      notifyListeners();
    } catch (e) {
      print('Login error: $e');
      throw Exception('ورود ناموفق: کاربر یافت نشد');
    }
  }

  Future<void> register(Map<String, dynamic> userData) async {
    try {
      // افزودن سطح اکانت پیش‌فرض
      userData['account_level'] = 'LEVEL_3';
      await _apiService.registerUser(userData);
      _phoneNumber = userData['phone_number'];
      // ذخیره شماره موبایل در shared_preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_phoneNumberKey, userData['phone_number']);
      print('Registration successful, stored phone number: ${_phoneNumber}');
      notifyListeners();
    } catch (e) {
      print('Registration error: $e');
      throw Exception('ثبت‌نام ناموفق: $e');
    }
  }

  Future<void> logout() async {
    _phoneNumber = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneNumberKey);
    print('Logged out, cleared stored phone number');
    notifyListeners();
  }
}
