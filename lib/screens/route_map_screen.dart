import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'home_screen.dart';
import 'weekly_routes_screen.dart';
import 'route_history_screen.dart';
import 'login_screen.dart';

import '../app/app_routes.dart';
import '../models/collection_route_model.dart';
import '../models/route_history_model.dart';
import '../services/auth_service.dart';
import '../services/route_history_service.dart';
import '../utils/app_colors.dart';

class RouteMapScreen extends StatefulWidget {
  final Map<String, String>? rotaInicial;
  final CollectionRouteModel? rotaInicialModel;
  final bool modoPrincipal;

  const RouteMapScreen({
    super.key,
    this.rotaInicial,
    this.rotaInicialModel,
    this.modoPrincipal = false,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  static const double distanciaEntrePontosDetalhados = 8;
  static const double toleranciaRotaMetros = 30;
  static const double limiteDesvioMetros = 70;

  GoogleMapController? mapController;
  StreamSubscription<Position>? locationSubscription;
  Timer? simulationTimer;

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  final RouteHistoryService routeHistoryService = const RouteHistoryService();

  LatLng? posicaoAtual;

  List<LatLng> rotaPlanejada = [];
  List<LatLng> rotaPlanejadaDetalhada = [];
  List<bool> pontosConcluidos = [];

  final List<LatLng> trajetoGps = [];

  bool carregando = true;
  bool rastreando = false;
  bool foraDaRota = false;

  String? erro;

  double progresso = 0.0;
  double distanciaPercorridaMetros = 0.0;

  int ultimoIndiceValidado = -1;

  DateTime? inicioRota;
  DateTime? fimRota;

  @override
  void initState() {
    super.initState();
    carregarLocalizacaoInicial();
  }

  @override
  void dispose() {
    locationSubscription?.cancel();
    simulationTimer?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> carregarLocalizacaoInicial() async {
    try {
      final position = await determinarPosicao();

      final localAtual = LatLng(position.latitude, position.longitude);

      final bairroDaRota = widget.rotaInicialModel?.bairro ?? 'Centro';
      final rotaTeste = gerarRotaTestePorBairro(localAtual, bairroDaRota);
      final rotaDetalhada = detalharRota(
        rotaTeste,
        distanciaEntrePontosDetalhados,
      );

      setState(() {
        posicaoAtual = localAtual;
        rotaPlanejada = rotaTeste;
        rotaPlanejadaDetalhada = rotaDetalhada;
        pontosConcluidos = List.filled(rotaDetalhada.length, false);
        carregando = false;

        validarPontoNaRota(localAtual);
        progresso = calcularProgresso();
      });

      await Future.delayed(const Duration(milliseconds: 500));

      mapController?.animateCamera(CameraUpdate.newLatLngZoom(localAtual, 16));
    } catch (e) {
      setState(() {
        erro = e.toString();
        carregando = false;
      });
    }
  }

  Future<Position> determinarPosicao() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      throw Exception('O serviço de localização está desativado.');
    }

    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();

      if (permissao == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão de localização negada permanentemente. Ative nas configurações do aparelho.',
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  List<LatLng> gerarRotaTestePorBairro(LatLng base, String bairro) {
    final bairroFormatado = bairro.toLowerCase();

    if (bairroFormatado.contains('cidade')) {
      return [
        base,
        LatLng(base.latitude + 0.0005, base.longitude + 0.0002),
        LatLng(base.latitude + 0.0010, base.longitude + 0.0010),
        LatLng(base.latitude + 0.0003, base.longitude + 0.0018),
        LatLng(base.latitude - 0.0005, base.longitude + 0.0014),
        LatLng(base.latitude - 0.0008, base.longitude + 0.0004),
      ];
    }

    if (bairroFormatado.contains('ponta')) {
      return [
        base,
        LatLng(base.latitude + 0.0003, base.longitude - 0.0005),
        LatLng(base.latitude + 0.0011, base.longitude - 0.0002),
        LatLng(base.latitude + 0.0014, base.longitude + 0.0008),
        LatLng(base.latitude + 0.0005, base.longitude + 0.0015),
        LatLng(base.latitude - 0.0004, base.longitude + 0.0010),
      ];
    }

    if (bairroFormatado.contains('flores')) {
      return [
        base,
        LatLng(base.latitude - 0.0004, base.longitude),
        LatLng(base.latitude - 0.0008, base.longitude + 0.0008),
        LatLng(base.latitude - 0.0002, base.longitude + 0.0015),
        LatLng(base.latitude + 0.0006, base.longitude + 0.0013),
        LatLng(base.latitude + 0.0008, base.longitude + 0.0004),
      ];
    }

    return [
      base,
      LatLng(base.latitude + 0.0008, base.longitude),
      LatLng(base.latitude + 0.0012, base.longitude + 0.0008),
      LatLng(base.latitude + 0.0008, base.longitude + 0.0015),
      LatLng(base.latitude, base.longitude + 0.0017),
      LatLng(base.latitude - 0.0006, base.longitude + 0.0010),
      LatLng(base.latitude - 0.0004, base.longitude + 0.0002),
    ];
  }

  List<LatLng> detalharRota(List<LatLng> rota, double intervaloMetros) {
    if (rota.isEmpty) return [];

    final List<LatLng> pontosDetalhados = [];

    for (int i = 0; i < rota.length - 1; i++) {
      final inicio = rota[i];
      final fim = rota[i + 1];

      final distancia = Geolocator.distanceBetween(
        inicio.latitude,
        inicio.longitude,
        fim.latitude,
        fim.longitude,
      );

      final passos = math.max(1, (distancia / intervaloMetros).ceil());

      for (int p = 0; p < passos; p++) {
        final t = p / passos;

        pontosDetalhados.add(
          LatLng(
            inicio.latitude + ((fim.latitude - inicio.latitude) * t),
            inicio.longitude + ((fim.longitude - inicio.longitude) * t),
          ),
        );
      }
    }

    pontosDetalhados.add(rota.last);

    return pontosDetalhados;
  }

  void iniciarOuPararRastreamento() {
    if (rastreando) {
      pararRastreamento();
    } else {
      iniciarRastreamento();
    }
  }

  void iniciarRastreamento() {
    inicioRota ??= DateTime.now();
    fimRota = null;

    simulationTimer?.cancel();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    locationSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final novaPosicao = LatLng(position.latitude, position.longitude);

            atualizarLocalizacao(novaPosicao, moverCamera: false);
          },
        );

    setState(() {
      rastreando = true;
    });
  }

  void pararRastreamento() {
    locationSubscription?.cancel();

    setState(() {
      rastreando = false;
    });
  }

  void atualizarLocalizacao(LatLng novaPosicao, {bool moverCamera = true}) {
    setState(() {
      posicaoAtual = novaPosicao;

      if (trajetoGps.isEmpty) {
        trajetoGps.add(novaPosicao);
      } else {
        final ultimoPonto = trajetoGps.last;

        final distancia = Geolocator.distanceBetween(
          ultimoPonto.latitude,
          ultimoPonto.longitude,
          novaPosicao.latitude,
          novaPosicao.longitude,
        );

        if (distancia >= 3) {
          distanciaPercorridaMetros += distancia;
          trajetoGps.add(novaPosicao);
        }
      }

      validarPontoNaRota(novaPosicao);
      progresso = calcularProgresso();
    });

    if (moverCamera && mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLng(novaPosicao));
    }
  }

  void validarPontoNaRota(LatLng pontoAtual) {
    if (rotaPlanejadaDetalhada.isEmpty || pontosConcluidos.isEmpty) {
      return;
    }

    final resultado = encontrarIndiceMaisProximoAdiante(pontoAtual);

    final int indiceMaisProximo = resultado.key;
    final double distanciaMaisProxima = resultado.value;

    if (distanciaMaisProxima > limiteDesvioMetros) {
      foraDaRota = true;
      return;
    }

    foraDaRota = false;

    if (distanciaMaisProxima <= toleranciaRotaMetros &&
        indiceMaisProximo > ultimoIndiceValidado) {
      final inicio = math.max(0, ultimoIndiceValidado + 1);

      for (int i = inicio; i <= indiceMaisProximo; i++) {
        pontosConcluidos[i] = true;
      }

      ultimoIndiceValidado = indiceMaisProximo;
    }
  }

  MapEntry<int, double> encontrarIndiceMaisProximoAdiante(LatLng pontoAtual) {
    int melhorIndice = math.max(0, ultimoIndiceValidado);
    double menorDistancia = double.infinity;

    for (int i = melhorIndice; i < rotaPlanejadaDetalhada.length; i++) {
      final pontoDaRota = rotaPlanejadaDetalhada[i];

      final distancia = Geolocator.distanceBetween(
        pontoAtual.latitude,
        pontoAtual.longitude,
        pontoDaRota.latitude,
        pontoDaRota.longitude,
      );

      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        melhorIndice = i;
      }
    }

    return MapEntry(melhorIndice, menorDistancia);
  }

  double calcularProgresso() {
    if (pontosConcluidos.isEmpty) return 0.0;

    final pontosValidados = pontosConcluidos.where((ponto) => ponto).length;

    return pontosValidados / pontosConcluidos.length;
  }

  List<LatLng> obterRotaValidada() {
    if (ultimoIndiceValidado < 1 || rotaPlanejadaDetalhada.isEmpty) {
      return [];
    }

    return rotaPlanejadaDetalhada.take(ultimoIndiceValidado + 1).toList();
  }

  void centralizarNoVeiculo() {
    if (posicaoAtual == null || mapController == null) return;

    mapController!.animateCamera(CameraUpdate.newLatLngZoom(posicaoAtual!, 17));
  }

  void simularPercurso() {
    if (rotaPlanejadaDetalhada.isEmpty) return;

    locationSubscription?.cancel();
    simulationTimer?.cancel();

    setState(() {
      rastreando = false;
      inicioRota = DateTime.now();
      fimRota = null;

      trajetoGps.clear();
      distanciaPercorridaMetros = 0.0;

      pontosConcluidos = List.filled(rotaPlanejadaDetalhada.length, false);

      ultimoIndiceValidado = -1;
      progresso = 0.0;
      foraDaRota = false;

      posicaoAtual = rotaPlanejadaDetalhada.first;
    });

    int index = 0;

    simulationTimer = Timer.periodic(const Duration(milliseconds: 250), (
      timer,
    ) {
      if (index >= rotaPlanejadaDetalhada.length) {
        timer.cancel();

        setState(() {
          fimRota = DateTime.now();
        });

        return;
      }

      final pontoSimulado = rotaPlanejadaDetalhada[index];

      atualizarLocalizacao(pontoSimulado, moverCamera: index % 5 == 0);

      index += 3;
    });
  }

  String calcularTempoRealFormatado() {
    if (inicioRota == null) {
      return 'Não iniciado';
    }

    final fim = fimRota ?? DateTime.now();
    final duracao = fim.difference(inicioRota!);

    final horas = duracao.inHours;
    final minutos = duracao.inMinutes.remainder(60);
    final segundos = duracao.inSeconds.remainder(60);

    if (horas > 0) {
      return '${horas}h ${minutos}min';
    }

    if (minutos > 0) {
      return '${minutos}min ${segundos}s';
    }

    return '${segundos}s';
  }

  String formatarDistancia(double metros) {
    if (metros >= 1000) {
      return '${(metros / 1000).toStringAsFixed(2)} km';
    }

    return '${metros.toStringAsFixed(0)} m';
  }

  Set<Polyline> criarPolylines() {
    final rotaValidada = obterRotaValidada();

    return {
      // CAMADA 1 — corredor base da rota planejada
      if (rotaPlanejadaDetalhada.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('rota_planejada_base'),
          points: rotaPlanejadaDetalhada,
          color: const Color.fromARGB(255, 255, 255, 255),
          width: 18,
          zIndex: 1,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),

      // CAMADA 2 — linha interna da rota planejada
      if (rotaPlanejadaDetalhada.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('rota_planejada_miolo'),
          points: rotaPlanejadaDetalhada,
          color: const Color(0xFFDCE7DC),
          width: 10,
          zIndex: 2,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),

      // CAMADA 3 — preenchimento validado (verde principal)
      if (rotaValidada.length >= 2)
        Polyline(
          polylineId: const PolylineId('rota_validada_base'),
          points: rotaValidada,
          color: const Color.fromARGB(255, 255, 255, 255),
          width: 18,
          zIndex: 3,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),

      // CAMADA 4 — brilho intermediário
      if (rotaValidada.length >= 2)
        Polyline(
          polylineId: const PolylineId('rota_validada_brilho'),
          points: rotaValidada,
          color: const Color.fromARGB(255, 29, 236, 39),
          width: 11,
          zIndex: 4,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),

      // CAMADA 5 — faixa central clara
      if (rotaValidada.length >= 2)
        Polyline(
          polylineId: const PolylineId('rota_validada_centro'),
          points: rotaValidada,
          color: const Color.fromARGB(255, 21, 255, 33),
          width: 5,
          zIndex: 5,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
    };
  }

  Set<Marker> criarMarcadores() {
    return {
      if (posicaoAtual != null)
        Marker(
          markerId: const MarkerId('veiculo'),
          position: posicaoAtual!,
          infoWindow: const InfoWindow(
            title: 'Veículo de coleta',
            snippet: 'Localização atual',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          zIndex: 8,
        ),
    };
  }

  Future<void> finalizarRota({
    required String bairro,
    required String tempo,
    required String motorista,
    required String veiculo,
    required String turno,
  }) async {
    fimRota = DateTime.now();

    locationSubscription?.cancel();
    simulationTimer?.cancel();

    final int pontosValidados = pontosConcluidos.where((ponto) => ponto).length;

    final String statusFinal = progresso >= 1.0
        ? 'Concluída'
        : 'Parcialmente concluída';

    final String distanciaFormatada = formatarDistancia(
      distanciaPercorridaMetros,
    );

    final String trechosValidados =
        '$pontosValidados/${pontosConcluidos.length}';

    final historico = RouteHistoryModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      rotaId: widget.rotaInicialModel?.id ?? 'rota_local',
      bairro: bairro,
      motorista: motorista,
      veiculo: veiculo,
      turno: turno,
      tempoEstimado: tempo,
      tempoReal: calcularTempoRealFormatado(),
      distanciaPercorrida: distanciaFormatada,
      trechosValidados: trechosValidados,
      progresso: progresso,
      status: statusFinal,
      dataFinalizacao: DateTime.now(),
    );

    await routeHistoryService.salvarHistorico(historico);

    if (!mounted) return;

    Navigator.pushNamed(
      context,
      AppRoutes.routeReport,
      arguments: {
        'bairro': bairro,
        'tempoEstimado': tempo,
        'tempoReal': historico.tempoReal,
        'progresso': progresso,
        'pontosPercorridos': trajetoGps.length,
        'status': statusFinal,
        'distanciaPercorrida': distanciaFormatada,
        'trechosValidados': trechosValidados,
      },
    );
  }

  void abrirTelaSubstituindo(Widget tela) {
    Navigator.of(context).pop();

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => tela));
    });
  }

  Future<void> sairDoApp() async {
    Navigator.of(context).pop();

    await Future.delayed(const Duration(milliseconds: 250));

    await AuthService().sair();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget construirMenuLateral() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: AppColors.primary,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_shipping, color: Colors.white, size: 46),
                  SizedBox(height: 12),
                  Text(
                    'Rota Limpa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Gestão de coleta urbana',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Painel inicial'),
              onTap: () {
                abrirTelaSubstituindo(const HomeScreen());
              },
            ),

            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Rotas da semana'),
              onTap: () {
                abrirTelaSubstituindo(WeeklyRoutesScreen());
              },
            ),

            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Histórico'),
              onTap: () {
                abrirTelaSubstituindo(const RouteHistoryScreen());
              },
            ),

            const Spacer(),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: sairDoApp,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rotaArgumento =
        ModalRoute.of(context)?.settings.arguments as Map<String, String>?;

    final rotaModel = widget.rotaInicialModel;

    final String dia =
        rotaModel?.dia ??
        widget.rotaInicial?['dia'] ??
        rotaArgumento?['dia'] ??
        'Rota em andamento';

    final String bairro =
        rotaModel?.bairro ??
        widget.rotaInicial?['bairro'] ??
        rotaArgumento?['bairro'] ??
        'Centro';

    final String tempo =
        rotaModel?.tempoEstimado ??
        widget.rotaInicial?['tempo'] ??
        rotaArgumento?['tempo'] ??
        '2h30min';

    final String motorista =
        rotaModel?.motorista ??
        widget.rotaInicial?['motorista'] ??
        rotaArgumento?['motorista'] ??
        'Motorista';

    final String veiculo =
        rotaModel?.veiculo ??
        widget.rotaInicial?['veiculo'] ??
        rotaArgumento?['veiculo'] ??
        'Caminhão';

    final String turno =
        rotaModel?.turno ??
        widget.rotaInicial?['turno'] ??
        rotaArgumento?['turno'] ??
        'Turno';

    final int progressoPercentual = (progresso * 100).round();

    final int pontosValidados = pontosConcluidos.where((ponto) => ponto).length;

    return Scaffold(
      key: scaffoldKey,
      drawer: construirMenuLateral(),
      body: carregando
          ? const Center(child: CircularProgressIndicator())
          : erro != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  erro!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: posicaoAtual!,
                    zoom: 17,
                  ),
                  onMapCreated: (controller) {
                    mapController = controller;
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  markers: criarMarcadores(),
                  polylines: criarPolylines(),
                ),

                // Topo estilo app GPS
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_shipping,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Rota Limpa',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  motorista,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Veículo: $veiculo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  'Turno: $turno',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: AppColors.textDark,
                            ),
                            onPressed: () {
                              scaffoldKey.currentState?.openDrawer();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Indicador de status da rota
                Positioned(
                  top: MediaQuery.of(context).padding.top + 92,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: foraDaRota
                          ? Colors.orange.shade100.withValues(alpha: 0.96)
                          : Colors.green.shade50.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: foraDaRota ? Colors.orange : AppColors.primary,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          foraDaRota
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle,
                          color: foraDaRota
                              ? Colors.orange.shade900
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            foraDaRota
                                ? 'Veículo fora da rota planejada'
                                : 'Veículo dentro da rota planejada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: foraDaRota
                                  ? Colors.orange.shade900
                                  : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Botões flutuantes laterais
                Positioned(
                  right: 16,
                  bottom: 245,
                  child: Column(
                    children: [
                      _BotaoMapa(
                        icon: Icons.my_location,
                        onTap: centralizarNoVeiculo,
                      ),
                      const SizedBox(height: 12),
                      _BotaoMapa(
                        icon: rastreando ? Icons.pause : Icons.play_arrow,
                        onTap: iniciarOuPararRastreamento,
                      ),
                      const SizedBox(height: 12),
                      _BotaoMapa(icon: Icons.route, onTap: simularPercurso),
                    ],
                  ),
                ),

                // Card inferior com informações da rota
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.97),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dia,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    bairro,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$progressoPercentual%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        LinearProgressIndicator(
                          value: progresso,
                          minHeight: 11,
                          backgroundColor: Colors.grey.shade300,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _InfoRota(
                                titulo: 'Tempo base',
                                valor: tempo,
                                icon: Icons.timer,
                              ),
                            ),
                            Expanded(
                              child: _InfoRota(
                                titulo: 'Validados',
                                valor:
                                    '$pontosValidados/${pontosConcluidos.length}',
                                icon: Icons.checklist,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              finalizarRota(
                                bairro: bairro,
                                tempo: tempo,
                                motorista: motorista,
                                veiculo: veiculo,
                                turno: turno,
                              );
                            },
                            icon: const Icon(Icons.flag),
                            label: const Text('Finalizar rota'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _BotaoMapa extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _BotaoMapa({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.96),
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
      ),
    );
  }
}

class _InfoRota extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icon;

  const _InfoRota({
    required this.titulo,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                valor,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
