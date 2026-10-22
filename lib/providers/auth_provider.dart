import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _error;

  bool _isLoggedIn = false;

  String? _userId;
  UserModel? _user;

  // getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  String get userId => _userId ?? "";
  UserModel? get user => _user;

  // =========================
  // Register
  // =========================
  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _setLoading(true);

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
    );

    _setLoading(false);

    if (result != null) {
      _setError(result);
      return false;
    }

    _clearError();

    return true;
  }

  // =========================
  // Login
  // =========================
  Future<bool> login(String email, String password) async {
    _setLoading(true);

    final result = await _authService.login(
      email: email,
      password: password,
    );

    if (result != null) {
      _setLoading(false);
      _setError(result);
      return false;
    }

    // get current user
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _setLoading(false);
      _setError("Failed to retrieve user after login.");
      return false;
    }

    _userId = firebaseUser.uid;

    // fetch user data
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .get();

      if (doc.exists) {
        _user = UserModel.fromMap(doc.data()!, _userId!);
      } else {
        _user = null;
      }
    } catch (e) {
      _setError("Failed to load user data");
    }

    // save login state
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', _userId!);

    _isLoggedIn = true;

    _setLoading(false);
    _clearError();

    return true;
  }

  // =========================
  // Check Login State (Auto Login)
  // =========================
  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();

    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userId = prefs.getString('userId');

    if (_isLoggedIn && _userId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .get();

        if (doc.exists) {
          _user = UserModel.fromMap(doc.data()!, _userId!);
        }
      } catch (e) {
        _error = "Failed to load user data";
      }
    }

    notifyListeners();
  }

  // =========================
  // Logout
  // =========================
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _isLoggedIn = false;
    _userId = null;
    _user = null;

    notifyListeners();
  }

  // =========================
  // Helpers
  // =========================
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String errorMsg) {
    _error = errorMsg;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}