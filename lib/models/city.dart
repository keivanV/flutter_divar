
class City {
  final int cityId;
  final String name;

  City({required this.cityId, required this.name});

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      cityId: json['city_id'] as int,
      name: json['name'] as String,
    );
  }
}
