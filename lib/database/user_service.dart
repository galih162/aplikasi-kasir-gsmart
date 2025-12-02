// lib/services/user_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final _client = Supabase.instance.client;

  // ==================== CREATE USER (Admin/Kasir) ====================
  Future<Map<String, dynamic>> createUser({
    required String? email,
    required String password,
    required String nama,
    required String jabatan, // 'admin' atau 'kasir'
  }) async {
    try {
      // 1. Buat user di Supabase Auth
      final authResponse = await _client.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: password,
          emailConfirm: true,
        ),
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Gagal membuat akun'};
      }

      // 2. Simpan data tambahan ke table users
      await _client.from('users').insert({
        'auth_id': authResponse.user!.id,
        'email': email,
        'nama': nama,
        'jabatan': jabatan,
        'is_active': true,
      });

      return {'success': true, 'message': 'Pengguna berhasil ditambahkan'};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // ==================== UPDATE USER ====================
  Future<Map<String, dynamic>> updateUser({
    required String userId,
    required String nama,
    required String email,
    required String jabatan,
    required bool isActive,
    String? newPassword,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'nama': nama,
        'email': email,
        'jabatan': jabatan,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Jika password diisi, update juga di auth
      if (newPassword != null && newPassword.isNotEmpty) {
        final authUser = _client.auth.currentUser;
        if (authUser != null) {
          await _client.auth.admin.updateUserById(
            userId,
          attributes: AdminUserAttributes(password: newPassword),
          );
        }
      }

      await _client.from('users').update(updateData).eq('id', userId);

      return {'success': true, 'message': 'Pengguna diperbarui'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal update: $e'};
    }
  }

  // ==================== DELETE USER ====================
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      // Hapus dari table users
      await _client.from('users').delete().eq('id', userId);

      // Hapus dari Supabase Auth (opsional, tapi disarankan)
      await _client.auth.admin.deleteUser(userId);

      return {'success': true, 'message': 'Pengguna dihapus permanen'};
    } catch (e) {
      return {'success': false, 'message': 'Gagal hapus: $e'};
    }
  }

  // ==================== REAL-TIME STREAM PENGGUNA ====================
  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}