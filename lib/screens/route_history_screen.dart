import 'package:flutter/material.dart';

import '../models/route_history_model.dart';
import '../services/route_history_service.dart';
import '../utils/app_colors.dart';

class RouteHistoryScreen extends StatefulWidget {
  const RouteHistoryScreen({super.key});

  @override
  State<RouteHistoryScreen> createState() => _RouteHistoryScreenState();
}

class _RouteHistoryScreenState extends State<RouteHistoryScreen> {
  final RouteHistoryService historyService = const RouteHistoryService();

  late Future<List<RouteHistoryModel>> historicoFuture;

  @override
  void initState() {
    super.initState();
    carregarHistorico();
  }

  void carregarHistorico() {
    historicoFuture = historyService.listarHistorico();
  }

  Future<void> limparHistorico() async {
    await historyService.limparHistorico();

    setState(() {
      carregarHistorico();
    });
  }

  String formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final ano = data.year.toString();

    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$ano às $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Rotas'),
        actions: [
          IconButton(
            onPressed: limparHistorico,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: FutureBuilder<List<RouteHistoryModel>>(
        future: historicoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final historico = snapshot.data ?? [];

          if (historico.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma rota finalizada ainda.',
                style: TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
            );
          }

          final historicoOrdenado = historico.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historicoOrdenado.length,
            itemBuilder: (context, index) {
              final item = historicoOrdenado[index];
              final progressoPercentual = (item.progresso * 100).round();

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.bairro,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Motorista: ${item.motorista}'),
                      Text('Veículo: ${item.veiculo}'),
                      Text('Turno: ${item.turno}'),
                      Text(
                        'Finalizada em: ${formatarData(item.dataFinalizacao)}',
                      ),
                      const Divider(height: 24),
                      Text('Status: ${item.status}'),
                      Text('Tempo estimado: ${item.tempoEstimado}'),
                      Text('Tempo real: ${item.tempoReal}'),
                      Text('Distância percorrida: ${item.distanciaPercorrida}'),
                      Text('Trechos validados: ${item.trechosValidados}'),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: item.progresso,
                        minHeight: 10,
                        backgroundColor: Colors.grey.shade300,
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$progressoPercentual% concluído',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
