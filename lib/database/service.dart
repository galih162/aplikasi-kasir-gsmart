import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class SupabaseConfig {
  static const String supabaseUrl = 'https://fxlkpkyxsehwhsfjyzml.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4bGtwa3l4c2Vod2hzZmp5em1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5Mjg4NjcsImV4cCI6MjA3NjUwNDg2N30.XflQ6dXHlUuBWcFPPxOapAe5dGeXXYXcsfTuQlu5DRo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // Disable PKCE untuk testing
      // authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}

class UserModel {
  final String id;
  final String email;
  final String nama;
  final String jabatan;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.nama,
    required this.jabatan,
    required this.isActive,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nama: json['nama'] as String? ?? 'User',
      jabatan: json['jabatan'] as String? ?? 'kasir',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isAdmin => jabatan == 'admin';
  bool get isKasir => jabatan == 'kasir';
}

class AuthService {
  final SupabaseClient _supabase = SupabaseConfig.client;

  Future<Map<String, dynamic>> loginUser(
      {required final String email, required final String password}) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final cleanPassword = password.trim();

      debugPrint('🔐 ATTEMPTING LOGIN: $cleanEmail');

      // 1. Login via Supabase Auth
      final response = await _supabase.auth
          .signInWithPassword(email: cleanEmail, password: cleanPassword);

      if (response.user == null) {
        return {'success': false, 'message': 'Login gagal'};
      }

      debugPrint('📨 AUTH RESPONSE: SUCCESS');
      debugPrint('👤 USER: ${response.user!.email}');
      debugPrint('🆔 AUTH ID: ${response.user!.id}');

      final userId = response.user!.id;

      // 2. Get user data - PAKAI 'id' BUKAN 'auth_id'
      Map<String, dynamic>? userData;

      userData = await _supabase
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();

      debugPrint('🔍 QUERY: SELECT * FROM users WHERE id = $userId');
      debugPrint(
          '📊 USER DATA RESULT: ${userData != null ? "FOUND" : "NOT FOUND"}');

      // 3. JIKA TIDAK DITEMUKAN, COBA CARI DENGAN auth_id
      if (userData == null) {
        debugPrint('🔄 TRYING WITH auth_id...');
        userData = await _supabase
            .from('users')
            .select()
            .eq('auth_id', userId) // 👈 COBA DENGAN auth_id
            .maybeSingle();

        debugPrint('🔍 QUERY: SELECT * FROM users WHERE auth_id = $userId');
        debugPrint(
            '📊 USER DATA RESULT (auth_id): ${userData != null ? "FOUND" : "NOT FOUND"}');
      }

      // 4. JIKA MASIH TIDAK DITEMUKAN, BUAT OTOMATIS
      if (userData == null) {
        debugPrint('🆕 USER NOT FOUND, CREATING IN PUBLIC.USERS...');

        userData = {
          'id': userId,
          'email': cleanEmail,
          'nama': cleanEmail.split('@')[0],
          'jabatan': 'kasir',
          'is_active': true,
          'auth_id': userId,
        };

        await _supabase.from('users').insert(userData);
        debugPrint('✅ AUTO-CREATED USER IN PUBLIC.USERS');

        // Ambil data yang baru dibuat
        userData =
            await _supabase.from('users').select().eq('id', userId).single();
      }

      debugPrint('📊 USER DATA: $userData');
      debugPrint('👤 USER STATUS: ${userData['is_active']}');

      if (userData['is_active'] == false) {
        await _supabase.auth.signOut();
        return {'success': false, 'message': 'Akun tidak aktif'};
      }

      await _saveUserToPrefs(response.user!);
      final user = UserModel.fromJson(userData);

      debugPrint('🎉 LOGIN SUCCESSFUL: ${user.email}');
      debugPrint('👤 USER ROLE: ${user.jabatan}');
      return {'success': true, 'message': 'Login berhasil', 'user': user};
    } catch (e) {
      debugPrint('💥 LOGIN ERROR: $e');
      return {'success': false, 'message': _getErrorMessage(e)};
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
    await prefs.remove('user_email');
  }

  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.id);
      await prefs.setString('user_email', user.email ?? '');
      debugPrint('💾 USER SAVED TO PREFS: ${user.email}');
    } catch (e) {
      debugPrint('❌ ERROR Saat simpan data: $e');
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      if (error.message.contains('Invalid login credentials')) {
        return 'Email atau password salah';
      }
      if (error.message.contains('Email not confirmed')) {
        return 'Email belum dikonfirmasi';
      }
      if (error.message.contains('user_already_exists')) {
        return 'Email sudah terdaftar';
      }
    }

    // Default error message
    return 'Terjadi kesalahan: ${error.toString()}';
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final session = _supabase.auth.currentSession;
      debugPrint('🔍 CURRENT SESSION: ${session != null ? "EXISTS" : "NULL"}');

      if (session == null) {
        debugPrint('❌ NO ACTIVE SESSION');
        return null;
      }

      // ✅ PERBAIKAN: Ganti 'id' jadi 'auth_id'
      final userData = await _supabase
          .from('users')
          .select()
          .eq('auth_id', session.user.id) // 👈 PAKAI auth_id
          .maybeSingle();

      debugPrint(
          '📊 USER DATA FROM DB: ${userData != null ? "FOUND" : "NOT FOUND"}');

      return userData != null ? UserModel.fromJson(userData) : null;
    } catch (e) {
      debugPrint('❌ getCurrentUser ERROR: $e');
      return null;
    }
  }
}

class UserService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final session = _client.auth.currentSession;
      if (session == null) return null;

      final userData = await _client
          .from('users')
          .select()
          .eq('auth_id', session.user.id)
          .maybeSingle();

      return userData;
    } catch (e) {
      debugPrint('❌ getCurrentUser ERROR: $e');
      return null;
    }
  }

  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }


  Future<Map<String, dynamic>> createUser({
    required String email,
    required String password,
    required String nama,
    required String jabatan,
  }) async {
    try {
      debugPrint('🔧 CREATING USER: $email with role: $jabatan');

      // 1. Buat user di auth
      final authResponse = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'nama': nama,
          'jabatan': jabatan,
        },
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Gagal membuat user auth'};
      }

      final userId = authResponse.user!.id;
      debugPrint('✅ Auth user created with ID: $userId');
      final userData = await _client
          .from('users')
          .insert({
            'id': userId, // Primary key
            'auth_id': userId, // Foreign key ke auth.users
            'email': email.trim(),
            'nama': nama,
            'jabatan': jabatan,
            'is_active': true,
          })
          .select()
          .single();

      debugPrint('✅ User successfully inserted into users table');

      return {
        'success': true,
        'message': 'User berhasil dibuat',
        'user_id': userId,
        'user_data': userData,
      };
    } catch (e) {
      debugPrint('❌ CREATE USER ERROR: $e');

      // Handle duplicate user error
      if (e
          .toString()
          .contains('duplicate key value violates unique constraint')) {
        return {
          'success': false,
          'message': 'User dengan email tersebut sudah ada'
        };
      }

      return {
        'success': false,
        'message': 'Gagal membuat user: ${e.toString()}',
      };
    }
  }

  Stream<List<Map<String, dynamic>>> getAllUsersStream() {
    return _client
        .from('users')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<Map<String, dynamic>> updateUser({
    required final String userId,
    required final String nama,
    required final String jabatan,
    required final bool isActive,
  }) async {
    try {
      await _client.from('users').update({
        'nama': nama,
        'jabatan': jabatan,
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      return {'success': true, 'message': 'User berhasil diupdate'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal update user: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deleteUser(final String userId) async {
    try {
      await _client.from('users').delete().eq('id', userId);
      return {'success': true, 'message': 'User berhasil dihapus'};
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menghapus user: ${e.toString()}',
      };
    }
  }
}

class ProductService {
  Future<Map<String, dynamic>> createProductWithImage({
    required String kodeProduk,
    required String namaProduk,
    required double hargaBeli,
    required double hargaJual,
    required String kategori,
    required String satuan,
    required int stokAwal,
    File? imageFile,
    String? deskripsi,
  }) async {
    try {
      String? imageUrl;

      // Upload gambar jika ada
      if (imageFile != null) {
        imageUrl = await StorageService().uploadProductImage(imageFile);
        if (imageUrl == null) {
          return {'success': false, 'message': 'Gagal upload gambar produk'};
        }
      }

      final currentUser = _client.auth.currentUser;

      final productResponse = await _client
          .from('products')
          .insert({
            'kode_produk': kodeProduk,
            'nama_produk': namaProduk,
            'deskripsi': deskripsi,
            'harga_beli': hargaBeli,
            'harga_jual': hargaJual,
            'kategori': kategori,
            'satuan': satuan,
            'stok_tersedia': stokAwal,
            'stok_minimum': 5,
            'image_url': imageUrl, // 👈 Simpan URL gambar
            'last_stock_update': DateTime.now().toIso8601String(),
            'created_by': currentUser?.id,
          })
          .select()
          .single();

      debugPrint('✅ Product created with image: $namaProduk');

      return {
        'success': true,
        'message': 'Produk berhasil ditambahkan',
        'product_id': productResponse['id'],
        'image_url': imageUrl,
      };
    } catch (e) {
      debugPrint('❌ ERROR createProductWithImage: $e');
      return {
        'success': false,
        'message': 'Gagal menambah produk: ${e.toString()}',
      };
    }
  }

// Update produk dengan gambar baru
  Future<Map<String, dynamic>> updateProductImage({
    required String productId,
    required String currentImageUrl,
    required File newImageFile,
  }) async {
    try {
      // Delete gambar lama
      await StorageService().deleteProductImage(currentImageUrl);

      // Upload gambar baru
      final newImageUrl =
          await StorageService().uploadProductImage(newImageFile);
      if (newImageUrl == null) {
        return {'success': false, 'message': 'Gagal upload gambar baru'};
      }

      // Update database
      await _client.from('products').update({
        'image_url': newImageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', productId);

      return {
        'success': true,
        'message': 'Gambar produk berhasil diupdate',
        'image_url': newImageUrl,
      };
    } catch (e) {
      debugPrint('❌ ERROR updateProductImage: $e');
      return {
        'success': false,
        'message': 'Gagal update gambar: ${e.toString()}',
      };
    }
  }

  final SupabaseClient _client = SupabaseConfig.client;

  // Stok sudah ada di tabel products, tidak perlu join
  Future<List<Map<String, dynamic>>> getAllProductsWithStock() async {
    try {
      debugPrint('🔄 Loading products from database...');

      final response = await _client.from('products').select('''
            id,
            kode_produk,
            nama_produk,
            deskripsi,
            harga_beli,
            harga_jual,
            kategori,
            satuan,
            stok_tersedia,
            stok_minimum,
            image_url,
            created_at,
            updated_at
          ''').order('nama_produk', ascending: true);

      debugPrint('✅ Products loaded: ${response.length} items');

      // DEBUG: Print sample data
      if (response.isNotEmpty) {
        final sampleCount = min(3, response.length); // ← PERBAIKAN DI SINI
        for (var i = 0; i < sampleCount; i++) {
          final product = response[i];
          debugPrint(
              '   📦 ${product['nama_produk']} - Stok: ${product['stok_tersedia']}');
        }
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ ERROR getAllProductsWithStock: $e');
      return [];
    }
  }

  //  Update stok langsung di tabel products
  Future<Map<String, dynamic>> updateStock({
    required String productId,
    required int stokTersedia,
    required int stokMinimum,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;

      await _client.from('products').update({
        'stok_tersedia': stokTersedia,
        'stok_minimum': stokMinimum,
        'last_stock_update': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'updated_by': currentUser?.id,
      }).eq('id', productId); // 👈 PERBAIKAN: pakai 'id' bukan 'kode_produk'

      return {'success': true, 'message': 'Stok berhasil diupdate'};
    } catch (e) {
      debugPrint('❌ ERROR updateStock: $e');
      return {
        'success': false,
        'message': 'Gagal update stok: ${e.toString()}',
      };
    }
  }

  // PERBAIKAN: Create product dengan stok langsung
  Future<Map<String, dynamic>> createProduct({
    required String kodeProduk,
    required String namaProduk,
    required double hargaBeli,
    required double hargaJual,
    required String kategori,
    required String satuan,
    required int stokAwal,
    final String? deskripsi,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;

      final productResponse = await _client
          .from('products')
          .insert({
            'kode_produk': kodeProduk,
            'nama_produk': namaProduk,
            'deskripsi': deskripsi,
            'harga_beli': hargaBeli,
            'harga_jual': hargaJual,
            'kategori': kategori,
            'satuan': satuan,
            'stok_tersedia': stokAwal, // 👈 STOK LANGSUNG DI SINI
            'stok_minimum': 5,
            'last_stock_update': DateTime.now().toIso8601String(),
            'created_by': currentUser?.id,
          })
          .select()
          .single();

      debugPrint('✅ Product created with stock: $stokAwal');

      return {
        'success': true,
        'message': 'Produk berhasil ditambahkan',
        'product_id': productResponse['id'],
      };
    } catch (e) {
      debugPrint('❌ ERROR createProduct: $e');
      return {
        'success': false,
        'message': 'Gagal menambah produk: ${e.toString()}',
      };
    }
  }

  // PERBAIKAN: Check stok untuk transaksi
  Future<Map<String, dynamic>> checkStockForTransaction({
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      for (final detail in details) {
        final stokCheck = await _client
            .from('products')
            .select('stok_tersedia, nama_produk')
            .eq('id', detail['produk_id'])
            .single();

        if ((stokCheck['stok_tersedia'] as int) < detail['jumlah']) {
          return {
            'success': false,
            'message':
                'Stok ${stokCheck['nama_produk']} tidak mencukupi. Stok tersedia: ${stokCheck['stok_tersedia']}'
          };
        }
      }

      return {'success': true};
    } catch (e) {
      return {
        'success': false,
        'message': 'Error checking stock: ${e.toString()}'
      };
    }
  }

  // PERBAIKAN: Update stok setelah transaksi
  Future<Map<String, dynamic>> updateStockAfterTransaction({
    required String productId,
    required int quantity,
  }) async {
    try {
      // Kurangi stok
      await _client.from('products').update({
        'stok_tersedia': _client.rpc('decrement_stock',
            params: {'row_id': productId, 'amount': quantity}),
        'last_stock_update': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', productId);

      return {'success': true};
    } catch (e) {
      debugPrint('❌ ERROR updateStockAfterTransaction: $e');
      return {
        'success': false,
        'message': 'Gagal update stok: ${e.toString()}'
      };
    }
  }

  // Method sederhana untuk kasir
  Future<List<Map<String, dynamic>>> getProductsForSale() async {
    try {
      final response = await _client
          .from('products')
          .select('''
            id,
            kode_produk,
            nama_produk,
            harga_jual,
            kategori,
            satuan,
            stok_tersedia
          ''')
          .gt('stok_tersedia', 0) // Hanya produk dengan stok > 0
          .order('nama_produk', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ ERROR getProductsForSale: $e');
      return [];
    }
  }

  // ✅ TAMBAHKAN METHOD INI - CREATE TRANSACTION WITH STOCK UPDATE
  Future<Map<String, dynamic>> createTransactionWithStockUpdate({
    required String kasirId,
    required double totalHarga,
    required List<Map<String, dynamic>> details,
  }) async {
    try {
      // 1. Check stok tersedia
      final stockCheck = await checkStockForTransaction(details: details);
      if (!stockCheck['success']) {
        return stockCheck;
      }

      // 2. Buat transaksi penjualan
      final penjualanRes = await _client
          .from('penjualan')
          .insert({
            'kasir_id': kasirId,
            'total_harga': totalHarga,
            'tanggal': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final penjualanId = penjualanRes['id'];

      // 3. Buat detail penjualan
      final detailPenjualan = details
          .map((final d) => {
                'penjualan_id': penjualanId,
                'produk_id': d['produk_id'],
                'jumlah': d['jumlah'],
                'harga_satuan': d['harga_satuan'],
                'subtotal': d['subtotal'],
                'diskon_item': d['diskon_item'] ?? 0,
              })
          .toList();

      await _client.from('detail_penjualan').insert(detailPenjualan);

      // 4. Update stok untuk setiap produk
      for (final detail in details) {
        await updateStockAfterTransaction(
          productId: detail['produk_id'],
          quantity: detail['jumlah'],
        );
      }

      return {
        'success': true,
        'penjualan_id': penjualanId,
        'message': 'Transaksi berhasil'
      };
    } catch (e) {
      debugPrint('❌ ERROR creating transaction: $e');
      return {
        'success': false,
        'message': 'Gagal membuat transaksi: ${e.toString()}'
      };
    }
  }
}

class TransactionService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> getTransactionHistory({
    final DateTime? startDate,
    final DateTime? endDate,
    final int limit = 50,
  }) async {
    try {
      if (startDate != null && endDate != null) {
        final startDateStr = startDate.toIso8601String();
        final endDateStr = endDate.toIso8601String();

        final response = await _client
            .from('penjualan')
            .select('''
              *,
              pelanggan(nama, no_telepon),
              users(nama),
              detail_penjualan(
                jumlah,
                harga_satuan,
                subtotal,
                produk:kode_produk, nama_produk
              )
            ''')
            .gte('created_at', startDateStr)
            .lte('created_at', endDateStr)
            .order('created_at', ascending: false)
            .limit(limit);

        return List<Map<String, dynamic>>.from(response);
      } else {
        final response = await _client.from('penjualan').select('''
              *,
              pelanggan(nama, no_telepon),
              users(nama),
              detail_penjualan(
                jumlah,
                harga_satuan,
                subtotal,
                produk:kode_produk, nama_produk
              )
            ''').order('created_at', ascending: false).limit(limit);

        return List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      debugPrint('Error getTransactionHistory: $e');
      return [];
    }
  }
}
class CustomerService {
  final SupabaseClient _client = SupabaseConfig.client;

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    try {
      final response = await _client
          .from('pelanggan')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error get all customers: $e');
      return [];
    }
  }

  // Tambahkan method ini untuk mengatasi error
  Stream<List<Map<String, dynamic>>> getAllCustomersStream() {
    return _client
        .from('pelanggan')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<Map<String, dynamic>> createCustomer({
    required String nama,
    required String noTelepon,
    String? alamat,
    String? email,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;

      final response = await _client.from('pelanggan').insert({
        'nama': nama,
        'no_telepon': noTelepon,
        'alamat': alamat,
        'email': email,
        'created_by': currentUser?.id,
      }).select().single();

      return {
        'success': true,
        'message': 'Pelanggan berhasil ditambahkan',
        'customer_id': response['id'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Gagal menambah pelanggan: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> updateCustomer({
    required String customerId,
    required String nama,
    required String noTelepon,
    String? alamat,
    String? email,
  }) async {
    try {
      final result = await _client
          .from('pelanggan')
          .update({
            'nama': nama,
            'no_telepon': noTelepon,
            'alamat': alamat,
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
            'updated_by': _client.auth.currentUser?.id,
          })
          .eq('id', customerId)
          .select()
          .single();

      if (result.isEmpty) {
        return {'success': false, 'message': 'Pelanggan tidak ditemukan'};
      }

      return {'success': true, 'message': 'Pelanggan berhasil diupdate'};
    } catch (e) {
      debugPrint('❌ Update customer error: $e');
      return {'success': false, 'message': 'Gagal update pelanggan: ${e.toString()}'};
    }
  }

Future<Map<String, dynamic>> deleteCustomer(String customerId) async {
  try {
    // Cek apakah pelanggan digunakan dalam transaksi
    final usageCheck = await _client
        .from('penjualan')
        .select('id')
        .eq('pelanggan_id', customerId);

    if (usageCheck.isNotEmpty) {
      return {
        'success': false, 
        'message': 'Pelanggan tidak dapat dihapus karena masih digunakan dalam ${usageCheck.length} transaksi'
      };
    }

    await _client
        .from('pelanggan')
        .delete()
        .eq('id', customerId);

    return {'success': true, 'message': 'Pelanggan berhasil dihapus'};

  } catch (e) {
    debugPrint('❌ Delete customer error: $e');
    return {'success': false, 'message': 'Gagal menghapus pelanggan: ${e.toString()}'};
  }
}
}

class StorageService {
  final SupabaseClient _client = SupabaseConfig.client;
  final ImagePicker _picker = ImagePicker();

  // Pick image dari galeri/kamera
  Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85, // Kompresi
      );

      if (pickedFile == null) return null;
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('❌ Pick image error: $e');
      return null;
    }
  }

  // Upload gambar produk
  Future<String?> uploadProductImage(File imageFile) async {
    try {
      // Buat nama file unik
      final fileExt = path.extension(imageFile.path);
      final fileName =
          'product_${DateTime.now().millisecondsSinceEpoch}$fileExt';
      final storagePath = 'products/$fileName';

      // Upload ke Supabase Storage
      await _client.storage
          .from('product-images')
          .upload(storagePath, imageFile);

      // Dapatkan public URL
      final imageUrl =
          _client.storage.from('product-images').getPublicUrl(storagePath);

      debugPrint('✅ Image uploaded: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('❌ Upload error: $e');
      return null;
    }
  }

  // Delete gambar lama
  Future<void> deleteProductImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      // Extract path dari URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final storagePath =
          pathSegments.sublist(pathSegments.indexOf('products')).join('/');

      await _client.storage.from('product-images').remove([storagePath]);
      debugPrint('✅ Image deleted: $storagePath');
    } catch (e) {
      debugPrint('❌ Delete error: $e');
    }
  }
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final ProductService _productService = ProductService();
  final TransactionService _transactionService = TransactionService();
  final CustomerService _customerService = CustomerService();
  final StorageService _storageService = StorageService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isInitialized => _isInitialized;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isKasir => _currentUser?.isKasir ?? false;

  UserService get userService => _userService;
  ProductService get productService => _productService;
  TransactionService get transactionService => _transactionService;
  CustomerService get customerService => _customerService;

  StorageService get storageService => _storageService;

  Future<void> checkSession() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _currentUser = await _authService.getCurrentUser();
      debugPrint(
          '✅ SESSION CHECK: ${_currentUser != null ? _currentUser!.email : "NO USER"}');
    } catch (e) {
      debugPrint('❌ SESSION ERROR: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    if (_isLoading) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result =
          await _authService.loginUser(email: email.trim(), password: password);

      if (result['success'] == true && result['user'] != null) {
        _currentUser = result['user'] as UserModel;
        _errorMessage = null;
        debugPrint('🎉 LOGIN SUCCESS: ${_currentUser!.email}');

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _currentUser = null;
        _errorMessage = result['message'] ?? 'Login failed';
        debugPrint('❌ LOGIN FAILED: $_errorMessage');

        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _currentUser = null;
      _errorMessage = 'Login error: ${e.toString()}';
      debugPrint('💥 LOGIN EXCEPTION: $e');

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _errorMessage = null;
      debugPrint('🚪 LOGOUT SUCCESSFUL');
    } catch (e) {
      debugPrint('❌ LOGOUT ERROR: $e');
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
