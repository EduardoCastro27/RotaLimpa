import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../services/auth_service.dart';

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  final AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    verificarUsuario();
  }

  Future<void> verificarUsuario() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final usuario = authService.usuarioAtual;

    if (!mounted) return;

    if (usuario == null) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    } else {
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.driverMap,
        arguments: {'email': usuario.email ?? ''},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
