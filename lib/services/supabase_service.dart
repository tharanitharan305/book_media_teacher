import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;

  SupabaseService._internal();

  late final SupabaseClient client;
  Future<void> init({required String url, required String anonKey}) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    client = Supabase.instance.client;

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: 'dev-teacher@example.com',
        password: 'DevPass123!',
      );
      debugPrint(
        'SIGNED IN USER: ${Supabase.instance.client.auth.currentUser?.id}',
      );
    } catch (e) {
      debugPrint('SIGNIN ERROR: $e');
    }
  }
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
  }) async {
    try {
      final bytes = await file.readAsBytes();

      final response = await client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      if (response.isEmpty) {
        throw Exception("Upload failed. Empty response.");
      }

      return client.storage.from(bucket).getPublicUrl(path).trim();
    } catch (e) {
      throw Exception("Supabase uploadFile error: $e");
    }
  }
  Future<String> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
  }) async {
    try {
      debugPrint(
        'Uploading to bucket=$bucket, path=$path, bytes=${bytes.length}',
      );
      final result = await client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(upsert: true, cacheControl: '3600'),
          );
      debugPrint('uploadBinary result: $result');
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      debugPrint('publicUrl: $publicUrl');
      return publicUrl;
    } catch (e, st) {
      debugPrint('uploadBytes ERROR: $e');
      debugPrint(st.toString());
      rethrow;
    }
  }
  String getPublicUrl({required String bucket, required String path}) {
    try {
      return client.storage.from(bucket).getPublicUrl(path).trim();
    } catch (e) {
      throw Exception("Supabase getPublicUrl error: $e");
    }
  }
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await client.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception("deleteFile error: $e");
    }
  }
}
