import 'dart:ui';
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

              // 2. Custom Sleek Title Bar at Top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: CustomTitleBar(controller: controller),
              ),

              // 3. Floating Experience Island in Experience Mode
              if (!isEdit)
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xB8101117),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0x2EFFFFFF), width: 1),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x66000000),
                                blurRadius: 20,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: const Color(0x1AD4AF37),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0x33D4AF37)),
                                ),
                                child: const Icon(Icons.touch_app_rounded, size: 12, color: Color(0xFFE5C07B)),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Drag ornaments to swing',
                                style: TextStyle(
                                  color: Color(0xFFE2E4EC),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '•',
                                style: TextStyle(color: Color(0xFF4C4F60)),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Scroll to zoom',
                                style: TextStyle(
                                  color: Color(0xFF888B9A),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Container(width: 1, height: 14, color: const Color(0x22FFFFFF)),
                              const SizedBox(width: 10),
                              // Customize pill button
                              InkWell(
                                onTap: () => controller.setMode('edit'),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF222432),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0x33D4AF37)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.tune_rounded, size: 12, color: Color(0xFFE5C07B)),
                                      SizedBox(width: 5),
                                      Text(
                                        'Studio',
                                        style: TextStyle(
                                          color: Color(0xFFF3ECE1),
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
                  ),
                ),

              // 4. Slide-in Professional Object Studio Sheet
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                top: 46,
                bottom: 0,
                right: isEdit ? 0 : -380,
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
                        border: Border.all(color: const Color(0x33D4AF37)),
                      ),
                      child: IconButton(
                        tooltip: 'Exit Fullscreen',
                        icon: const Icon(Icons.fullscreen_exit_rounded, color: Color(0xFFE5C07B)),
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
