import 'dart:convert';
import 'dart:js' as js;
import 'dart:js_util' as js_util;

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

  final dados = pontos
      .map(
        (ponto) => {
          'latitude': ponto.latitude,
          'longitude': ponto.longitude,
        },
      )
      .toList();

  final pontosJson = jsonEncode(dados);

  final funcao = js.context['rotaLimpaCalcularRota'];

  if (funcao == null) {
    throw Exception(
      'A função rotaLimpaCalcularRota não foi encontrada no navegador.',
    );
  }

  try {
    final resultadoJS = js_util.callMethod(
      js.context,
      'rotaLimpaCalcularRota',
      <dynamic>[pontosJson],
    );

    final resultado = await js_util.promiseToFuture<dynamic>(
      resultadoJS,
    );

    final resposta = jsonDecode(
      resultado.toString(),
    );

    if (resposta is! List) {
      throw Exception(
        'A API de rotas não retornou um caminho válido.',
      );
    }

    return resposta.map<LatLng>((ponto) {
      final dadosPonto = Map<String, dynamic>.from(
        ponto as Map,
      );

      return LatLng(
        (dadosPonto['latitude'] as num).toDouble(),
        (dadosPonto['longitude'] as num).toDouble(),
      );
    }).toList();
  } catch (error) {
    throw Exception(
      'Erro ao calcular a rota pelas ruas: $error',
    );
  }
}
