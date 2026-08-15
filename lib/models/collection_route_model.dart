import 'route_point_model.dart';

class CollectionRouteModel {
  final String id;
  final String dia;
  final String bairro;
  final String tempoEstimado;
  final String motorista;
  final String emailMotorista;
  final String veiculo;
  final String turno;
  final String status;
  final List<RoutePointModel> pontos;

  const CollectionRouteModel({
    required this.id,
    required this.dia,
    required this.bairro,
    required this.tempoEstimado,
    required this.motorista,
    required this.emailMotorista,
    required this.veiculo,
    required this.turno,
    this.status = 'Pendente',
    this.pontos = const [],
  });

  bool get possuiPontosFixos => pontos.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dia': dia,
      'bairro': bairro,
      'tempoEstimado': tempoEstimado,
      'motorista': motorista,
      'emailMotorista': emailMotorista,
      'veiculo': veiculo,
      'turno': turno,
      'status': status,
      'pontos': pontos.map((ponto) => ponto.toMap()).toList(),
    };
  }

  factory CollectionRouteModel.fromMap(Map<String, dynamic> map) {
    return CollectionRouteModel(
      id: map['id'] ?? '',
      dia: map['dia'] ?? '',
      bairro: map['bairro'] ?? '',
      tempoEstimado: map['tempoEstimado'] ?? '',
      motorista: map['motorista'] ?? '',
      emailMotorista: map['emailMotorista'] ?? '',
      veiculo: map['veiculo'] ?? '',
      turno: map['turno'] ?? '',
      status: map['status'] ?? 'Pendente',
      pontos: map['pontos'] == null
          ? []
          : List<RoutePointModel>.from(
              (map['pontos'] as List).map(
                (ponto) =>
                    RoutePointModel.fromMap(Map<String, dynamic>.from(ponto)),
              ),
            ),
    );
  }
}
