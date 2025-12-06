import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gs_mart_aplikasi/database/supabase_config.dart';
import 'package:gs_mart_aplikasi/models/products.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ================= ProductService =================
class ProductService {
  final SupabaseClient _client;
  ProductService() : _client = AppSupabase.client;
  SupabaseClient get client => _client;
  final supabase = Supabase.instance.client; 
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await _client
          .from('products')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => ProductModel.fromDatabase(e))
          .toList();
    } catch (e) {
      debugPrint("getAllProducts error: $e");
      return [];
    }
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      final response =
          await _client.from('products').select().eq('id', id).maybeSingle();

      if (response == null) return null;
      return ProductModel.fromDatabase(response);
    } catch (e) {
      debugPrint("getProductById error: $e");
      return null;
    }
  }

  Future<bool> createProduct(ProductModel product) async {
    try {
      // 1. Siapkan data untuk insert
      final data = product.toJson();

      // 2. Tambahkan user ID jika belum ada
      if (product.createdBy == null || product.createdBy!.isEmpty) {
        final userId = _client.auth.currentUser?.id;
        if (userId != null) {
          data['created_by'] = userId;
        }
      }

      // 3. Insert ke database
      print('📊 Data yang akan diinsert: $data');
      final response = await _client.from('products').insert(data).select();

      print('✅ Produk berhasil dibuat dengan ID: ${response[0]['id']}');
      print('📸 image_url di database: ${response[0]['image_url']}');

      return true;
    } catch (e) {
      debugPrint("❌ createProduct error: $e");

      // Debug lebih detail
      if (e is PostgrestException) {
        print('🔄 PostgrestException: ${e.message}');
        print('📝 Code: ${e.code}');
        print('🔍 Details: ${e.details}');
      }

      return false;
    }
  }

  Future<bool> updateProduct(ProductModel product) async {
    try {
      // 1. Siapkan data untuk update
      final data = product.toJson();

      // 2. Update database
      print('📊 Data update: $data');
      print('🆔 Update product dengan ID: ${product.id}');

      final response = await _client
          .from('products')
          .update(data)
          .eq('id', product.id)
          .select();

      print('✅ Produk berhasil diupdate');
      print('📸 image_url setelah update: ${response[0]['image_url']}');

      return true;
    } catch (e) {
      debugPrint("❌ updateProduct error: $e");
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      print('🗑️ Menghapus produk dengan ID: $id');

      // 1. Cek dulu apakah produk ada
      final product = await getProductById(id);
      if (product == null) {
        print('❌ Produk dengan ID $id tidak ditemukan');
        return false;
      }

      // 2. Hapus gambar dari storage jika ada
      if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        try {
          // Extract file name dari URL
          final url = product.imageUrl!;
          final fileName = url.split('/').last;

          await _client.storage.from('product-images').remove([fileName]);

          print('✅ Gambar produk dihapus dari storage: $fileName');
        } catch (e) {
          print('⚠️ Gagal hapus gambar: $e');
          // Lanjutkan hapus produk meski gambar gagal dihapus
        }
      }

      // 3. Hapus dari database
      final response = await _client.from('products').delete().eq('id', id);

      print('✅ Produk berhasil dihapus dari database');
      return true;
    } catch (e) {
      debugPrint("❌ deleteProduct error: $e");

      if (e is PostgrestException) {
        print('🔄 PostgrestException: ${e.message}');
        print('📝 Code: ${e.code}');
      }

      return false;
    }
  }

  Future<String?> uploadImage(dynamic file) async {
    try {
      print('🚀 === UPLOAD IMAGE START ===');
      print('Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      print('File type: ${file.runtimeType}');

      final bucket = 'product-images';
      final fileName = 'product_${DateTime.now().millisecondsSinceEpoch}.jpg';

      print('1. Bucket: $bucket');
      print('2. File name: $fileName');

      if (kIsWeb && file is Uint8List) {
        // WEB: upload binary
        print('3. Platform: WEB - Uploading bytes');
        print('   - Bytes length: ${file.length}');

        await _client.storage.from(bucket).uploadBinary(fileName, file);
        print('4. Upload complete!');
      } else if (!kIsWeb && file is File) {
        // MOBILE: upload File
        print('3. Platform: MOBILE');
        print('   - File path: ${file.path}');

        await _client.storage.from(bucket).upload(fileName, file);
        print('4. Upload complete!');
      } else {
        print('❌ ERROR: Invalid file type for platform');
        print('   - kIsWeb: $kIsWeb');
        print('   - File type: ${file.runtimeType}');
        return null;
      }
      // Get URL
      final publicUrl = _client.storage.from(bucket).getPublicUrl(fileName);
      print('5. Public URL: $publicUrl');
      print('🚀 === UPLOAD IMAGE END ===');

      return publicUrl;
    } catch (e) {
      print('💥 === UPLOAD ERROR ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('💥 === ERROR END ===');
      return null;
    }
  }

  Future<bool> addStock(String productId, int qty) async {
    try {
      final product = await getProductById(productId);
      if (product == null) return false;

      final newStock = product.stokTersedia + qty;

      await _client.from('products').update({
        'stok_tersedia': newStock,
        'last_stock_update': DateTime.now().toIso8601String(),
      }).eq('id', productId);

      return true;
    } catch (e) {
      debugPrint("addStock error: $e");
      return false;
    }
  }

  Future createTransactionWithStockUpdate({required String kasirId, required double totalHarga, required List<Map<String, Object>> details}) async {}

  Future getAllProductsWithStock() async {}
}
// CRUD Produk selesai