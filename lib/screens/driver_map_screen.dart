import 'package:flutter/material.dart';

import '../models/collection_route_model.dart';
import '../services/route_service.dart';
import '../utils/app_colors.dart';
import 'route_map_screen.dart';

class DriverMapScreen extends StatelessWidget {
  final String? emailUsuario;
  final RouteService routeService;

  DriverMapScreen({super.key, this.emailUsuario, RouteService? routeService})
    : routeService = routeService ?? RouteService();

  Future<CollectionRouteModel> carregarRota(String email) async {
    return routeService.buscarRotaPorEmail(email);
  }

  @override
  Widget build(BuildContext context) {
    final dados =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String email = emailUsuario ?? dados?['email'] ?? '';

    return FutureBuilder<CollectionRouteModel>(
      future: carregarRota(email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar rota:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textDark),
                ),
              ),
            ),
          );
        }

        final rotaDoUsuario = snapshot.data;

        if (rotaDoUsuario == null) {
          return const Scaffold(
            body: Center(child: Text('Nenhuma rota encontrada.')),
          );
        }

        return RouteMapScreen(
          rotaInicialModel: rotaDoUsuario,
          modoPrincipal: true,
        );
      },
    );
  }
}
