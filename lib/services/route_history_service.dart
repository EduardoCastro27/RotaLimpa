import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/route_history_model.dart';

class RouteHistoryService {
  static const String _key = 'route_history';

  const RouteHistoryService();

  Future<List<RouteHistoryModel>> listarHistorico() async {
    final prefs = await SharedPreferences.getInstance();

    final dadosSalvos = prefs.getStringList(_key) ?? [];

    return dadosSalvos.map((item) {
      final map = jsonDecode(item) as Map<String, dynamic>;
      return RouteHistoryModel.fromMap(map);
    }).toList();
  }

  Future<void> salvarHistorico(RouteHistoryModel historico) async {
    final prefs = await SharedPreferences.getInstance();

    final historicoAtual = prefs.getStringList(_key) ?? [];

    historicoAtual.add(jsonEncode(historico.toMap()));

    await prefs.setStringList(_key, historicoAtual);
  }

  Future<void> limparHistorico() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
