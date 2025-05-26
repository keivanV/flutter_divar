import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/province.dart';
import '../models/city.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  int? _provinceId;
  int? _cityId;
  bool _isLoginTab = true;
  bool _isAdminMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // متغیرها برای ذخیره لیست‌های دریافت‌شده از API
  List<Province> provinces = [];
  List<City> cities = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // لود کردن استان‌ها در زمان اولیه‌سازی
    _loadProvinces();
  }

  // تابع برای لود کردن استان‌ها
  Future<void> _loadProvinces() async {
    try {
      final apiService = ApiService();
      final fetchedProvinces = await apiService.getProvinces();
      setState(() {
        provinces = fetchedProvinces;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در لود کردن استان‌ها: $e';
      });
    }
  }

  // تابع برای لود کردن شهرها بر اساس provinceId
  Future<void> _loadCities(int provinceId) async {
    try {
      final apiService = ApiService();
      final fetchedCities = await apiService.getCities(provinceId);
      setState(() {
        cities = fetchedCities;
        _cityId = null; // ریست کردن شهر انتخاب‌شده
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'خطا در لود کردن شهرها: $e';
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      if (_isAdminMode) {
        await authProvider.adminLogin(
            _usernameController.text, _passwordController.text);
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else if (_isLoginTab) {
        await authProvider.login(_phoneController.text);
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        await authProvider.register({
          'phone_number': _phoneController.text,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'nickname': _nicknameController.text,
          'province_id': _provinceId,
          'city_id': _cityId,
        });
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _switchToRegister() {
    setState(() {
      _isLoginTab = false;
      _isAdminMode = false;
      _errorMessage = null;
      _animationController.reset();
      _animationController.forward();
    });
  }

  void _toggleAdminMode() {
    setState(() {
      _isAdminMode = !_isAdminMode;
      _isLoginTab = true;
      _errorMessage = null;
      _animationController.reset();
      _animationController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAdminMode
                          ? 'ورود ادمین'
                          : _isLoginTab
                              ? 'ورود به دیوار'
                              : 'ثبت‌نام در دیوار',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),
                    if (_isAdminMode) ...[
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'نام کاربری',
                          prefixIcon: Icon(Icons.person, color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.redAccent, width: 2),
                          ),
                        ),
                        textDirection: TextDirection.ltr,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً نام کاربری را وارد کنید';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'رمز عبور',
                          prefixIcon: Icon(Icons.lock, color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.redAccent, width: 2),
                          ),
                        ),
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً رمز عبور را وارد کنید';
                          }
                          return null;
                        },
                      ),
                    ] else ...[
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'شماره موبایل',
                          prefixIcon: Icon(Icons.phone, color: Colors.red),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.red, width: 2),
                          ),
                          errorBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: UnderlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.redAccent, width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                        textDirection: TextDirection.ltr,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً شماره موبایل را وارد کنید';
                          }
                          if (!RegExp(r'^09\d{9}$').hasMatch(value)) {
                            return 'شماره موبایل باید 11 رقم و با 09 شروع شود';
                          }
                          return null;
                        },
                      ),
                      if (!_isLoginTab) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'نام',
                            prefixIcon: Icon(Icons.person, color: Colors.red),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.red, width: 2),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.redAccent, width: 2),
                            ),
                          ),
                          textDirection: TextDirection.rtl,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'لطفاً نام را وارد کنید';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'نام خانوادگی',
                            prefixIcon: Icon(Icons.person, color: Colors.red),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.red, width: 2),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.redAccent, width: 2),
                            ),
                          ),
                          textDirection: TextDirection.rtl,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'لطفاً نام خانوادگی را وارد کنید';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nicknameController,
                          decoration: const InputDecoration(
                            labelText: 'نام مستعار',
                            prefixIcon: Icon(Icons.badge, color: Colors.red),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.red, width: 2),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.redAccent, width: 2),
                            ),
                          ),
                          textDirection: TextDirection.rtl,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'لطفاً نام مستعار را وارد کنید';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'استان',
                            prefixIcon:
                                Icon(Icons.location_city, color: Colors.red),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.red, width: 2),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.redAccent, width: 2),
                            ),
                          ),
                          value: _provinceId,
                          items: provinces
                              .map((province) => DropdownMenuItem<int>(
                                    value: province.provinceId,
                                    child: Text(province.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _provinceId = value;
                              _cityId = null;
                              cities = []; // ریست کردن لیست شهرها
                              if (value != null) {
                                _loadCities(value); // لود کردن شهرها
                              }
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'لطفاً استان را انتخاب کنید';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'شهر',
                            prefixIcon:
                                Icon(Icons.location_on, color: Colors.red),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.red, width: 2),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.redAccent),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.redAccent, width: 2),
                            ),
                          ),
                          value: _cityId,
                          items: cities
                              .map((city) => DropdownMenuItem<int>(
                                    value: city.cityId,
                                    child: Text(city.name),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _cityId = value;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'لطفاً شهر را انتخاب کنید';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: _toggleAdminMode,
                      child: Text(
                        _isAdminMode
                            ? 'ورود به عنوان کاربر'
                            : 'ورود به عنوان ادمین',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (!_isAdminMode && _isLoginTab)
                      Column(
                        children: [
                          const Text(
                            'حساب کاربری ندارید؟',
                            style: TextStyle(
                                color: Colors.redAccent, fontSize: 14),
                          ),
                          TextButton(
                            onPressed: _switchToRegister,
                            child: const Text(
                              'ثبت‌نام کنید',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_errorMessage != null &&
                        _errorMessage != 'حساب کاربری ندارید؟')
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 14),
                      ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                _isAdminMode
                                    ? 'ورود ادمین'
                                    : _isLoginTab
                                        ? 'ورود'
                                        : 'ثبت‌نام',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}