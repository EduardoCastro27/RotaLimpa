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
  final RouteHistoryService _historyService = RouteHistoryService();
  late Future<List<RouteHistoryModel>> _historicoFuture;

  @override
  void initState() {
    super.initState();
    _recarregarHistorico();
  }

  void _recarregarHistorico() {
    _historicoFuture = _historyService.listarHistorico();
  }

  Future<void> _limparHistorico() async {
    try {
      await _historyService.limparHistorico();
      if (!mounted) return;
      setState(_recarregarHistorico);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível limpar o histórico: $error')),
      );
    }
  }

  String _formatarData(DateTime data) {
    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final hora = data.hour.toString().padLeft(2, '0');
    final minuto = data.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${data.year} às $hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Rotas'),
        actions: [
          IconButton(
            tooltip: 'Limpar histórico',
            onPressed: _limparHistorico,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: FutureBuilder<List<RouteHistoryModel>>(
        future: _historicoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar histórico:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                ),
              ),
            );
          }

          final historico = (snapshot.data ?? []).reversed.toList();
          if (historico.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma rota finalizada ainda.',
                style: TextStyle(fontSize: 16, color: AppColors.textDark),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => setState(_recarregarHistorico),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historico.length,
              itemBuilder: (context, index) {
                final item = historico[index];
                final percentual = (item.progresso * 100).round();
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
                        Text('Finalizada em: ${_formatarData(item.dataFinalizacao)}'),
                        const Divider(height: 24),
                        Text('Status: ${item.status}'),
                        Text('Tempo estimado: ${item.tempoEstimado}'),
                        Text('Tempo real: ${item.tempoReal}'),
                        Text('Distância percorrida: ${item.distanciaPercorrida}'),
                        Text('Trechos validados: ${item.trechosValidados}'),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: item.progresso.clamp(0.0, 1.0).toDouble(),
                          minHeight: 10,
                          backgroundColor: Colors.grey.shade300,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$percentual% concluído',
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
            ),
          );
        },
      ),
    );
  }
}
