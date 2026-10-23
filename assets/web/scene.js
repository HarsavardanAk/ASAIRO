/**
 * Hangly 3D Interactive Scene & Renderer
 * Three.js + Verlet Physics Integration
 */

// Global scene state
let scene, camera, renderer, physicsWorld;
let hangingMeshes = new Map(); // id -> { group, cordMesh, physicsObj, highlightMesh }
let activeHoveredId = null;
let activeSelectedId = null;
let isDraggingObject = false;
let currentDraggedPhysics = null;
let currentMode = 'experience'; // 'experience' | 'edit' | 'fullscreen'
let gltfLoader = null;

// Raycasting & pointer tracking
const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();
const dragPlane = new THREE.Plane();
const planeIntersectPoint = new THREE.Vector3();

// Lighting references
let spotLight, warmKeyLight, rimLight, ambientLight;

// Clock for time-based animation
const clock = new THREE.Clock();

// Communication with Flutter
function sendToFlutter(message) {
  try {
    const jsonStr = JSON.stringify(message);
    if (window.chrome && window.chrome.webview) {
      window.chrome.webview.postMessage(jsonStr);
    } else if (window.flutter_inappwebview) {
      window.flutter_inappwebview.callHandler('onFlutterMessage', jsonStr);
    } else {
      console.log('[To Flutter]', message);
    }
  } catch (e) {
    console.error('Failed to send message to Flutter:', e);
  }
}

// Receive messages from Flutter
window.handleFlutterMessage = function (data) {
  if (typeof data === 'string') {
    try {
      data = JSON.parse(data);
    } catch (e) {
      console.error('Invalid JSON from Flutter:', e);
      return;
    }
  }

  const action = data.action;
  const payload = data.payload || {};

  switch (action) {
    case 'addObject':
      createAndAddHangingObject(payload);
      break;
    case 'removeObject':
      removeHangingObject(payload.id);
      break;
    case 'updateObject':
      updateHangingObjectConfig(payload);
      break;
    case 'resetPositions':
      resetAllPositions();
      break;
    case 'setMode':
      setAppMode(payload.mode);
      break;
    case 'selectObject':
      selectObjectById(payload.id);
      break;
    case 'importGLB':
      loadUserGLBModel(payload);
      break;
    case 'loadScene':
      loadEntireScene(payload.objects);
      break;
    default:
      console.warn('Unknown action:', action);
  }
};

// Listen for native webview messages
if (window.chrome && window.chrome.webview) {
  window.chrome.webview.addEventListener('message', function (event) {
    window.handleFlutterMessage(event.data);
  });
}

function initScene() {
  const container = document.getElementById('canvas-container');

  // 1. Scene
  scene = new THREE.Scene();
  scene.background = new THREE.Color(0x0a0b0e);
  scene.fog = new THREE.FogExp2(0x0a0b0e, 0.035);

  // 2. Camera
  camera = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 0.1, 100);
  camera.position.set(0, 0.8, 8.8);
  camera.lookAt(0, 0.5, 0);

  // 3. Renderer
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false, powerPreference: 'high-performance' });
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.15;
  renderer.outputEncoding = THREE.sRGBEncoding;
  container.appendChild(renderer.domElement);

  // 4. Physics World
  physicsWorld = new PhysicsWorld();

  // 5. Lighting Setup (Cinematic dark studio)
  setupLighting();

  // 6. Ceiling mount rod & floor reflection plane
  setupArchitecturalEnvironment();

  // 7. GLTF Loader
  if (typeof THREE.GLTFLoader !== 'undefined') {
    gltfLoader = new THREE.GLTFLoader();
  }

  // 8. Event Listeners
  window.addEventListener('resize', onWindowResize, false);
  container.addEventListener('pointermove', onPointerMove, false);
  container.addEventListener('pointerdown', onPointerDown, false);
  window.addEventListener('pointerup', onPointerUp, false);
  window.addEventListener('pointercancel', onPointerUp, false);
  container.addEventListener('wheel', onMouseWheel, { passive: false });

  // 9. Physics collision callback
  window.onPhysicsCollision = (id1, id2, dist) => {
    sendToFlutter({
      event: 'collision',
      data: { id1, id2 }
    });
  };

  // 10. Load Initial Default Collection
  loadDefaultCollection();

  // Hide loading spinner
  const overlay = document.getElementById('loading-overlay');
  if (overlay) {
    setTimeout(() => {
      overlay.style.opacity = '0';
      setTimeout(() => overlay.remove(), 600);
    }, 400);
  }

  // Notify Flutter that 3D scene is ready
  sendToFlutter({ event: 'sceneReady' });

  // Start Animation Loop
  animate();
}

function setupLighting() {
  // Ambient fill
  ambientLight = new THREE.AmbientLight(0x232733, 0.9);
  scene.add(ambientLight);

  // Overhead Key Spot Light
  spotLight = new THREE.SpotLight(0xfff3db, 2.8);
  spotLight.position.set(0, 7.5, 3.5);
  spotLight.angle = Math.PI / 3;
  spotLight.penumbra = 0.8;
  spotLight.decay = 1.6;
  spotLight.distance = 25;
  spotLight.castShadow = true;
  spotLight.shadow.mapSize.width = 2048;
  spotLight.shadow.mapSize.height = 2048;
  spotLight.shadow.camera.near = 1.0;
  spotLight.shadow.camera.far = 15;
  spotLight.shadow.bias = -0.0005;
  scene.add(spotLight);

  // Warm Gold Rim Light from bottom-back
  warmKeyLight = new THREE.DirectionalLight(0xd4af37, 1.3);
  warmKeyLight.position.set(-5, 3, -4);
  scene.add(warmKeyLight);

  // Cool Blue Depth Light
  rimLight = new THREE.DirectionalLight(0x4a6582, 0.9);
  rimLight.position.set(5, 2, -3);
  scene.add(rimLight);
}

function setupArchitecturalEnvironment() {
  // Ceiling rail / bar from which cords hang
  const railGeom = new THREE.CylinderGeometry(0.045, 0.045, 18, 32);
  railGeom.rotateZ(Math.PI / 2);
  const railMat = new THREE.MeshStandardMaterial({
    color: 0x1a1a24,
    metalness: 0.9,
    roughness: 0.25,
  });
  const rail = new THREE.Mesh(railGeom, railMat);
  rail.position.set(0, 4.5, 0);
  scene.add(rail);

  // Floor plane for soft shadows and reflections
  const floorGeom = new THREE.PlaneGeometry(30, 30);
  const floorMat = new THREE.MeshStandardMaterial({
    color: 0x07080b,
    roughness: 0.7,
    metalness: 0.3,
  });
  const floor = new THREE.Mesh(floorGeom, floorMat);
  floor.rotation.x = -Math.PI / 2;
  floor.position.y = -4.5;
  floor.receiveShadow = true;
  scene.add(floor);
}

// ----------------------------------------------------
// 3D MESH GENERATORS (Realistic PBR Models)
// ----------------------------------------------------

/**
 * 1. Traditional Indian Nimbu-Mirchi Nazar Battu (Lemon + 7 Chillies)
 */
function createLemonChilliesMesh() {
  const group = new THREE.Group();

  // Top suspension brass ring
  const ringGeom = new THREE.TorusGeometry(0.12, 0.025, 16, 32);
  const brassMat = new THREE.MeshStandardMaterial({
    color: 0xd4af37,
    metalness: 0.92,
    roughness: 0.22,
  });
  const ring = new THREE.Mesh(ringGeom, brassMat);
  ring.position.y = 0.55;
  group.add(ring);

  // Ripe textured Yellow Lemon
  const lemonGeom = new THREE.SphereGeometry(0.42, 32, 28);
  lemonGeom.scale(1.0, 1.25, 1.0); // prolate lemon shape
  // Add subtle organic surface displacement to lemon vertices
  const pos = lemonGeom.attributes.position;
  for (let i = 0; i < pos.count; i++) {
    const vx = pos.getX(i);
    const vy = pos.getY(i);
    const vz = pos.getZ(i);
    // Pinch the tips
    if (Math.abs(vy) > 0.4) {
      const tipFactor = (Math.abs(vy) - 0.4) * 0.3;
      pos.setXYZ(i, vx * (1 - tipFactor), vy * (1 + tipFactor * 0.5), vz * (1 - tipFactor));
    }
  }
  lemonGeom.computeVertexNormals();

  const lemonMat = new THREE.MeshStandardMaterial({
    color: 0xffd319,
    roughness: 0.55,
    metalness: 0.05,
    bumpScale: 0.04,
  });
  const lemon = new THREE.Mesh(lemonGeom, lemonMat);
  lemon.castShadow = true;
  lemon.receiveShadow = true;
  lemon.position.y = 0.15;
  group.add(lemon);

  // Small dark green stem at lemon apex
  const stemGeom = new THREE.CylinderGeometry(0.04, 0.05, 0.12, 12);
  const stemMat = new THREE.MeshStandardMaterial({ color: 0x2d4f1e, roughness: 0.6 });
  const stem = new THREE.Mesh(stemGeom, stemMat);
  stem.position.y = 0.62;
  group.add(stem);

  // 7 Fresh Dangling Green Chillies
  const chilliMat = new THREE.MeshStandardMaterial({
    color: 0x1f7a28,
    roughness: 0.28,
    metalness: 0.08,
  });
  const chilliCalyxMat = new THREE.MeshStandardMaterial({
    color: 0x134819,
    roughness: 0.6,
  });

  const chilliAngles = [0, 0.9, 1.8, 2.7, 3.6, 4.5, 5.4];
  chilliAngles.forEach((angle, idx) => {
    const chilliGroup = new THREE.Group();

    // Curved chili spine
    const curvePoints = [];
    const curveLength = 0.75 + (idx % 3) * 0.1;
    const curveCurvature = 0.18 + (idx % 2) * 0.08;

    curvePoints.push(new THREE.Vector3(0, 0, 0));
    curvePoints.push(new THREE.Vector3(curveCurvature * 0.6, -curveLength * 0.4, 0.02));
    curvePoints.push(new THREE.Vector3(curveCurvature, -curveLength * 0.75, -0.01));
    curvePoints.push(new THREE.Vector3(curveCurvature * 0.8, -curveLength, 0.01));

    const curve = new THREE.CatmullRomCurve3(curvePoints);
    const chilliGeom = new THREE.TubeGeometry(curve, 20, 0.075, 12, false);
    // Taper chilli tip
    const cPos = chilliGeom.attributes.position;
    for (let p = 0; p < cPos.count; p++) {
      const cy = cPos.getY(p);
      const t = Math.max(0, Math.min(1, -cy / curveLength));
      const taper = 1.0 - Math.pow(t, 1.4) * 0.85;
      cPos.setX(p, cPos.getX(p) * taper);
      cPos.setZ(p, cPos.getZ(p) * taper);
    }
    chilliGeom.computeVertexNormals();

    const chilli = new THREE.Mesh(chilliGeom, chilliMat);
    chilli.castShadow = true;
    chilliGroup.add(chilli);

    // Dark calyx/cap
    const calyxGeom = new THREE.ConeGeometry(0.1, 0.12, 8);
    calyxGeom.rotateX(Math.PI);
    const calyx = new THREE.Mesh(calyxGeom, chilliCalyxMat);
    calyx.position.y = 0.02;
    chilliGroup.add(calyx);

    // Arrange chillies radiating outward beneath the lemon
    const rad = 0.22;
    const cx = Math.cos(angle) * rad;
    const cz = Math.sin(angle) * rad;
    chilliGroup.position.set(cx, -0.28, cz);
    chilliGroup.rotation.y = angle;
    chilliGroup.rotation.z = 0.22; // slight splay outwards
    group.add(chilliGroup);
  });

  return group;
}

/**
 * 2. Mediterranean Nazar Boncuğu (Evil Eye Glass Talisman)
 */
function createEvilEyeMesh() {
  const group = new THREE.Group();

  // Top suspension golden ring & bead
  const ringGeom = new THREE.TorusGeometry(0.14, 0.03, 16, 32);
  const goldMat = new THREE.MeshStandardMaterial({
    color: 0xe6b800,
    metalness: 0.95,
    roughness: 0.18,
  });
  const ring = new THREE.Mesh(ringGeom, goldMat);
  ring.position.y = 0.88;
  group.add(ring);

  const topBeadGeom = new THREE.SphereGeometry(0.09, 20, 20);
  const topBeadMat = new THREE.MeshStandardMaterial({
    color: 0x0033aa,
    roughness: 0.1,
    metalness: 0.1,
  });
  const topBead = new THREE.Mesh(topBeadGeom, topBeadMat);
  topBead.position.y = 0.72;
  group.add(topBead);

  // Main Glass Disc
  // Concentric layered discs to form authentic Nazar eye
  const discGeom = new THREE.CylinderGeometry(0.68, 0.68, 0.14, 48);
  discGeom.rotateX(Math.PI / 2);
  const deepBlueGlass = new THREE.MeshPhysicalMaterial({
    color: 0x002fbe,
    roughness: 0.15,
    metalness: 0.1,
    clearcoat: 1.0,
    clearcoatRoughness: 0.1,
    transmission: 0.35,
    opacity: 0.95,
    transparent: true,
  });
  const mainDisc = new THREE.Mesh(discGeom, deepBlueGlass);
  mainDisc.castShadow = true;
  group.add(mainDisc);

  // White Ring
  const whiteGeom = new THREE.CylinderGeometry(0.5, 0.5, 0.146, 48);
  whiteGeom.rotateX(Math.PI / 2);
  const whiteMat = new THREE.MeshStandardMaterial({
    color: 0xffffff,
    roughness: 0.3,
  });
  const whiteRing = new THREE.Mesh(whiteGeom, whiteMat);
  group.add(whiteRing);

  // Cyan / Sky Blue Ring
  const cyanGeom = new THREE.CylinderGeometry(0.32, 0.32, 0.152, 40);
  cyanGeom.rotateX(Math.PI / 2);
  const cyanMat = new THREE.MeshStandardMaterial({
    color: 0x00bbd4,
    roughness: 0.25,
  });
  const cyanRing = new THREE.Mesh(cyanGeom, cyanMat);
  group.add(cyanRing);

  // Black Pupil
  const pupilGeom = new THREE.CylinderGeometry(0.16, 0.16, 0.158, 32);
  pupilGeom.rotateX(Math.PI / 2);
  const pupilMat = new THREE.MeshStandardMaterial({
    color: 0x060608,
    roughness: 0.2,
  });
  const pupil = new THREE.Mesh(pupilGeom, pupilMat);
  group.add(pupil);

  // Bottom dangling brass teardrop charm
  const charmGeom = new THREE.ConeGeometry(0.12, 0.38, 20);
  charmGeom.rotateX(Math.PI);
  const charm = new THREE.Mesh(charmGeom, goldMat);
  charm.position.y = -0.85;
  charm.castShadow = true;
  group.add(charm);

  return group;
}

/**
 * 3. Ornate Antique Brass Temple Bell (Ghanta Pendant)
 */
function createBrassBellMesh() {
  const group = new THREE.Group();

  const brassMat = new THREE.MeshStandardMaterial({
    color: 0xc89d3d,
    metalness: 0.88,
    roughness: 0.26,
  });

  // Top Loop handle
  const loopGeom = new THREE.TorusGeometry(0.15, 0.035, 16, 32);
  const loop = new THREE.Mesh(loopGeom, brassMat);
  loop.position.y = 0.95;
  group.add(loop);

  // Bell Finial / Crest
  const finialGeom = new THREE.CylinderGeometry(0.08, 0.18, 0.3, 24);
  const finial = new THREE.Mesh(finialGeom, brassMat);
  finial.position.y = 0.72;
  group.add(finial);

  // Bell Body (lathed / lofted dome)
  const bellPoints = [];
  bellPoints.push(new THREE.Vector2(0.18, 0.58));
  bellPoints.push(new THREE.Vector2(0.32, 0.38));
  bellPoints.push(new THREE.Vector2(0.42, 0.12));
  bellPoints.push(new THREE.Vector2(0.52, -0.25));
  bellPoints.push(new THREE.Vector2(0.68, -0.55));
  bellPoints.push(new THREE.Vector2(0.72, -0.62));
  bellPoints.push(new THREE.Vector2(0.66, -0.64));
  bellPoints.push(new THREE.Vector2(0.55, -0.62));

  const bellGeom = new THREE.LatheGeometry(bellPoints, 36);
  const bell = new THREE.Mesh(bellGeom, brassMat);
  bell.castShadow = true;
  bell.receiveShadow = true;
  group.add(bell);

  // Decorative engraved ring bands
  const bandGeom = new THREE.TorusGeometry(0.54, 0.02, 12, 36);
  bandGeom.rotateX(Math.PI / 2);
  const band = new THREE.Mesh(bandGeom, brassMat);
  band.position.y = -0.28;
  group.add(band);

  // Dangling Clapper with red silk bead
  const clapperRodGeom = new THREE.CylinderGeometry(0.02, 0.02, 0.6, 12);
  const clapperRod = new THREE.Mesh(clapperRodGeom, brassMat);
  clapperRod.position.y = -0.45;
  group.add(clapperRod);

  const clapperBallGeom = new THREE.SphereGeometry(0.12, 20, 20);
  const redSilkMat = new THREE.MeshStandardMaterial({
    color: 0xb51a2b,
    roughness: 0.5,
    metalness: 0.1,
  });
  const clapperBall = new THREE.Mesh(clapperBallGeom, redSilkMat);
  clapperBall.position.y = -0.8;
  clapperBall.castShadow = true;
  group.add(clapperBall);

  return group;
}

/**
 * 4. Obsidian & Gold Astral Totem Figurine
 */
function createAstralTotemMesh() {
  const group = new THREE.Group();

  const obsidianMat = new THREE.MeshStandardMaterial({
    color: 0x14151a,
    roughness: 0.18,
    metalness: 0.85,
  });
  const goldTrimMat = new THREE.MeshStandardMaterial({
    color: 0xd4af37,
    roughness: 0.22,
    metalness: 0.95,
  });

  // Top Loop
  const loopGeom = new THREE.TorusGeometry(0.12, 0.025, 16, 28);
  const loop = new THREE.Mesh(loopGeom, goldTrimMat);
  loop.position.y = 0.9;
  group.add(loop);

  // Geometric Faceted Head
  const headGeom = new THREE.DodecahedronGeometry(0.38, 0);
  const head = new THREE.Mesh(headGeom, obsidianMat);
  head.position.y = 0.42;
  head.castShadow = true;
  group.add(head);

  // Gold Crest Crown
  const crownGeom = new THREE.ConeGeometry(0.18, 0.32, 5);
  const crown = new THREE.Mesh(crownGeom, goldTrimMat);
  crown.position.y = 0.78;
  group.add(crown);

  // Central Core / Body
  const bodyGeom = new THREE.OctahedronGeometry(0.55, 0);
  bodyGeom.scale(1.0, 1.35, 1.0);
  const body = new THREE.Mesh(bodyGeom, obsidianMat);
  body.castShadow = true;
  body.position.y = -0.22;
  group.add(body);

  // Gold Gyro Rings around body
  const ring1Geom = new THREE.TorusGeometry(0.62, 0.02, 12, 32);
  const ring1 = new THREE.Mesh(ring1Geom, goldTrimMat);
  ring1.position.y = -0.22;
  ring1.rotation.x = Math.PI / 4;
  group.add(ring1);

  // Dangling Crystal Drop
  const dropGeom = new THREE.ConeGeometry(0.15, 0.45, 6);
  dropGeom.rotateX(Math.PI);
  const drop = new THREE.Mesh(dropGeom, goldTrimMat);
  drop.position.y = -0.95;
  drop.castShadow = true;
  group.add(drop);

  return group;
}

// ----------------------------------------------------
// CORD & CHAIN VISUAL BUILDER
// ----------------------------------------------------

function createCordVisual(physicsObj) {
  const type = physicsObj.stringType || 'cord';

  if (type === 'chain') {
    // Interlocking metallic link chain
    const chainGroup = new THREE.Group();
    const linkGeom = new THREE.TorusGeometry(0.065, 0.018, 8, 16);
    const chainMat = new THREE.MeshStandardMaterial({
      color: 0xc49a3c,
      metalness: 0.92,
      roughness: 0.28,
    });

    const totalLinks = physicsObj.numSegments * 4;
    for (let k = 0; k < totalLinks; k++) {
      const link = new THREE.Mesh(linkGeom, chainMat);
      link.castShadow = true;
      chainGroup.add(link);
    }
    chainGroup.userData = { type: 'chain', totalLinks };
    return chainGroup;
  } else {
    // Smooth dynamic curve tube (cord, rope, or silk)
    let cordColor = 0x111216; // black sacred thread for nimbu-mirchi
    let cordRadius = 0.028;
    let roughness = 0.8;
    let metalness = 0.1;

    if (type === 'silk') {
      cordColor = 0xa31621; // crimson silk ribbon
      cordRadius = 0.035;
      roughness = 0.45;
    } else if (type === 'rope') {
      cordColor = 0x82694b; // textured hemp rope
      cordRadius = 0.042;
      roughness = 0.9;
    }

    const cordMat = new THREE.MeshStandardMaterial({
      color: cordColor,
      roughness: roughness,
      metalness: metalness,
    });

    // Initial dummy curve
    const points = physicsObj.particles.map((p) => new THREE.Vector3(p.x, p.y, p.z));
    const curve = new THREE.CatmullRomCurve3(points);
    const cordGeom = new THREE.TubeGeometry(curve, 32, cordRadius, 8, false);
    const cordMesh = new THREE.Mesh(cordGeom, cordMat);
    cordMesh.castShadow = true;
    cordMesh.userData = { type: 'tube', radius: cordRadius, material: cordMat };
    return cordMesh;
  }
}

function updateCordVisual(cordVisual, physicsObj) {
  if (!cordVisual) return;

  const points = physicsObj.particles.map((p) => new THREE.Vector3(p.x, p.y, p.z));
  const curve = new THREE.CatmullRomCurve3(points);

  if (cordVisual.userData.type === 'chain') {
    // Update chain links positions & orientations along curve
    const links = cordVisual.children;
    const count = links.length;
    for (let i = 0; i < count; i++) {
      const u = i / (count - 1);
      const pos = curve.getPointAt(u);
      const tangent = curve.getTangentAt(u);

      links[i].position.copy(pos);
      links[i].quaternion.setFromUnitVectors(new THREE.Vector3(0, 1, 0), tangent);
      // Alternate 90 degree twist for interlocking links
      if (i % 2 === 1) {
        links[i].rotateY(Math.PI / 2);
      }
    }
  } else {
    // Rebuild tube geometry along updated Verlet curve
    cordVisual.geometry.dispose();
    cordVisual.geometry = new THREE.TubeGeometry(
      curve,
      32,
      cordVisual.userData.radius || 0.028,
      8,
      false
    );
  }
}

// ----------------------------------------------------
// SELECTION HIGHLIGHT & EDIT GIZMOS
// ----------------------------------------------------

function createHighlightGlow(radius = 0.8) {
  const geom = new THREE.RingGeometry(radius * 0.95, radius * 1.05, 36);
  geom.rotateX(-Math.PI / 2);
  const mat = new THREE.MeshBasicMaterial({
    color: 0xd4af37,
    side: THREE.DoubleSide,
    transparent: true,
    opacity: 0,
    depthWrite: false,
  });
  const glow = new THREE.Mesh(geom, mat);
  glow.visible = false;
  return glow;
}

// ----------------------------------------------------
// OBJECT FACTORY & MANAGEMENT
// ----------------------------------------------------

function createAndAddHangingObject(config) {
  const id = config.id || 'obj_' + Date.now();
  const type = config.type || 'lemon_chillies';
  const name = config.name || formatObjectName(type);

  // Physics object
  const physicsObj = new HangingPhysicsObject({
    id: id,
    name: name,
    x: config.x !== undefined ? config.x : 0,
    anchorY: 4.5,
    z: config.z !== undefined ? config.z : 0,
    cordLength: config.cordLength || 3.4,
    mass: config.mass || 1.2,
    damping: config.damping !== undefined ? config.damping : 0.994,
    gravity: config.gravity !== undefined ? config.gravity : -19.6,
    sensitivity: config.sensitivity || 1.1,
    stringType: config.stringType || 'cord',
    scale: config.scale || 1.0,
  });

  physicsWorld.add(physicsObj);

  // 3D Model group
  let meshGroup;
  if (type === 'lemon_chillies') {
    meshGroup = createLemonChilliesMesh();
  } else if (type === 'evil_eye') {
    meshGroup = createEvilEyeMesh();
  } else if (type === 'brass_bell') {
    meshGroup = createBrassBellMesh();
  } else if (type === 'astral_totem') {
    meshGroup = createAstralTotemMesh();
  } else {
    // Default fallback
    meshGroup = createLemonChilliesMesh();
  }

  meshGroup.scale.setScalar(physicsObj.scale);
  meshGroup.userData = { id: id, name: name, isHangingObject: true };
  scene.add(meshGroup);

  // Cord visual
  const cordMesh = createCordVisual(physicsObj);
  scene.add(cordMesh);

  // Selection highlight indicator
  const highlight = createHighlightGlow(physicsObj.radius * physicsObj.scale);
  scene.add(highlight);

  // Store in map
  hangingMeshes.set(id, {
    group: meshGroup,
    cordMesh: cordMesh,
    physicsObj: physicsObj,
    highlight: highlight,
    type: type,
    name: name,
  });

  return id;
}

function removeHangingObject(id) {
  const item = hangingMeshes.get(id);
  if (!item) return;

  scene.remove(item.group);
  scene.remove(item.cordMesh);
  scene.remove(item.highlight);

  physicsWorld.remove(id);
  hangingMeshes.delete(id);

  if (activeSelectedId === id) {
    activeSelectedId = null;
  }
}

function updateHangingObjectConfig(config) {
  const item = hangingMeshes.get(config.id);
  if (!item) return;

  const p = item.physicsObj;

  if (config.x !== undefined || config.z !== undefined) {
    p.setAnchor(
      config.x !== undefined ? config.x : p.anchor.x,
      p.anchor.y,
      config.z !== undefined ? config.z : p.anchor.z
    );
  }

  if (config.cordLength !== undefined) {
    p.setCordLength(config.cordLength);
  }

  if (config.mass !== undefined) p.mass = config.mass;
  if (config.damping !== undefined) p.damping = config.damping;
  if (config.gravity !== undefined) p.gravity = config.gravity;
  if (config.sensitivity !== undefined) p.sensitivity = config.sensitivity;

  if (config.scale !== undefined) {
    p.scale = config.scale;
    item.group.scale.setScalar(config.scale);
  }

  if (config.stringType && config.stringType !== p.stringType) {
    p.stringType = config.stringType;
    scene.remove(item.cordMesh);
    item.cordMesh = createCordVisual(p);
    scene.add(item.cordMesh);
  }
}

function resetAllPositions() {
  hangingMeshes.forEach((item) => {
    item.physicsObj.reset();
  });
}

function selectObjectById(id) {
  activeSelectedId = id;
  hangingMeshes.forEach((item, itemId) => {
    if (item.highlight) {
      if (itemId === id) {
        item.highlight.visible = true;
        if (item.highlight.material) item.highlight.material.opacity = 0.85;
      } else {
        item.highlight.visible = false;
        if (item.highlight.material) item.highlight.material.opacity = 0;
      }
    }
  });

  sendToFlutter({
    event: 'objectSelected',
    data: { id: id }
  });
}

function setAppMode(mode) {
  currentMode = mode;
  // If leaving edit mode, hide selection highlights
  if (currentMode !== 'edit') {
    hangingMeshes.forEach((item) => {
      if (item.highlight) {
        item.highlight.visible = false;
      }
    });
  }
}

function loadUserGLBModel(payload) {
  if (!gltfLoader) {
    console.error('GLTF Loader not initialized');
    return;
  }

  const url = payload.url || payload.base64;
  gltfLoader.load(
    url,
    function (gltf) {
      const model = gltf.scene;

      // Compute bounding box and normalize scale
      const box = new THREE.Box3().setFromObject(model);
      const size = new THREE.Vector3();
      box.getSize(size);
      const maxDim = Math.max(size.x, size.y, size.z) || 1.0;
      const targetScale = 1.2 / maxDim;
      model.scale.setScalar(targetScale);

      // Center model
      const center = new THREE.Vector3();
      box.getCenter(center);
      model.position.sub(center.multiplyScalar(targetScale));

      // Enable shadows on all child meshes
      model.traverse((child) => {
        if (child.isMesh) {
          child.castShadow = true;
          child.receiveShadow = true;
        }
      });

      const id = payload.id || 'custom_' + Date.now();
      const name = payload.name || 'Imported Model';

      const physicsObj = new HangingPhysicsObject({
        id: id,
        name: name,
        x: payload.x || 0,
        anchorY: 4.5,
        z: payload.z || 0,
        cordLength: payload.cordLength || 3.2,
        mass: payload.mass || 1.5,
        damping: payload.damping || 0.994,
        stringType: payload.stringType || 'chain',
        scale: 1.0,
      });

      physicsWorld.add(physicsObj);

      const customGroup = new THREE.Group();
      customGroup.add(model);
      customGroup.userData = { id: id, name: name, isHangingObject: true };
      scene.add(customGroup);

      const cordMesh = createCordVisual(physicsObj);
      scene.add(cordMesh);

      const highlight = createHighlightGlow(1.0);
      scene.add(highlight);

      hangingMeshes.set(id, {
        group: customGroup,
        cordMesh: cordMesh,
        physicsObj: physicsObj,
        highlight: highlight,
        type: 'custom',
        name: name,
      });

      sendToFlutter({
        event: 'objectAdded',
        data: { id: id, name: name }
      });
    },
    undefined,
    function (error) {
      console.error('Error loading GLB:', error);
      sendToFlutter({
        event: 'error',
        data: { message: 'Failed to parse 3D model file.' }
      });
    }
  );
}

function loadEntireScene(objectsConfig) {
  // Clear existing
  hangingMeshes.forEach((item, id) => {
    removeHangingObject(id);
  });

  if (Array.isArray(objectsConfig)) {
    objectsConfig.forEach((cfg) => {
      createAndAddHangingObject(cfg);
    });
  }
}

function loadDefaultCollection() {
  // 3 Curated iconic hanging talismans arranged horizontally
  createAndAddHangingObject({
    id: 'talisman_lemon_chillies',
    type: 'lemon_chillies',
    name: 'Nimbu-Mirchi Nazar Battu',
    x: -2.3,
    z: 0,
    cordLength: 3.3,
    mass: 1.3,
    damping: 0.993,
    stringType: 'cord',
    scale: 1.1,
  });

  createAndAddHangingObject({
    id: 'talisman_evil_eye',
    type: 'evil_eye',
    name: 'Nazar Boncuğu Glass Eye',
    x: 0.0,
    z: 0.15,
    cordLength: 3.1,
    mass: 1.1,
    damping: 0.995,
    stringType: 'chain',
    scale: 1.05,
  });

  createAndAddHangingObject({
    id: 'talisman_brass_bell',
    type: 'brass_bell',
    name: 'Ornate Brass Ghanta Bell',
    x: 2.3,
    z: 0,
    cordLength: 3.5,
    mass: 1.6,
    damping: 0.992,
    stringType: 'chain',
    scale: 1.15,
  });
}

function formatObjectName(type) {
  switch (type) {
    case 'lemon_chillies': return 'Nimbu-Mirchi';
    case 'evil_eye': return 'Evil Eye';
    case 'brass_bell': return 'Temple Bell';
    case 'astral_totem': return 'Astral Totem';
    default: return 'Hanging Ornament';
  }
}

// ----------------------------------------------------
// MOUSE & TOUCH INTERACTION
// ----------------------------------------------------

function getIntersectedObject(event) {
  const rect = renderer.domElement.getBoundingClientRect();
  pointer.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
  pointer.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;

  raycaster.setFromCamera(pointer, camera);

  // Test against all hanging meshes and their children
  const intersectables = [];
  hangingMeshes.forEach((item) => {
    intersectables.push(...item.group.children);
  });

  const intersects = raycaster.intersectObjects(intersectables, true);
  if (intersects.length > 0) {
    let curr = intersects[0].object;
    while (curr && curr.parent && !curr.userData.isHangingObject) {
      curr = curr.parent;
    }
    if (curr && curr.userData.id) {
      return { id: curr.userData.id, point: intersects[0].point };
    }
  }
  return null;
}

function onPointerMove(event) {
  const hit = getIntersectedObject(event);
  const tooltip = document.getElementById('object-tooltip');

  if (isDraggingObject && currentDraggedPhysics) {
    // Project mouse position onto drag plane
    raycaster.setFromCamera(pointer, camera);
    if (raycaster.ray.intersectPlane(dragPlane, planeIntersectPoint)) {
      currentDraggedPhysics.updateDrag(planeIntersectPoint);
    }
    if (tooltip) tooltip.classList.remove('visible');
    return;
  }

  // Hover effect
  if (hit) {
    const item = hangingMeshes.get(hit.id);
    if (item) {
      document.body.style.cursor = 'grab';
      if (tooltip) {
        tooltip.textContent = item.name;
        tooltip.style.left = event.clientX + 'px';
        tooltip.style.top = event.clientY + 'px';
        tooltip.classList.add('visible');
      }
      activeHoveredId = hit.id;
      return;
    }
  }

  document.body.style.cursor = 'default';
  if (tooltip) tooltip.classList.remove('visible');
  activeHoveredId = null;
}

function onPointerDown(event) {
  if (event.button !== 0) return; // Only primary mouse button

  const hit = getIntersectedObject(event);
  if (hit) {
    const item = hangingMeshes.get(hit.id);
    if (item) {
      isDraggingObject = true;
      currentDraggedPhysics = item.physicsObj;

      // Define drag plane parallel to camera at object's position
      const bottomPos = item.physicsObj.getBottomPosition();
      const planeNormal = camera.getWorldDirection(new THREE.Vector3()).negate();
      dragPlane.setFromNormalAndCoplanarPoint(planeNormal, new THREE.Vector3(bottomPos.x, bottomPos.y, bottomPos.z));

      currentDraggedPhysics.startDrag(bottomPos);
      selectObjectById(hit.id);
      document.body.style.cursor = 'grabbing';
    }
  }
}

function onPointerUp() {
  if (isDraggingObject && currentDraggedPhysics) {
    currentDraggedPhysics.endDrag();
    isDraggingObject = false;
    currentDraggedPhysics = null;
    document.body.style.cursor = activeHoveredId ? 'grab' : 'default';
  }
}

function onMouseWheel(event) {
  event.preventDefault();
  const zoomSpeed = 0.003;
  camera.position.z += event.deltaY * zoomSpeed;
  camera.position.z = Math.max(4.0, Math.min(14.0, camera.position.z));
}

function onWindowResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
}

// ----------------------------------------------------
// MAIN RENDER & ANIMATION LOOP
// ----------------------------------------------------

function animate() {
  requestAnimationFrame(animate);

  const dt = Math.min(clock.getDelta(), 0.033); // clamp to avoid physics explosion on tab switch
  const elapsedTime = clock.getElapsedTime();

  // 1. Step Physics Simulation
  physicsWorld.update(dt, elapsedTime);

  // 2. Synchronize 3D Meshes with Physics particles
  hangingMeshes.forEach((item) => {
    const p = item.physicsObj;
    const bottomPos = p.getBottomPosition();

    // Position model at bottom particle
    item.group.position.set(bottomPos.x, bottomPos.y, bottomPos.z);

    // Apply natural swinging tilt and spin
    item.group.rotation.set(p.pitch, p.yaw, p.roll);

    // Update cord mesh geometry
    updateCordVisual(item.cordMesh, p);

    // Update highlight ring position
    if (item.highlight && item.highlight.visible) {
      item.highlight.position.set(bottomPos.x, bottomPos.y - 0.7 * p.scale, bottomPos.z);
    }
  });

  // 3. Render
  renderer.render(scene, camera);
}

// Initialize on DOM load
window.addEventListener('DOMContentLoaded', initScene);

