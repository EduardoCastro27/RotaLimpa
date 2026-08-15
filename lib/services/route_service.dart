import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/collection_route_model.dart';

class RouteService {
  final FirebaseFirestore _firestore;

  RouteService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<CollectionRouteModel> buscarRotaPorEmail(String email) async {
    final emailFormatado = email.trim().toLowerCase();

    await criarRotasIniciaisSeNaoExistirem();

    final resultado = await _firestore
        .collection('rotas')
        .where('emailMotorista', isEqualTo: emailFormatado)
        .limit(1)
        .get();

    if (resultado.docs.isNotEmpty) {
      final doc = resultado.docs.first;
      final dados = doc.data();

      return CollectionRouteModel.fromMap({
        ...dados,
        'id': dados['id'] ?? doc.id,
      });
    }

    return rotaPadrao(emailFormatado);
  }

  Future<void> criarRotasIniciaisSeNaoExistirem() async {
    final rotas = [
      const CollectionRouteModel(
        id: 'rota_centro_001',
        dia: 'Rota de hoje',
        bairro: 'Centro',
        tempoEstimado: '2h30min',
        motorista: 'Motorista Centro',
        emailMotorista: 'centro@empresa.com',
        veiculo: 'Caminhão 01',
        turno: 'Manhã',
      ),
      const CollectionRouteModel(
        id: 'rota_cidade_nova_001',
        dia: 'Rota de hoje',
        bairro: 'Cidade Nova',
        tempoEstimado: '3h',
        motorista: 'Motorista Cidade Nova',
        emailMotorista: 'cidade@empresa.com',
        veiculo: 'Caminhão 02',
        turno: 'Manhã',
      ),
      const CollectionRouteModel(
        id: 'rota_ponta_negra_001',
        dia: 'Rota de hoje',
        bairro: 'Ponta Negra',
        tempoEstimado: '3h20min',
        motorista: 'Motorista Ponta Negra',
        emailMotorista: 'ponta@empresa.com',
        veiculo: 'Caminhão 03',
        turno: 'Tarde',
      ),
      const CollectionRouteModel(
        id: 'rota_flores_001',
        dia: 'Rota de hoje',
        bairro: 'Flores',
        tempoEstimado: '2h45min',
        motorista: 'Motorista Flores',
        emailMotorista: 'flores@empresa.com',
        veiculo: 'Caminhão 04',
        turno: 'Noite',
      ),
    ];

    for (final rota in rotas) {
      final docRef = _firestore.collection('rotas').doc(rota.id);
      final doc = await docRef.get();

      if (!doc.exists) {
        await docRef.set(rota.toMap());
      }
    }
  }

  CollectionRouteModel rotaPadrao(String email) {
    return CollectionRouteModel(
      id: 'rota_padrao_001',
      dia: 'Rota de hoje',
      bairro: 'Centro',
      tempoEstimado: '2h30min',
      motorista: 'Motorista padrão',
      emailMotorista: email,
      veiculo: 'Caminhão padrão',
      turno: 'Manhã',
    );
  }

  Future<List<CollectionRouteModel>> listarRotasDisponiveis() async {
    await criarRotasIniciaisSeNaoExistirem();

    final resultado = await _firestore.collection('rotas').get();

    return resultado.docs.map((doc) {
      final dados = doc.data();

      return CollectionRouteModel.fromMap({
        ...dados,
        'id': dados['id'] ?? doc.id,
      });
    }).toList();
  }
}
