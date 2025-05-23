import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class PostAdScreen extends StatefulWidget {
  const PostAdScreen({super.key});

  @override
  _PostAdScreenState createState() => _PostAdScreenState();
}

class _PostAdScreenState extends State<PostAdScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _constructionYearController = TextEditingController();
  final _roomsController = TextEditingController();
  final _depositController = TextEditingController();
  final _monthlyRentController = TextEditingController();
  final _floorController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _mileageController = TextEditingController();
  final _colorController = TextEditingController();
  final _basePriceController = TextEditingController();
  String? _category;
  String? _realEstateType;
  int? _provinceId;
  int? _cityId;
  bool _hasParking = false;
  bool _hasStorage = false;
  bool _hasBalcony = false;
  String _gearbox = 'MANUAL';
  String _engineStatus = 'HEALTHY';
  String _chassisStatus = 'HEALTHY';
  String _bodyStatus = 'HEALTHY';

  List<File> _images = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> categories = [
    {'id': 'REAL_ESTATE', 'name': 'املاک'},
    {'id': 'VEHICLE', 'name': 'وسایل نقلیه'},
    {'id': 'DIGITAL', 'name': 'لوازم الکترونیکی'},
    {'id': 'HOME', 'name': 'لوازم خانگی'},
    {'id': 'SERVICES', 'name': 'خدمات'},
    {'id': 'PERSONAL', 'name': 'وسایل شخصی'},
    {'id': 'ENTERTAINMENT', 'name': 'سرگرمی و فراغت'},
  ];

  final List<Map<String, dynamic>> realEstateTypes = [
    {'id': 'SALE', 'name': 'فروش'},
    {'id': 'RENT', 'name': 'اجاره'},
  ];

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
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _priceController.addListener(_formatNumber);
    _depositController.addListener(_formatNumber);
    _monthlyRentController.addListener(_formatNumber);
    _basePriceController.addListener(_formatNumber);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.removeListener(_formatNumber);
    _priceController.dispose();
    _areaController.dispose();
    _constructionYearController.dispose();
    _roomsController.dispose();
    _depositController.removeListener(_formatNumber);
    _depositController.dispose();
    _monthlyRentController.removeListener(_formatNumber);
    _monthlyRentController.dispose();
    _floorController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _mileageController.dispose();
    _colorController.dispose();
    _basePriceController.removeListener(_formatNumber);
    _basePriceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _formatNumber() {
    for (var controller in [
      _priceController,
      _depositController,
      _monthlyRentController,
      _basePriceController
    ]) {
      final text = controller.text.replaceAll(',', '');
      if (text.isEmpty) continue;

      final number = int.tryParse(text);
      if (number == null || number < 0) continue;

      final formatter = NumberFormat('#,###');
      final formatted = formatter.format(number);
      if (controller.text != formatted) {
        controller
          ..text = formatted
          ..selection = TextSelection.collapsed(offset: formatted.length);
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('انتخاب منبع تصویر'),
          content: const Text('لطفاً منبع تصویر را انتخاب کنید:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: const Text('دوربین'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: const Text('گالری'),
            ),
          ],
        ),
      );

      if (source != null) {
        final picker = ImagePicker();
        final pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 80,
        );
        if (pickedFile != null) {
          final fileExtension = pickedFile.path.split('.').last.toLowerCase();
          if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('فقط تصاویر JPEG و PNG مجاز هستند')),
            );
            return;
          }
          if (_images.length < 5) {
            setState(() {
              _images.add(File(pickedFile.path));
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('حداکثر 5 تصویر می‌توانید اضافه کنید')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در انتخاب تصویر: $e')),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً تمام فیلدهای اجباری را پر کنید'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final adProvider = Provider.of<AdProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.phoneNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لطفاً ابتدا وارد حساب خود شوید'),
          duration: Duration(seconds: 5),
        ),
      );
      Navigator.pushNamed(context, '/auth');
      return;
    }

    try {
      print(
          'Submitting ad with category: $_category, province: $_provinceId, city: $_cityId');
      await adProvider.postAd(
        title: _titleController.text,
        description: _descriptionController.text,
        adType: _category!,
        price: _category == 'VEHICLE'
            ? _basePriceController.text.replaceAll(',', '')
            : _priceController.text.replaceAll(',', ''),
        provinceId: _provinceId!,
        cityId: _cityId!,
        images: _images,
        phoneNumber: authProvider.phoneNumber!,
        realEstateType: _category == 'REAL_ESTATE' ? _realEstateType : null,
        area: _category == 'REAL_ESTATE' ? _areaController.text : null,
        constructionYear: _category == 'REAL_ESTATE'
            ? _constructionYearController.text
            : null,
        rooms: _category == 'REAL_ESTATE' ? _roomsController.text : null,
        totalPrice: _category == 'REAL_ESTATE'
            ? _priceController.text.replaceAll(',', '')
            : null,
        pricePerMeter: _category == 'REAL_ESTATE'
            ? (int.parse(_priceController.text.replaceAll(',', '')) ~/
                    int.parse(_areaController.text))
                .toString()
            : null,
        hasParking: _category == 'REAL_ESTATE' ? _hasParking : null,
        hasStorage: _category == 'REAL_ESTATE' ? _hasStorage : null,
        hasBalcony: _category == 'REAL_ESTATE' ? _hasBalcony : null,
        deposit: _category == 'REAL_ESTATE'
            ? _depositController.text.replaceAll(',', '')
            : null,
        monthlyRent: _category == 'REAL_ESTATE'
            ? _monthlyRentController.text.replaceAll(',', '')
            : null,
        floor: _category == 'REAL_ESTATE' ? _floorController.text : null,
        brand: _category == 'VEHICLE' ? _brandController.text : null,
        model: _category == 'VEHICLE' ? _modelController.text : null,
        mileage: _category == 'VEHICLE' ? _mileageController.text : null,
        color: _category == 'VEHICLE' ? _colorController.text : null,
        gearbox: _category == 'VEHICLE' ? _gearbox : null,
        basePrice: _category == 'VEHICLE'
            ? _basePriceController.text.replaceAll(',', '')
            : null,
        engineStatus: _category == 'VEHICLE' ? _engineStatus : null,
        chassisStatus: _category == 'VEHICLE' ? _chassisStatus : null,
        bodyStatus: _category == 'VEHICLE' ? _bodyStatus : null,
      );

      if (adProvider.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('آگهی با موفقیت ثبت شد'),
            duration: Duration(seconds: 5),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adProvider.errorMessage!),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('Error in _submit: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطا در ثبت آگهی: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required IconData icon,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.red),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[600]),
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت آگهی'),
        backgroundColor: Colors.red,
        elevation: 2,
      ),
      body: Consumer<AdProvider>(
        builder: (context, adProvider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTextField(
                          controller: _titleController,
                          label: 'عنوان آگهی',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'لطفاً عنوان آگهی را وارد کنید';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'توضیحات آگهی',
                          icon: Icons.description,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'لطفاً توضیحات آگهی را وارد کنید';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildDropdownField<String>(
                          label: 'دسته‌بندی',
                          icon: Icons.category,
                          value: _category,
                          items: categories
                              .map((cat) => DropdownMenuItem<String>(
                                    value: cat['id'],
                                    child: Text(cat['name']),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _category = value;
                              _realEstateType = null;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'لطفاً دسته‌بندی را انتخاب کنید';
                            }
                            return null;
                          },
                        ),
                        if (_category == 'REAL_ESTATE') ...[
                          const SizedBox(height: 20),
                          _buildDropdownField<String>(
                            label: 'نوع معامله',
                            icon: Icons.swap_horiz,
                            value: _realEstateType,
                            items: realEstateTypes
                                .map((type) => DropdownMenuItem<String>(
                                      value: type['id'],
                                      child: Text(type['name']),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _realEstateType = value;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً نوع معامله را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _areaController,
                            label: 'مساحت (متر مربع)',
                            icon: Icons.square_foot,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً مساحت را وارد کنید';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number <= 0) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _constructionYearController,
                            label: 'سال ساخت',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً سال ساخت را وارد کنید';
                              }
                              final number = int.tryParse(value);
                              if (number == null ||
                                  number < 1300 ||
                                  number > 1404) {
                                return 'لطفاً یک سال معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _roomsController,
                            label: 'تعداد اتاق',
                            icon: Icons.king_bed,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً تعداد اتاق را وارد کنید';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number < 0) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _priceController,
                            label: 'قیمت کل (تومان)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً قیمت را وارد کنید';
                              }
                              final number =
                                  int.tryParse(value.replaceAll(',', ''));
                              if (number == null || number < 0) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _depositController,
                            label: 'ودیعه (تومان)',
                            icon: Icons.account_balance_wallet,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_realEstateType == 'RENT' &&
                                  (value == null || value.isEmpty)) {
                                return 'لطفاً ودیعه را وارد کنید';
                              }
                              final number = int.tryParse(
                                  value?.replaceAll(',', '') ?? '');
                              if (number != null && number < 0) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _monthlyRentController,
                            label: 'اجاره ماهانه (تومان)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (_realEstateType == 'RENT' &&
                                  (value == null || value.isEmpty)) {
                                return 'لطفاً اجاره ماهانه را وارد کنید';
                              }
                              final number = int.tryParse(
                                  value?.replaceAll(',', '') ?? '');
                              if (number != null && number < 0) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _floorController,
                            label: 'طبقه',
                            icon: Icons.elevator,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً طبقه را وارد کنید';
                              }
                              final number = int.tryParse(value);
                              if (number == null) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          CheckboxListTile(
                            title: const Text('پارکینگ'),
                            value: _hasParking,
                            onChanged: (value) {
                              setState(() {
                                _hasParking = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('انباری'),
                            value: _hasStorage,
                            onChanged: (value) {
                              setState(() {
                                _hasStorage = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('بالکن'),
                            value: _hasBalcony,
                            onChanged: (value) {
                              setState(() {
                                _hasBalcony = value!;
                              });
                            },
                          ),
                        ] else if (_category == 'VEHICLE') ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _brandController,
                            label: 'برند',
                            icon: Icons.directions_car,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً برند خودرو را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _modelController,
                            label: 'مدل',
                            icon: Icons.model_training,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً مدل خودرو را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _mileageController,
                            label: 'کارکرد (کیلومتر)',
                            icon: Icons.speed,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً کارکرد را وارد کنید';
                              }
                              final number = int.tryParse(value);
                              if (number == null || number < 0) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _colorController,
                            label: 'رنگ',
                            icon: Icons.color_lens,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً رنگ خودرو را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildDropdownField<String>(
                            label: 'نوع گیربکس',
                            icon: Icons.settings,
                            value: _gearbox,
                            items: const [
                              DropdownMenuItem(
                                  value: 'MANUAL', child: Text('دستی')),
                              DropdownMenuItem(
                                  value: 'AUTOMATIC', child: Text('اتوماتیک')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _gearbox = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً نوع گیربکس را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _basePriceController,
                            label: 'قیمت پایه (تومان)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً قیمت پایه را وارد کنید';
                              }
                              final number =
                                  int.tryParse(value.replaceAll(',', ''));
                              if (number == null || number < 0) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildDropdownField<String>(
                            label: 'وضعیت موتور',
                            icon: Icons.engineering,
                            value: _engineStatus,
                            items: const [
                              DropdownMenuItem(
                                  value: 'HEALTHY', child: Text('سالم')),
                              DropdownMenuItem(
                                  value: 'NEEDS_REPAIR',
                                  child: Text('نیاز به تعمیر')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _engineStatus = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً وضعیت موتور را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildDropdownField<String>(
                            label: 'وضعیت شاسی',
                            icon: Icons.car_repair,
                            value: _chassisStatus,
                            items: const [
                              DropdownMenuItem(
                                  value: 'HEALTHY', child: Text('سالم')),
                              DropdownMenuItem(
                                  value: 'IMPACTED', child: Text('تصادفی')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _chassisStatus = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً وضعیت شاسی را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildDropdownField<String>(
                            label: 'وضعیت بدنه',
                            icon: Icons.car_crash,
                            value: _bodyStatus,
                            items: const [
                              DropdownMenuItem(
                                  value: 'HEALTHY', child: Text('سالم')),
                              DropdownMenuItem(
                                  value: 'MINOR_SCRATCH',
                                  child: Text('خط و خش جزیی')),
                              DropdownMenuItem(
                                  value: 'ACCIDENTED', child: Text('تصادفی')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _bodyStatus = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً وضعیت بدنه را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _priceController,
                            label: 'قیمت (تومان)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً قیمت را وارد کنید';
                              }
                              final number =
                                  int.tryParse(value.replaceAll(',', ''));
                              if (number == null || number < 0) {
                                return 'لطفاً یک عدد معتبر وارد کنید';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        _buildDropdownField<int>(
                          label: 'استان',
                          icon: Icons.location_city,
                          value: _provinceId,
                          items: provinces.map((province) {
                            final id = province['id'] is String
                                ? int.parse(province['id'])
                                : province['id'] as int;
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(province['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _provinceId = value;
                              _cityId = null;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'لطفاً استان را انتخاب کنید';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildDropdownField<int>(
                          label: 'شهر',
                          icon: Icons.location_on,
                          value: _cityId,
                          items: cities
                              .where(
                                  (city) => city['province_id'] == _provinceId)
                              .map((city) {
                            final id = city['id'] is String
                                ? int.parse(city['id'])
                                : city['id'] as int;
                            return DropdownMenuItem<int>(
                              value: id,
                              child: Text(city['name']),
                            );
                          }).toList(),
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تصاویر آگهی (${_images.length}/5)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  _images.length < 5 ? _pickImages : null,
                              icon: const Icon(Icons.add_a_photo, size: 20),
                              label: const Text('افزودن تصویر'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 3,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_images.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _images.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Stack(
                                    children: [
                                      GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
                                                blurRadius: 5,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                            image: DecorationImage(
                                              image: FileImage(_images[index]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 5,
                                        left: 5,
                                        child: IconButton(
                                          icon: const Icon(Icons.remove_circle,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _images.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 32),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red,
                                Colors.redAccent.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: adProvider.isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: adProvider.isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'ثبت آگهی',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
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
          );
        },
      ),
    );
  }
}
