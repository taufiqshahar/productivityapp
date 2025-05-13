import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> registerWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i('Registration successful for ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      _logger.e('Registration error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _logger.i('Sign-in successful for ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      _logger.e('Sign-in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _logger.i('Sign-out successful');
    } catch (e) {
      _logger.e('Sign-out error: $e');
      rethrow;
    }
  }
}