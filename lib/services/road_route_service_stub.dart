import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/route_point_model.dart';

Future<List<LatLng>> calcularRotaPelasRuasPlatform(
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

  throw UnsupportedError(
    'O cálculo de rotas pelas ruas está disponível na versão Web.',
  );
}
