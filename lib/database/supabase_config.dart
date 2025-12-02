import 'package:supabase_flutter/supabase_flutter.dart';

class AppSupabase {
  static const String supabaseUrl = 'https://fxlkpkyxsehwhsfjyzml.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ4bGtwa3l4c2Vod2hzZmp5em1sIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5Mjg4NjcsImV4cCI6MjA3NjUwNDg2N30.XflQ6dXHlUuBWcFPPxOapAe5dGeXXYXcsfTuQlu5DRo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
