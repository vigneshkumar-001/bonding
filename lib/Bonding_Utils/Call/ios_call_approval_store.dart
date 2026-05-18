import 'package:shared_preferences/shared_preferences.dart';

class IosCallApprovalStore {
  static const _key = 'ios_call_approved_staff_ids';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  static Future<bool> isApproved(String staffMongoId) async {
    final id = staffMongoId.trim();
    if (id.isEmpty) return false;
    final set = await load();
    return set.contains(id);
  }

  static Future<void> markApproved(String staffMongoId) async {
    final id = staffMongoId.trim();
    if (id.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_key) ?? const <String>[]).toSet();
    current.add(id);
    await prefs.setStringList(_key, current.toList());
  }
}
