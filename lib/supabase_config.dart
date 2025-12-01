import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://qdnijhsaomczkeacqjcm.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFkbmlqaHNhb21jemtlYWNxamNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ0ODI2MDAsImV4cCI6MjA4MDA1ODYwMH0.0Z_6hBCEJ_WGGDdaYkGWl5m0HJ7Sggk23m52xS1MQ0M',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
