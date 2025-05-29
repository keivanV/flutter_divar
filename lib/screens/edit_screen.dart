import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/ad.dart';
import '../providers/ad_provider.dart';
import 'package:intl/intl.dart';

class EditAdScreen extends StatefulWidget {
  final Ad ad;
  final String phoneNumber;

  const EditAdScreen({super.key, required this.ad, required this.phoneNumber});

  @override
  _EditAdScreenState createState() => _EditAdScreenState();
}

class _EditAdScreenState extends State<EditAdScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _areaController;
  late TextEditingController _constructionYearController;
  late TextEditingController _roomsController;
  late TextEditingController _depositController;
  late TextEditingController _monthlyRentController;
  late TextEditingController _floorController;
  late TextEditingController _brandController;
  late TextEditingController _modelController;
  late TextEditingController _mileageController;
  late TextEditingController _colorController;
  late TextEditingController _basePriceController;
  late TextEditingController _serviceTypeController;
  late TextEditingController _serviceDurationController;

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
  String _itemCondition = 'NEW';
  List<File> _newImages = [];
  List<String> _existingImages = [];

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

  final List<Map<String, dynamic>> conditionTypes = [
    {'id': 'NEW', 'name': 'نو'},
    {'id': 'USED', 'name': 'کارکرده'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeFields();
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

    final adProvider = Provider.of<AdProvider>(context, listen: false);
    adProvider.fetchProvinces();
    if (widget.ad.provinceId != null) {
      adProvider.fetchCities(widget.ad.provinceId!);
    }
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.ad.title);
    _descriptionController = TextEditingController(text: widget.ad.description);
    _priceController = TextEditingController(
      text: widget.ad.adType == 'REAL_ESTATE' &&
              widget.ad.realEstateType == 'SALE'
          ? widget.ad.totalPrice?.toString() ?? ''
          : widget.ad.adType == 'VEHICLE'
              ? widget.ad.basePrice?.toString() ?? ''
              : widget.ad.price?.toString() ?? '',
    );
    _areaController =
        TextEditingController(text: widget.ad.area?.toString() ?? '');
    _constructionYearController = TextEditingController(
        text: widget.ad.constructionYear?.toString() ?? '');
    _roomsController =
        TextEditingController(text: widget.ad.rooms?.toString() ?? '');
    _depositController =
        TextEditingController(text: widget.ad.deposit?.toString() ?? '');
    _monthlyRentController =
        TextEditingController(text: widget.ad.monthlyRent?.toString() ?? '');
    _floorController =
        TextEditingController(text: widget.ad.floor?.toString() ?? '');
    _brandController = TextEditingController(text: widget.ad.brand ?? '');
    _modelController = TextEditingController(text: widget.ad.model ?? '');
    _mileageController =
        TextEditingController(text: widget.ad.mileage?.toString() ?? '');
    _colorController = TextEditingController(text: widget.ad.color ?? '');
    _basePriceController =
        TextEditingController(text: widget.ad.basePrice?.toString() ?? '');
    _serviceTypeController =
        TextEditingController(text: widget.ad.serviceType ?? '');
    _serviceDurationController = TextEditingController(
        text: widget.ad.serviceDuration?.toString() ?? '');
  }

  void _initializeFields() {
    _category = widget.ad.adType;
    _realEstateType = widget.ad.realEstateType;
    _provinceId = widget.ad.provinceId;
    _cityId = widget.ad.cityId;
    _hasParking = widget.ad.hasParking ?? false;
    _hasStorage = widget.ad.hasStorage ?? false;
    _hasBalcony = widget.ad.hasBalcony ?? false;
    _gearbox = widget.ad.gearbox ?? 'MANUAL';
    _engineStatus = widget.ad.engineStatus ?? 'HEALTHY';
    _chassisStatus = widget.ad.chassisStatus ?? 'HEALTHY';
    _bodyStatus = widget.ad.bodyStatus ?? 'HEALTHY';
    _itemCondition = widget.ad.itemCondition ?? 'NEW';
    _existingImages = widget
        .ad.imageUrls; // Changed from widget.ad.images to widget.ad.imageUrls
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
    _serviceTypeController.dispose();
    _serviceDurationController.dispose();
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
          if (_newImages.length + _existingImages.length < 5) {
            setState(() {
              _newImages.add(File(pickedFile.path));
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('حداکثر 5 تصویر می‌توانید اضافه کنید'),
              ),
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
        SnackBar(
          content: Text('لطفاً تمام فیلدهای اجباری را پر کنید'),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    final adProvider = Provider.of<AdProvider>(context, listen: false);
    try {
      // Validate images
      if (_newImages.isEmpty && _existingImages.isEmpty) {
        throw Exception('حداقل یک تصویر برای آگهی الزامی است');
      }

      // Initialize variables
      String? price;
      int? totalPrice;
      int? deposit;
      int? monthlyRent;
      int? pricePerMeter;
      int? area;
      int? constructionYear;
      int? rooms;
      int? floor;
      int? mileage;
      int? basePrice;
      int? serviceDuration;

      // Use existing ad values as defaults
      String title = _titleController.text.isNotEmpty
          ? _titleController.text
          : widget.ad.title;
      String description = _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : widget.ad.description;
      String adType = _category ?? widget.ad.adType;
      int provinceId = _provinceId ?? widget.ad.provinceId;
      int cityId = _cityId ?? widget.ad.cityId;
      String phoneNumber = widget.phoneNumber;

      // Validate required fields
      if (title.trim().isEmpty) {
        throw Exception('عنوان آگهی نمی‌تواند خالی باشد');
      }
      if (description.trim().isEmpty) {
        throw Exception('توضیحات آگهی نمی‌تواند خالی باشد');
      }
      if (![
        'REAL_ESTATE',
        'VEHICLE',
        'DIGITAL',
        'HOME',
        'SERVICES',
        'PERSONAL',
        'ENTERTAINMENT'
      ].contains(adType)) {
        throw Exception('نوع آگهی نامعتبر است');
      }
      if (phoneNumber.trim().isEmpty) {
        throw Exception('شماره تلفن نمی‌تواند خالی باشد');
      }
      if (provinceId <= 0) {
        throw Exception('لطفاً استان را انتخاب کنید');
      }
      if (cityId <= 0) {
        throw Exception('لطفاً شهر را انتخاب کنید');
      }

      if (adType == 'REAL_ESTATE') {
        area = _areaController.text.isNotEmpty
            ? int.parse(_areaController.text)
            : widget.ad.area;
        constructionYear = _constructionYearController.text.isNotEmpty
            ? int.parse(_constructionYearController.text)
            : widget.ad.constructionYear;
        rooms = _roomsController.text.isNotEmpty
            ? int.parse(_roomsController.text)
            : widget.ad.rooms;
        floor = _floorController.text.isNotEmpty
            ? int.parse(_floorController.text)
            : widget.ad.floor;

        if (_realEstateType == 'SALE') {
          totalPrice = _priceController.text.isNotEmpty
              ? int.parse(_priceController.text.replaceAll(',', ''))
              : widget.ad.totalPrice;
          price = totalPrice?.toString();
          if (area != null && totalPrice != null && area > 0) {
            pricePerMeter = totalPrice ~/ area;
          }
        } else if (_realEstateType == 'RENT') {
          deposit = _depositController.text.isNotEmpty
              ? int.parse(_depositController.text.replaceAll(',', ''))
              : widget.ad.deposit;
          monthlyRent = _monthlyRentController.text.isNotEmpty
              ? int.parse(_monthlyRentController.text.replaceAll(',', ''))
              : widget.ad.monthlyRent;
          price = deposit?.toString();
        }

        if (area == null || area <= 0) {
          throw Exception('مساحت باید یک عدد معتبر و بزرگ‌تر از صفر باشد');
        }
        if (constructionYear == null ||
            constructionYear < 1300 ||
            constructionYear > 1404) {
          throw Exception('سال ساخت باید بین ۱۳۰۰ تا 1404 باشد');
        }
        if (rooms == null || rooms < 0) {
          throw Exception('تعداد اتاق باید عدد معتبر غیرمنفع باشد');
        }
        if (floor == null) {
          throw Exception('طبقه باید عدد معتبر باشد');
        }
        if (_realEstateType == 'SALE' &&
            (totalPrice == null || totalPrice < 0)) {
          throw Exception(
              'قیمت کل برای فروش املاک الزامی و باید عدد معتبر باشد');
        }
        if (_realEstateType == 'RENT') {
          if (deposit == null || deposit < 0) {
            throw Exception(
                'ودیعه برای اجاره املاک الزامی و باید عدد معتبر باشد');
          }
          if (monthlyRent == null || monthlyRent < 0) {
            throw Exception(
                'اجاره ماهانه برای اجاره املاک الزامی و باید عدد معتبر باشد');
          }
        }
      } else if (adType == 'VEHICLE') {
        mileage = _mileageController.text.isNotEmpty
            ? int.parse(_mileageController.text)
            : widget.ad.mileage;
        basePrice = _basePriceController.text.isNotEmpty
            ? int.parse(_basePriceController.text.replaceAll(',', ''))
            : widget.ad.basePrice;
        if (mileage == null || mileage < 0) {
          throw Exception('کارکرد خودرو باید عدد معتبر غیرمنفع باشد');
        }
        if (basePrice == null || basePrice < 0) {
          throw Exception('قیمت پایه خودرو الزامی و باید عدد معتبر باشد');
        }
        price = basePrice?.toString();
      } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT']
          .contains(adType)) {
        price = _priceController.text.isNotEmpty
            ? _priceController.text.replaceAll(',', '')
            : widget.ad.price?.toString() ?? '0';
        if (int.tryParse(price) == null || int.parse(price) < 0) {
          throw Exception('قیمت باید عدد معتبر غیرمنفع باشد');
        }
      } else if (adType == 'SERVICES') {
        price = _priceController.text.isNotEmpty
            ? _priceController.text.replaceAll(',', '')
            : widget.ad.price?.toString() ?? '0';
        if (int.tryParse(price) == null || int.parse(price) < 0) {
          throw Exception('هزینه خدمت باید عدد معتبر غیرمنفع باشد');
        }
        serviceDuration = _serviceDurationController.text.isNotEmpty
            ? int.parse(_serviceDurationController.text)
            : null;
      }

      // Log the data being sent
      final adData = {
        'adId': widget.ad.adId,
        'title': title,
        'description': description,
        'adType': adType,
        'price': price,
        'provinceId': provinceId,
        'cityId': cityId,
        'phoneNumber': phoneNumber,
        'realEstateType': _realEstateType ?? widget.ad.realEstateType,
        'area': area,
        'constructionYear': constructionYear,
        'rooms': rooms,
        'totalPrice': totalPrice,
        'pricePerMeter': pricePerMeter,
        'hasParking': _hasParking,
        'hasStorage': _hasStorage,
        'hasBalcony': _hasBalcony,
        'deposit': deposit,
        'monthlyRent': monthlyRent,
        'floor': floor,
        'brand': _brandController.text.isNotEmpty
            ? _brandController.text
            : widget.ad.brand,
        'model': _modelController.text.isNotEmpty
            ? _modelController.text
            : widget.ad.model,
        'mileage': mileage,
        'color': _colorController.text.isNotEmpty
            ? _colorController.text
            : widget.ad.color,
        'gearbox': _gearbox,
        'basePrice': basePrice,
        'engineStatus': _engineStatus,
        'chassisStatus': _chassisStatus,
        'bodyStatus': _bodyStatus,
        'itemCondition': _itemCondition,
        'serviceType': _serviceTypeController.text.isNotEmpty
            ? _serviceTypeController.text
            : widget.ad.serviceType,
        'serviceDuration': serviceDuration,
      };
      print('Updating ad with data: $adData');
      print('New images count: ${_newImages.length}');
      print('Existing images: $_existingImages');

      await adProvider.updateAd(
        adId: widget.ad.adId,
        title: title,
        description: description,
        adType: adType,
        price: price,
        provinceId: provinceId,
        cityId: cityId,
        images: _newImages,
        existingImages: _existingImages,
        phoneNumber: phoneNumber,
        realEstateType: _realEstateType ?? widget.ad.realEstateType,
        area: area,
        constructionYear: constructionYear,
        rooms: rooms,
        totalPrice: totalPrice,
        pricePerMeter: pricePerMeter,
        hasParking: _hasParking,
        hasStorage: _hasStorage,
        hasBalcony: _hasBalcony,
        deposit: deposit,
        monthlyRent: monthlyRent,
        floor: floor,
        brand: _brandController.text.isNotEmpty
            ? _brandController.text
            : widget.ad.brand,
        model: _modelController.text.isNotEmpty
            ? _modelController.text
            : widget.ad.model,
        mileage: mileage,
        color: _colorController.text.isNotEmpty
            ? _colorController.text
            : widget.ad.color,
        gearbox: _gearbox,
        basePrice: basePrice,
        engineStatus: _engineStatus,
        chassisStatus: _chassisStatus,
        bodyStatus: _bodyStatus,
        itemCondition: _itemCondition,
        serviceType: _serviceTypeController.text.isNotEmpty
            ? _serviceTypeController.text
            : widget.ad.serviceType,
        serviceDuration: serviceDuration,
      );

      if (adProvider.errorMessage == null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('آگهی با موفقیت ویرایش شد')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(adProvider.errorMessage!)),
          );
        }
      }
    } catch (e) {
      print('Submit error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating ad: ${e.toString()}'),
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
        labelStyle: const TextStyle(fontFamily: 'Vazir'),
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
        labelStyle: const TextStyle(fontFamily: 'Vazir'),
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
      ),
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('ویرایش آگهی',
                style: TextStyle(fontFamily: 'Vazir')),
            centerTitle: true,
            backgroundColor: Colors.red,
          ),
          body: SafeArea(
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
                              _itemCondition = 'NEW';
                              _brandController.clear();
                              _modelController.clear();
                              _priceController.clear();
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
                                return 'لطفاً سال ساخت بین ۱۳۰۰ تا ۱۴۰۴ وارد کنید';
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
                          if (_realEstateType == 'SALE') ...[
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
                          ],
                          if (_realEstateType == 'RENT') ...[
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _depositController,
                              label: 'ودیعه (تومان)',
                              icon: Icons.account_balance_wallet,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً ودیعه را وارد کنید';
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
                              controller: _monthlyRentController,
                              label: 'اجاره ماهانه (تومان)',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'لطفاً اجاره ماهانه را وارد کنید';
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
                            title: const Text('پارکینگ',
                                style: TextStyle(fontFamily: 'Vazir')),
                            value: _hasParking,
                            onChanged: (value) {
                              setState(() {
                                _hasParking = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('انباری',
                                style: TextStyle(fontFamily: 'Vazir')),
                            value: _hasStorage,
                            onChanged: (value) {
                              setState(() {
                                _hasStorage = value!;
                              });
                            },
                          ),
                          CheckboxListTile(
                            title: const Text('بالکن',
                                style: TextStyle(fontFamily: 'Vazir')),
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
                            label: 'برند خودرو',
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
                            label: 'مدل خودرو',
                            icon: Icons.car_repair,
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
                                return 'لطفاً کارکرد خودرو را وارد کنید';
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
                            label: 'رنگ خودرو',
                            icon: Icons.color_lens,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً رنگ خودرو را وارد کنید';
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
                                return 'لطفاً قیمت پایه خودرو را وارد کنید';
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
                            icon: Icons.car_crash,
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
                            icon: Icons.directions_car_filled,
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
                        ] else if ([
                          'DIGITAL',
                          'HOME',
                          'PERSONAL',
                          'ENTERTAINMENT'
                        ].contains(_category)) ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _brandController,
                            label: 'برند',
                            icon: Icons.branding_watermark,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً برند را وارد کنید';
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
                                return 'لطفاً مدل را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildDropdownField<String>(
                            label: 'وضعیت',
                            icon: Icons.check_circle,
                            value: _itemCondition,
                            items: conditionTypes
                                .map((type) => DropdownMenuItem<String>(
                                      value: type['id'],
                                      child: Text(type['name']),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _itemCondition = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null) {
                                return 'لطفاً وضعیت را انتخاب کنید';
                              }
                              return null;
                            },
                          ),
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
                        ] else if (_category == 'SERVICES') ...[
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _serviceTypeController,
                            label: 'نوع خدمت',
                            icon: Icons.work,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً نوع خدمت را وارد کنید';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _serviceDurationController,
                            label: 'مدت زمان خدمت (اختیاری)',
                            icon: Icons.timer,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final number = int.tryParse(value);
                                if (number == null || number <= 0) {
                                  return 'لطفاً یک عدد معتبر وارد کنید';
                                }
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _priceController,
                            label: 'هزینه خدمت (تومان)',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'لطفاً هزینه خدمت را وارد کنید';
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
                          items: adProvider.provinces
                              .map((province) => DropdownMenuItem<int>(
                                    value: province.provinceId,
                                    child: Text(province.name),
                                  ))
                              .toList(),
                          onChanged: (value) async {
                            setState(() {
                              _provinceId = value;
                              _cityId = null;
                            });
                            if (value != null) {
                              await adProvider.fetchCities(value);
                            }
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'لطفاً استان را انتخاب کنید';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        adProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : _buildDropdownField<int>(
                                label: 'شهر',
                                icon: Icons.location_on,
                                value: _cityId,
                                items: adProvider.cities
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
                        if (adProvider.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              adProvider.errorMessage!,
                              style: const TextStyle(
                                  color: Colors.redAccent, fontSize: 14),
                            ),
                          ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'تصاویر آگهی (${_newImages.length + _existingImages.length}/5)',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Vazir',
                                  ),
                            ),
                            ElevatedButton.icon(
                              onPressed:
                                  _newImages.length + _existingImages.length < 5
                                      ? _pickImages
                                      : null,
                              icon: const Icon(Icons.add_a_photo, size: 20),
                              label: const Text('افزودن تصویر',
                                  style: TextStyle(fontFamily: 'Vazir')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_existingImages.isNotEmpty || _newImages.isNotEmpty)
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  _existingImages.length + _newImages.length,
                              itemBuilder: (context, index) {
                                if (index < _existingImages.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: DecorationImage(
                                              image: NetworkImage(
                                                  _existingImages[index]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _existingImages.removeAt(index);
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  final newImageIndex =
                                      index - _existingImages.length;
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 100,
                                          height: 100,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: DecorationImage(
                                              image: FileImage(
                                                  _newImages[newImageIndex]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            iconSize: 20,
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                                Icons.remove_circle,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                _newImages
                                                    .removeAt(newImageIndex);
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        const SizedBox(height: 32),
                        ElevatedButton(
                          onPressed: adProvider.isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: adProvider.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'ذخیره تغییرات',
                                  style: TextStyle(
                                    fontFamily: 'Vazir',
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
      },
    );
  }
}
