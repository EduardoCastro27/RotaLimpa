class RoutePointModel {
  final double latitude;
  final double longitude;
  final bool concluido;

  const RoutePointModel({
    required this.latitude,
    required this.longitude,
    this.concluido = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'concluido': concluido,
    };
  }

  factory RoutePointModel.fromMap(Map<String, dynamic> map) {
    return RoutePointModel(
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      concluido: map['concluido'] ?? false,
    );
  }
}
