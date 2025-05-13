class Ad {
  final int id;
  final String title;
  final String description;
  final String adType;
  final int? price;
  final int provinceId;
  final int cityId;
  final List<String> imageUrls;
  final String ownerPhoneNumber;
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
  final String? cityName;
  final String? provinceName;
  final DateTime createdAt;
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
    required this.id,
    required this.title,
    required this.description,
    required this.adType,
    this.price,
    required this.provinceId,
    required this.cityId,
    required this.imageUrls,
    required this.ownerPhoneNumber,
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
    this.cityName,
    this.provinceName,
    required this.createdAt,
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
      id: json['ad_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      adType: json['ad_type'] as String,
      price: _parseInt(json['price']),
      provinceId: json['province_id'] as int,
      cityId: json['city_id'] as int,
      imageUrls: (json['images'] as List<dynamic>?)?.cast<String>() ?? [],
      ownerPhoneNumber: json['owner_phone_number'] as String,
      realEstateType: json['real_estate_type'] as String?,
      area: json['area'] as int?,
      constructionYear: json['construction_year'] as int?,
      rooms: json['rooms'] as int?,
      totalPrice: _parseInt(json['total_price']),
      pricePerMeter: _parseInt(json['price_per_meter']),
      hasParking: json['has_parking'] == 1,
      hasStorage: json['has_storage'] == 1,
      hasBalcony: json['has_balcony'] == 1,
      deposit: _parseInt(json['deposit']),
      monthlyRent: _parseInt(json['monthly_rent']),
      floor: json['floor'] as int?,
      cityName: json['city_name'] as String?,
      provinceName: json['province_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      mileage: json['mileage'] as int?,
      color: json['color'] as String?,
      gearbox: json['gearbox'] as String?,
      basePrice: _parseInt(json['base_price']),
      engineStatus: json['engine_status'] as String?,
      chassisStatus: json['chassis_status'] as String?,
      bodyStatus: json['body_status'] as String?,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'ad_id': id,
      'title': title,
      'description': description,
      'ad_type': adType,
      'price': price,
      'province_id': provinceId,
      'city_id': cityId,
      'imageUrls': imageUrls,
      'owner_phone_number': ownerPhoneNumber,
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
      'city_name': cityName,
      'province_name': provinceName,
      'created_at': createdAt.toIso8601String(),
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
