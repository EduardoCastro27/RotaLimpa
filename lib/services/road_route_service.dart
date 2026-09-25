import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_point_model.dart';
import 'road_route_service_stub.dart'
    if (dart.library.html) 'road_route_service_web.dart';

class RoadRouteService {
  Future<List<LatLng>> calcularRotaPelasRuas(
    List<RoutePointModel> pontos,
  ) async {
    if (pontos.length < 2) {
      return pontos
          .map(
            (ponto) => LatLng(
              ponto.latitude,
              ponto.longitude,
            ),
          )
          .toList();
    }

    return calcularRotaPelasRuasPlatform(pontos);
  }
}
