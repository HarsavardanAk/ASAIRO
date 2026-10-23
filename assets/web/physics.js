/**
 * Hangly 3D Physics Engine
 * Realistic Verlet rope/cord integration with spherical pendulum dynamics,
 * aerodynamic drag, mass-dependent swinging, and collision detection.
 */

class VerletParticle {
  constructor(x, y, z, mass = 1.0, isPinned = false) {
    this.x = x;
    this.y = y;
    this.z = z;
    this.oldX = x;
    this.oldY = y;
    this.oldZ = z;
    this.mass = mass;
    this.isPinned = isPinned;
  }

  integrate(dt, gravity, damping, wind = { x: 0, y: 0, z: 0 }) {
    if (this.isPinned) return;

    const vx = (this.x - this.oldX) * damping;
    const vy = (this.y - this.oldY) * damping;
    const vz = (this.z - this.oldZ) * damping;

    this.oldX = this.x;
    this.oldY = this.y;
    this.oldZ = this.z;

    const dtSq = dt * dt;
    this.x += vx + (wind.x / this.mass) * dtSq;
    this.y += vy + (gravity + wind.y / this.mass) * dtSq;
    this.z += vz + (wind.z / this.mass) * dtSq;
  }

  setVelocity(vx, vy, vz, dt = 1 / 60) {
    this.oldX = this.x - vx * dt;
    this.oldY = this.y - vy * dt;
    this.oldZ = this.z - vz * dt;
  }

  getVelocity(dt = 1 / 60) {
    return {
      x: (this.x - this.oldX) / dt,
      y: (this.y - this.oldY) / dt,
      z: (this.z - this.oldZ) / dt,
    };
  }
}

class HangingPhysicsObject {
  constructor(config) {
    this.id = config.id || 'obj_' + Math.random().toString(36).substr(2, 9);
    this.name = config.name || 'Hanging Object';
    this.anchor = { x: config.x || 0, y: config.anchorY || 4.5, z: config.z || 0 };
    this.cordLength = config.cordLength || 3.2;
    this.numSegments = config.numSegments || 7;
    this.segmentLength = this.cordLength / this.numSegments;
    this.mass = config.mass || 1.2;
    this.damping = config.damping !== undefined ? config.damping : 0.994;
    this.gravity = config.gravity !== undefined ? config.gravity : -19.6; // realistic punchy gravity
    this.sensitivity = config.sensitivity || 1.1;
    this.radius = config.radius || 0.65; // collision radius
    this.stringType = config.stringType || 'cord'; // 'cord', 'chain', 'rope', 'silk'
    this.scale = config.scale || 1.0;

    // Rotational dynamics (yaw rotation / spinning)
    this.yaw = 0;
    this.yawVelocity = (Math.random() - 0.5) * 0.4;
    this.yawDamping = 0.985;
    this.pitch = 0;
    this.roll = 0;

    // Interaction state
    this.isDragging = false;
    this.dragTarget = null;
    this.dragHistory = [];

    // Ambient drift phase
    this.driftPhase = Math.random() * Math.PI * 2;
    this.driftSpeed = 0.4 + Math.random() * 0.3;

    // Initialize Verlet particles
    this.particles = [];
    for (let i = 0; i <= this.numSegments; i++) {
      const ratio = i / this.numSegments;
      const py = this.anchor.y - ratio * this.cordLength;
      // Anchor particle is pinned
      const p = new VerletParticle(
        this.anchor.x,
        py,
        this.anchor.z,
        i === this.numSegments ? this.mass : 0.08,
        i === 0
      );
      this.particles.push(p);
    }
  }

  setAnchor(x, y, z) {
    const dx = x - this.anchor.x;
    const dy = y - this.anchor.y;
    const dz = z - this.anchor.z;
    this.anchor.x = x;
    this.anchor.y = y;
    this.anchor.z = z;

    // Shift all particles
    this.particles.forEach((p) => {
      p.x += dx;
      p.y += dy;
      p.z += dz;
      p.oldX += dx;
      p.oldY += dy;
      p.oldZ += dz;
    });
  }

  setCordLength(newLength) {
    this.cordLength = newLength;
    this.segmentLength = this.cordLength / this.numSegments;
  }

  reset() {
    this.isDragging = false;
    this.yawVelocity = 0;
    for (let i = 0; i <= this.numSegments; i++) {
      const ratio = i / this.numSegments;
      const py = this.anchor.y - ratio * this.cordLength;
      const p = this.particles[i];
      p.x = this.anchor.x;
      p.y = py;
      p.z = this.anchor.z;
      p.oldX = p.x;
      p.oldY = p.y;
      p.oldZ = p.z;
    }
  }

  startDrag(target3D) {
    this.isDragging = true;
    this.dragTarget = { ...target3D };
    this.dragHistory = [{ x: target3D.x, y: target3D.y, z: target3D.z, time: performance.now() }];
  }

  updateDrag(target3D) {
    if (!this.isDragging) return;
    this.dragTarget = { ...target3D };
    const now = performance.now();
    this.dragHistory.push({ x: target3D.x, y: target3D.y, z: target3D.z, time: now });
    // Keep last 150ms of drag history
    while (this.dragHistory.length > 1 && now - this.dragHistory[0].time > 150) {
      this.dragHistory.shift();
    }
  }

  endDrag() {
    if (!this.isDragging) return;
    this.isDragging = false;

    // Calculate release velocity from history
    if (this.dragHistory.length >= 2) {
      const first = this.dragHistory[0];
      const last = this.dragHistory[this.dragHistory.length - 1];
      const dt = (last.time - first.time) / 1000;
      if (dt > 0.01) {
        const vx = ((last.x - first.x) / dt) * this.sensitivity;
        const vy = ((last.y - first.y) / dt) * this.sensitivity;
        const vz = ((last.z - first.z) / dt) * this.sensitivity;

        // Cap maximum velocity for stability
        const maxV = 16.0;
        const speed = Math.sqrt(vx * vx + vy * vy + vz * vz);
        const factor = speed > maxV ? maxV / speed : 1.0;

        const bottomP = this.particles[this.particles.length - 1];
        bottomP.setVelocity(vx * factor, vy * factor, vz * factor);

        // Impart natural twist / angular velocity from lateral drag
        this.yawVelocity = (vx * 0.4 + (Math.random() - 0.5) * 0.5) * this.sensitivity;
      }
    }
    this.dragHistory = [];
  }

  step(dt, time) {
    const bottomIndex = this.particles.length - 1;
    const bottomP = this.particles[bottomIndex];

    // Subtle natural ambient breeze (gives lifelike micro-sway)
    const breezeX = Math.sin(time * this.driftSpeed + this.driftPhase) * 0.12 + Math.cos(time * 0.7) * 0.05;
    const breezeZ = Math.cos(time * this.driftSpeed * 0.8 + this.driftPhase) * 0.08;
    const wind = { x: breezeX, y: 0, z: breezeZ };

    // 1. Integrate Verlet particles
    for (let i = 1; i <= bottomIndex; i++) {
      this.particles[i].integrate(dt, this.gravity, this.damping, wind);
    }

    // 2. Drag pull on bottom particle
    if (this.isDragging && this.dragTarget) {
      // Kinematically constrain bottom particle toward target with distance sphere
      const dx = this.dragTarget.x - this.anchor.x;
      const dy = this.dragTarget.y - this.anchor.y;
      const dz = this.dragTarget.z - this.anchor.z;
      const dist = Math.sqrt(dx * dx + dy * dy + dz * dz);
      const maxDist = this.cordLength * 0.995;

      if (dist > maxDist) {
        const factor = maxDist / dist;
        bottomP.x = this.anchor.x + dx * factor;
        bottomP.y = this.anchor.y + dy * factor;
        bottomP.z = this.anchor.z + dz * factor;
      } else {
        bottomP.x = this.dragTarget.x;
        bottomP.y = this.dragTarget.y;
        bottomP.z = this.dragTarget.z;
      }
    }

    // 3. Relax distance constraints between consecutive particles (Gauss-Seidel)
    const iterations = 6;
    for (let it = 0; it < iterations; it++) {
      // Pin root
      this.particles[0].x = this.anchor.x;
      this.particles[0].y = this.anchor.y;
      this.particles[0].z = this.anchor.z;

      for (let i = 0; i < bottomIndex; i++) {
        const p1 = this.particles[i];
        const p2 = this.particles[i + 1];

        const deltaX = p2.x - p1.x;
        const deltaY = p2.y - p1.y;
        const deltaZ = p2.z - p1.z;
        const currentDist = Math.sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ) || 0.0001;
        const diff = (currentDist - this.segmentLength) / currentDist;

        if (p1.isPinned) {
          p2.x -= deltaX * diff;
          p2.y -= deltaY * diff;
          p2.z -= deltaZ * diff;
        } else if (i + 1 === bottomIndex && this.isDragging) {
          p1.x += deltaX * diff;
          p1.y += deltaY * diff;
          p1.z += deltaZ * diff;
        } else {
          const invM1 = 1 / p1.mass;
          const invM2 = 1 / p2.mass;
          const totalInv = invM1 + invM2;

          p1.x += deltaX * diff * (invM1 / totalInv);
          p1.y += deltaY * diff * (invM1 / totalInv);
          p1.z += deltaZ * diff * (invM1 / totalInv);

          p2.x -= deltaX * diff * (invM2 / totalInv);
          p2.y -= deltaY * diff * (invM2 / totalInv);
          p2.z -= deltaZ * diff * (invM2 / totalInv);
        }
      }
    }

    // 4. Update rotational dynamics
    this.yaw += this.yawVelocity * dt;
    this.yawVelocity *= Math.pow(this.yawDamping, dt * 60);

    // Natural orientation calculation from last segment
    const prevP = this.particles[bottomIndex - 1];
    const tx = bottomP.x - prevP.x;
    const ty = bottomP.y - prevP.y;
    const tz = bottomP.z - prevP.z;
    const len = Math.sqrt(tx * tx + ty * ty + tz * tz) || 1;

    // Pitch and Roll based on cord tilt direction
    const targetRoll = -Math.atan2(tx, -ty);
    const targetPitch = Math.atan2(tz, -ty);

    // Smooth transition
    this.roll += (targetRoll - this.roll) * 0.25;
    this.pitch += (targetPitch - this.pitch) * 0.25;
  }

  getBottomPosition() {
    const bottomP = this.particles[this.particles.length - 1];
    return { x: bottomP.x, y: bottomP.y, z: bottomP.z };
  }
}

class PhysicsWorld {
  constructor() {
    this.objects = [];
  }

  add(object) {
    this.objects.push(object);
  }

  remove(id) {
    this.objects = this.objects.filter((obj) => obj.id !== id);
  }

  get(id) {
    return this.objects.find((obj) => obj.id === id);
  }

  clear() {
    this.objects = [];
  }

  update(dt, time) {
    // 1. Step individual objects
    for (let i = 0; i < this.objects.length; i++) {
      this.objects[i].step(dt, time);
    }

    // 2. Inter-object collision resolution (elastic response)
    const count = this.objects.length;
    for (let i = 0; i < count; i++) {
      for (let j = i + 1; j < count; j++) {
        this.resolveCollision(this.objects[i], this.objects[j]);
      }
    }
  }

  resolveCollision(objA, objB) {
    const pA = objA.particles[objA.particles.length - 1];
    const pB = objB.particles[objB.particles.length - 1];

    const dx = pB.x - pA.x;
    const dy = pB.y - pA.y;
    const dz = pB.z - pA.z;
    const distSq = dx * dx + dy * dy + dz * dz;
    const minDist = (objA.radius * objA.scale) + (objB.radius * objB.scale);

    if (distSq < minDist * minDist && distSq > 0.0001) {
      const dist = Math.sqrt(distSq);
      const nx = dx / dist;
      const ny = dy / dist;
      const nz = dz / dist;

      // Overlap separation
      const overlap = (minDist - dist) * 0.5;
      if (!objA.isDragging) {
        pA.x -= nx * overlap;
        pA.y -= ny * overlap;
        pA.z -= nz * overlap;
      }
      if (!objB.isDragging) {
        pB.x += nx * overlap;
        pB.y += ny * overlap;
        pB.z += nz * overlap;
      }

      // Elastic velocity exchange
      const vA = pA.getVelocity();
      const vB = pB.getVelocity();

      const rvx = vB.x - vA.x;
      const rvy = vB.y - vA.y;
      const rvz = vB.z - vA.z;
      const velAlongNormal = rvx * nx + rvy * ny + rvz * nz;

      // Only resolve if closing in
      if (velAlongNormal < 0) {
        const restitution = 0.55; // bouncy rubber/acrylic feel
        const invMassA = 1 / objA.mass;
        const invMassB = 1 / objB.mass;
        const impulseMag = -(1 + restitution) * velAlongNormal / (invMassA + invMassB);

        const impX = impulseMag * nx;
        const impY = impulseMag * ny;
        const impZ = impulseMag * nz;

        if (!objA.isDragging) {
          pA.setVelocity(vA.x - impX * invMassA, vA.y - impY * invMassA, vA.z - impZ * invMassA);
          objA.yawVelocity += (Math.random() - 0.5) * 1.5;
        }
        if (!objB.isDragging) {
          pB.setVelocity(vB.x + impX * invMassB, vB.y + impY * invMassB, vB.z + impZ * invMassB);
          objB.yawVelocity += (Math.random() - 0.5) * 1.5;
        }

        // Trigger subtle collision audio/visual callback
        if (window.onPhysicsCollision) {
          window.onPhysicsCollision(objA.id, objB.id, dist);
        }
      }
    }
  }
}

