
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/ad.dart';
import '../services/api_service.dart';

class AdProvider with ChangeNotifier {
  List<Ad> _ads = [];
  List<Ad> _userAds = [];
  List<Ad> _searchResults = []; // New field for search results
  bool _isLoading = false;
  String? _sortBy;
  String? _errorMessage;
  String? _adType;
  String? _realEstateType;
  int? _provinceId;
  int? _cityId;

  List<Ad> get ads => _ads;
  List<Ad> get userAds => _userAds;
  List<Ad> get searchResults => _searchResults; // New getter for search results
  bool get isLoading => _isLoading;
  String? get sortBy => _sortBy;
  String? get errorMessage => _errorMessage;
  String? get adType => _adType;
  String? get realEstateType => _realEstateType;

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
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhoneNumber.length != 11) {
        throw Exception('شماره تلفن باید 11 رقم باشد');
      }

      // Set price based on adType
      String effectivePrice;
      if (adType == 'VEHICLE') {
        if (basePrice == null || int.tryParse(basePrice) == null) {
          throw Exception('قیمت پایه خودرو الزامی و باید عدد معتبر باشد');
        }
        effectivePrice = basePrice;
      } else if (adType == 'REAL_ESTATE') {
        if (totalPrice == null || int.tryParse(totalPrice) == null) {
          throw Exception('قیمت کل املاک الزامی و باید عدد معتبر باشد');
        }
        effectivePrice = totalPrice;
      } else {
        effectivePrice = price ?? '0';
      }

      if (adType == 'VEHICLE') {
        if (brand == null || brand.isEmpty) {
          throw Exception('برند خودرو الزامی است');
        }
        if (model == null || model.isEmpty) {
          throw Exception('مدل خودرو الزامی است');
        }
        if (mileage == null || int.tryParse(mileage) == null) {
          throw Exception('کارکرد خودرو الزامی و باید عدد معتبر باشد');
        }
        if (color == null || color.isEmpty) {
          throw Exception('رنگ خودرو الزامی است');
        }
        if (gearbox == null || !['MANUAL', 'AUTOMATIC'].contains(gearbox)) {
          throw Exception('نوع گیربکس باید دستی یا اتوماتیک باشد');
        }
        if (engineStatus == null ||
            !['HEALTHY', 'NEEDS_REPAIR'].contains(engineStatus)) {
          throw Exception('وضعیت موتور باید سالم یا نیاز به تعمیر باشد');
        }
        if (chassisStatus == null ||
            !['HEALTHY', 'IMPACTED'].contains(chassisStatus)) {
          throw Exception('وضعیت شاسی باید سالم یا تصادفی باشد');
        }
        if (bodyStatus == null ||
            !['HEALTHY', 'MINOR_SCRATCH', 'ACCIDENTED'].contains(bodyStatus)) {
          throw Exception('وضعیت بدنه باید سالم، خط و خش جزیی یا تصادفی باشد');
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
          if (realEstateType != null) 'real_estate_type': realEstateType,
          if (area != null) 'area': int.tryParse(area) ?? 0,
          if (rooms != null) 'rooms': int.tryParse(rooms) ?? 0,
          if (totalPrice != null) 'total_price': int.tryParse(totalPrice) ?? 0,
          if (pricePerMeter != null)
            'price_per_meter': int.tryParse(pricePerMeter) ?? 0,
          if (hasParking != null) 'has_parking': hasParking,
          if (hasStorage != null) 'has_storage': hasStorage,
          if (hasBalcony != null) 'has_balcony': hasBalcony,
          if (realEstateType == 'RENT' && deposit != null && deposit.isNotEmpty)
            'deposit': int.tryParse(deposit) ?? 0,
          if (realEstateType == 'RENT' &&
              monthlyRent != null &&
              monthlyRent.isNotEmpty)
            'monthly_rent': int.tryParse(monthlyRent) ?? 0,
          if (realEstateType == 'SALE') 'deposit': null,
          if (realEstateType == 'SALE') 'monthly_rent': null,
          if (floor != null) 'floor': int.tryParse(floor) ?? 0,
        },
        if (adType == 'VEHICLE') ...{
          'brand': brand!,
          'model': model!,
          'mileage': int.tryParse(mileage!) ?? 0,
          'color': color!,
          'gearbox': gearbox!,
          'base_price': int.tryParse(basePrice!) ?? 0,
          'engine_status': engineStatus!,
          'chassis_status': chassisStatus!,
          'body_status': bodyStatus!,
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
        await fetchUserAds(cleanPhoneNumber); // Refresh user ads
      } catch (e) {
        print('Failed to refresh user ads after posting: $e');
        // Continue without failing the post
      }
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error posting ad: $_errorMessage');
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

    // Validate sortBy
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
    int? price,
    required String phoneNumber,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateAd(
        adId: adId,
        title: title,
        description: description,
        price: price,
      );
      print('Ad updated: $adId');
      await fetchUserAds(phoneNumber); // Use provided phoneNumber
    } catch (e, stackTrace) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      print('Error updating ad: $_errorMessage');
      print('Stack trace: $stackTrace');
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
      await _apiService.deleteAd(adId);
      print('Ad deleted: $adId');
      await fetchUserAds(phoneNumber); // Use provided phoneNumber
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

    // Validate sortBy
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
}
