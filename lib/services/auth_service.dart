import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get usuarioAtual => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> login({
    required String email,
    required String senha,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: senha.trim(),
      );
    } on FirebaseAuthException catch (e) {
      // Mantém o erro original para a tela de login identificar o código.
      throw e;
    } catch (e) {
      throw Exception('Erro inesperado ao fazer login: $e');
    }
  }

  Future<void> cadastrar({
    required String email,
    required String senha,
  }) async {
    try {
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
    } on FirebaseAuthException catch (e) {
      // Mantém o erro original para conseguirmos identificar o problema.
      throw e;
    } catch (e) {
      throw Exception('Erro inesperado ao cadastrar usuário: $e');
    }
  }

  Future<void> sair() async {
    await _auth.signOut();
  }
}
