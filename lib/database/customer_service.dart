// lib/services/customer_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerService {
  final _client = Supabase.instance.client;

  // ==================== CREATE PELANGGAN ====================
  Future<Map<String, dynamic>> createCustomer({
    required String nama,
    required String noTelepon,
    String? alamat,
    String? email,
  }) async {
    try {
      final response = await _client.from('pelanggan').insert({
        'nama': nama,
        'no_telepon': noTelepon,
        'alamat': alamat,
        'email': email,
        'created_by': _client.auth.currentUser?.id,
      }).select();

      return {'success': true, 'message': 'Pelanggan berhasil ditambahkan'};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ==================== UPDATE PELANGGAN ====================
  Future<Map<String, dynamic>> updateCustomer({
    required String customerId,
    required String nama,
    required String noTelepon,
    String? alamat,
    String? email,
  }) async {
    try {
      await _client.from('pelanggan').update({
        'nama': nama,
        'no_telepon': noTelepon,
        'alamat': alamat,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': _client.auth.currentUser?.id,
      }).eq('id', customerId);

      return {'success': true, 'message': 'Pelanggan berhasil diperbarui'};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Gagal update: $e'};
    }
  }

  // ==================== DELETE PELANGGAN ====================
  Future<Map<String, dynamic>> deleteCustomer(String customerId) async {
    try {
      await _client.from('pelanggan').delete().eq('id', customerId);
      return {'success': true, 'message': 'Pelanggan dihapus'};
    } on PostgrestException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Gagal menghapus'};
    }
  }

  // ==================== REAL-TIME STREAM PELANGGAN ====================
  Stream<List<Map<String, dynamic>>> getAllCustomersStream() {
    return _client
        .from('pelanggan')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
// CRUD Pelanggan selesai