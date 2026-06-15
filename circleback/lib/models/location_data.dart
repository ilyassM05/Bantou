/// Lightweight model representing a geographic meeting location.
/// Stores the GPS coordinates and the human-readable formatted address.
class LocationData {
  final double lat;
  final double lng;
  final String address;

  const LocationData({
    required this.lat,
    required this.lng,
    required this.address,
  });

  /// Parses a location from the API response map (circle data).
  factory LocationData.fromCircleData(Map<String, dynamic> data) {
    return LocationData(
      lat: (data['meetingLat'] as num).toDouble(),
      lng: (data['meetingLng'] as num).toDouble(),
      address: data['meetingAddress'] as String? ?? '',
    );
  }

  /// Serializes to a JSON-compatible map for API calls.
  Map<String, dynamic> toJson() => {
        'meetingLat': lat,
        'meetingLng': lng,
        'meetingAddress': address,
      };

  LocationData copyWith({
    double? lat,
    double? lng,
    String? address,
  }) {
    return LocationData(
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      address: address ?? this.address,
    );
  }

  @override
  String toString() => 'LocationData(lat: $lat, lng: $lng, address: $address)';
}
