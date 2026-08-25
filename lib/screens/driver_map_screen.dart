import 'package:flutter/material.dart';

import '../models/collection_route_model.dart';
import '../services/route_service.dart';
import '../utils/app_colors.dart';
import 'route_map_screen.dart';

/// Carrega a rota uma única vez por abertura desta tela.
///
/// Antes, o Future era criado dentro do build. Qualquer rebuild iniciava uma
/// nova busca e podia desmontar/remontar o RouteMapScreen e o GoogleMap.
class DriverMapScreen extends StatefulWidget {
  final String? emailUsuario;
  final RouteService routeService;

  DriverMapScreen({super.key, this.emailUsuario, RouteService? routeService})
      : routeService = routeService ?? RouteService();

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  Future<CollectionRouteModel>? _rotaFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // ModalRoute só está disponível depois de initState. A proteção evita que
    // mudanças de dependências executem uma segunda consulta ao Firestore.
    _rotaFuture ??= widget.routeService.buscarRotaPorEmail(_emailDaRota());
  }

  String _emailDaRota() {
    final dados =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return widget.emailUsuario ?? dados?['email']?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CollectionRouteModel>(
      future: _rotaFuture,
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