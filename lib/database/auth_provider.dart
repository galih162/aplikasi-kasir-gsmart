import 'package:flutter/material.dart';
import 'package:gs_mart_aplikasi/database/auth_service.dart';
import 'package:gs_mart_aplikasi/models/user.dart';
import 'package:gs_mart_aplikasi/database/user_service.dart';
import 'package:gs_mart_aplikasi/database/customer_service.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  final customerService = CustomerService();
  final userService = UserService();

  UserModel? currentUser;
  String? errorMessage;

  bool isLoading = false;
// 👈 FIX

  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;     // 👈 FIX
      notifyListeners();

      final result = await _authService.login(email, password);

      final userData = result?['user_data'];
      if (userData == null) {
        isLoading = false;
        return false;
      }

      currentUser = UserModel.fromDatabase(userData);
      errorMessage = null;

      isLoading = false;    // 👈 FIX
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;    // 👈 FIX
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    notifyListeners();
  }

  checkSession() {}

  void initialize() {}
}
