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
  static const String _adminIdKey = 'admin_id'; // Added for clarity

  Future<void> adminLogin(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final adminId = await _apiService.adminLogin(username, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_adminIdKey, adminId);
      _adminId = adminId;
      print('adminLogin successful, adminId: $adminId, stored in SharedPreferences'); // Enhanced
      // Verify storage
      final storedAdminId = prefs.getInt(_adminIdKey);
      print('Verified stored adminId: $storedAdminId'); // Added
    } catch (e) {
      if (e.toString().contains('نام کاربری یا رمز عبور اشتباه است')) {
        _errorMessage = 'رمز اشتباه است';
      } else {
        _errorMessage = e.toString();
      }
      print('adminLogin error: $e');
      throw Exception(_errorMessage);
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
      final storedAdminId = prefs.getInt(_adminIdKey);
      print('Stored phone number: $storedPhoneNumber, adminId: $storedAdminId');
      if (storedPhoneNumber != null && storedPhoneNumber.isNotEmpty) {
        try {
          await _apiService.fetchUserProfile(storedPhoneNumber);
          _phoneNumber = storedPhoneNumber;
          print('User profile fetched successfully for $storedPhoneNumber');
        } catch (e) {
          print('Error fetching user profile: $e');
          await prefs.remove(_phoneNumberKey);
          _phoneNumber = null;
        }
      } else {
        _phoneNumber = null;
        print('No stored phone number found');
      }
      _adminId = storedAdminId;
      if (_adminId != null) {
        print('Admin ID initialized: $_adminId'); // Added
      } else {
        print('No admin ID found in SharedPreferences'); // Added
      }
    } catch (e) {
      print('Error initializing SharedPreferences: $e');
      _phoneNumber = null;
      _adminId = null;
    }
    print('AuthProvider.initialize completed, phoneNumber: $_phoneNumber, adminId: $_adminId');
    notifyListeners();
  }

  Future<void> login(String phoneNumber) async {
    try {
      await _apiService.fetchUserProfile(phoneNumber);
      _phoneNumber = phoneNumber;
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
      userData['account_level'] = 'LEVEL_3';
      await _apiService.registerUser(userData);
      _phoneNumber = userData['phone_number'];
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
    _adminId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_adminIdKey);
    print('Logged out, cleared stored phone number and admin id');
    notifyListeners();
  }
}