import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get usuarioAtual => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> login({required String email, required String senha}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: senha.trim(),
    );
  }

  Future<void> cadastrar({required String email, required String senha}) async {
    final credencial = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: senha.trim(),
    );

    final usuario = credencial.user;

    if (usuario == null) {
      throw Exception('Não foi possível criar o usuário.');
    }

    await _firestore.collection('usuarios').doc(usuario.uid).set({
      'uid': usuario.uid,
      'email': usuario.email,
      'tipo': 'motorista',
      'rotaAtualId': null,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sair() async {
    await _auth.signOut();
  }
}
