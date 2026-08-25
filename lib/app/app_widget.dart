import 'package:flutter/material.dart';

import '../screens/auth_check_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/route_map_screen.dart';
import '../screens/route_report_screen.dart';
import '../screens/weekly_routes_screen.dart';
import '../screens/driver_map_screen.dart';
import '../screens/route_history_screen.dart';
import '../utils/app_colors.dart';
import 'app_routes.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rota Limpa',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          centerTitle: true,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      home: const AuthCheckScreen(),

      routes: {
        AppRoutes.login: (context) => const LoginScreen(),

        AppRoutes.home: (context) => const HomeScreen(),

        AppRoutes.weeklyRoutes: (context) => WeeklyRoutesScreen(),

        AppRoutes.routeMap: (context) => const RouteMapScreen(),

        AppRoutes.routeReport: (context) => const RouteReportScreen(),

        // IMPORTANTE:
        // Esta tela recebe o e-mail enviado pelo AuthCheckScreen
        // e busca a rota do motorista.
        AppRoutes.driverMap: (context) => DriverMapScreen(),

        AppRoutes.routeHistory: (context) => const RouteHistoryScreen(),
      },
    );
  }
}