import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

class RouteReportScreen extends StatelessWidget {
  const RouteReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dados =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final String bairro = dados?['bairro'] ?? 'Centro';
    final String tempoEstimado = dados?['tempoEstimado'] ?? '2h30min';
    final String tempoReal = dados?['tempoReal'] ?? 'Não informado';
    final double progresso = dados?['progresso'] ?? 0.0;
    final int pontosPercorridos = dados?['pontosPercorridos'] ?? 0;
    final String status = dados?['status'] ?? 'Não finalizada';

    final int progressoPercentual = (progresso * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Relatório da Rota')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Resumo da coleta',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 20),

            _ReportCard(
              title: 'Bairro',
              value: bairro,
              icon: Icons.location_city,
            ),
            _ReportCard(title: 'Status', value: status, icon: Icons.flag),
            _ReportCard(
              title: 'Tempo estimado',
              value: tempoEstimado,
              icon: Icons.timer,
            ),
            _ReportCard(
              title: 'Tempo real',
              value: tempoReal,
              icon: Icons.access_time,
            ),
            _ReportCard(
              title: 'Pontos registrados',
              value: pontosPercorridos.toString(),
              icon: Icons.route,
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      'Progresso da rota',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progresso,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    const SizedBox(height: 12),
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
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Voltar ao início'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _ReportCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(icon, color: AppColors.white),
        ),
        title: Text(title),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}
