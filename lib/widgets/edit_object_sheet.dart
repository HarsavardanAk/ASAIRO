import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../controllers/scene_controller.dart';
import '../models/hanging_object.dart';

class EditObjectSheet extends StatelessWidget {
  final SceneController controller;

  const EditObjectSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.selectedObject;
        final objects = controller.objects;

        return Container(
          width: 340,
          margin: const EdgeInsets.only(top: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xEB111218),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33D4AF37), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x88000000),
                blurRadius: 30,
                offset: Offset(-5, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(context),

                // Object Chips selector
                _buildObjectChips(objects, selected),

                const Divider(color: Color(0x22D4AF37), height: 1),

                // Scrollable Controls
                Expanded(
                  child: selected == null
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          children: [
                            // Object Title & Type
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selected.name,
                                        style: const TextStyle(
                                          color: Color(0xFFF3ECE1),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Type: ${selected.type.toUpperCase()}',
                                        style: const TextStyle(
                                          color: Color(0xFFC5A059),
                                          fontSize: 10,
                                          letterSpacing: 1.0,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Delete Object',
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  onPressed: () => controller.removeObject(selected.id),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // String / Chain style selector
                            _buildStringStyleSelector(selected),

                            const SizedBox(height: 16),

                            // Sliders
                            _buildSlider(
                              label: 'Horizontal Position (X)',
                              value: selected.x,
                              min: -3.8,
                              max: 3.8,
                              format: (v) => v.toStringAsFixed(1),
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(x: val));
                              },
                            ),

                            _buildSlider(
                              label: 'Cord Length',
                              value: selected.cordLength,
                              min: 2.0,
                              max: 4.4,
                              format: (v) => '${v.toStringAsFixed(1)}m',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(cordLength: val));
                              },
                            ),

                            _buildSlider(
                              label: 'Object Mass',
                              value: selected.mass,
                              min: 0.4,
                              max: 3.5,
                              format: (v) => '${v.toStringAsFixed(1)}kg',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(mass: val));
                              },
                            ),

                            _buildSlider(
                              label: 'Swing Damping (Air Resistance)',
                              value: selected.damping,
                              min: 0.985,
                              max: 0.999,
                              format: (v) => v.toStringAsFixed(3),
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(damping: val));
                              },
                            ),

                            _buildSlider(
                              label: 'Drag & Release Sensitivity',
                              value: selected.sensitivity,
                              min: 0.5,
                              max: 2.2,
                              format: (v) => '${v.toStringAsFixed(1)}x',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(sensitivity: val));
                              },
                            ),

                            _buildSlider(
                              label: 'Object Scale',
                              value: selected.scale,
                              min: 0.6,
                              max: 1.8,
                              format: (v) => '${v.toStringAsFixed(1)}x',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(scale: val));
                              },
                            ),
                          ],
                        ),
                ),

                const Divider(color: Color(0x22D4AF37), height: 1),

                // Footer Quick Actions
                _buildFooterActions(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF161822),
        border: Border(bottom: BorderSide(color: Color(0x22D4AF37))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: Color(0xFFD4AF37)),
              SizedBox(width: 8),
              Text(
                'OBJECT STUDIO',
                style: TextStyle(
                  color: Color(0xFFE8D7A5),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Close Edit Mode',
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF8E909B)),
            splashRadius: 16,
            onPressed: () => controller.setMode('experience'),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectChips(List<HangingObject> objects, HangingObject? selected) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: objects.length,
        separatorBuilder: (ctx, index) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final obj = objects[idx];
          final isSel = selected?.id == obj.id;
          return FilterChip(
            selected: isSel,
            showCheckmark: false,
            label: Text(
              obj.name,
              style: TextStyle(
                color: isSel ? const Color(0xFF0C0D11) : const Color(0xFFB0B3BE),
                fontSize: 11,
                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            backgroundColor: const Color(0xFF1A1C26),
            selectedColor: const Color(0xFFD4AF37),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isSel ? const Color(0xFFD4AF37) : const Color(0x22FFFFFF),
              ),
            ),
            onSelected: (_) => controller.selectObject(obj.id),
          );
        },
      ),
    );
  }

  Widget _buildStringStyleSelector(HangingObject selected) {
    const styles = [
      {'key': 'cord', 'label': 'Thread', 'icon': Icons.line_style_rounded},
      {'key': 'chain', 'label': 'Gold Chain', 'icon': Icons.link_rounded},
      {'key': 'rope', 'label': 'Hemp Rope', 'icon': Icons.blur_linear_rounded},
      {'key': 'silk', 'label': 'Silk Ribbon', 'icon': Icons.bookmark_border_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SUSPENSION STYLE',
          style: TextStyle(
            color: Color(0xFFC5A059),
            fontSize: 10,
            letterSpacing: 1.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: styles.map((s) {
            final isSel = selected.stringType == s['key'];
            return ChoiceChip(
              label: Text(
                s['label'] as String,
                style: TextStyle(
                  color: isSel ? const Color(0xFF0C0D11) : const Color(0xFFB8BBC6),
                  fontSize: 11,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              selected: isSel,
              selectedColor: const Color(0xFFD4AF37),
              backgroundColor: const Color(0xFF1B1D28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              onSelected: (_) {
                controller.updateObject(selected.copyWith(stringType: s['key'] as String));
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    final clamped = value.clamp(min, max);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFF9E9FA8), fontSize: 11, fontWeight: FontWeight.w500),
              ),
              Text(
                format(clamped),
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFD4AF37),
              inactiveTrackColor: const Color(0xFF262835),
              thumbColor: const Color(0xFFF3ECE1),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 3,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: clamped,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF14151E),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Add preset object
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddObjectDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add Ornament'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0C0D11),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Import GLB
              IconButton(
                tooltip: 'Import Custom GLB/GLTF',
                icon: const Icon(Icons.file_upload_outlined, color: Color(0xFFD4AF37), size: 20),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF212330),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final files = await FilePicker.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['glb', 'gltf'],
                  );
                  if (files.isNotEmpty && files.first.path != null) {
                    final file = File(files.first.path!);
                    await controller.importGLB(file);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.touch_app_rounded, size: 36, color: Color(0xFF4C4F60)),
          const SizedBox(height: 10),
          const Text(
            'Select an object to customize',
            style: TextStyle(color: Color(0xFF8E909B), fontSize: 13),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () => controller.resetToDefaultScene(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF212330),
              foregroundColor: const Color(0xFFD4AF37),
            ),
            child: const Text('Restore Default Scene'),
          ),
        ],
      ),
    );
  }

  void _showAddObjectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161822),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x33D4AF37)),
          ),
          title: const Text(
            'Add 3D Ornament',
            style: TextStyle(color: Color(0xFFF3ECE1), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAddTile(ctx, 'Nimbu-Mirchi Nazar Battu', 'lemon_chillies', Icons.eco_rounded),
              _buildAddTile(ctx, 'Nazar Boncuğu Glass Eye', 'evil_eye', Icons.remove_red_eye_rounded),
              _buildAddTile(ctx, 'Ornate Brass Ghanta Bell', 'brass_bell', Icons.notifications_active_rounded),
              _buildAddTile(ctx, 'Astral Totem Figurine', 'astral_totem', Icons.token_rounded),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddTile(BuildContext ctx, String title, String type, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFD4AF37), size: 22),
      title: Text(title, style: const TextStyle(color: Color(0xFFE0E2EC), fontSize: 13)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(ctx);
        final newObj = HangingObject(
          id: 'obj_${DateTime.now().millisecondsSinceEpoch}',
          name: title,
          type: type,
          x: (controller.objects.length % 2 == 0 ? 1 : -1) * (0.8 + controller.objects.length * 0.4),
          cordLength: 3.3,
          mass: 1.2,
          damping: 0.994,
          gravity: -19.6,
          sensitivity: 1.1,
          scale: 1.0,
          stringType: type == 'brass_bell' || type == 'evil_eye' ? 'chain' : 'cord',
        );
        controller.addObject(newObj);
      },
    );
  }
}
