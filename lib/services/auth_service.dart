import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // =========================
  // Register
  // =========================
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // 1. Create user
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user!;
      final userId = user.uid;

      // 2. Reload user to ensure session is active
      await user.reload();
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return "Failed to create user session.";
      }

      // 3. Create UserModel بدون صورة
      final userModel = UserModel(
        id: userId,
        name: name,
        email: email,
        image: '', // لا يوجد صورة، يمكنك وضع رابط placeholder إذا أحببت
        searchKey: name.toLowerCase(),
        createdAt: DateTime.now(),
      );

      // 4. Save to Firestore
      await _db.collection('users').doc(userId).set(userModel.toMap());

      return null;
    }

    // Firebase Auth Errors
    on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    }

    // General Errors
    catch (e) {
      print(e);
      return "Something went wrong. Please try again."+e.toString();
    }
  }

  // =========================
  // Login
  // =========================
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _handleAuthError(e);
    } catch (e) {
      return "Login failed. Try again.";
    }
  }

  // =========================
  // Get Current User Data
  // =========================
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  // =========================
  // Logout
  // =========================
  Future<void> logout() async {
    await _auth.signOut();
  }

  // =========================
  // Error Handling
  // =========================
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "This email is already registered.";
      case 'invalid-email':
        return "Invalid email format.";
      case 'weak-password':
        return "Password is too weak.";
      case 'user-not-found':
        return "No user found with this email.";
      case 'wrong-password':
        return "Incorrect password.";
      case 'network-request-failed':
        return "Check your internet connection.";
      default:
        return e.message ?? "Authentication error occurred.";
    }
  }
}