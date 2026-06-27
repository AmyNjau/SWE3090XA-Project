/// A nearby healthcare provider returned by POST /api/providers.
class Provider {
  final String id;
  final String name;
  final String specialty;
  final String? address;
  final double? rating;
  final int? reviews;
  final double? latitude;
  final double? longitude;
  final int? distanceMetres;

  const Provider({
    required this.id,
    required this.name,
    required this.specialty,
    this.address,
    this.rating,
    this.reviews,
    this.latitude,
    this.longitude,
    this.distanceMetres,
  });

  /// Distance rendered for display, e.g. "1.2 km" or "850 m".
  String get distanceLabel {
    if (distanceMetres == null) return '';
    if (distanceMetres! >= 1000) {
      return '${(distanceMetres! / 1000).toStringAsFixed(1)} km';
    }
    return '$distanceMetres m';
  }

  /// Up-to-two-letter initials used by the avatar chip.
  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  factory Provider.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>?;
    return Provider(
      id: json['id'].toString(),
      name: json['name'] as String,
      specialty: json['specialty'] as String? ?? '',
      address: json['address'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviews: (json['reviews'] as num?)?.toInt(),
      latitude: (loc?['latitude'] as num?)?.toDouble(),
      longitude: (loc?['longitude'] as num?)?.toDouble(),
      distanceMetres: (json['distanceMetres'] as num?)?.toInt(),
    );
  }
}
