import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

class StorageService {
  final SupabaseClient _client = AppSupabase.client;

  Future<String> uploadProductImage(File file, String fileName) async {
      print('=== DEBUG UPLOAD START ===');

    final path = 'product/$fileName';

    await _client.storage.from('product_images').upload(path, file);

    final publicUrl = _client.storage.from('product_images').getPublicUrl(path);
    return publicUrl;
  }
}
