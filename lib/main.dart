import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'controllers/scene_controller.dart';
import 'screens/home_screen.dart';
import 'services/local_asset_server.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Desktop Window Manager
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1340, 860),
      minimumSize: Size(960, 640),
      center: true,
      backgroundColor: Color(0xFF0A0B0E),
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Hangly — 3D Hanging Objects',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Start Local Embedded Asset Server
  final assetServer = LocalAssetServer();
  await assetServer.start();

  // Initialize Scene Controller
  final sceneController = SceneController(assetServer: assetServer);
  await sceneController.initScene();

  runApp(HanglyApp(
    controller: sceneController,
    assetServer: assetServer,
  ));
}

class HanglyApp extends StatelessWidget {
  final SceneController controller;
  final LocalAssetServer assetServer;

  const HanglyApp({
    super.key,
    required this.controller,
    required this.assetServer,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hangly — 3D Hanging Objects',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0B0E),
        primaryColor: const Color(0xFFD4AF37),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFD4AF37),
          secondary: Color(0xFFC5A059),
          surface: Color(0xFF14151D),
        ),
        fontFamily: 'Segoe UI',
      ),
      home: HomeScreen(
        controller: controller,
        assetServer: assetServer,
      ),
    );
  }
}
