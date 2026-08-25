import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/app_routes.dart';
import '../models/collection_route_model.dart';
import '../models/route_history_model.dart';
import '../services/auth_service.dart';
import '../services/route_history_service.dart';
import '../utils/app_colors.dart';
import 'login_screen.dart';
import 'route_history_screen.dart';
import 'weekly_routes_screen.dart';

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
  static const double _distanciaEntrePontosMetros = 20;
  static const double _toleranciaRotaMetros = 30;
  static const double _limiteDesvioMetros = 70;

  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _historyService = RouteHistoryService();

  GoogleMapController? _mapController;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _simulationTimer;

  LatLng? _posicaoAtual;
  List<LatLng> _rotaDetalhada = [];
  List<bool> _pontosConcluidos = [];
  final List<LatLng> _trajetoGps = [];

  bool _carregando = true;
  bool _rastreando = false;
  bool _foraDaRota = false;
  bool _navegandoPeloMenu = false;
  bool _finalizando = false;
  String? _erro;

  int _ultimoIndiceValidado = -1;
  double _progresso = 0;
  double _distanciaPercorridaMetros = 0;
  DateTime? _inicioRota;
  DateTime? _fimRota;

  @override
  void initState() {
    super.initState();
    _carregarLocalizacaoInicial();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _simulationTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _carregarLocalizacaoInicial() async {
    try {
      final position = await _determinarPosicao();
      if (!mounted) return;

      final localAtual = LatLng(position.latitude, position.longitude);
      final rota = _gerarRotaTestePorBairro(localAtual, _bairro);
      final rotaDetalhada = _detalharRota(rota, _distanciaEntrePontosMetros);

      setState(() {
        _posicaoAtual = localAtual;
        _rotaDetalhada = rotaDetalhada;
        _pontosConcluidos = List.filled(rotaDetalhada.length, false);
        _validarPontoNaRota(localAtual);
        _progresso = _calcularProgresso();
        _carregando = false;
      });

      // Dá tempo para o GoogleMap ser criado; não usa controller após dispose.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(localAtual, 16),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _erro = error.toString();
        _carregando = false;
      });
    }
  }

  Future<Position> _determinarPosicao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('O serviço de localização está desativado.');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied) {
      throw Exception('Permissão de localização negada.');
    }
    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão de localização negada permanentemente. Ative nas configurações do aparelho.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  List<LatLng> _gerarRotaTestePorBairro(LatLng base, String bairro) {
    final nome = bairro.toLowerCase();
    if (nome.contains('cidade')) {
      return [
        base,
        LatLng(base.latitude + .0005, base.longitude + .0002),
        LatLng(base.latitude + .0010, base.longitude + .0010),
        LatLng(base.latitude + .0003, base.longitude + .0018),
        LatLng(base.latitude - .0005, base.longitude + .0014),
        LatLng(base.latitude - .0008, base.longitude + .0004),
      ];
    }
    if (nome.contains('ponta')) {
      return [
        base,
        LatLng(base.latitude + .0003, base.longitude - .0005),
        LatLng(base.latitude + .0011, base.longitude - .0002),
        LatLng(base.latitude + .0014, base.longitude + .0008),
        LatLng(base.latitude + .0005, base.longitude + .0015),
        LatLng(base.latitude - .0004, base.longitude + .0010),
      ];
    }
    if (nome.contains('flores')) {
      return [
        base,
        LatLng(base.latitude - .0004, base.longitude),
        LatLng(base.latitude - .0008, base.longitude + .0008),
        LatLng(base.latitude - .0002, base.longitude + .0015),
        LatLng(base.latitude + .0006, base.longitude + .0013),
        LatLng(base.latitude + .0008, base.longitude + .0004),
      ];
    }
    return [
      base,
      LatLng(base.latitude + .0008, base.longitude),
      LatLng(base.latitude + .0012, base.longitude + .0008),
      LatLng(base.latitude + .0008, base.longitude + .0015),
      LatLng(base.latitude, base.longitude + .0017),
      LatLng(base.latitude - .0006, base.longitude + .0010),
      LatLng(base.latitude - .0004, base.longitude + .0002),
    ];
  }

  List<LatLng> _detalharRota(List<LatLng> rota, double intervaloMetros) {
    if (rota.isEmpty) return [];
    final pontos = <LatLng>[];
    for (var i = 0; i < rota.length - 1; i++) {
      final inicio = rota[i];
      final fim = rota[i + 1];
      final distancia = Geolocator.distanceBetween(
        inicio.latitude,
        inicio.longitude,
        fim.latitude,
        fim.longitude,
      );
      final passos = math.max(1, (distancia / intervaloMetros).ceil());
      for (var passo = 0; passo < passos; passo++) {
        final fator = passo / passos;
        pontos.add(LatLng(
          inicio.latitude + (fim.latitude - inicio.latitude) * fator,
          inicio.longitude + (fim.longitude - inicio.longitude) * fator,
        ));
      }
    }
    pontos.add(rota.last);
    return pontos;
  }

  void _iniciarOuPararRastreamento() {
    _rastreando ? _pararRastreamento() : _iniciarRastreamento();
  }

  void _iniciarRastreamento() {
    _locationSubscription?.cancel();
    _simulationTimer?.cancel();
    _inicioRota ??= DateTime.now();
    _fimRota = null;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((position) {
      if (!mounted) return;
      _atualizarLocalizacao(LatLng(position.latitude, position.longitude));
    });

    setState(() => _rastreando = true);
  }

  void _pararRastreamento() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    if (mounted) setState(() => _rastreando = false);
  }

  void _atualizarLocalizacao(LatLng novaPosicao, {bool moverCamera = true}) {
    if (!mounted) return;
    setState(() {
      _posicaoAtual = novaPosicao;
      if (_trajetoGps.isEmpty) {
        _trajetoGps.add(novaPosicao);
      } else {
        final ultimo = _trajetoGps.last;
        final distancia = Geolocator.distanceBetween(
          ultimo.latitude,
          ultimo.longitude,
          novaPosicao.latitude,
          novaPosicao.longitude,
        );
        if (distancia >= 5) {
          _distanciaPercorridaMetros += distancia;
          _trajetoGps.add(novaPosicao);
        }
      }
      _validarPontoNaRota(novaPosicao);
      _progresso = _calcularProgresso();
    });

    if (moverCamera) {
      _mapController?.animateCamera(CameraUpdate.newLatLng(novaPosicao));
    }
  }

  void _validarPontoNaRota(LatLng pontoAtual) {
    if (_rotaDetalhada.isEmpty || _pontosConcluidos.isEmpty) return;
    final proximo = _encontrarIndiceMaisProximoAdiante(pontoAtual);
    if (proximo.value > _limiteDesvioMetros) {
      _foraDaRota = true;
      return;
    }
    _foraDaRota = false;
    if (proximo.value <= _toleranciaRotaMetros &&
        proximo.key > _ultimoIndiceValidado) {
      for (var i = math.max(0, _ultimoIndiceValidado + 1); i <= proximo.key; i++) {
        _pontosConcluidos[i] = true;
      }
      _ultimoIndiceValidado = proximo.key;
    }
  }

  MapEntry<int, double> _encontrarIndiceMaisProximoAdiante(LatLng atual) {
    var indice = math.max(0, _ultimoIndiceValidado);
    var menorDistancia = double.infinity;
    for (var i = indice; i < _rotaDetalhada.length; i++) {
      final ponto = _rotaDetalhada[i];
      final distancia = Geolocator.distanceBetween(
        atual.latitude,
        atual.longitude,
        ponto.latitude,
        ponto.longitude,
      );
      if (distancia < menorDistancia) {
        menorDistancia = distancia;
        indice = i;
      }
    }
    return MapEntry(indice, menorDistancia);
  }

  double _calcularProgresso() {
    if (_pontosConcluidos.isEmpty) return 0;
    return _pontosConcluidos.where((concluido) => concluido).length /
        _pontosConcluidos.length;
  }

  void _simularPercurso() {
    if (_rotaDetalhada.isEmpty) return;
    _locationSubscription?.cancel();
    _simulationTimer?.cancel();
    setState(() {
      _rastreando = false;
      _inicioRota = DateTime.now();
      _fimRota = null;
      _trajetoGps.clear();
      _distanciaPercorridaMetros = 0;
      _pontosConcluidos = List.filled(_rotaDetalhada.length, false);
      _ultimoIndiceValidado = -1;
      _progresso = 0;
      _foraDaRota = false;
      _posicaoAtual = _rotaDetalhada.first;
    });

    var indice = 0;
    // Um intervalo maior reduz o volume de atualizações enviadas ao mapa nativo.
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || indice >= _rotaDetalhada.length) {
        timer.cancel();
        if (mounted) setState(() => _fimRota = DateTime.now());
        return;
      }
      _atualizarLocalizacao(_rotaDetalhada[indice], moverCamera: indice % 6 == 0);
      indice += 2;
    });
  }

  List<LatLng> get _rotaValidada => _ultimoIndiceValidado < 1
      ? const []
      : _rotaDetalhada.take(_ultimoIndiceValidado + 1).toList();

  Set<Polyline> _criarPolylines() {
    final validada = _rotaValidada;
    return {
      if (_rotaDetalhada.isNotEmpty)
        Polyline(
          polylineId: const PolylineId('rota_planejada'),
          points: _rotaDetalhada,
          color: const Color(0xFFDCE7DC),
          width: 9,
          zIndex: 1,
          jointType: JointType.round,
        ),
      if (validada.length >= 2)
        Polyline(
          polylineId: const PolylineId('rota_validada'),
          points: validada,
          color: AppColors.primary,
          width: 10,
          zIndex: 2,
          jointType: JointType.round,
        ),
    };
  }

  Set<Marker> _criarMarcadores() => {
    if (_posicaoAtual != null)
      Marker(
        markerId: const MarkerId('veiculo'),
        position: _posicaoAtual!,
        infoWindow: const InfoWindow(title: 'Veículo de coleta'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        zIndex: 3,
      ),
  };

  Future<void> _finalizarRota() async {
    if (_finalizando) return;
    setState(() => _finalizando = true);
    try {
      _fimRota = DateTime.now();
      _locationSubscription?.cancel();
      _simulationTimer?.cancel();
      final validados = _pontosConcluidos.where((ponto) => ponto).length;
      final historico = RouteHistoryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        rotaId: widget.rotaInicialModel?.id ?? 'rota_local',
        bairro: _bairro,
        motorista: _motorista,
        veiculo: _veiculo,
        turno: _turno,
        tempoEstimado: _tempo,
        tempoReal: _tempoReal,
        distanciaPercorrida: _formatarDistancia(_distanciaPercorridaMetros),
        trechosValidados: '$validados/${_pontosConcluidos.length}',
        progresso: _progresso,
        status: _progresso >= 1 ? 'Concluída' : 'Parcialmente concluída',
        dataFinalizacao: DateTime.now(),
      );
      await _historyService.salvarHistorico(historico);
      if (!mounted) return;
      await Navigator.of(context).pushNamed(
        AppRoutes.routeReport,
        arguments: {
          'bairro': _bairro,
          'tempoEstimado': _tempo,
          'tempoReal': historico.tempoReal,
          'progresso': _progresso,
          'pontosPercorridos': _trajetoGps.length,
          'status': historico.status,
        },
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível finalizar a rota: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  /// Fecha o Drawer, deixa o FocusScope concluir o ciclo atual e então empilha
  /// a nova tela. Não use pushReplacement aqui: o mapa deve permanecer vivo.
  Future<void> _abrirTelaDoMenu(WidgetBuilder builder) async {
    if (_navegandoPeloMenu) return;
    _navegandoPeloMenu = true;
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      Navigator.of(context).pop();
      await Future<void>.delayed(Duration.zero);
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(builder: builder));
    } finally {
      if (mounted) _navegandoPeloMenu = false;
    }
  }

  Future<void> _sairDoApp() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
    await Future<void>.delayed(Duration.zero);
    await AuthService().sair();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  Widget _menuLateral() => Drawer(
    child: SafeArea(
      child: Column(
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
                Text('Rota Limpa', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Gestão de coleta urbana', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month),
            title: const Text('Rotas da semana'),
            onTap: () => _abrirTelaDoMenu((_) => WeeklyRoutesScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Histórico'),
            onTap: () => _abrirTelaDoMenu((_) => const RouteHistoryScreen()),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: _sairDoApp,
          ),
        ],
      ),
    ),
  );

  void _centralizarNoVeiculo() {
    if (_posicaoAtual != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_posicaoAtual!, 17),
      );
    }
  }

  String get _bairro => widget.rotaInicialModel?.bairro ?? widget.rotaInicial?['bairro'] ?? 'Centro';
  String get _tempo => widget.rotaInicialModel?.tempoEstimado ?? widget.rotaInicial?['tempo'] ?? '2h30min';
  String get _motorista => widget.rotaInicialModel?.motorista ?? widget.rotaInicial?['motorista'] ?? 'Motorista';
  String get _veiculo => widget.rotaInicialModel?.veiculo ?? widget.rotaInicial?['veiculo'] ?? 'Caminhão';
  String get _turno => widget.rotaInicialModel?.turno ?? widget.rotaInicial?['turno'] ?? 'Turno';
  String get _tempoReal {
    if (_inicioRota == null) return 'Não iniciado';
    final duracao = (_fimRota ?? DateTime.now()).difference(_inicioRota!);
    final horas = duracao.inHours;
    final minutos = duracao.inMinutes.remainder(60);
    return horas > 0 ? '${horas}h ${minutos}min' : '${duracao.inMinutes}min';
  }

  String _formatarDistancia(double metros) => metros >= 1000
      ? '${(metros / 1000).toStringAsFixed(2)} km'
      : '${metros.toStringAsFixed(0)} m';

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_erro != null || _posicaoAtual == null) {
      return Scaffold(body: Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(_erro ?? 'Não foi possível obter a localização.', textAlign: TextAlign.center),
      )));
    }

    final percentual = (_progresso * 100).round();
    final validados = _pontosConcluidos.where((ponto) => ponto).length;
    return Scaffold(
      key: _scaffoldKey,
      drawer: _menuLateral(),
      body: Stack(children: [
        GoogleMap(
          key: const ValueKey('mapa-rota-principal'),
          initialCameraPosition: CameraPosition(target: _posicaoAtual!, zoom: 17),
          onMapCreated: (controller) => _mapController = controller,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: false,
          markers: _criarMarcadores(),
          polylines: _criarPolylines(),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .95),
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(children: [
                const CircleAvatar(
                  radius: 23,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.local_shipping, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rota Limpa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      const SizedBox(height: 2),
                      Text(_motorista, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                      Text('Veículo: $_veiculo', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      Text('Turno: $_turno', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  icon: const Icon(Icons.menu, color: AppColors.textDark),
                ),
              ]),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 92,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: (_foraDaRota ? Colors.orange.shade100 : Colors.green.shade50).withValues(alpha: .96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _foraDaRota ? Colors.orange : AppColors.primary),
            ),
            child: Row(children: [
              Icon(_foraDaRota ? Icons.warning_amber_rounded : Icons.check_circle, color: _foraDaRota ? Colors.orange.shade900 : AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _foraDaRota ? 'Veículo fora da rota planejada' : 'Veículo dentro da rota planejada',
                style: TextStyle(fontWeight: FontWeight.bold, color: _foraDaRota ? Colors.orange.shade900 : AppColors.primary),
              )),
            ]),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 240,
          child: Column(children: [
            _BotaoMapa(icon: Icons.my_location, onTap: _centralizarNoVeiculo),
            const SizedBox(height: 12),
            _BotaoMapa(icon: _rastreando ? Icons.pause : Icons.play_arrow, onTap: _iniciarOuPararRastreamento),
            const SizedBox(height: 12),
            _BotaoMapa(icon: Icons.route, onTap: _simularPercurso),
          ]),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 20,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .97),
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 16, offset: Offset(0, 6))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Rota de hoje', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(_bairro, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                  child: Text('$percentual%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 14),
              LinearProgressIndicator(value: _progresso, minHeight: 11, borderRadius: BorderRadius.circular(20), color: AppColors.primary),
              const SizedBox(height: 10),
              Text('Tempo base: $_tempo  •  Validados: $validados/${_pontosConcluidos.length}'),
              const SizedBox(height: 14),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(
                onPressed: _finalizando ? null : _finalizarRota,
                icon: const Icon(Icons.flag),
                label: Text(_finalizando ? 'Finalizando...' : 'Finalizar rota'),
              )),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _BotaoMapa extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BotaoMapa({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 6,
    child: IconButton(icon: Icon(icon, color: AppColors.primary), onPressed: onTap),
  );
}
