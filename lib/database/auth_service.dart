import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// LOGIN → Ambil auth user → Ambil data user di tabel public.users
  Future<Map<String, dynamic>?> login(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final authUser = response.user;

    if (authUser == null) {
      throw Exception("Login gagal: user tidak ditemukan");
    }

    // Cari data user di public.users berdasarkan auth_id
    final userData = await _supabase
        .from("users")
        .select()
        .eq("auth_id", authUser.id)
        .maybeSingle();

    if (userData == null) {
      throw Exception("Akun tidak terdaftar di tabel users.");
    }

    return {
      "auth_user": authUser,
      "user_data": userData,
    };
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
