import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

class LocalAssetServer {
  HttpServer? _server;
  int _port = 0;
  String? _webRootPath;
  final Map<String, File> _customFiles = {};

  int get port => _port;
  String get baseUrl => 'http://127.0.0.1:$_port';

  Future<void> start() async {
    _webRootPath = _resolveWebRoot();
    if (_webRootPath == null) {
      throw Exception('Could not locate web assets directory');
    }

    final staticHandler = createStaticHandler(
      _webRootPath!,
      defaultDocument: 'index.html',
      serveFilesOutsidePath: true,
    );

    final cascade = Cascade()
        .add(_customFilesHandler)
        .add(staticHandler);

    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(cascade.handler);

    // Bind to localhost on an ephemeral free port
    _server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
    _port = _server!.port;
  }

  Response _customFilesHandler(Request request) {
    final path = request.url.path;
    if (path.startsWith('custom_models/')) {
      final key = path.substring('custom_models/'.length);
      final file = _customFiles[key];
      if (file != null && file.existsSync()) {
        final bytes = file.readAsBytesSync();
        return Response.ok(
          bytes,
          headers: {
            'Content-Type': 'model/gltf-binary',
            'Access-Control-Allow-Origin': '*',
          },
        );
      }
    }
    return Response.notFound('Not found');
  }

  String registerCustomModel(File file) {
    final filename = '${DateTime.now().millisecondsSinceEpoch}_${file.uri.pathSegments.last}';
    _customFiles[filename] = file;
    return '$baseUrl/custom_models/$filename';
  }

  String? _resolveWebRoot() {
    // 1. Check current working directory
    final localDir = Directory('${Directory.current.path}/assets/web');
    if (localDir.existsSync()) {
      return localDir.path;
    }

    // 2. Check compiled bundle location
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final bundleDir = Directory('$exeDir/data/flutter_assets/assets/web');
    if (bundleDir.existsSync()) {
      return bundleDir.path;
    }

    // 3. Fallback relative check
    final devDir = Directory('assets/web');
    if (devDir.existsSync()) {
      return devDir.path;
    }

    return null;
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}

