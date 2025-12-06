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

  /// =============================
  ///   LOGIN FUNCTION (FIXED)
  /// =============================
  Future<bool> login(String email, String password) async {
  print('🔐 Login attempt with email: $email');
  isLoading = true;
  errorMessage = null;
  notifyListeners();

  try {
    print('📞 Calling SupabaseAuthService.login()...');
    final result = await _authService.login(email, password);
    print('✅ SupabaseAuthService response: ${result != null}');

    if (result == null || result['user_data'] == null) {
      print('❌ User data is null');
      errorMessage = "Akun tidak ditemukan.";
      isLoading = false;
      notifyListeners();
      return false;
    }

    print('✅ User found: ${result['user_data']['email']}');
    currentUser = UserModel.fromDatabase(result['user_data']);
    errorMessage = null;

    isLoading = false;
    notifyListeners();
    return true;
  } catch (e) {
    print('❌ Login error: $e');
    print('❌ Error type: ${e.runtimeType}');
    print('❌ Error toString: ${e.toString()}');
    
    errorMessage = _getUserFriendlyErrorMessage(e.toString());
    
    print('📢 Error message to user: $errorMessage');
    
    isLoading = false;
    notifyListeners();
    return false;
  }
}

  // Helper untuk membuat pesan error lebih user-friendly
  String _getUserFriendlyErrorMessage(String error) {
    if (error.contains("Invalid login credentials") || 
        error.contains("Email atau password salah")) {
      return "Email atau password salah";
    } else if (error.contains("Email not confirmed")) {
      return "Email belum diverifikasi";
    } else if (error.contains("User not found")) {
      return "Akun tidak ditemukan";
    } else if (error.contains("network") || error.contains("connection")) {
      return "Tidak dapat terhubung ke server. Cek koneksi internet";
    } else {
      return "Terjadi kesalahan. Coba lagi";
    }
  }

  /// =============================
  ///   LOGOUT
  /// =============================
  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    notifyListeners();
  }

  void checkSession() {
    // Implement jika perlu
  }

  void initialize() {
    // Implement jika perlu
  }
}