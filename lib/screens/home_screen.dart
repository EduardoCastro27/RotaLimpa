import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> sair(BuildContext context) async {
    await AuthService().sair();

    if (!context.mounted) return;

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rota Limpa'),
        actions: [
          IconButton(
            onPressed: () => sair(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Painel inicial',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _DashboardCard(
              title: 'Rotas da Semana',
              subtitle: 'Visualizar rotas programadas',
              icon: Icons.calendar_month,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.weeklyRoutes);
              },
            ),
            _DashboardCard(
              title: 'Mapa ao Vivo',
              subtitle: 'Acompanhar rota em andamento',
              icon: Icons.map,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.driverMap);
              },
            ),
            _DashboardCard(
              title: 'Relatórios',
              subtitle: 'Consultar desempenho da coleta',
              icon: Icons.bar_chart,
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.routeReport);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.secondary,
          child: Icon(icon, color: AppColors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
