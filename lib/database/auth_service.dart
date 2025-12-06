import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// LOGIN → Ambil auth user → Ambil data user di tabel public.users
  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final authUser = response.user;

      if (authUser == null) {
        throw Exception("Email atau password salah");
      }

      // Ambil data user dari tabel users
      final userData = await _supabase
          .from("users")
          .select()
          .eq("auth_id", authUser.id)
          .maybeSingle();

      if (userData == null) {
        throw Exception("Akun tidak terdaftar pada database.");
      }

      return {
        "auth_user": authUser,
        "user_data": userData,
      };
    }

    // 🔥 Tangkap ERROR LOGIN dari Supabase
    on AuthException catch (e) {
      if (e.message.contains("Invalid login credentials")) {
        throw Exception("Email atau password salah");
      }

      if (e.message.contains("Email not confirmed")) {
        throw Exception("Email belum diverifikasi");
      }

      throw Exception(e.message);
    }

    // 🔥 Tangkap error lainnya
    catch (e) {
      throw Exception("Terjadi kesalahan: $e");
    }
  }

  /// LOGOUT dari Supabase
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  /// Ambil user auth saat ini + informasi user dari tabel public.users
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;

    final userData = await _supabase
        .from("users")
        .select()
        .eq("auth_id", authUser.id)
        .maybeSingle();

    if (userData == null) return null;

    return {
      "auth_user": authUser,
      "user_data": userData,
    };
  }
}
