class Province {
  final int provinceId;
  final String name;

  Province({required this.provinceId, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      provinceId: json['province_id'] as int,
      name: json['name'] as String,
    );
  }
}
