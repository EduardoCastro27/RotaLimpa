class RouteHistoryModel {
  final String id;
  final String rotaId;
  final String bairro;
  final String motorista;
  final String veiculo;
  final String turno;
  final String tempoEstimado;
  final String tempoReal;
  final String distanciaPercorrida;
  final String trechosValidados;
  final double progresso;
  final String status;
  final DateTime dataFinalizacao;

  const RouteHistoryModel({
    required this.id,
    required this.rotaId,
    required this.bairro,
    required this.motorista,
    required this.veiculo,
    required this.turno,
    required this.tempoEstimado,
    required this.tempoReal,
    required this.distanciaPercorrida,
    required this.trechosValidados,
    required this.progresso,
    required this.status,
    required this.dataFinalizacao,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'rotaId': rotaId,
      'bairro': bairro,
      'motorista': motorista,
      'veiculo': veiculo,
      'turno': turno,
      'tempoEstimado': tempoEstimado,
      'tempoReal': tempoReal,
      'distanciaPercorrida': distanciaPercorrida,
      'trechosValidados': trechosValidados,
      'progresso': progresso,
      'status': status,
      'dataFinalizacao': dataFinalizacao.toIso8601String(),
    };
  }

  factory RouteHistoryModel.fromMap(Map<String, dynamic> map) {
    return RouteHistoryModel(
      id: map['id'] ?? '',
      rotaId: map['rotaId'] ?? '',
      bairro: map['bairro'] ?? '',
      motorista: map['motorista'] ?? '',
      veiculo: map['veiculo'] ?? '',
      turno: map['turno'] ?? '',
      tempoEstimado: map['tempoEstimado'] ?? '',
      tempoReal: map['tempoReal'] ?? '',
      distanciaPercorrida: map['distanciaPercorrida'] ?? '',
      trechosValidados: map['trechosValidados'] ?? '',
      progresso: (map['progresso'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? '',
      dataFinalizacao:
          DateTime.tryParse(map['dataFinalizacao'] ?? '') ?? DateTime.now(),
    );
  }
}
