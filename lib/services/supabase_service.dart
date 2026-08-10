import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://yjddbkmvjchuocwbpczv.supabase.co';
  static const String supabaseKey = 'sb_publishable_a1Y07txTriiNK-ju_Cmvkw_XQw49hA9';
  static const String bucketName = 'paws-images';

  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseKey,
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Supabase init warning: $e');
    }
  }

  static SupabaseClient get client => Supabase.instance.client;

  /// Upload profile image bytes to Supabase Storage: profile_images/$uid.jpg
  static Future<String?> uploadProfileImage(String uid, Uint8List bytes) async {
    try {
      final fileName = 'profile_images/$uid.jpg';
      final storage = client.storage.from(bucketName);

      await storage.uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = storage.getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading profile image: $e');
      }
      return null;
    }
  }

  /// Upload post image bytes to Supabase Storage: posts/$postId.jpg
  static Future<String?> uploadPostImage(String postId, Uint8List bytes) async {
    try {
      final fileName = 'posts/$postId.jpg';
      final storage = client.storage.from(bucketName);

      await storage.uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = storage.getPublicUrl(fileName);
      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading post image: $e');
      }
      return null;
    }
  }

  /// Delete a specific post image from Supabase Storage
  static Future<void> deletePostImage(String postId) async {
    try {
      final fileName = 'posts/$postId.jpg';
      await client.storage.from(bucketName).remove([fileName]);
      if (kDebugMode) {
        print('Post image deleted: $fileName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting post image from Supabase: $e');
      }
    }
  }

  /// Delete all user data from Supabase Storage (profile image + all posts images)
  static Future<void> deleteAllUserDataFromSupabase(String uid, List<String> postIds) async {
    try {
      final storage = client.storage.from(bucketName);

      // 1. Delete profile image
      try {
        await storage.remove(['profile_images/$uid.jpg']);
      } catch (e) {
        if (kDebugMode) print('Error deleting profile image: $e');
      }

      // 2. Delete all post images
      final postPaths = postIds.map((id) => 'posts/$id.jpg').toList();
      if (postPaths.isNotEmpty) {
        try {
          await storage.remove(postPaths);
        } catch (e) {
          if (kDebugMode) print('Error deleting bulk post images: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in bulk deletion from Supabase: $e');
      }
    }
  }
}
