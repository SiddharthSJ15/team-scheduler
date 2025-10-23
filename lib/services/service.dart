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
      return UserModel.fromMap(res);
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
      try {
        return (url as dynamic).data ??
            (url as dynamic).publicUrl ??
            url.toString();
      } catch (_) {}
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

  // Availability
  static Future<List<Map<String, dynamic>>> getAvailability(
    String userId,
  ) async {
    try {
      final res = await _supabase
          .from('availability')
          .select()
          .eq('user_id', userId)
          .order('start_time', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('getAvailability error: $e');
      return [];
    }
  }

  static Future<bool> addAvailability({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      // Ensure times are in UTC
      final startUtc = start.isUtc ? start : start.toUtc();
      final endUtc = end.isUtc ? end : end.toUtc();

      await _supabase.from('availability').insert({
        'user_id': userId,
        'start_time': startUtc.toIso8601String(),
        'end_time': endUtc.toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('addAvailability error: $e');
      return false;
    }
  }

  static Future<void> deleteAvailability(int id) async {
    try {
      await _supabase.from('availability').delete().eq('id', id);
    } catch (e) {
      debugPrint('deleteAvailability error: $e');
    }
  }

  // Team
  // Fetch all users (useful for collaborator selection)
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final res = await _supabase.from('users').select().order('name');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('getAllUsers error: $e');
      return [];
    }
  }

  static Future<Map<String, List<Map<String, dynamic>>>>
  getAvailabilitiesForUsers(List<String> userIds) async {
    final result = <String, List<Map<String, dynamic>>>{};
    if (userIds.isEmpty) return result;
    try {
      final res = await _supabase
          .from('availability')
          .select()
          .inFilter('user_id', userIds)
          .order('start_time', ascending: true);
      final rows = List<Map<String, dynamic>>.from(res);
      for (final id in userIds) result[id] = [];
      for (final r in rows) {
        final uid = r['user_id'].toString();
        result.putIfAbsent(uid, () => []);
        result[uid]!.add(r);
      }
      return result;
    } catch (e) {
      debugPrint('getAvailabilitiesForUsers error: $e');
      return {for (var id in userIds) id: []};
    }
  }

  static Future<Map<String, dynamic>?> createTaskWithCollaborators({
    required String title,
    String? description,
    required String createdBy,
    required DateTime startTime,
    required DateTime endTime,
    required List<String> collaboratorIds,
  }) async {
    try {
      // Ensure times are in UTC
      final startUtc = startTime.isUtc ? startTime : startTime.toUtc();
      final endUtc = endTime.isUtc ? endTime : endTime.toUtc();

      final task = await _supabase
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'created_by': createdBy,
            'start_time': startUtc.toIso8601String(),
            'end_time': endUtc.toIso8601String(),
          })
          .select()
          .single();

      final taskId = task['id'];

      final inserts = collaboratorIds
          .map((uid) => {'task_id': taskId, 'user_id': uid})
          .toList();

      if (inserts.isNotEmpty) {
        await _supabase.from('task_collaborators').insert(inserts);
      }

      return Map<String, dynamic>.from(task);
    } catch (e) {
      debugPrint('createTaskWithCollaborators error: $e');
      return null;
    }
  }

  static List<List<DateTime>> findCommonSlots(
    List<List<List<DateTime>>> perUserIntervals,
    Duration duration, {
    Duration? stepDuration,
  }) {
    final step = stepDuration ?? duration;

    List<List<DateTime>> mergeIntervals(List<List<DateTime>> arr) {
      if (arr.isEmpty) return [];
      arr.sort((a, b) => a[0].compareTo(b[0]));
      final res = <List<DateTime>>[];
      var cur = [arr[0][0], arr[0][1]];
      for (var i = 1; i < arr.length; i++) {
        final next = arr[i];
        if (next[0].isBefore(cur[1]) || next[0].isAtSameMomentAs(cur[1])) {
          cur[1] = cur[1].isAfter(next[1]) ? cur[1] : next[1];
        } else {
          res.add([cur[0], cur[1]]);
          cur = [next[0], next[1]];
        }
      }
      res.add([cur[0], cur[1]]);
      return res;
    }

    List<List<DateTime>> intersectTwo(
      List<List<DateTime>> a,
      List<List<DateTime>> b,
    ) {
      final res = <List<DateTime>>[];
      int i = 0, j = 0;
      while (i < a.length && j < b.length) {
        final start = a[i][0].isAfter(b[j][0]) ? a[i][0] : b[j][0];
        final end = a[i][1].isBefore(b[j][1]) ? a[i][1] : b[j][1];
        // Check if there's a valid intersection (start < end)
        if (start.isBefore(end)) {
          res.add([start, end]);
        }
        if (a[i][1].isBefore(b[j][1])) {
          i++;
        } else {
          j++;
        }
      }
      return res;
    }

    if (perUserIntervals.isEmpty) return [];

    final merged = perUserIntervals
        .map((u) => mergeIntervals(List.from(u)))
        .toList();
    var common = merged[0];
    for (var k = 1; k < merged.length; k++) {
      common = intersectTwo(common, merged[k]);
      if (common.isEmpty) return [];
    }

    final slots = <List<DateTime>>[];
    for (final interval in common) {
      var current = interval[0];
      final end = interval[1];
      while (current.add(duration).isBefore(end) ||
          current.add(duration).isAtSameMomentAs(end)) {
        slots.add([current, current.add(duration)]);
        current = current.add(step);
      }
    }
    return slots;
  }

  // service.dart — add these methods

  /// Fetch tasks and their collaborators + user objects in two queries,
  /// then compose them into a convenient structure for UI.
  static Future<List<Map<String, dynamic>>>
  getAllTasksWithCollaborators() async {
    try {
      final tasksRes = await _supabase
          .from('tasks')
          .select()
          .order('start_time', ascending: true);
      final tasks = List<Map<String, dynamic>>.from(tasksRes ?? []);

      if (tasks.isEmpty) return [];

      // Gather task ids and user ids to fetch collaborators & users in batch
      final taskIds = tasks.map((t) => t['id']).toList();
      final createdByIds = tasks
          .where((t) => t['created_by'] != null)
          .map((t) => t['created_by'].toString())
          .toSet();

      // fetch collaborator rows
      final collRes = await _supabase
          .from('task_collaborators')
          .select()
          .inFilter('task_id', taskIds);
      final collRows = List<Map<String, dynamic>>.from(collRes ?? []);

      // gather collaborator user ids
      final collUserIds = collRows.map((r) => r['user_id'].toString()).toSet();
      final allUserIds = {...createdByIds, ...collUserIds};

      // fetch user rows
      final usersRes = await _supabase
          .from('users')
          .select()
          .inFilter('id', allUserIds.toList());
      final users = List<Map<String, dynamic>>.from(usersRes ?? []);

      // build a map userId -> userMap
      final userMap = <String, Map<String, dynamic>>{};
      for (final u in users) {
        userMap[u['id'].toString()] = u;
      }

      // compose final tasks with collaborators & creator user
      final composed = <Map<String, dynamic>>[];
      for (final t in tasks) {
        final tid = t['id'];
        final createdById = t['created_by']?.toString();
        final collForTask = collRows
            .where((c) => c['task_id'] == tid)
            .map((c) => userMap[c['user_id'].toString()])
            .where((u) => u != null)
            .cast<Map<String, dynamic>>()
            .toList();

        composed.add({
          ...t, // keep original fields (id, title, start_time, end_time, created_by, etc)
          'created_by_user': createdById != null ? userMap[createdById] : null,
          'collaborators': collForTask,
        });
      }

      return composed;
    } catch (e) {
      debugPrint('getAllTasksWithCollaborators error: $e');
      return [];
    }
  }

  /// Optionally: fetch tasks where a given user is collaborator or creator.
  static Future<List<Map<String, dynamic>>> getTasksForUser(
    String userId,
  ) async {
    try {
      final all = await getAllTasksWithCollaborators();
      final filtered = all.where((t) {
        final createdBy = t['created_by']?.toString();
        if (createdBy == userId) return true;
        final coll = (t['collaborators'] as List<dynamic>?) ?? [];
        return coll.any((u) => u['id'].toString() == userId);
      }).toList();
      return filtered;
    } catch (e) {
      debugPrint('getTasksForUser error: $e');
      return [];
    }
  }
}
