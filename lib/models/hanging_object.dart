class HangingObject {
  final String id;
  String name;
  String type; // 'lemon_chillies' | 'evil_eye' | 'brass_bell' | 'astral_totem' | 'custom'
  double x;
  double z;
  double cordLength;
  double mass;
  double damping;
  double gravity;
  double sensitivity;
  double scale;
  String stringType; // 'cord' | 'chain' | 'rope' | 'silk'
  String? customModelPath;
  String? customModelUrl;

  HangingObject({
    required this.id,
    required this.name,
    required this.type,
    this.x = 0.0,
    this.z = 0.0,
    this.cordLength = 3.3,
    this.mass = 1.2,
    this.damping = 0.994,
    this.gravity = -19.6,
    this.sensitivity = 1.1,
    this.scale = 1.0,
    this.stringType = 'cord',
    this.customModelPath,
    this.customModelUrl,
  });

  HangingObject copyWith({
    String? id,
    String? name,
    String? type,
    double? x,
    double? z,
    double? cordLength,
    double? mass,
    double? damping,
    double? gravity,
    double? sensitivity,
    double? scale,
    String? stringType,
    String? customModelPath,
    String? customModelUrl,
  }) {
    return HangingObject(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      x: x ?? this.x,
      z: z ?? this.z,
      cordLength: cordLength ?? this.cordLength,
      mass: mass ?? this.mass,
      damping: damping ?? this.damping,
      gravity: gravity ?? this.gravity,
      sensitivity: sensitivity ?? this.sensitivity,
      scale: scale ?? this.scale,
      stringType: stringType ?? this.stringType,
      customModelPath: customModelPath ?? this.customModelPath,
      customModelUrl: customModelUrl ?? this.customModelUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'x': x,
      'z': z,
      'cordLength': cordLength,
      'mass': mass,
      'damping': damping,
      'gravity': gravity,
      'sensitivity': sensitivity,
      'scale': scale,
      'stringType': stringType,
      'customModelPath': customModelPath,
      'customModelUrl': customModelUrl,
    };
  }

  factory HangingObject.fromJson(Map<String, dynamic> json) {
    return HangingObject(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Hanging Object',
      type: json['type'] as String? ?? 'lemon_chillies',
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      z: (json['z'] as num?)?.toDouble() ?? 0.0,
      cordLength: (json['cordLength'] as num?)?.toDouble() ?? 3.3,
      mass: (json['mass'] as num?)?.toDouble() ?? 1.2,
      damping: (json['damping'] as num?)?.toDouble() ?? 0.994,
      gravity: (json['gravity'] as num?)?.toDouble() ?? -19.6,
      sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 1.1,
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      stringType: json['stringType'] as String? ?? 'cord',
      customModelPath: json['customModelPath'] as String?,
      customModelUrl: json['customModelUrl'] as String?,
    );
  }
}

