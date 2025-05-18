class Ad {
  int? bookmarkId; // Single, settable field
  final int adId;
  final String title;
  final String description;
  final String adType;
  final int? price;
  final int provinceId;
  final int cityId;
  final String ownerPhoneNumber;
  final DateTime createdAt;
  final String status;
  final String? provinceName;
  final String? cityName;
  final List<String> imageUrls;

  // REAL_ESTATE fields
  final String? realEstateType;
  final int? area;
  final int? constructionYear;
  final int? rooms;
  final int? totalPrice;
  final int? pricePerMeter;
  final bool? hasParking;
  final bool? hasStorage;
  final bool? hasBalcony;
  final int? deposit;
  final int? monthlyRent;
  final int? floor;

  // VEHICLE fields
  final String? brand;
  final String? model;
  final int? mileage;
  final String? color;
  final String? gearbox;
  final int? basePrice;
  final String? engineStatus;
  final String? chassisStatus;
  final String? bodyStatus;

  Ad({
    this.bookmarkId,
    required this.adId,
    required this.title,
    required this.description,
    required this.adType,
    this.price,
    required this.provinceId,
    required this.cityId,
    required this.ownerPhoneNumber,
    required this.createdAt,
    required this.status,
    this.provinceName,
    this.cityName,
    required this.imageUrls,
    this.realEstateType,
    this.area,
    this.constructionYear,
    this.rooms,
    this.totalPrice,
    this.pricePerMeter,
    this.hasParking,
    this.hasStorage,
    this.hasBalcony,
    this.deposit,
    this.monthlyRent,
    this.floor,
    this.brand,
    this.model,
    this.mileage,
    this.color,
    this.gearbox,
    this.basePrice,
    this.engineStatus,
    this.chassisStatus,
    this.bodyStatus,
  });

  factory Ad.fromJson(Map<String, dynamic> json) {
    return Ad(
      bookmarkId: json['bookmark_id'] as int?,
      adId: json['ad_id'] as int? ?? 0, // Default to 0 if null
      title: json['title'] as String? ?? 'بدون عنوان',
      description: json['description'] as String? ?? '',
      adType: json['ad_type'] as String? ?? 'UNKNOWN',
      price: json['price'] as int?,
      provinceId: json['province_id'] as int? ?? 0,
      cityId: json['city_id'] as int? ?? 0,
      ownerPhoneNumber: json['owner_phone_number'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      status: json['status'] as String? ?? 'UNKNOWN',
      provinceName: json['province_name'] as String?,
      cityName: json['city_name'] as String?,
      imageUrls: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      realEstateType: json['real_estate_type'] as String?,
      area: json['area'] as int?,
      constructionYear: json['construction_year'] as int?,
      rooms: json['rooms'] as int?,
      totalPrice: json['total_price'] as int?,
      pricePerMeter: json['price_per_meter'] as int?,
      hasParking: json['has_parking'] == 1 || json['has_parking'] == true,
      hasStorage: json['has_storage'] == 1 || json['has_storage'] == true,
      hasBalcony: json['has_balcony'] == 1 || json['has_balcony'] == true,
      deposit: json['deposit'] as int?,
      monthlyRent: json['monthly_rent'] as int?,
      floor: json['floor'] as int?,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      mileage: json['mileage'] as int?,
      color: json['color'] as String?,
      gearbox: json['gearbox'] as String?,
      basePrice: json['base_price'] as int?,
      engineStatus: json['engine_status'] as String?,
      chassisStatus: json['chassis_status'] as String?,
      bodyStatus: json['body_status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookmark_id': bookmarkId,
      'ad_id': adId,
      'title': title,
      'description': description,
      'ad_type': adType,
      'price': price,
      'province_id': provinceId,
      'city_id': cityId,
      'owner_phone_number': ownerPhoneNumber,
      'created_at': createdAt.toIso8601String(),
      'status': status,
      'province_name': provinceName,
      'city_name': cityName,
      'images': imageUrls,
      'real_estate_type': realEstateType,
      'area': area,
      'construction_year': constructionYear,
      'rooms': rooms,
      'total_price': totalPrice,
      'price_per_meter': pricePerMeter,
      'has_parking': hasParking,
      'has_storage': hasStorage,
      'has_balcony': hasBalcony,
      'deposit': deposit,
      'monthly_rent': monthlyRent,
      'floor': floor,
      'brand': brand,
      'model': model,
      'mileage': mileage,
      'color': color,
      'gearbox': gearbox,
      'base_price': basePrice,
      'engine_status': engineStatus,
      'chassis_status': chassisStatus,
      'body_status': bodyStatus,
    };
  }
}
