import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/route_history_model.dart';

class RouteHistoryService {
  RouteHistoryService();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _historicoCollection {
    final usuario = _auth.currentUser;

    if (usuario == null) {
      throw Exception('Usuário não autenticado.');
    }

    return _firestore
        .collection('usuarios')
        .doc(usuario.uid)
        .collection('historico_rotas');
  }

  Future<List<RouteHistoryModel>> listarHistorico() async {
    final snapshot = await _historicoCollection
        .orderBy('dataFinalizacao', descending: false)
        .get();

    return snapshot.docs.map((doc) {
      final dados = doc.data();

      return RouteHistoryModel.fromMap({
        ...dados,
        'id': doc.id,
      });
    }).toList();
  }

  Future<void> salvarHistorico(RouteHistoryModel historico) async {
    await _historicoCollection.doc(historico.id).set({
      ...historico.toMap(),
      'dataFinalizacao': Timestamp.fromDate(historico.dataFinalizacao),
    });
  }

  Future<void> limparHistorico() async {
    final snapshot = await _historicoCollection.get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}