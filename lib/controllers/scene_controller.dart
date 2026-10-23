import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:webview_windows/webview_windows.dart';
import '../models/hanging_object.dart';
import '../services/local_asset_server.dart';
import '../services/scene_storage_service.dart';

class SceneController extends ChangeNotifier {
  final LocalAssetServer assetServer;
  WebviewController? _webviewController;

  List<HangingObject> _objects = [];
  String? _selectedObjectId;
  String _mode = 'experience'; // 'experience' | 'edit' | 'fullscreen'
  bool _isSceneReady = false;
  String? _statusMessage;

  SceneController({required this.assetServer});

  List<HangingObject> get objects => List.unmodifiable(_objects);
  String? get selectedObjectId => _selectedObjectId;
  String get mode => _mode;
  bool get isSceneReady => _isSceneReady;
  String? get statusMessage => _statusMessage;

  HangingObject? get selectedObject {
    if (_selectedObjectId == null) return null;
    try {
      return _objects.firstWhere((o) => o.id == _selectedObjectId);
    } catch (_) {
      return null;
    }
  }

  void attachWebview(WebviewController controller) {
    _webviewController = controller;
  }

  Future<void> initScene() async {
    _objects = await SceneStorageService.loadSavedObjects();
    _mode = await SceneStorageService.loadSavedMode();
    notifyListeners();
  }

  void onSceneReady() {
    _isSceneReady = true;
    _sendAction('loadScene', {'objects': _objects.map((o) => o.toJson()).toList()});
    _sendAction('setMode', {'mode': _mode});
    notifyListeners();
  }

  void handleWebMessage(String jsonStr) {
    try {
      final data = jsonDecode(jsonStr);
      final event = data['event'];
      final eventData = data['data'] ?? {};

      if (event == 'sceneReady') {
        onSceneReady();
      } else if (event == 'objectSelected') {
        final id = eventData['id'] as String?;
        if (id != _selectedObjectId) {
          _selectedObjectId = id;
          notifyListeners();
        }
      } else if (event == 'collision') {
        // Inter-object collision event
        _statusMessage = 'Motion contact detected';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling web message: $e');
    }
  }

  void setMode(String newMode) {
    _mode = newMode;
    if (newMode == 'edit' && _selectedObjectId == null && _objects.isNotEmpty) {
      _selectedObjectId = _objects.first.id;
    }
    SceneStorageService.saveMode(newMode);
    _sendAction('setMode', {'mode': newMode});
    if (_selectedObjectId != null) {
      _sendAction('selectObject', {'id': _selectedObjectId!});
    }
    notifyListeners();
  }

  void selectObject(String? id) {
    _selectedObjectId = id;
    if (id != null) {
      _sendAction('selectObject', {'id': id});
    }
    notifyListeners();
  }

  void addObject(HangingObject object) {
    _objects.add(object);
    _selectedObjectId = object.id;
    _sendAction('addObject', object.toJson());
    SceneStorageService.saveObjects(_objects);
    notifyListeners();
  }

  void updateObject(HangingObject updated) {
    final index = _objects.indexWhere((o) => o.id == updated.id);
    if (index != -1) {
      _objects[index] = updated;
      _sendAction('updateObject', updated.toJson());
      SceneStorageService.saveObjects(_objects);
      notifyListeners();
    }
  }

  void removeObject(String id) {
    _objects.removeWhere((o) => o.id == id);
    if (_selectedObjectId == id) {
      _selectedObjectId = _objects.isNotEmpty ? _objects.first.id : null;
    }
    _sendAction('removeObject', {'id': id});
    SceneStorageService.saveObjects(_objects);
    notifyListeners();
  }

  void resetPositions() {
    _sendAction('resetPositions', {});
  }

  Future<void> importGLB(File file, {String? customName}) async {
    final url = assetServer.registerCustomModel(file);
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final name = customName ?? file.uri.pathSegments.last.replaceAll('.glb', '').replaceAll('.gltf', '');

    final newObj = HangingObject(
      id: id,
      name: name,
      type: 'custom',
      x: 0.0,
      z: 0.0,
      cordLength: 3.2,
      mass: 1.4,
      damping: 0.994,
      gravity: -19.6,
      sensitivity: 1.1,
      scale: 1.0,
      stringType: 'chain',
      customModelPath: file.path,
      customModelUrl: url,
    );

    _objects.add(newObj);
    _selectedObjectId = id;

    _sendAction('importGLB', {
      'id': id,
      'name': name,
      'url': url,
      'x': newObj.x,
      'z': newObj.z,
      'cordLength': newObj.cordLength,
      'mass': newObj.mass,
      'damping': newObj.damping,
      'stringType': newObj.stringType,
    });

    await SceneStorageService.saveObjects(_objects);
    notifyListeners();
  }

  void resetToDefaultScene() {
    _objects = SceneStorageService.getDefaultObjects();
    _selectedObjectId = _objects.isNotEmpty ? _objects.first.id : null;
    _sendAction('loadScene', {'objects': _objects.map((o) => o.toJson()).toList()});
    SceneStorageService.saveObjects(_objects);
    notifyListeners();
  }

  void _sendAction(String action, Map<String, dynamic> payload) {
    if (_webviewController == null || !_isSceneReady) return;
    try {
      final msg = jsonEncode({'action': action, 'payload': payload});
      _webviewController!.postWebMessage(msg);
    } catch (e) {
      debugPrint('Failed to post message to webview: $e');
    }
  }
}

