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
      // In fullscreen mode, keep titlebar hidden or minimal hover
      return const SizedBox.shrink();
    }

    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0E13),
        border: Border(
          bottom: BorderSide(
            color: Color(0x22D4AF37),
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
                    // Brand / Logo Icon
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF262115), Color(0xFF101115)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.swap_calls_rounded,
                          size: 15,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'HANGLY',
                      style: TextStyle(
                        color: Color(0xFFE8D7A5),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Subtle Divider
                    Container(
                      width: 1,
                      height: 18,
                      color: const Color(0x33D4AF37),
                    ),
                    const SizedBox(width: 16),
                    // Mode Selector Pill
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
              IconButton(
                tooltip: 'Reset Swing Positions',
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF9E9FA8)),
                splashRadius: 18,
                onPressed: () {
                  widget.controller.resetPositions();
                },
              ),

              // Fullscreen toggle
              IconButton(
                tooltip: 'Toggle Full Screen',
                icon: const Icon(Icons.fullscreen_rounded, size: 20, color: Color(0xFF9E9FA8)),
                splashRadius: 18,
                onPressed: () async {
                  final isFull = await windowManager.isFullScreen();
                  await windowManager.setFullScreen(!isFull);
                  setState(() {
                    _isFullScreen = !isFull;
                  });
                },
              ),

              const SizedBox(width: 8),

              // Minimize
              _buildWindowButton(
                icon: Icons.remove_rounded,
                onTap: () => windowManager.minimize(),
              ),

              // Maximize / Restore
              _buildWindowButton(
                icon: _isMaximized ? Icons.filter_none_rounded : Icons.crop_square_rounded,
                iconSize: 14,
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
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFF14151C),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x22FFFFFF), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModeTab('Experience', 'experience', currentMode == 'experience'),
              _buildModeTab('Edit Mode', 'edit', currentMode == 'edit'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModeTab(String label, String modeKey, bool isSelected) {
    return GestureDetector(
      onTap: () => widget.controller.setMode(modeKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD4AF37) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF0C0D11) : const Color(0xFF8E909B),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildWindowButton({
    required IconData icon,
    required VoidCallback onTap,
    double iconSize = 16,
    bool isClose = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 48,
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: iconSize,
          color: const Color(0xFF9E9FA8),
        ),
      ),
    );
  }
}

