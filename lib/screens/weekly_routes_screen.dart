import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../models/collection_route_model.dart';
import '../services/route_service.dart';
import '../utils/app_colors.dart';

class WeeklyRoutesScreen extends StatelessWidget {
  WeeklyRoutesScreen({super.key});

  final RouteService routeService = RouteService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rotas da Semana')),
      body: FutureBuilder<List<CollectionRouteModel>>(
        future: routeService.listarRotasDisponiveis(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar rotas:\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final rotas = snapshot.data ?? [];

          if (rotas.isEmpty) {
            return const Center(child: Text('Nenhuma rota cadastrada.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rotas.length,
            itemBuilder: (context, index) {
              final rota = rotas[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.route, color: AppColors.white),
                  ),
                  title: Text(rota.dia),
                  subtitle: Text(
                    'Bairro: ${rota.bairro}\n'
                    'Motorista: ${rota.motorista}\n'
                    'Veículo: ${rota.veiculo}\n'
                    'Tempo estimado: ${rota.tempoEstimado}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.driverMap,
                      arguments: {
                        'dia': rota.dia,
                        'bairro': rota.bairro,
                        'tempo': rota.tempoEstimado,
                        'motorista': rota.motorista,
                        'veiculo': rota.veiculo,
                        'turno': rota.turno,
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
