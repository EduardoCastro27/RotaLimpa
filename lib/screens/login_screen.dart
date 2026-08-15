import 'package:flutter/material.dart';

import '../app/app_routes.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  final AuthService authService = AuthService();

  bool carregando = false;
  bool modoCadastro = false;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> entrarOuCadastrar() async {
    final email = emailController.text.trim();
    final senha = senhaController.text.trim();

    if (email.isEmpty || senha.isEmpty) {
      mostrarMensagem('Informe e-mail e senha.');
      return;
    }

    if (senha.length < 6) {
      mostrarMensagem('A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    setState(() {
      carregando = true;
    });

    try {
      if (modoCadastro) {
        await authService.cadastrar(email: email, senha: senha);
      } else {
        await authService.login(email: email, senha: senha);
      }

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.driverMap,
        (route) => false,
        arguments: {
          'email': email,
        },
      );
    } catch (e) {
      mostrarMensagem(tratarErroFirebase(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          carregando = false;
        });
      }
    }
  }

  String tratarErroFirebase(String erro) {
    if (erro.contains('user-not-found')) {
      return 'Usuário não encontrado.';
    }

    if (erro.contains('wrong-password')) {
      return 'Senha incorreta.';
    }

    if (erro.contains('email-already-in-use')) {
      return 'Este e-mail já está cadastrado.';
    }

    if (erro.contains('invalid-email')) {
      return 'E-mail inválido.';
    }

    if (erro.contains('weak-password')) {
      return 'Senha muito fraca.';
    }

    if (erro.contains('invalid-credential')) {
      return 'E-mail ou senha inválidos.';
    }

    return 'Erro ao autenticar. Verifique os dados e tente novamente.';
  }

  void mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 6,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_shipping,
                    size: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Rota Limpa',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gestão inteligente de coleta urbana',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textDark),
                  ),
                  const SizedBox(height: 32),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: carregando ? null : entrarOuCadastrar,
                      child: carregando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(modoCadastro ? 'Cadastrar' : 'Entrar'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: carregando
                        ? null
                        : () {
                            setState(() {
                              modoCadastro = !modoCadastro;
                            });
                          },
                    child: Text(
                      modoCadastro ? 'Já tenho conta' : 'Criar nova conta',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
