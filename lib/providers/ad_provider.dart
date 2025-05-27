import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ad.dart';
import '../services/api_service.dart';
import '../models/province.dart';
import '../models/city.dart';

class AdProvider with ChangeNotifier {
  List<Ad> _ads = [];
  List<Ad> _userAds = [];
  List<Ad> _searchResults = [];
  List<Province> _provinces = [];
  List<Ad> _commentRelatedAds = [];
  List<City> _cities = [];
  bool _isLoading = false;
  String? _sortBy;
  String? _errorMessage;
  String? _adType;
  String? _realEstateType;
  int? _provinceId;
  int? _cityId;

  List<Ad> get ads => _ads;
  List<Ad> get userAds => _userAds;
  List<Ad> get searchResults => _searchResults;
  List<Province> get provinces => _provinces;
  List<Ad> get commentRelatedAds => _commentRelatedAds;
  List<City> get cities => _cities;
  bool get isLoading => _isLoading;
  String? get sortBy => _sortBy;
  String? get errorMessage => _errorMessage;
  String? get adType => _adType;
  String? get realEstateType => _realEstateType;
  int? get selectedProvinceId => _provinceId;
  int? get selectedCityId => _cityId;

  final ApiService _apiService = ApiService();
  static const List<String> _validSortByValues = [
    'newest',
    'oldest',
    'price_asc',
    'price_desc'
  ];

  AdProvider() {
    _sortBy = null;
    fetchAds();
  }

  Ad? getAdById(int adId) {
    try {
      return _commentRelatedAds.firstWhere(
        (ad) => ad.adId == adId,
        orElse: () => _ads.firstWhere(
          (ad) => ad.adId == adId,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<Ad?> fetchAdById(int adId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Fetching ad with adId: $adId');
      final ad = await _apiService.fetchAdById(adId);
      if (ad != null) {
        print('Fetched ad: ${ad.toJson()}');
        // Update _ads, avoiding duplicates
        _ads = [..._ads.where((a) => a.adId != adId), ad];
        notifyListeners();
        return ad;
      } else {
        _errorMessage = 'آگهی با شناسه $adId یافت نشد';
        print('Error: $_errorMessage');
        return null;
      }
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching ad by ID: $_errorMessage');
      print('Stack trace: $stackTrace');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCommentRelatedAds(List<int> adIds) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Fetching comment-related ads for adIds: $adIds');
      final ads = await _apiService.fetchAdsByIds(adIds);
      print('Fetched ${ads.length} comment-related ads');
      _commentRelatedAds = ads;
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching comment-related ads: $_errorMessage');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postAd({
    required String title,
    required String description,
    required String adType,
    String? price,
    required int provinceId,
    required int cityId,
    List<File> images = const [],
    required String phoneNumber,
    String? realEstateType,
    String? area,
    String? constructionYear,
    String? rooms,
    String? totalPrice,
    String? pricePerMeter,
    bool? hasParking,
    bool? hasStorage,
    bool? hasBalcony,
    String? deposit,
    String? monthlyRent,
    String? floor,
    String? brand,
    String? model,
    String? mileage,
    String? color,
    String? gearbox,
    String? basePrice,
    String? engineStatus,
    String? chassisStatus,
    String? bodyStatus,
    String? itemCondition, // For DIGITAL, HOME, PERSONAL, ENTERTAINMENT
    String? serviceType, // For SERVICES
    String? serviceDuration, // For SERVICES
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhoneNumber.length != 11) {
        throw Exception('شماره تلفن باید ۱۱ رقم باشد');
      }

      String effectivePrice;
      if (adType == 'VEHICLE') {
        if (basePrice == null || int.tryParse(basePrice) == null) {
          throw Exception('قیمت پایه خودرو الزامی و باید عدد معتبر باشد');
        }
        effectivePrice = basePrice;
      } else if (adType == 'REAL_ESTATE') {
        if (realEstateType == null ||
            !['SALE', 'RENT'].contains(realEstateType)) {
          throw Exception('نوع معامله املاک (فروش یا اجاره) الزامی است');
        }
        if (area == null ||
            int.tryParse(area) == null ||
            int.parse(area) <= 0) {
          throw Exception('مساحت الزامی و باید عدد معتبر بزرگ‌تر از صفر باشد');
        }
        if (constructionYear == null ||
            int.tryParse(constructionYear) == null ||
            int.parse(constructionYear) < 1300 ||
            int.parse(constructionYear) > 1404) {
          throw Exception('سال ساخت الزامی و باید بین ۱۳۰۰ تا ۱۴۰۴ باشد');
        }
        if (rooms == null ||
            int.tryParse(rooms) == null ||
            int.parse(rooms) < 0) {
          throw Exception('تعداد اتاق الزامی و باید عدد معتبر غیرمنفی باشد');
        }
        if (floor == null || int.tryParse(floor) == null) {
          throw Exception('طبقه الزامی و باید عدد معتبر باشد');
        }
        if (realEstateType == 'SALE') {
          if (totalPrice == null || int.tryParse(totalPrice) == null) {
            throw Exception(
                'قیمت کل برای فروش املاک الزامی و باید عدد معتبر باشد');
          }
          effectivePrice = totalPrice;
        } else {
          // RENT
          if (deposit == null || int.tryParse(deposit) == null) {
            throw Exception(
                'ودیعه برای اجاره املاک الزامی و باید عدد معتبر باشد');
          }
          if (monthlyRent == null || int.tryParse(monthlyRent) == null) {
            throw Exception(
                'اجاره ماهانه برای اجاره املاک الزامی و باید عدد معتبر باشد');
          }
          effectivePrice = deposit; // Use deposit as price for RENT ads
        }
      } else if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT']
          .contains(adType)) {
        if (brand == null || brand.isEmpty) {
          throw Exception('برند الزامی است');
        }
        if (model == null || model.isEmpty) {
          throw Exception('مدل الزامی است');
        }
        if (itemCondition == null || !['NEW', 'USED'].contains(itemCondition)) {
          throw Exception('وضعیت باید "نو" یا "کارکرده" باشد');
        }
        effectivePrice = price ?? '0';
      } else if (adType == 'SERVICES') {
        if (serviceType == null || serviceType.isEmpty) {
          throw Exception('نوع خدمت الزامی است');
        }
        if (serviceDuration != null && serviceDuration.isNotEmpty) {
          if (int.tryParse(serviceDuration) == null ||
              int.parse(serviceDuration) <= 0) {
            throw Exception('مدت زمان خدمت باید عدد مثبت باشد');
          }
        }
        effectivePrice = price ?? '0';
      } else {
        effectivePrice = price ?? '0';
      }

      int? calculatedPricePerMeter;
      if (adType == 'REAL_ESTATE') {
        if (realEstateType == 'RENT' && deposit != null && area != null) {
          final areaInt = int.parse(area);
          final depositInt = int.parse(deposit);
          calculatedPricePerMeter =
              depositInt ~/ areaInt; // Price per meter for RENT
        } else if (realEstateType == 'SALE' && pricePerMeter != null) {
          calculatedPricePerMeter =
              int.parse(pricePerMeter); // Price per meter for SALE
        }
      }

      final adData = {
        'title': title,
        'description': description,
        'ad_type': adType,
        'price': effectivePrice,
        'province_id': provinceId,
        'city_id': cityId,
        'owner_phone_number': cleanPhoneNumber,
        if (adType == 'REAL_ESTATE') ...{
          'real_estate_type': realEstateType,
          'area': area != null ? int.parse(area) : null,
          'construction_year':
              constructionYear != null ? int.parse(constructionYear) : null,
          'rooms': rooms != null ? int.parse(rooms) : null,
          'total_price': realEstateType == 'RENT'
              ? 0
              : (totalPrice != null ? int.parse(totalPrice) : null),
          if (calculatedPricePerMeter != null)
            'price_per_meter': calculatedPricePerMeter,
          if (hasParking != null) 'has_parking': hasParking,
          if (hasStorage != null) 'has_storage': hasStorage,
          if (hasBalcony != null) 'has_balcony': hasBalcony,
          if (realEstateType == 'RENT' && deposit != null && deposit.isNotEmpty)
            'deposit': int.parse(deposit),
          if (realEstateType == 'RENT' &&
              monthlyRent != null &&
              monthlyRent.isNotEmpty)
            'monthly_rent': int.parse(monthlyRent),
          if (realEstateType == 'SALE') 'deposit': null,
          if (realEstateType == 'SALE') 'monthly_rent': null,
          'floor': floor != null ? int.parse(floor) : null,
        },
        if (adType == 'VEHICLE') ...{
          'brand': brand!,
          'model': model!,
          'mileage': mileage != null ? int.parse(mileage!) : null,
          'color': color!,
          'gearbox': gearbox!,
          'base_price': basePrice != null ? int.parse(basePrice!) : null,
          'engine_status': engineStatus!,
          'chassis_status': chassisStatus!,
          'body_status': bodyStatus!,
        },
        if (['DIGITAL', 'HOME', 'PERSONAL', 'ENTERTAINMENT']
            .contains(adType)) ...{
          'brand': brand!,
          'model': model!,
          'item_condition': itemCondition!,
        },
        if (adType == 'SERVICES') ...{
          'service_type': serviceType!,
          'service_duration':
              serviceDuration != null && serviceDuration.isNotEmpty
                  ? int.parse(serviceDuration)
                  : null,
        },
      };

      print('Sending ad data: $adData');
      print('Images count: ${images.length}');
      if (images.isNotEmpty) {
        print('Image paths: ${images.map((file) => file.path).toList()}');
        for (var image in images) {
          print('Image exists: ${await image.exists()}');
          print('Image size: ${await image.length()} bytes');
        }
      } else {
        print('No images provided');
      }

      await _apiService.postAd(adData, images);
      await fetchAds(
        adType: _adType,
        provinceId: _provinceId,
        cityId: _cityId,
        sortBy: _sortBy,
      );
      try {
        await fetchUserAds(cleanPhoneNumber);
      } catch (e) {
        print('Failed to refresh user ads after posting: $e');
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error posting ad: $_errorMessage');
      throw Exception('خطا در ثبت آگهی: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAds({
    String? adType,
    int? provinceId,
    int? cityId,
    String? sortBy,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final validatedSortBy =
        sortBy != null && _validSortByValues.contains(sortBy) ? sortBy : null;

    try {
      print('Fetching ads with sortBy: $validatedSortBy');
      final ads = await _apiService.fetchAds(
        adType: adType ?? _adType,
        provinceId: provinceId ?? _provinceId,
        cityId: cityId ?? _cityId,
        sortBy: validatedSortBy,
      );
      print('Fetched ${ads.length} ads with adType: ${adType ?? _adType}, '
          'provinceId: ${provinceId ?? _provinceId}, cityId: ${cityId ?? _cityId}, sortBy: $validatedSortBy');
      for (var ad in ads) {
        print('Parsed ad JSON: ${ad.toJson()}');
      }
      _ads = ads;
      _adType = adType ?? _adType;
      _provinceId = provinceId ?? _provinceId;
      _cityId = cityId ?? _cityId;
      _sortBy = validatedSortBy;
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching ads: $_errorMessage');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserAds(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Fetching user ads for phone: $phoneNumber');
      final ads = await _apiService.fetchUserAds(phoneNumber);
      print('Fetched ${ads.length} user ads for phone: $phoneNumber');
      _userAds = ads;
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching user ads: $_errorMessage');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchAds(String query) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('Searching ads with query: $query');
      final ads = await _apiService.searchAds(query);
      print('Fetched ${ads.length} ads for query: $query');
      _searchResults = ads;
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error searching ads: $_errorMessage');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearchResults() {
    _searchResults = [];
    _errorMessage = null;
    print('Search results cleared');
    notifyListeners();
  }

  Future<void> updateAd({
    required int adId,
    required String title,
    required String description,
    int? price, // For VEHICLE and OTHER ads
    int? totalPrice, // For REAL_ESTATE SALE ads
    int? deposit, // For REAL_ESTATE RENT ads
    int? monthlyRent, // For REAL_ESTATE RENT ads
    required String phoneNumber,
    required String adType,
    String? realEstateType,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (adId <= 0) {
        throw Exception('شناسه آگهی نامعتبر است');
      }
      if (title.isEmpty) {
        throw Exception('عنوان آگهی نمی‌تواند خالی باشد');
      }
      if (description.isEmpty) {
        throw Exception('توضیحات آگهی نمی‌تواند خالی باشد');
      }
      if (phoneNumber.isEmpty) {
        throw Exception('شماره تلفن نمی‌تواند خالی باشد');
      }
      if (!['VEHICLE', 'REAL_ESTATE', 'OTHER'].contains(adType)) {
        throw Exception('نوع آگهی نامعتبر است');
      }
      if (adType == 'VEHICLE' && (price == null || price < 0)) {
        throw Exception('قیمت پایه برای آگهی خودرو الزامی و باید غیرمنفی باشد');
      }
      if (adType == 'REAL_ESTATE') {
        if (realEstateType == null ||
            !['SALE', 'RENT'].contains(realEstateType)) {
          throw Exception('نوع آگهی املاک (فروش یا اجاره) الزامی است');
        }
        if (realEstateType == 'SALE' &&
            (totalPrice == null || totalPrice < 0)) {
          throw Exception(
              'قیمت کل برای آگهی فروش املاک الزامی و باید غیرمنفی باشد');
        }
        if (realEstateType == 'RENT') {
          if (deposit == null || deposit < 0) {
            throw Exception(
                'ودیعه برای آگهی اجاره املاک الزامی و باید غیرمنفی باشد');
          }
          if (monthlyRent == null || monthlyRent < 0) {
            throw Exception(
                'اجاره ماهیانه برای آگهی اجاره املاک الزامی و باید غیرمنفی باشد');
          }
        }
      }

      print(
          'updateAd called with: adId=$adId, title=$title, description=$description, '
          'price=$price, totalPrice=$totalPrice, deposit=$deposit, monthlyRent=$monthlyRent, '
          'phoneNumber=$phoneNumber, adType=$adType, realEstateType=$realEstateType');

      final adData = {
        'ad_id': adId,
        'title': title,
        'description': description,
        'ad_type': adType,
        'owner_phone_number': phoneNumber,
        if (adType == 'VEHICLE') 'base_price': price,
        if (adType == 'REAL_ESTATE') ...{
          'real_estate_type': realEstateType,
          if (realEstateType == 'SALE') ...{
            'total_price': totalPrice,
            'price': totalPrice,
          },
          if (realEstateType == 'RENT') ...{
            'total_price': 0, // Set total_price to 0 for RENT ads
            'deposit': deposit,
            'monthly_rent': monthlyRent,
            'price': deposit,
          },
        },
        if (adType == 'OTHER') 'price': price,
      };

      print('Sending update request: $adData');
      await _apiService.updateAd(adData: adData);
      print('Ad updated: $adId');

      await Future.wait([
        fetchUserAds(phoneNumber),
        fetchAds(
          adType: _adType,
          provinceId: _provinceId,
          cityId: _cityId,
          sortBy: _sortBy,
        ),
      ]);

      print('Updated ads list: ${_ads.map((ad) => ad.toJson()).toList()}');
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error updating ad: $_errorMessage');
      print('Stack trace: $stackTrace');
      throw Exception('خطا در به‌روزرسانی آگهی: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAd(int adId, String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userAds.removeWhere((ad) => ad.adId == adId);
      _ads.removeWhere((ad) => ad.adId == adId);
      notifyListeners();

      await _apiService.deleteAd(adId);
      print('Ad deleted: $adId');

      await fetchUserAds(phoneNumber);
      await fetchAds(
        adType: _adType,
        provinceId: _provinceId,
        cityId: _cityId,
        sortBy: _sortBy,
      );
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error deleting ad: $_errorMessage');
      print('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilters({
    String? adType,
    String? realEstateType,
    int? provinceId,
    int? cityId,
    String? sortBy,
  }) {
    bool changed = false;

    final validatedSortBy =
        sortBy != null && _validSortByValues.contains(sortBy)
            ? sortBy
            : _sortBy;

    if (_adType != adType) {
      _adType = adType;
      changed = true;
    }
    if (_realEstateType != realEstateType) {
      _realEstateType = realEstateType;
      changed = true;
    }
    if (_provinceId != provinceId) {
      _provinceId = provinceId;
      changed = true;
    }
    if (_cityId != cityId) {
      _cityId = cityId;
      changed = true;
    }
    if (_sortBy != validatedSortBy) {
      _sortBy = validatedSortBy;
      changed = true;
    }

    print('setFilters: adType=$_adType, realEstateType=$_realEstateType, '
        'provinceId=$_provinceId, cityId=$_cityId, sortBy=$_sortBy');

    if (changed) {
      fetchAds();
    }
  }

  void clearFilters() {
    if (_adType != null ||
        _realEstateType != null ||
        _provinceId != null ||
        _cityId != null ||
        _sortBy != null) {
      _adType = null;
      _realEstateType = null;
      _provinceId = null;
      _cityId = null;
      _sortBy = null;
      print('Filters cleared');
      fetchAds();
    }
  }

  Future<void> fetchProvinces() async {
    try {
      _provinces = await _apiService.getProvinces();
      print('Fetched ${_provinces.length} provinces');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error fetching provinces: $_errorMessage');
      notifyListeners();
    }
  }

  Future<void> fetchCities(int provinceId) async {
    try {
      _cities = await _apiService.getCities(provinceId);
      print('Fetched ${_cities.length} cities for provinceId: $provinceId');
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(')', '');
      print('Error fetching cities: $errorMessage');
      notifyListeners();
    }
  }

  void setLocation(int provinceId, int cityId) {
    print('Setting location: provinceId=$provinceId, cityId=$cityId');
    _provinceId = provinceId;
    _cityId = cityId;
    notifyListeners();
    fetchAds(provinceId: provinceId, cityId: cityId);
  }
}
