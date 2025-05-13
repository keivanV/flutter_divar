import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  int? _provinceId;
  int? _cityId;
  bool _isLoginTab = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> provinces = [
    {'id': 1, 'name': 'Tehran'},
    {'id': 2, 'name': 'Isfahan'},
    {'id': 3, 'name': 'Fars'},
    {'id': 4, 'name': 'Khuzestan'},
    {'id': 5, 'name': 'Mazandaran'},
  ];

  final List<Map<String, dynamic>> cities = [
    {'id': 1, 'name': 'Tehran', 'province_id': 1},
    {'id': 2, 'name': 'Karaj', 'province_id': 1},
    {'id': 3, 'name': 'Isfahan', 'province_id': 2},
    {'id': 4, 'name': 'Kashan', 'province_id': 2},
    {'id': 5, 'name': 'Shiraz', 'province_id': 3},
    {'id': 6, 'name': 'Marvdasht', 'province_id': 3},
    {'id': 7, 'name': 'Ahvaz', 'province_id': 4},
    {'id': 8, 'name': 'Dezful', 'province_id': 4},
    {'id': 9, 'name': 'Sari', 'province_id': 5},
    {'id': 10, 'name': 'Babol', 'province_id': 5},
  ];

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
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
      if (_isLoginTab) {
        // ورود
        await authProvider.login(_phoneController.text);
      } else {
        // ثبت‌نام
        await authProvider.register({
          'phone_number': _phoneController.text,
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'nickname': _nicknameController.text,
          'province_id': _provinceId,
          'city_id': _cityId,
        });
      }
      // هدایت به صفحه اصلی
      Navigator.pushReplacementNamed(context, '/home');
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
                    // عنوان
                    Text(
                      _isLoginTab ? 'ورود به دیوار' : 'ثبت‌نام در دیوار',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 24),
                    // فیلد شماره موبایل
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
                      // فیلد نام
                      TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'نام',
                          prefixIcon:
                              Icon(Icons.person, color: Colors.red),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً نام را وارد کنید';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // فیلد نام خانوادگی
                      TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'نام خانوادگی',
                          prefixIcon:
                              Icon(Icons.person, color: Colors.red),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً نام خانوادگی را وارد کنید';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // فیلد نام مستعار
                      TextFormField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: 'نام مستعار',
                          prefixIcon:
                              Icon(Icons.badge, color: Colors.red),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'لطفاً نام مستعار را وارد کنید';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // انتخاب استان
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'استان',
                          prefixIcon: Icon(Icons.location_city,
                              color: Colors.red),
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
                        value: _provinceId,
                        items: provinces
                            .map((province) => DropdownMenuItem<int>(
                                  value: province['id'] as int,
                                  child: Text(province['name'] as String),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _provinceId = value;
                            _cityId = null; // ریست شهر
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
                      // انتخاب شهر
                      DropdownButtonFormField<int>(
                        decoration: const InputDecoration(
                          labelText: 'شهر',
                          prefixIcon:
                              Icon(Icons.location_on, color: Colors.red),
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
                        value: _cityId,
                        items: cities
                            .where((city) => city['province_id'] == _provinceId)
                            .map((city) => DropdownMenuItem<int>(
                                  value: city['id'] as int,
                                  child: Text(city['name'] as String),
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
                    const SizedBox(height: 24),
                    // پیام حساب کاربری و دکمه ثبت‌نام (همیشه نمایش داده می‌شود در تب ورود)
                    if (_isLoginTab)
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
                    // نمایش خطاهای دیگر
                    if (_errorMessage != null &&
                        _errorMessage != 'حساب کاربری ندارید؟')
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 14),
                      ),
                    const SizedBox(height: 16),
                    // دکمه ارسال
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
                                _isLoginTab ? 'ورود' : 'ثبت‌نام',
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
