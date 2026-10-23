# Hangly — 3D Hanging Objects (Windows Desktop Application)

A premium Windows desktop application inspired by the interactive 3D hanging-object experience on [Hangly](https://www.sharancreatedthis.in/products/hangly).

Features high-fidelity real-time 3D rendering with **Three.js**, an embedded **WebView2** runtime inside **Flutter**, and a custom **Verlet multi-segment physics engine** for lifelike swinging, gravity, cord tension, inertia release, and inter-object collisions.

---

## Features

- **Iconic Hanging Ornaments**:
  - **Nimbu-Mirchi Nazar Battu**: Traditional Indian talisman featuring a textured lemon with pore displacement and 7 curved dangling green chillies with calyx caps on a black sacred thread.
  - **Nazar Boncuğu (Evil Eye)**: Mediterranean glass amulet with concentric cobalt blue, white, cyan, and black rings, clearcoat glass transmission, and dangling brass teardrop charm.
  - **Ornate Brass Bell (Ghanta)**: Antique temple bell with engraved ridge bands, hanging clapper rod, and crimson silk bead.
  - **Astral Totem**: Stylized obsidian and metallic gold faceted sculpture.
  - **Custom User GLB/GLTF**: Import any 3D model file from your local computer.
- **Realistic Multi-Segment Physics**:
  - Articulated Verlet particle cords with Gauss-Seidel distance constraint relaxation.
  - Natural pendulum physics with gravitational acceleration and air damping.
  - Natural tilt, roll, and rotational spinning (yaw) following cord tangents and angular momentum.
  - Mouse grabbing and dragging with release velocity impulse.
  - Subtle ambient breeze drift preventing objects from staying completely static.
  - Inter-object elastic collision detection and impulse response.
- **Multiple Suspension Styles**:
  - Sacred Thread (Dark cord)
  - Gold Link Chain (Interlocking 3D metallic links)
  - Hemp Rope (Braided rope)
  - Silk Ribbon (Vibrant crimson)
- **Application Modes**:
  - **Experience Mode**: Distraction-free, minimal UI for contemplation and interaction.
  - **Edit Mode (Object Studio)**: Real-time customization of position (X), cord length, mass, damping, sensitivity, scale, and suspension style.
  - **Full-Screen Mode**: Immersive full-screen display.
- **Local Persistence**:
  - Automatically saves object arrangements, physics parameters, and custom models between application launches.
- **100% Offline-Capable**:
  - Bundled Three.js r128, GLTFLoader, and OrbitControls served via an embedded in-app HTTP server without CORS or file-protocol restrictions.

---

## Project Structure

```
d:\hangly\hangly\
├── assets/
│   ├── web/
│   │   ├── libs/
│   │   │   ├── three.min.js          # Offline Three.js library
│   │   │   ├── GLTFLoader.js         # 3D model loader
│   │   │   └── OrbitControls.js      # Camera controls
│   │   ├── index.html                # WebGL canvas shell
│   │   ├── physics.js                # Verlet rope & pendulum physics engine
│   │   ├── scene.js                  # Three.js 3D scene, PBR models & interactions
│   │   └── style.css                 # Dark minimalist styling & vignette
│   └── 3d/                           # Bundled 3D models directory
├── lib/
│   ├── controllers/
│   │   └── scene_controller.dart     # Scene state management & WebView bridge
│   ├── models/
│   │   └── hanging_object.dart       # Object & physics data model
│   ├── screens/
│   │   └── home_screen.dart          # Main application desktop UI
│   ├── services/
│   │   ├── local_asset_server.dart   # In-app local HTTP server (Shelf)
│   │   └── scene_storage_service.dart# SharedPreferences local persistence
│   ├── widgets/
│   │   ├── custom_title_bar.dart     # Modern frameless title bar with drag & mode switch
│   │   ├── edit_object_sheet.dart    # Object studio with sliders & GLB import
│   │   └── three_d_view.dart         # Embedded Windows WebView2 widget
│   └── main.dart                     # App entry point & window manager setup
├── windows/                          # Native Windows runner & CMake configuration
└── pubspec.yaml                      # Project dependencies & asset declarations
```

---

## How to Run & Build

### Prerequisites
- Windows 10/11 (64-bit)
- Flutter SDK (3.10+ / Dart 3.10+)
- Visual Studio 2022 with "Desktop development with C++" workload installed
- Microsoft Edge WebView2 Evergreen Runtime (pre-installed on Windows 10 & 11)

### Running in Debug Mode
```powershell
flutter run -d windows
```

### Building the Release Executable
```powershell
flutter build windows
```
The compiled standalone Windows application will be generated at:
```
build\windows\x64\runner\Release\hangly.exe
```

---

## Mouse & Keyboard Controls

- **Left Mouse Click & Drag**: Pull any hanging ornament away from its resting position.
- **Left Mouse Release**: Release the ornament to swing naturally with physical momentum.
- **Mouse Wheel / Scroll**: Zoom camera in and out.
- **Hover**: Highlight ornament and view its title tooltip.
- **Top Bar Tabs**: Switch between **Experience** and **Edit Mode**.
- **Top Right Buttons**: Reset positions, Toggle Fullscreen, Minimize, Maximize, Close.
