import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/models.dart';

final _supabase = Supabase.instance.client;
const _userKey = 'scheduler_user_id';

class SupabaseService {
  // Create user in Supabase; returns new id or null
  static Future<String?> createUser({
    required String name,
    String? photoUrl,
  }) async {
    try {
      final res = await _supabase
          .from('users')
          .insert({'name': name, 'photo_url': photoUrl})
          .select()
          .single();
      if (res == null) return null;
      final id = res['id'].toString();
      await saveUserIdLocally(id);
      return id;
    } catch (e) {
      debugPrint('createUser error: $e');
      return null;
    }
  }

  static Future<UserModel?> getUserById(String id) async {
    try {
      final res = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      return UserModel.fromMap(res as Map<String, dynamic>);
    } catch (e) {
      debugPrint('getUserById error: $e');
      return null;
    }
  }

  static Future<void> saveUserIdLocally(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_userKey, id);
  }

  static Future<String?> getSavedUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_userKey);
  }

  static Future<void> clearSavedUserId() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_userKey);
  }

  static Future<String?> uploadProfileImage(
    XFile file,
    String targetPath,
  ) async {
    try {
      final bytes = await file.readAsBytes();
      final bucket = 'profile';
      final path = targetPath;
      await _supabase.storage.from(bucket).uploadBinary(path, bytes);
      final url = _supabase.storage.from(bucket).getPublicUrl(path);
      // if (url is PostgrestResponse || url is Map) {

      // }
      if (url is dynamic) {
        try {
          return (url as dynamic).data ??
              (url as dynamic).publicUrl ??
              url.toString();
        } catch (_) {}
      }
      final projectUrl = _supabase.storage.from(bucket).getPublicUrl(path);
      try {
        return (projectUrl as dynamic).data ?? projectUrl.toString();
      } catch (_) {
        return null;
      }
    } catch (e) {
      debugPrint('uploadProfileImage error: $e');
      return null;
    }
  }
}
