import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../controllers/scene_controller.dart';

class CustomTitleBar extends StatefulWidget {
  final SceneController controller;

  const CustomTitleBar({super.key, required this.controller});

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> {
  bool _isMaximized = false;
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _checkWindowState();
  }

  Future<void> _checkWindowState() async {
    final max = await windowManager.isMaximized();
    final full = await windowManager.isFullScreen();
    if (mounted) {
      setState(() {
        _isMaximized = max;
        _isFullScreen = full;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Color(0xF2090A0E),
        border: Border(
          bottom: BorderSide(
            color: Color(0x1FFFFFFF),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Drag area for window movement
          Expanded(
            child: DragToMoveArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    // Brand Glyph
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.2),
                        gradient: const RadialGradient(
                          colors: [Color(0xFF2A2315), Color(0xFF0F1015)],
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33D4AF37),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.all_inclusive_rounded,
                          size: 13,
                          color: Color(0xFFE5C07B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // App Title
                    const Text(
                      'HANGLY',
                      style: TextStyle(
                        color: Color(0xFFF0E6D2),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0x1FD4AF37),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0x33D4AF37)),
                      ),
                      child: const Text(
                        'STUDIO',
                        style: TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Divider
                    Container(
                      width: 1,
                      height: 16,
                      color: const Color(0x1AFFFFFF),
                    ),
                    const SizedBox(width: 20),
                    // Segmented Mode Switcher
                    _buildModeSelector(),
                  ],
                ),
              ),
            ),
          ),

          // Window and Quick Action Controls
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Reset physics positions button
              _buildActionButton(
                icon: Icons.restart_alt_rounded,
                tooltip: 'Reset Swing Positions',
                onTap: () => widget.controller.resetPositions(),
              ),

              // Fullscreen toggle
              _buildActionButton(
                icon: Icons.fullscreen_rounded,
                tooltip: 'Toggle Full Screen',
                onTap: () async {
                  final isFull = await windowManager.isFullScreen();
                  await windowManager.setFullScreen(!isFull);
                  setState(() => _isFullScreen = !isFull);
                },
              ),

              const SizedBox(width: 4),
              Container(width: 1, height: 16, color: const Color(0x1AFFFFFF)),
              const SizedBox(width: 4),

              // Minimize
              _buildWindowButton(
                icon: Icons.remove_rounded,
                onTap: () => windowManager.minimize(),
              ),

              // Maximize / Restore
              _buildWindowButton(
                icon: _isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
                iconSize: 13,
                onTap: () async {
                  if (await windowManager.isMaximized()) {
                    await windowManager.unmaximize();
                    setState(() => _isMaximized = false);
                  } else {
                    await windowManager.maximize();
                    setState(() => _isMaximized = true);
                  }
                },
              ),

              // Close
              _buildWindowButton(
                icon: Icons.close_rounded,
                isClose: true,
                onTap: () => windowManager.close(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final currentMode = widget.controller.mode;
        return Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            color: const Color(0xFF13141C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x1AFFFFFF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeTab(
                label: 'Experience',
                icon: Icons.remove_red_eye_outlined,
                modeKey: 'experience',
                isSelected: currentMode == 'experience',
              ),
              const SizedBox(width: 2),
              _buildModeTab(
                label: 'Edit Mode',
                icon: Icons.tune_rounded,
                modeKey: 'edit',
                isSelected: currentMode == 'edit',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required String modeKey,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => widget.controller.setMode(modeKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF222432) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: const Color(0x33D4AF37)) : null,
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? const Color(0xFFE5C07B) : const Color(0xFF757888),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFF3ECE1) : const Color(0xFF888B9A),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xFF8E92A2)),
        ),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 15,
    bool isClose = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: isClose ? const Color(0xFFE81123) : const Color(0x1AFFFFFF),
        child: SizedBox(
          width: 44,
          height: 46,
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: const Color(0xFF9EA2B4),
            ),
          ),
        ),
      ),
    );
  }
}
