class Ad {
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
      adId: json['ad_id'],
      title: json['title'],
      description: json['description'],
      adType: json['ad_type'],
      price: json['price'],
      provinceId: json['province_id'],
      cityId: json['city_id'],
      ownerPhoneNumber: json['owner_phone_number'],
      createdAt: DateTime.parse(json['created_at']),
      status: json['status'],
      provinceName: json['province_name'],
      cityName: json['city_name'],
      imageUrls: List<String>.from(json['images'] ?? []),
      realEstateType: json['real_estate_type'],
      area: json['area'],
      constructionYear: json['construction_year'],
      rooms: json['rooms'],
      totalPrice: json['total_price'],
      pricePerMeter: json['price_per_meter'],
      hasParking: json['has_parking'] == 1,
      hasStorage: json['has_storage'] == 1,
      hasBalcony: json['has_balcony'] == 1,
      deposit: json['deposit'],
      monthlyRent: json['monthly_rent'],
      floor: json['floor'],
      brand: json['brand'],
      model: json['model'],
      mileage: json['mileage'],
      color: json['color'],
      gearbox: json['gearbox'],
      basePrice: json['base_price'],
      engineStatus: json['engine_status'],
      chassisStatus: json['chassis_status'],
      bodyStatus: json['body_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
