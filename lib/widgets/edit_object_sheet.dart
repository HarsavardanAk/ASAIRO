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
          width: 360,
          margin: const EdgeInsets.only(top: 10, right: 12, bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xF50D0E14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x24FFFFFF), width: 1.0),
            boxShadow: const [
              BoxShadow(
                color: Color(0x99000000),
                blurRadius: 28,
                spreadRadius: 2,
                offset: Offset(-4, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Studio Header
                _buildHeader(context, objects.length),

                // 2. Horizontal Visual Selector Cards
                _buildOrnamentSelector(objects, selected),

                const Divider(color: Color(0x1AFFFFFF), height: 1),

                // 3. Scrollable Controls Body
                Expanded(
                  child: selected == null
                      ? _buildEmptyState()
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          children: [
                            // Selected Object Title & Actions Bar
                            _buildObjectTitleCard(context, selected),

                            const SizedBox(height: 18),

                            // Suspension Style Material Selector
                            _buildSuspensionStyleSection(selected),

                            const SizedBox(height: 20),

                            // Section 1: Dimensions & Placement
                            _buildSectionHeader('GEOMETRY & POSITION', Icons.straighten_rounded),
                            const SizedBox(height: 10),
                            _buildSlider(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Horizontal Position (X)',
                              value: selected.x,
                              min: -3.8,
                              max: 3.8,
                              unit: '',
                              format: (v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)}',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(x: val));
                              },
                            ),
                            _buildSlider(
                              icon: Icons.height_rounded,
                              label: 'Cord Length',
                              value: selected.cordLength,
                              min: 2.0,
                              max: 4.4,
                              unit: 'm',
                              format: (v) => '${v.toStringAsFixed(1)}m',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(cordLength: val));
                              },
                            ),
                            _buildSlider(
                              icon: Icons.zoom_in_rounded,
                              label: 'Visual Scale',
                              value: selected.scale,
                              min: 0.6,
                              max: 1.8,
                              unit: 'x',
                              format: (v) => '${v.toStringAsFixed(1)}x',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(scale: val));
                              },
                            ),

                            const SizedBox(height: 18),

                            // Section 2: Physical Dynamics
                            _buildSectionHeader('PHYSICS & SWING DYNAMICS', Icons.speed_rounded),
                            const SizedBox(height: 10),
                            _buildSlider(
                              icon: Icons.fitness_center_rounded,
                              label: 'Mass (Inertia)',
                              value: selected.mass,
                              min: 0.4,
                              max: 3.5,
                              unit: 'kg',
                              format: (v) => '${v.toStringAsFixed(1)}kg',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(mass: val));
                              },
                            ),
                            _buildSlider(
                              icon: Icons.air_rounded,
                              label: 'Air Resistance (Damping)',
                              value: selected.damping,
                              min: 0.985,
                              max: 0.999,
                              unit: '',
                              format: (v) => v.toStringAsFixed(3),
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(damping: val));
                              },
                            ),
                            _buildSlider(
                              icon: Icons.touch_app_rounded,
                              label: 'Drag & Release Impulse',
                              value: selected.sensitivity,
                              min: 0.5,
                              max: 2.2,
                              unit: 'x',
                              format: (v) => '${v.toStringAsFixed(1)}x',
                              onChanged: (val) {
                                controller.updateObject(selected.copyWith(sensitivity: val));
                              },
                            ),
                          ],
                        ),
                ),

                const Divider(color: Color(0x1AFFFFFF), height: 1),

                // 4. Professional Bottom Action Bar
                _buildFooterActions(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int objectCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF13141C),
        border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFD4AF37),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x88D4AF37), blurRadius: 6),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'OBJECT STUDIO',
                style: TextStyle(
                  color: Color(0xFFF3ECE1),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$objectCount Active',
                  style: const TextStyle(
                    color: Color(0xFF9E9FA8),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => controller.setMode('experience'),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF888B9A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrnamentSelector(List<HangingObject> objects, HangingObject? selected) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: const Color(0xFF0F1017),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: objects.length,
        separatorBuilder: (ctx, idx) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final obj = objects[idx];
          final isSel = selected?.id == obj.id;
          final iconData = _getIconForType(obj.type);

          return InkWell(
            onTap: () => controller.selectObject(obj.id),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF222432) : const Color(0xFF14151E),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSel ? const Color(0xFFD4AF37) : const Color(0x1FFFFFFF),
                  width: isSel ? 1.2 : 1.0,
                ),
                boxShadow: isSel
                    ? const [
                        BoxShadow(
                          color: Color(0x22D4AF37),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconData,
                    size: 15,
                    color: isSel ? const Color(0xFFE5C07B) : const Color(0xFF757888),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _shortenName(obj.name),
                    style: TextStyle(
                      color: isSel ? const Color(0xFFF3ECE1) : const Color(0xFF9093A2),
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildObjectTitleCard(BuildContext context, HangingObject selected) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF14151E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x1FFFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1E202C),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x33D4AF37)),
            ),
            child: Icon(
              _getIconForType(selected.type),
              size: 18,
              color: const Color(0xFFE5C07B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selected.name,
                  style: const TextStyle(
                    color: Color(0xFFF3ECE1),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  selected.type.toUpperCase().replaceAll('_', ' '),
                  style: const TextStyle(
                    color: Color(0xFFC5A059),
                    fontSize: 9.5,
                    letterSpacing: 1.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove Ornament',
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE06C75), size: 18),
            splashRadius: 16,
            onPressed: () => _confirmDelete(context, selected),
          ),
        ],
      ),
    );
  }

  Widget _buildSuspensionStyleSection(HangingObject selected) {
    const styles = [
      {'key': 'cord', 'label': 'Black Thread', 'icon': Icons.horizontal_rule_rounded},
      {'key': 'chain', 'label': 'Gold Links', 'icon': Icons.link_rounded},
      {'key': 'rope', 'label': 'Hemp Rope', 'icon': Icons.line_weight_rounded},
      {'key': 'silk', 'label': 'Silk Ribbon', 'icon': Icons.bookmark_border_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('SUSPENSION MATERIAL', Icons.texture_rounded),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.7,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: styles.length,
          itemBuilder: (context, idx) {
            final item = styles[idx];
            final isSel = selected.stringType == item['key'];

            return InkWell(
              onTap: () {
                controller.updateObject(selected.copyWith(stringType: item['key'] as String));
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF222432) : const Color(0xFF13141C),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSel ? const Color(0xFFD4AF37) : const Color(0x1FFFFFFF),
                    width: isSel ? 1.2 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item['icon'] as IconData,
                      size: 14,
                      color: isSel ? const Color(0xFFE5C07B) : const Color(0xFF6F7282),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: TextStyle(
                          color: isSel ? const Color(0xFFF3ECE1) : const Color(0xFF888B9A),
                          fontSize: 10.5,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFFC5A059)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFFC5A059),
            fontSize: 10,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required String Function(double) format,
    required ValueChanged<double> onChanged,
  }) {
    final clamped = value.clamp(min, max);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF13141C),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 13, color: const Color(0xFF7B7F92)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF9E9FA8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1D27),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0x22D4AF37)),
                ),
                child: Text(
                  format(clamped),
                  style: const TextStyle(
                    color: Color(0xFFE5C07B),
                    fontSize: 10.5,
                    fontFamily: 'Consolas',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFFD4AF37),
              inactiveTrackColor: const Color(0xFF232533),
              thumbColor: const Color(0xFFF5EEDB),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              trackHeight: 2.2,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
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
      padding: const EdgeInsets.all(14),
      color: const Color(0xFF11121A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // Add Ornament
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddOrnamentModal(context),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('Add Ornament'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4AF37),
                    foregroundColor: const Color(0xFF0C0D11),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Import GLB File
              Tooltip(
                message: 'Import Custom 3D Model (.glb / .gltf)',
                child: InkWell(
                  onTap: () async {
                    final files = await FilePicker.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['glb', 'gltf'],
                    );
                    if (files.isNotEmpty && files.first.path != null) {
                      final file = File(files.first.path!);
                      await controller.importGLB(file);
                    }
                  },
                  borderRadius: BorderRadius.circular(7),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1C27),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0x33D4AF37)),
                    ),
                    child: const Icon(Icons.file_upload_outlined, size: 18, color: Color(0xFFD4AF37)),
                  ),
                ),
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
          const Icon(Icons.touch_app_rounded, size: 32, color: Color(0xFF4C4F60)),
          const SizedBox(height: 10),
          const Text(
            'Select an ornament to customize',
            style: TextStyle(color: Color(0xFF8E909B), fontSize: 12),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: () => controller.resetToDefaultScene(),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFD4AF37),
              side: const BorderSide(color: Color(0x44D4AF37)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Restore Default Scene', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, HangingObject selected) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF151620),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x22FFFFFF)),
        ),
        title: const Text('Delete Ornament', style: TextStyle(color: Color(0xFFF3ECE1), fontSize: 15)),
        content: Text(
          'Are you sure you want to remove "${selected.name}" from the scene?',
          style: const TextStyle(color: Color(0xFF9E9FA8), fontSize: 12.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF888B9A))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              controller.removeObject(selected.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE06C75),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddOrnamentModal(BuildContext context) {
    const presets = [
      {
        'title': 'Nimbu-Mirchi Nazar Battu',
        'desc': 'Traditional protective lemon and 7 green chillies on sacred thread.',
        'type': 'lemon_chillies',
        'icon': Icons.eco_rounded,
        'string': 'cord',
      },
      {
        'title': 'Nazar Boncuğu Glass Eye',
        'desc': 'Authentic Turkish glass amulet with concentric blue rings.',
        'type': 'evil_eye',
        'icon': Icons.remove_red_eye_rounded,
        'string': 'chain',
      },
      {
        'title': 'Ornate Brass Ghanta Bell',
        'desc': 'Polished temple bell with engraved bands and swinging red clapper.',
        'type': 'brass_bell',
        'icon': Icons.notifications_active_rounded,
        'string': 'chain',
      },
      {
        'title': 'Astral Totem Figurine',
        'desc': 'Faceted obsidian sculpture with geometric metallic gold rings.',
        'type': 'astral_totem',
        'icon': Icons.token_rounded,
        'string': 'chain',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12131C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        side: BorderSide(color: Color(0x22FFFFFF)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ADD 3D ORNAMENT',
                    style: TextStyle(
                      color: Color(0xFFF3ECE1),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16, color: Color(0xFF787B8B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...presets.map((p) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    tileColor: const Color(0xFF181A25),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: Color(0x14FFFFFF)),
                    ),
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222432),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(p['icon'] as IconData, color: const Color(0xFFD4AF37), size: 18),
                    ),
                    title: Text(
                      p['title'] as String,
                      style: const TextStyle(color: Color(0xFFF3ECE1), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      p['desc'] as String,
                      style: const TextStyle(color: Color(0xFF888B9A), fontSize: 10.5),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      final offset = (controller.objects.length % 2 == 0 ? 1 : -1) *
                          (0.8 + controller.objects.length * 0.45);
                      final newObj = HangingObject(
                        id: 'obj_${DateTime.now().millisecondsSinceEpoch}',
                        name: p['title'] as String,
                        type: p['type'] as String,
                        x: offset,
                        cordLength: 3.3,
                        mass: 1.2,
                        damping: 0.994,
                        gravity: -19.6,
                        sensitivity: 1.1,
                        scale: 1.0,
                        stringType: p['string'] as String,
                      );
                      controller.addObject(newObj);
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'lemon_chillies':
        return Icons.eco_rounded;
      case 'evil_eye':
        return Icons.remove_red_eye_rounded;
      case 'brass_bell':
        return Icons.notifications_active_rounded;
      case 'astral_totem':
        return Icons.token_rounded;
      default:
        return Icons.view_in_ar_rounded;
    }
  }

  String _shortenName(String name) {
    if (name.length > 14) {
      return '${name.substring(0, 12)}..';
    }
    return name;
  }
}
