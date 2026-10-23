import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import '../controllers/scene_controller.dart';
import '../services/local_asset_server.dart';

class ThreeDView extends StatefulWidget {
  final SceneController controller;
  final LocalAssetServer assetServer;

  const ThreeDView({
    super.key,
    required this.controller,
    required this.assetServer,
  });

  @override
  State<ThreeDView> createState() => _ThreeDViewState();
}

class _ThreeDViewState extends State<ThreeDView> {
  final WebviewController _webviewController = WebviewController();
  StreamSubscription? _messageSubscription;
  bool _isInitialized = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initWebview();
  }

  Future<void> _initWebview() async {
    try {
      await _webviewController.initialize();
      await _webviewController.setBackgroundColor(const Color(0xFF0A0B0E));

      _messageSubscription = _webviewController.webMessage.listen((message) {
        widget.controller.handleWebMessage(message);
      });

      widget.controller.attachWebview(_webviewController);

      final url = widget.assetServer.baseUrl;
      await _webviewController.loadUrl(url);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to initialize 3D WebView: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _webviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF161820),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x4DFF5252)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 36),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFECEFF4), fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _errorMessage = null);
                  _initWebview();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF0C0D11),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: const Color(0xFF0A0B0E),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'INITIALIZING 3D ENVIRONMENT',
                style: TextStyle(
                  color: Color(0xFFC5A059),
                  fontSize: 11,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF0A0B0E),
      child: Webview(_webviewController),
    );
  }
}
