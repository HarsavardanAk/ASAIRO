import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/hanging_object.dart';

class SceneStorageService {
  static const String _keySceneObjects = 'hangly_saved_scene_objects';
  static const String _keyActiveMode = 'hangly_active_mode';

  static List<HangingObject> getDefaultObjects() {
    return [
      HangingObject(
        id: 'talisman_lemon_chillies',
        name: 'Nimbu-Mirchi Nazar Battu',
        type: 'lemon_chillies',
        x: -2.3,
        z: 0.0,
        cordLength: 3.3,
        mass: 1.3,
        damping: 0.993,
        gravity: -19.6,
        sensitivity: 1.15,
        scale: 1.1,
        stringType: 'cord',
      ),
      HangingObject(
        id: 'talisman_evil_eye',
        name: 'Nazar Boncuğu Glass Eye',
        type: 'evil_eye',
        x: 0.0,
        z: 0.15,
        cordLength: 3.1,
        mass: 1.1,
        damping: 0.995,
        gravity: -19.6,
        sensitivity: 1.2,
        scale: 1.05,
        stringType: 'chain',
      ),
      HangingObject(
        id: 'talisman_brass_bell',
        name: 'Ornate Brass Ghanta Bell',
        type: 'brass_bell',
        x: 2.3,
        z: 0.0,
        cordLength: 3.5,
        mass: 1.6,
        damping: 0.992,
        gravity: -19.6,
        sensitivity: 1.0,
        scale: 1.15,
        stringType: 'chain',
      ),
    ];
  }

  static Future<List<HangingObject>> loadSavedObjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keySceneObjects);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        return decoded.map((item) => HangingObject.fromJson(item)).toList();
      }
    } catch (e) {
      // Return defaults on reading error
    }
    return getDefaultObjects();
  }

  static Future<void> saveObjects(List<HangingObject> objects) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(objects.map((o) => o.toJson()).toList());
      await prefs.setString(_keySceneObjects, jsonStr);
    } catch (e) {
      // Handle error gracefully
    }
  }

  static Future<String> loadSavedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyActiveMode) ?? 'experience';
    } catch (_) {
      return 'experience';
    }
  }

  static Future<void> saveMode(String mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyActiveMode, mode);
    } catch (_) {}
  }
}

