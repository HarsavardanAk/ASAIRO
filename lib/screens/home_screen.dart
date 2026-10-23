import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../controllers/scene_controller.dart';
import '../services/local_asset_server.dart';
import '../widgets/custom_title_bar.dart';
import '../widgets/edit_object_sheet.dart';
import '../widgets/three_d_view.dart';

class HomeScreen extends StatelessWidget {
  final SceneController controller;
  final LocalAssetServer assetServer;

  const HomeScreen({
    super.key,
    required this.controller,
    required this.assetServer,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0E),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final isEdit = controller.mode == 'edit';

          return Stack(
            children: [
              // 1. 3D WebGL Scene Background (Three.js Canvas)
              Positioned.fill(
                child: ThreeDView(
                  key: const ValueKey('three_d_scene_view'),
                  controller: controller,
                  assetServer: assetServer,
                ),
              ),

              // 2. Custom Title Bar at Top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CustomTitleBar(controller: controller),
              ),

              // 3. Floating Bottom Control Bar in Experience Mode
              if (!isEdit)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xD0111218),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0x33D4AF37), width: 1),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x66000000),
                            blurRadius: 16,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_outlined, size: 16, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 8),
                          const Text(
                            'Drag ornaments to swing • Scroll to zoom',
                            style: TextStyle(
                              color: Color(0xFFC7CBD8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(width: 1, height: 16, color: const Color(0x33D4AF37)),
                          const SizedBox(width: 14),
                          // Quick Customize button
                          InkWell(
                            onTap: () => controller.setMode('edit'),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(Icons.tune_rounded, size: 14, color: Color(0xFFD4AF37)),
                                  SizedBox(width: 6),
                                  Text(
                                    'Customize',
                                    style: TextStyle(
                                      color: Color(0xFFE8D7A5),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // 4. Slide-in Edit Mode Object Studio Sheet
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                top: 48,
                bottom: 0,
                right: isEdit ? 0 : -360,
                child: EditObjectSheet(controller: controller),
              ),

              // 5. Fullscreen exit floating button
              Positioned(
                top: 16,
                right: 16,
                child: FutureBuilder<bool>(
                  future: windowManager.isFullScreen(),
                  builder: (context, snapshot) {
                    if (snapshot.data != true) return const SizedBox.shrink();
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xCC111218),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0x44D4AF37)),
                      ),
                      child: IconButton(
                        tooltip: 'Exit Fullscreen',
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Color(0xFFD4AF37)),
                        onPressed: () => windowManager.setFullScreen(false),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
