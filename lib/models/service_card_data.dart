class ServiceCardData {
  final int id;
  final String name;
  final String? description;
  final num? price;
  final String? mainPhoto;
  final Map<String, dynamic> specialist;

  ServiceCardData.fromMap(Map<String, dynamic> map)
    : id = map['id'] as int,
      name = map['name'] as String,
      description = map['description'] as String?,
      price = map['price'] as num?,
      mainPhoto = map['main_photo'] as String?,
      specialist = map['profiles'] as Map<String, dynamic>? ?? {};
}
