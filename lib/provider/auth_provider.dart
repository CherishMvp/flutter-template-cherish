// auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;
  // final GoRouter _router = approuter;
  final GoRouter _router;

  AuthProvider(this._router) {
    loadLoginStatus(); //注入这个地方无法做到异步执行
  }

  Future<void> loadLoginStatus() async {
    final token = await _storage.read(key: 'auth_token');
    print("立即读取token$token");
    _isLoggedIn = token != null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    _isLoggedIn = false;
    notifyListeners();
  }
}
