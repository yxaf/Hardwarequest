<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Explorer.aspx.cs" Inherits="Hardwarequest.Explore.Explorer" %>
<%--

  LIBRARIES (all from CDN — this page needs internet)
  ---------------------------------------------------
    three.js 0.132.2        WebGL rendering
    OrbitControls 0.132.2   drag to rotate / scroll to zoom
    MediaPipe Tasks Vision 0.10.14   hand tracking (loaded on demand, Task 7)

  FILE LAYOUT — the script is split into 7 numbered tasks:
    setup    (~426-586)   renderer, floor, lights, camera, controls, tick loop
    Task 2   (~588-821)   helpers, PARTS data table, the PC case
    Task 3   (~823-1048)  board side: motherboard, CPU, RAM, SSD
    Task 4   (~1050-1450) power side, assembly, EXPLOSION, auto-framing
    Task 5   (~1452-1661) hover highlight, click-to-focus, spec card
    Task 6   (~1663-1749) leader-line callouts in exploded view
    Task 7   (~1751-2047) webcam hand tracking

  COORDINATE SYSTEM:  +X right, +Y up, +Z toward the viewer.
--%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>3D Explorer — HardwareQuest</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Comfortaa:wght@500;700&family=Quicksand:wght@500;700&display=swap" rel="stylesheet">
<style>
  /* ======================================================================
     CSS BLOCK 1 — THE PALETTE
     Five colours drive the entire HUD. They are hand-copied from the app
     theme (tactile-maker.css) so the Explorer matches the rest of the site
     even though it does not load that stylesheet.
     [EDIT: COLOUR] change these five and every panel, button and pill
     follows. NOTE: these style the 2D interface only — the colours of the
     3D parts live in the JavaScript further down (search for mat({ color).
     ====================================================================== */
  :root {
    --cream: #fff8f0;    /* panel backgrounds (= --tm-surface in the app)   */
    --green: #2e6950;    /* buttons, headings (= --tm-primary in the app)   */
    --copper: #d8a657;   /* cursor dot + meter fill, the one accent colour  */
    --border: #e3d9c6;   /* the 1px outline on every floating panel         */
    --ink: #1f1b10;      /* body text (= --tm-on-surface in the app)        */
  }

  * { box-sizing: border-box; }

  html, body {
    margin: 0;
    padding: 0;
    width: 100%;
    height: 100%;
    overflow: hidden;
    font-family: 'Quicksand', sans-serif;
    color: var(--ink);
    background: #f4f2ee;
  }

  /* ======================================================================
     CSS BLOCK 2 — THE 3D CANVAS
     This element is NOT in the markup. three.js creates it and the script
     tags it with this id (renderer.domElement.id = 'app-canvas').
     inset:0 makes it fill the window; everything else floats on top of it
     via z-index. overflow:hidden on <body> above stops the page scrolling,
     because unlike InsideTheMachine this page is driven by dragging, not
     by scrolling.
     ====================================================================== */
  #app-canvas {
    position: fixed;
    inset: 0;
    display: block;
  }

  /* ======================================================================
     CSS BLOCK 3 — THE HUD (heads-up display)
     Everything from here down is a panel floating over the 3D scene.
     They are all position:fixed with a z-index, so they never move when
     the model rotates. Layer order used on this page:
        z-index 5   #callouts   (leader lines, must sit UNDER the panels)
        z-index 10  panels      (title, controls, card, toast, hand panel)
        z-index 20  #homePill, #hoverTag
        z-index 30  #cursorDot  (the hand-tracking pointer, always on top)
     ====================================================================== */
  #title {
    position: fixed;
    top: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: var(--cream);
    color: var(--green);
    font-family: 'Comfortaa', cursive;
    font-weight: 700;
    font-size: 16px;
    padding: 10px 26px;
    border-radius: 999px;
    border: 1px solid var(--border);
    box-shadow: 0 6px 18px rgba(31, 27, 16, 0.12);
    z-index: 10;
    white-space: nowrap;
  }

  #controls {
    position: fixed;
    bottom: 20px;
    left: 50%;
    transform: translateX(-50%);
    background: var(--cream);
    border: 1px solid var(--border);
    border-radius: 18px;
    box-shadow: 0 6px 18px rgba(31, 27, 16, 0.12);
    padding: 14px 22px;
    z-index: 10;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 8px;
    min-width: 320px;
  }

  #controls .row {
    display: flex;
    align-items: center;
    gap: 10px;
    width: 100%;
  }

  #controls label {
    font-family: 'Quicksand', sans-serif;
    font-weight: 700;
    font-size: 13px;
    color: var(--ink);
    white-space: nowrap;
  }

  #explode {
    flex: 1;
    accent-color: var(--green);
  }

  #controls .hint {
    font-size: 12px;
    color: #6b6252;
    font-weight: 500;
  }

  button {
    font-family: 'Quicksand', sans-serif;
    font-weight: 700;
    font-size: 13px;
    border-radius: 999px;
    padding: 8px 18px;
    cursor: pointer;
    border: 1px solid var(--green);
    transition: opacity 0.15s ease;
  }

  button:hover { opacity: 0.85; }

  button.solid {
    background: var(--green);
    color: var(--cream);
  }

  button.outline {
    background: transparent;
    color: var(--green);
  }

  a.btn-like {
    font-family: 'Quicksand', sans-serif;
    font-weight: 700;
    font-size: 13px;
    border-radius: 999px;
    padding: 8px 18px;
    border: 1px solid var(--green);
    background: transparent;
    color: var(--green);
    text-decoration: none;
    display: inline-block;
    transition: opacity 0.15s ease;
  }

  a.btn-like:hover { opacity: 0.85; }

  #homePill {
    position: fixed;
    top: 20px;
    left: 24px;
    z-index: 20;
    background: var(--cream);
    border: 1px solid var(--border);
    box-shadow: 0 6px 18px rgba(31, 27, 16, 0.12);
    color: var(--ink);
  }

  #camBtn {
    background: var(--green);
    color: var(--cream);
    border: 1px solid var(--green);
  }

  /* THE SPEC CARD — the panel that slides in when you click a part.
     display:none by default; the script shows it and fills #cardName,
     #cardRole and #cardSpecs from window.HQ_PARTS (i.e. from the database). */
  #card {
    position: fixed;
    top: 50%;
    right: 24px;
    transform: translateY(-50%);
    width: 280px;
    background: var(--cream);
    border: 1px solid var(--border);
    border-radius: 16px;
    box-shadow: 0 10px 30px rgba(31, 27, 16, 0.16);
    padding: 20px;
    z-index: 10;
    display: none;
  }

  #card h2 {
    font-family: 'Comfortaa', cursive;
    font-weight: 700;
    font-size: 18px;
    color: var(--green);
    margin: 0 0 4px 0;
  }

  #card p.role {
    font-size: 13px;
    color: #6b6252;
    margin: 0 0 12px 0;
    font-weight: 500;
  }

  #card ul.specs {
    list-style: none;
    margin: 0 0 16px 0;
    padding: 0;
    font-size: 13px;
    font-weight: 500;
  }

  #card ul.specs li {
    padding: 4px 0;
    border-bottom: 1px dashed var(--border);
  }

  #card .actions {
    display: flex;
    gap: 8px;
  }

  /* TOAST — the small temporary message pill (bottom-left), used for things
     like "Camera blocked" or gesture feedback. Hidden until the script
     sets display and a message. */
  #toast {
    position: fixed;
    bottom: 20px;
    left: 20px;
    background: var(--cream);
    border: 1px solid var(--border);
    border-radius: 999px;
    box-shadow: 0 6px 18px rgba(31, 27, 16, 0.12);
    padding: 10px 20px;
    font-size: 13px;
    font-weight: 700;
    color: var(--green);
    z-index: 10;
    display: none;
  }

  /* ---------------------------------------------------------------------
     HAND-TRACKING INTERFACE (all hidden until the user enables the camera)
       #handPanel     the small webcam preview, bottom-right
       #gestureGuide  the legend of gestures, sits to its left
       #cursorDot     the on-screen pointer your finger drives
       #openMeter     the bar showing how open your hand is (0 = fist)
     --------------------------------------------------------------------- */
  #handPanel {
    position: fixed;
    bottom: 20px;
    right: 24px;
    width: 180px;
    background: var(--cream);
    border: 1px solid var(--border);
    border-radius: 16px;
    box-shadow: 0 6px 18px rgba(31, 27, 16, 0.12);
    padding: 10px;
    z-index: 10;
    display: none;
  }

  #gestureGuide {
    position: fixed;
    bottom: 20px;
    right: 224px;
    width: 252px;
    background: var(--cream);
    border: 1px solid var(--border);
    border-radius: 16px;
    box-shadow: 0 6px 18px rgba(31, 27, 16, 0.12);
    padding: 8px 10px;
    z-index: 10;
    display: none;
    font-size: 0.8rem;
  }

  .gg-row {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 4px 6px;
    border-radius: 8px;
    transition: background 0.15s ease;
  }

  .gg-row .gg-icon {
    font-size: 1.15rem;
    flex: none;
  }

  .gg-row.active {
    background: rgba(46, 105, 80, 0.16);
  }

  #handPanel .stage {
    position: relative;
    width: 100%;
    aspect-ratio: 4 / 3;
    border-radius: 10px;
    overflow: hidden;
    background: #000;
  }

  #handVideo, #handOverlay {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
  }

  #handVideo {
    object-fit: cover;
    transform: scaleX(-1); /* mirror so the preview matches the user's motion */
  }

  /* The pointer driven by your index finger. z-index 30 = above everything.
     The .pinch variant below grows it and fills it green, which is the
     visual confirmation that a pinch was detected. */
  #cursorDot {
    position: fixed;
    width: 22px;
    height: 22px;
    border-radius: 50%;
    border: 2px solid var(--copper);
    background: rgba(46, 105, 80, 0.35);
    transform: translate(-50%, -50%);
    pointer-events: none;
    z-index: 30;
    display: none;
    transition: width 0.12s ease, height 0.12s ease, background 0.12s ease;
  }

  #cursorDot.pinch {
    width: 34px;
    height: 34px;
    background: var(--green);
  }

  #openMeter {
    margin-top: 8px;
    width: 100%;
    height: 6px;
    border-radius: 999px;
    background: var(--border);
    overflow: hidden;
  }

  #openFill {
    height: 100%;
    width: 0%;
    background: var(--copper);
    transition: width 0.1s ease;
  }

  /* The little name label that follows the mouse when you hover a part.
     pointer-events:none is essential — without it the label would sit
     under the cursor and block the click it is advertising. */
  #hoverTag {
    position: fixed;
    pointer-events: none;
    background: var(--cream);
    border: 1px solid var(--border);
    border-radius: 10px;
    box-shadow: 0 4px 12px rgba(31, 27, 16, 0.14);
    padding: 6px 12px;
    font-size: 12px;
    font-weight: 700;
    color: var(--ink);
    z-index: 20;
    display: none;
    transform: translate(12px, -50%);
  }

  /* CALLOUTS — the labelled leader lines shown in the exploded view
     (Task 6 fills this container with an <svg> plus .callout <div>s).
     z-index 5 keeps them BELOW the HUD panels so they never cover a button.
     .callout.left / .right add the small stub line on the correct side. */
  #callouts {
    position: fixed;
    inset: 0;
    pointer-events: none;
    z-index: 5;
  }

  #callouts svg {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
  }

  .callout {
    position: absolute;
    font-family: 'Quicksand', sans-serif;
    font-size: 13px;
    font-weight: 700;
    color: var(--ink);
    white-space: nowrap;
    transform: translateY(-50%);
    padding: 2px 8px;
  }

  .callout.left { border-right: 1px solid #8a8a86; }
  .callout.right { border-left: 1px solid #8a8a86; }
</style>
</head>
<body>

<div id="title">HardwareQuest — Interactive Hardware Explorer</div>
<a id="homePill" class="btn-like" href="<%= ResolveUrl("~/Default.aspx") %>">← HardwareQuest</a>

<div id="controls">
  <div class="row">
    <label for="explode">Explode view</label>
    <input id="explode" type="range" min="0" max="1" step="0.001" value="0">
  </div>
  <div class="hint">Drag to rotate · Scroll to zoom · Click a part for details</div>
  <button id="camBtn" class="solid">Enable hand tracking</button>
</div>

<div id="card">
  <h2 id="cardName">Part Name</h2>
  <p class="role" id="cardRole">Role description</p>
  <ul class="specs" id="cardSpecs"></ul>
  <div class="actions">
    <button id="cardListen" class="outline">Listen</button>
    <a id="cardLearn" class="btn-like" href="#" style="display:none">Learn more</a>
    <button id="cardClose" class="solid">Close</button>
  </div>
</div>

<div id="toast"></div>

<div id="gestureGuide">
  <div class="gg-row"><span class="gg-icon">✋</span><span>Open hand — take it apart</span></div>
  <div class="gg-row"><span class="gg-icon">✊</span><span>Fist — put it back</span></div>
  <div class="gg-row"><span class="gg-icon">👆</span><span>Point — move the dot</span></div>
  <div class="gg-row" id="ggPick"><span class="gg-icon">👌</span><span>Quick pinch — pick a part</span></div>
  <div class="gg-row" id="ggSpin"><span class="gg-icon">👌💨</span><span>Pinch + move — spin around</span></div>
</div>

<div id="handPanel">
  <div class="stage">
    <video id="handVideo" playsinline muted></video>
    <canvas id="handOverlay"></canvas>
  </div>
  <div id="openMeter"><div id="openFill"></div></div>
</div>

<div id="hoverTag"></div>

<div id="cursorDot"></div>

<div id="callouts"></div>

<script>window.HQ_PARTS = <%= PartsJson %>;</script>
<script src="https://unpkg.com/three@0.132.2/build/three.min.js"></script>
<script src="https://unpkg.com/three@0.132.2/examples/js/controls/OrbitControls.js"></script>
<script>
(function () {
  'use strict';

  // ---------- Renderer ----------
  const canvasHost = document.body;
  const renderer = new THREE.WebGLRenderer({ antialias: true });
  renderer.setPixelRatio(window.devicePixelRatio);
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.outputEncoding = THREE.sRGBEncoding;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.0;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.domElement.id = 'app-canvas';
  canvasHost.appendChild(renderer.domElement);

  // ---------- Scene ----------
  const scene = new THREE.Scene();
  scene.background = new THREE.Color('#f4f2ee');
  scene.fog = null;

  // Gradient cyclorama background via canvas texture.
  (function buildBackground() {
    const c = document.createElement('canvas');
    c.width = 2048;
    c.height = 1024;
    const ctx = c.getContext('2d');
    const grad = ctx.createLinearGradient(0, 0, 0, c.height);
    grad.addColorStop(0, '#ffffff');
    grad.addColorStop(1, '#e8e5df');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, c.width, c.height);
    const tex = new THREE.CanvasTexture(c);
    tex.encoding = THREE.sRGBEncoding;
    scene.background = tex;
  })();

  // Floor
  const floor = new THREE.Mesh(
    new THREE.PlaneGeometry(500, 500),
    new THREE.MeshStandardMaterial({ color: '#f1efe9', roughness: 0.95, metalness: 0 })
  );
  floor.rotation.x = -Math.PI / 2;
  floor.position.y = -52;
  floor.receiveShadow = true;
  scene.add(floor);

  // Contact shadow (soft radial alpha blob just above floor)
  (function buildContactShadow() {
    const c = document.createElement('canvas');
    c.width = 512;
    c.height = 512;
    const ctx = c.getContext('2d');
    const grad = ctx.createRadialGradient(256, 256, 0, 256, 256, 256);
    grad.addColorStop(0, 'rgba(0,0,0,0.28)');
    grad.addColorStop(1, 'rgba(0,0,0,0)');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, c.width, c.height);
    const tex = new THREE.CanvasTexture(c);
    const mat = new THREE.MeshBasicMaterial({ map: tex, transparent: true, depthWrite: false });
    const mesh = new THREE.Mesh(new THREE.PlaneGeometry(140, 90), mat);
    mesh.rotation.x = -Math.PI / 2;
    mesh.position.y = -51.9;
    scene.add(mesh);
  })();

  // ---------- Lights ----------
  const keyLight = new THREE.DirectionalLight('#ffffff', 1.1);
  keyLight.position.set(60, 110, 80);
  keyLight.castShadow = true;
  keyLight.shadow.mapSize.set(1024, 1024);
  keyLight.shadow.camera.left = -90;
  keyLight.shadow.camera.right = 90;
  keyLight.shadow.camera.top = 90;
  keyLight.shadow.camera.bottom = -90;
  keyLight.shadow.bias = -0.0005;
  scene.add(keyLight);

  const fillLight = new THREE.DirectionalLight('#dfe8ff', 0.45);
  fillLight.position.set(-80, 40, 30);
  scene.add(fillLight);

  const rimLight = new THREE.DirectionalLight('#fff2dd', 0.5);
  rimLight.position.set(0, 30, -120);
  scene.add(rimLight);

  const hemiLight = new THREE.HemisphereLight('#ffffff', '#d8d4cc', 0.6);
  scene.add(hemiLight);

  // ---------- Environment (softbox studio) ----------
  const pmrem = new THREE.PMREMGenerator(renderer);
  pmrem.compileEquirectangularShader();

  const envScene = new THREE.Scene();
  envScene.background = new THREE.Color('#000000');

  function addSoftbox(color, size, position, rotation) {
    const panel = new THREE.Mesh(
      new THREE.PlaneGeometry(size[0], size[1]),
      new THREE.MeshBasicMaterial({ color: color, side: THREE.DoubleSide })
    );
    panel.position.set(position[0], position[1], position[2]);
    if (rotation) panel.rotation.set(rotation[0], rotation[1], rotation[2]);
    envScene.add(panel);
  }

  addSoftbox('#ffffff', [1200, 1200], [0, 0, -400]);
  addSoftbox('#ffffff', [1200, 1200], [0, 0, 400], [0, Math.PI, 0]);
  addSoftbox('#f2efe8', [1200, 1200], [-400, 0, 0], [0, Math.PI / 2, 0]);
  addSoftbox('#f2efe8', [1200, 1200], [400, 0, 0], [0, -Math.PI / 2, 0]);
  addSoftbox('#ffffff', [1200, 1200], [0, 400, 0], [Math.PI / 2, 0, 0]);
  addSoftbox('#e6e2d8', [1200, 1200], [0, -400, 0], [-Math.PI / 2, 0, 0]);

  const envMap = pmrem.fromScene(envScene, 0.04, 0.1, 1000).texture;
  scene.environment = envMap;

  // ---------- Camera & Controls ----------
  const camera = new THREE.PerspectiveCamera(42, window.innerWidth / window.innerHeight, 0.1, 1000);
  camera.position.set(70, 40, 110);
  camera.lookAt(0, 0, 0);

  const controls = new THREE.OrbitControls(camera, renderer.domElement);
  controls.enableDamping = true;
  controls.dampingFactor = 0.08;
  controls.minDistance = 40;
  controls.maxDistance = 260;
  controls.maxPolarAngle = Math.PI * 0.52;
  controls.target.set(0, 0, 0);

  // ---------- World group ----------
  const world = new THREE.Group();
  scene.add(world);

  let goalDist = camera.position.distanceTo(controls.target);
  let curDist = goalDist;

  function frameScene(pad) {
    pad = pad === undefined ? 1.25 : pad;
    const s = new THREE.Sphere();
    new THREE.Box3().setFromObject(world).getBoundingSphere(s);
    const d = (s.radius * pad) / Math.tan(THREE.MathUtils.degToRad(camera.fov / 2));
    goalDist = THREE.MathUtils.clamp(d, controls.minDistance, controls.maxDistance);
  }

  const tickFns = [];

  tickFns.push(function () {
    curDist += (goalDist - curDist) * 0.06;
    const dir = new THREE.Vector3().subVectors(camera.position, controls.target).normalize();
    if (dir.lengthSq() === 0) dir.set(0, 0, 1);
    camera.position.copy(controls.target).addScaledVector(dir, curDist);
  });

  renderer.setAnimationLoop(function () {
    tickFns.forEach(function (f) { f(); });
    controls.update();
    renderer.render(scene, camera);
  });

  window.addEventListener('resize', function () {
    camera.aspect = window.innerWidth / window.innerHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(window.innerWidth, window.innerHeight);
  });

  // ==================================================================
  // Task 2: material/texture helpers, PARTS data, and the PC case model
  // ==================================================================

  // ---------- Material helper ----------
  // envMap comes from scene.environment automatically for MeshStandardMaterial.
  function mat(opts) {
    opts = opts || {};
    const params = {
      color: opts.color !== undefined ? opts.color : '#ffffff',
      metalness: opts.metalness !== undefined ? opts.metalness : 0,
      roughness: opts.roughness !== undefined ? opts.roughness : 0.6
    };
    const m = new THREE.MeshStandardMaterial(params);
    if (opts.map !== undefined) m.map = opts.map;
    if (opts.emissive !== undefined) m.emissive = new THREE.Color(opts.emissive);
    if (opts.emissiveIntensity !== undefined) m.emissiveIntensity = opts.emissiveIntensity;
    if (opts.transparent !== undefined) m.transparent = opts.transparent;
    if (opts.opacity !== undefined) m.opacity = opts.opacity;
    if (opts.side !== undefined) m.side = opts.side;
    return m;
  }

  // ---------- Mesh helpers ----------
  function box(w, h, d, material, x, y, z, parent) {
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), material);
    mesh.position.set(x || 0, y || 0, z || 0);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    (parent || world).add(mesh);
    return mesh;
  }

  function cyl(r, h, material, x, y, z, parent, seg) {
    seg = seg === undefined ? 24 : seg;
    const mesh = new THREE.Mesh(new THREE.CylinderGeometry(r, r, h, seg), material);
    mesh.position.set(x || 0, y || 0, z || 0);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    (parent || world).add(mesh);
    return mesh;
  }

  // ---------- Runtime-painted texture helper ----------
  function paintTexture(w, h, drawFn) {
    const c = document.createElement('canvas');
    c.width = w;
    c.height = h;
    const ctx = c.getContext('2d');
    drawFn(ctx, w, h);
    const tex = new THREE.CanvasTexture(c);
    tex.encoding = THREE.sRGBEncoding;
    tex.anisotropy = 4;
    return tex;
  }

  // ---------- Part registry ----------
  const partGroups = [];

  // Clone every mesh material at registration so hover/fade effects on one
  // part can never leak into another that shared the material (RAM clones,
  // repeated fans). If a material was queued for RGB hue-drift, keep the
  // rgbMats entry pointing at the clone actually in use.
  function cloneTracked(m) {
    const c = m.clone();
    const idx = rgbMats.indexOf(m);
    if (idx >= 0) rgbMats[idx] = c;
    return c;
  }

  function registerPart(group, partKey) {
    group.userData = { partKey: partKey, isPart: true };
    group.traverse(function (o) {
      if (!o.isMesh || o.userData.noRay) return;
      if (Array.isArray(o.material)) o.material = o.material.map(cloneTracked);
      else o.material = cloneTracked(o.material);
    });
    partGroups.push(group);
    return group;
  }

  // ---------- PARTS data ----------
  // home/dir are filled in by Task 4 (explode layout); left as zero vectors here.
  const PARTS = [
    {
      partKey: 'cpu',
      name: 'CPU — Central Processing Unit',
      role: "Executes every instruction a program issues; the machine's general-purpose engine.",
      specs: ['8 cores / 16 threads', 'Up to 5.0 GHz boost', 'Socket AM5', '5 nm process'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    },
    {
      partKey: 'cooler',
      name: 'CPU Cooler',
      role: 'Pulls heat away from the processor so it can sustain high clock speeds without throttling.',
      specs: ['Direct-touch copper heatpipes', '120 mm PWM fan, 300–1500 RPM', 'Supports up to 250 W TDP', 'Aluminium fin stack'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    },
    {
      partKey: 'ram',
      name: 'RAM — Memory',
      role: "Holds the data and instructions the CPU is actively working with for near-instant access.",
      specs: ['32 GB (2×16 GB) kit', 'DDR5-6000', 'CL30 latency', 'Dual-channel'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    },
    {
      partKey: 'motherboard',
      name: 'Motherboard',
      role: 'The circuit board that connects every component and routes power and data between them.',
      specs: ['ATX form factor', 'Socket AM5, DDR5 support', 'PCIe 5.0 x16 slot', 'Four M.2 NVMe slots'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    },
    {
      partKey: 'gpu',
      name: 'GPU — Graphics Card',
      role: 'Renders images and accelerates parallel workloads like gaming, video, and machine learning.',
      specs: ['12 GB GDDR6 memory', 'Dual-fan open-air cooling', 'PCIe 4.0 x16 interface', 'Up to 285 W power draw'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    },
    {
      partKey: 'ssd',
      name: 'SSD — Solid-State Drive',
      role: 'Stores the operating system, programs, and files on flash memory for fast, durable access.',
      specs: ['1 TB capacity', 'NVMe PCIe 4.0 interface', 'Up to 7000 MB/s read', 'M.2 2280 form factor'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    },
    {
      partKey: 'psu',
      name: 'PSU — Power Supply Unit',
      role: 'Converts wall AC power into the stable DC voltages every component needs to run.',
      specs: ['750 W continuous output', '80 Plus Gold efficiency', 'Fully modular cabling', 'ATX 3.0 / PCIe 5.0 ready'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    },
    {
      partKey: 'fans',
      name: 'Case Fans',
      role: 'Move air through the case to carry heat away from components and out of the chassis.',
      specs: ['3× 120 mm side intake', 'Up to 1800 RPM', 'Fluid-dynamic bearing', 'PWM speed control'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    },
    {
      partKey: 'case',
      name: 'Case — Chassis',
      role: 'The frame and enclosure that houses every component, manages airflow, and shields internals.',
      specs: ['Aluminium frame, tempered glass panels', 'Supports ATX motherboards', 'Front-to-back airflow layout', 'Tool-less side panel access'],
      home: { x: 0, y: 0, z: 0 },
      dir: { x: 0, y: 0, z: 0 }
    }
  ];

  // ---------- Case model ----------
  function buildCase() {
    const caseGroup = new THREE.Group();

    const frameMat = mat({ color: '#c8ccd2', metalness: 0.85, roughness: 0.35 });
    const glassMat = mat({ color: '#eef4f8', metalness: 0, roughness: 0.05, transparent: true, opacity: 0.12, side: THREE.DoubleSide });
    glassMat.depthWrite = false;
    const panelMat = mat({ color: '#e9e9ec', metalness: 0.4, roughness: 0.5 });
    const footMat = mat({ color: '#3a3d42', metalness: 0.5, roughness: 0.6 });

    // Interior dims W64 x H92 x D40, centred at origin.
    const W = 64, H = 92, D = 40;
    const hw = W / 2, hh = H / 2, hd = D / 2;
    const bar = 2.5;

    // 12 edge bars of the aluminium frame (4 vertical + 4 top + 4 bottom).
    box(bar, H, bar, frameMat, -hw, 0, -hd, caseGroup);
    box(bar, H, bar, frameMat, hw, 0, -hd, caseGroup);
    box(bar, H, bar, frameMat, -hw, 0, hd, caseGroup);
    box(bar, H, bar, frameMat, hw, 0, hd, caseGroup);

    box(W, bar, bar, frameMat, 0, hh, -hd, caseGroup);
    box(W, bar, bar, frameMat, 0, hh, hd, caseGroup);
    box(bar, bar, D, frameMat, -hw, hh, 0, caseGroup);
    box(bar, bar, D, frameMat, hw, hh, 0, caseGroup);

    box(W, bar, bar, frameMat, 0, -hh, -hd, caseGroup);
    box(W, bar, bar, frameMat, 0, -hh, hd, caseGroup);
    box(bar, bar, D, frameMat, -hw, -hh, 0, caseGroup);
    box(bar, bar, D, frameMat, hw, -hh, 0, caseGroup);

    // Glass panels: front (+z) and left side (-x). Not raycast-targetable.
    const frontGlass = new THREE.Mesh(new THREE.PlaneGeometry(W, H), glassMat);
    frontGlass.position.set(0, 0, hd);
    frontGlass.userData.noRay = true;
    caseGroup.add(frontGlass);

    const leftGlass = new THREE.Mesh(new THREE.PlaneGeometry(D, H), glassMat);
    leftGlass.rotation.y = Math.PI / 2;
    leftGlass.position.set(-hw, 0, 0);
    leftGlass.userData.noRay = true;
    caseGroup.add(leftGlass);

    // Solid panels: right side (+x), back (-z), top (+y).
    const rightPanel = new THREE.Mesh(new THREE.PlaneGeometry(D, H), panelMat);
    rightPanel.rotation.y = Math.PI / 2;
    rightPanel.position.set(hw, 0, 0);
    rightPanel.castShadow = true;
    rightPanel.receiveShadow = true;
    rightPanel.userData.casePanel = true;
    caseGroup.add(rightPanel);

    const backPanel = new THREE.Mesh(new THREE.PlaneGeometry(W, H), panelMat);
    backPanel.rotation.y = Math.PI;
    backPanel.position.set(0, 0, -hd);
    backPanel.castShadow = true;
    backPanel.receiveShadow = true;
    backPanel.userData.casePanel = true;
    caseGroup.add(backPanel);

    const topPanel = new THREE.Mesh(new THREE.PlaneGeometry(W, D), panelMat);
    topPanel.rotation.x = -Math.PI / 2;
    topPanel.position.set(0, hh, 0);
    topPanel.castShadow = true;
    topPanel.receiveShadow = true;
    topPanel.userData.casePanel = true;
    caseGroup.add(topPanel);

    // Feet: two low bars under the case.
    box(8, 3, D - 6, footMat, -hw + 10, -hh - 1.5, 0, caseGroup);
    box(8, 3, D - 6, footMat, hw - 10, -hh - 1.5, 0, caseGroup);

    registerPart(caseGroup, 'case');
    world.add(caseGroup);
    return caseGroup;
  }

  // ==================================================================
  // Task 3: board-side models — motherboard, CPU, RAM, SSD
  // ==================================================================

  // rgbMats holds materials that Task 4 will hue-cycle for the "RGB" look
  // (currently just the RAM light-bar).
  const rgbMats = [];

  // ---------- Local helper: two-tone box (distinct front/back faces) ----------
  // BoxGeometry face order is [+x, -x, +y, -y, +z, -z]; front (+z) and back
  // (-z) get their own materials, the remaining four faces share edgeMat.
  function slab(w, h, d, frontMat, backMat, edgeMat, x, y, z, parent) {
    const mats = [edgeMat, edgeMat, edgeMat, edgeMat, frontMat, backMat];
    const mesh = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mats);
    mesh.position.set(x || 0, y || 0, z || 0);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    (parent || world).add(mesh);
    return mesh;
  }

  // ---------- Motherboard albedo: deep-green PCB, traces, silkscreen, pads ----------
  function drawMotherboardTexture(ctx, w, h) {
    ctx.fillStyle = '#123524';
    ctx.fillRect(0, 0, w, h);

    // Thin lighter trace lines: random Manhattan (right-angle) runs.
    ctx.strokeStyle = '#1d5c3d';
    ctx.lineWidth = 1;
    for (let i = 0; i < 140; i++) {
      let x = Math.random() * w;
      let y = Math.random() * h;
      ctx.beginPath();
      ctx.moveTo(x, y);
      const segs = 2 + Math.floor(Math.random() * 4);
      for (let s = 0; s < segs; s++) {
        if (Math.random() < 0.5) x += (Math.random() < 0.5 ? -1 : 1) * (10 + Math.random() * 80);
        else y += (Math.random() < 0.5 ? -1 : 1) * (10 + Math.random() * 80);
        ctx.lineTo(x, y);
      }
      ctx.stroke();
    }

    // Silkscreen text.
    ctx.fillStyle = 'rgba(255,255,255,0.85)';
    ctx.font = 'bold 20px sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('HARDWAREQUEST HQ-X1', 24, 34);

    // White component outlines scattered around the board.
    ctx.strokeStyle = 'rgba(255,255,255,0.6)';
    ctx.lineWidth = 1.5;
    for (let i = 0; i < 20; i++) {
      const rw = 14 + Math.random() * 30;
      const rh = 8 + Math.random() * 18;
      ctx.strokeRect(Math.random() * (w - rw), 50 + Math.random() * (h - 100 - rh), rw, rh);
    }

    // Gold pads row near the bottom edge.
    ctx.fillStyle = '#d8a657';
    const padCount = 24;
    const padW = 10, padH = 18, gap = (w - 40) / padCount;
    for (let i = 0; i < padCount; i++) {
      ctx.fillRect(20 + i * gap, h - 40, padW, padH);
    }
  }

  function buildMotherboard() {
    const g = new THREE.Group();
    const W = 48, H = 56, D = 1.6;
    const hd = D / 2;

    const pcbTex = paintTexture(512, 640, drawMotherboardTexture);
    const pcbFrontMat = mat({ color: '#ffffff', map: pcbTex, roughness: 0.55 });
    const pcbEdgeMat = mat({ color: '#123524', roughness: 0.6 });
    slab(W, H, D, pcbFrontMat, pcbEdgeMat, pcbEdgeMat, 0, 0, 0, g);

    // Chipset heatsink: brushed metal box.
    box(10, 10, 3, mat({ color: '#aeb4bc', metalness: 0.75, roughness: 0.4 }), 6, -16, hd + 1.5, g);

    // Grey I/O shroud, top-left of the board.
    box(10, 14, 6, mat({ color: '#3a3d45', roughness: 0.5 }), -19, 21, hd + 3, g);

    // Emissive accent strip along the shroud's lower front edge.
    box(8, 0.8, 0.6, mat({ color: '#111111', emissive: '#2e6950', emissiveIntensity: 1.2 }), -19, 14.4, hd + 6 + 0.3, g);

    // Four white PCIe/RAM slot bars.
    for (let i = 0; i < 4; i++) {
      box(1.4, 24, 0.3, mat({ color: '#f4f2ee', roughness: 0.5 }), 10 + i * 2, 8, hd + 0.15, g);
    }

    // CPU socket square: darker inset where the CPU sits.
    box(12, 12, 0.6, mat({ color: '#14100a', roughness: 0.55 }), -6, 10, hd + 0.3, g);

    // M.2 slot groove — placed above the PCIe area so the mounted SSD stays
    // visible over the graphics card.
    box(16, 3, 0.3, mat({ color: '#0d0d0d', roughness: 0.5 }), 2, -8, hd + 0.15, g);

    registerPart(g, 'motherboard');
    return g;
  }

  // ---------- CPU: nickel IHS top, gold substrate underside ----------
  function drawCpuIhsTexture(ctx, w, h) {
    ctx.fillStyle = '#d7dbe0';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = 'rgba(0,0,0,0.05)';
    ctx.lineWidth = 1;
    for (let y = 0; y < h; y += 3) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(w, y);
      ctx.stroke();
    }
    ctx.fillStyle = '#3a3f45';
    ctx.font = 'bold 26px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('HQ CORE i9', w / 2, h / 2 + 8);
    // Pin-1 corner marker.
    ctx.fillStyle = 'rgba(58,63,69,0.5)';
    ctx.beginPath();
    ctx.moveTo(16, 16);
    ctx.lineTo(40, 16);
    ctx.lineTo(16, 40);
    ctx.closePath();
    ctx.fill();
  }

  function drawCpuGoldTexture(ctx, w, h) {
    ctx.fillStyle = '#1a1a1a';
    ctx.fillRect(0, 0, w, h);
    ctx.fillStyle = '#d8a657';
    const n = 18;
    const gx = w / (n + 1);
    for (let i = 0; i < n; i++) {
      for (let j = 0; j < n; j++) {
        ctx.fillRect(i * gx + gx * 0.5 - 3, j * gx + gx * 0.5 - 3, 6, 6);
      }
    }
  }

  function buildCpu() {
    const g = new THREE.Group();
    const W = 10, H = 10, D = 1.8;

    const ihsTex = paintTexture(256, 256, drawCpuIhsTexture);
    const goldTex = paintTexture(256, 256, drawCpuGoldTexture);

    const ihsMat = mat({ color: '#cfd3d8', metalness: 0.95, roughness: 0.28, map: ihsTex });
    const goldMat = mat({ color: '#ffffff', map: goldTex, metalness: 0.3, roughness: 0.5 });
    const substrateMat = mat({ color: '#123524', roughness: 0.6 });

    // Front (+z) = nickel IHS with etched text; back (-z) = gold pad grid.
    slab(W, H, D, ihsMat, goldMat, substrateMat, 0, 0, 0, g);

    registerPart(g, 'cpu');
    return g;
  }

  // ---------- RAM: black PCB, chips, aluminium spreaders, RGB light-bar ----------
  function buildRam() {
    const g = new THREE.Group();
    const W = 3, H = 22, coreD = 1, spreaderD = 0.2;
    const coreHalf = coreD / 2;
    const spreaderZ = coreHalf + spreaderD / 2;

    const pcbMat = mat({ color: '#14100a', roughness: 0.65 });
    box(W, H, coreD, pcbMat, 0, 0, 0, g);

    // 8 small chip boxes mounted on the PCB core (sit under the spreaders).
    const chipMat = mat({ color: '#2e3138', roughness: 0.5 });
    for (let i = 0; i < 8; i++) {
      const cy = -8 + i * 2.1;
      box(1.6, 1.2, 0.15, chipMat, 0, cy, coreHalf + 0.075, g);
    }

    // Gunmetal heat-spreader plates, both faces (dark enough to read against
    // the bright studio backdrop).
    const spreaderMat = mat({ color: '#565b63', metalness: 0.7, roughness: 0.35 });
    box(2.8, 20, spreaderD, spreaderMat, 0, 0, spreaderZ + 0.15, g);
    box(2.8, 20, spreaderD, spreaderMat, 0, 0, -spreaderZ - 0.15, g);

    // White translucent light-bar along the top edge (Task 4 animates its hue).
    const lightMat = mat({ color: '#ffffff', emissive: '#ffffff', emissiveIntensity: 0.7 });
    box(W, 1.5, 1.0, lightMat, 0, H / 2 + 0.75, 0, g);
    rgbMats.push(lightMat);

    registerPart(g, 'ram');
    return g;
  }

  // ---------- SSD: green PCB + brushed heatsink label ----------
  function drawSsdLabelTexture(ctx, w, h) {
    ctx.fillStyle = '#cfd3d8';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = 'rgba(0,0,0,0.06)';
    ctx.lineWidth = 1;
    for (let x = 0; x < w; x += 4) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, h);
      ctx.stroke();
    }
    ctx.fillStyle = '#1f1b10';
    ctx.font = 'bold 28px sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('HQ NVMe 1TB', w / 2, h / 2 + 10);
  }

  function buildSsd() {
    const g = new THREE.Group();
    const W = 16, H = 5, pcbD = 1, hsD = 1;
    const pcbHalf = pcbD / 2;
    const hsZ = pcbHalf + hsD / 2;

    const pcbMat = mat({ color: '#123524', roughness: 0.6 });
    box(W, H, pcbD, pcbMat, 0, 0, 0, g);

    const labelTex = paintTexture(512, 160, drawSsdLabelTexture);
    const hsFrontMat = mat({ color: '#ffffff', map: labelTex, metalness: 0.6, roughness: 0.4 });
    const hsEdgeMat = mat({ color: '#9aa0a8', metalness: 0.7, roughness: 0.35 });
    slab(15, 4.4, hsD, hsFrontMat, hsEdgeMat, hsEdgeMat, 0, 0, hsZ, g);

    registerPart(g, 'ssd');
    return g;
  }

  // ==================================================================
  // Task 4: power-side models, assembly, explosion, auto-framing
  // ==================================================================

  // fanSpins holds the spinning-blade sub-groups animated in the tick below.
  const fanSpins = [];

  // ---------- Fan: emissive ring + hub + 7 pitched blades in a spin group ----------
  // Built facing +Z (blades in the XY plane, spin axis = local Z).
  function buildFan(r) {
    const g = new THREE.Group();

    const ringMat = new THREE.MeshBasicMaterial({ color: '#2e6950' });
    rgbMats.push(ringMat);
    const ring = new THREE.Mesh(new THREE.TorusGeometry(r, r * 0.09, 8, 32), ringMat);
    g.add(ring);

    const spin = new THREE.Group();

    const hubMat = mat({ color: '#3a3d45', roughness: 0.5, metalness: 0.3 });
    const hub = new THREE.Mesh(new THREE.CylinderGeometry(r * 0.28, r * 0.28, r * 0.22, 20), hubMat);
    hub.rotation.x = Math.PI / 2;
    hub.castShadow = true;
    spin.add(hub);

    const bladeMat = mat({ color: '#4a4e56', roughness: 0.45, metalness: 0.2, side: THREE.DoubleSide });
    for (let i = 0; i < 7; i++) {
      const holder = new THREE.Group();
      const blade = new THREE.Mesh(new THREE.BoxGeometry(r * 0.62, r * 0.26, 0.1), bladeMat);
      blade.position.x = r * 0.55;
      blade.rotation.x = 0.7;
      blade.castShadow = true;
      holder.add(blade);
      holder.rotation.z = (i / 7) * Math.PI * 2;
      spin.add(holder);
    }

    g.add(spin);
    fanSpins.push(spin);
    return g;
  }

  // ---------- GPU backplate: brushed dark metal with model label ----------
  function drawGpuBackplateTexture(ctx, w, h) {
    ctx.fillStyle = '#33363c';
    ctx.fillRect(0, 0, w, h);
    ctx.strokeStyle = 'rgba(255,255,255,0.05)';
    ctx.lineWidth = 1;
    for (let x = 0; x < w; x += 3) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, h);
      ctx.stroke();
    }
    // Vent slots at the far end.
    ctx.fillStyle = '#22242a';
    for (let i = 0; i < 8; i++) {
      ctx.fillRect(w - 150, 40 + i * 52, 110, 24);
    }
    ctx.fillStyle = '#e8e8ea';
    ctx.font = 'bold 84px sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('HQ RTX', 60, h / 2 + 30);
    ctx.strokeStyle = '#d8a657';
    ctx.lineWidth = 6;
    ctx.beginPath();
    ctx.moveTo(60, h / 2 + 62);
    ctx.lineTo(340, h / 2 + 62);
    ctx.stroke();
  }

  function buildGpu() {
    const g = new THREE.Group();
    const W = 40, H = 9, D = 20;

    const bodyMat = mat({ color: '#2b2e34', roughness: 0.5, metalness: 0.3 });
    box(W, H, D, bodyMat, 0, 0, 0, g);

    // Brushed backplate with label, laid over the top face.
    const bpTex = paintTexture(1024, 512, drawGpuBackplateTexture);
    const bpMat = mat({ color: '#ffffff', map: bpTex, metalness: 0.75, roughness: 0.35 });
    const bp = new THREE.Mesh(new THREE.PlaneGeometry(W - 1, D - 1), bpMat);
    bp.rotation.x = -Math.PI / 2;
    bp.position.y = H / 2 + 0.05;
    g.add(bp);

    // Two cooling fans inset in the underside shroud face.
    const f1 = buildFan(6);
    f1.rotation.x = Math.PI / 2;
    f1.position.set(-9, -H / 2 - 0.4, 0);
    g.add(f1);
    const f2 = buildFan(6);
    f2.rotation.x = Math.PI / 2;
    f2.position.set(9, -H / 2 - 0.4, 0);
    g.add(f2);

    // Gold PCIe edge connector along the underside, toward the back edge.
    box(18, 1.4, 1.2, mat({ color: '#d8a657', metalness: 0.8, roughness: 0.35 }), -8, -H / 2 - 0.7, -D / 2 + 2, g);

    // Port bracket end plate with three dark port slots.
    const bracketMat = mat({ color: '#c8ccd2', metalness: 0.85, roughness: 0.35 });
    box(0.5, H + 3, D * 0.9, bracketMat, -W / 2 - 0.25, 0, 0, g);
    const portMat = mat({ color: '#101114', roughness: 0.6 });
    for (let i = 0; i < 3; i++) {
      box(0.7, 2, 4.5, portMat, -W / 2 - 0.3, -0.5, -6 + i * 6, g);
    }

    registerPart(g, 'gpu');
    return g;
  }

  // ---------- PSU textures ----------
  function drawPsuStickerTexture(ctx, w, h) {
    ctx.fillStyle = '#1c1e22';
    ctx.fillRect(0, 0, w, h);
    // White spec label with a rating grid.
    const lx = w * 0.08, ly = h * 0.14, lw = w * 0.84, lh = h * 0.72;
    ctx.fillStyle = '#f4f2ee';
    ctx.fillRect(lx, ly, lw, lh);
    ctx.strokeStyle = '#1f1b10';
    ctx.lineWidth = 2;
    ctx.strokeRect(lx, ly, lw, lh);
    ctx.fillStyle = '#1f1b10';
    ctx.font = 'bold 44px sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('HQ 750W GOLD', lx + 24, ly + 60);
    // Grid of voltage-rail cells.
    ctx.strokeStyle = 'rgba(31,27,16,0.55)';
    ctx.lineWidth = 1.5;
    const gy = ly + 84, gh = lh - 108, cols = 5, rows = 2;
    for (let i = 0; i <= cols; i++) {
      const x = lx + 24 + (i * (lw - 48)) / cols;
      ctx.beginPath(); ctx.moveTo(x, gy); ctx.lineTo(x, gy + gh); ctx.stroke();
    }
    for (let j = 0; j <= rows; j++) {
      const y = gy + (j * gh) / rows;
      ctx.beginPath(); ctx.moveTo(lx + 24, y); ctx.lineTo(lx + lw - 24, y); ctx.stroke();
    }
    ctx.font = 'bold 20px sans-serif';
    const rails = ['+3.3V', '+5V', '+12V', '-12V', '+5Vsb'];
    for (let i = 0; i < cols; i++) {
      ctx.fillText(rails[i], lx + 32 + (i * (lw - 48)) / cols, gy + 30);
    }
  }

  function drawPsuHoneycombTexture(ctx, w, h) {
    ctx.fillStyle = '#1c1e22';
    ctx.fillRect(0, 0, w, h);
    ctx.fillStyle = '#0c0d0f';
    const r = 14, dx = r * 2.2, dy = r * 1.9;
    for (let row = 0; row * dy < h + dy; row++) {
      for (let col = 0; col * dx < w + dx; col++) {
        const x = col * dx + (row % 2 ? dx / 2 : 0);
        ctx.beginPath();
        ctx.arc(x, row * dy, r, 0, Math.PI * 2);
        ctx.fill();
      }
    }
  }

  function buildPsu() {
    const g = new THREE.Group();
    const W = 26, H = 14, D = 24;

    const bodyMat = mat({ color: '#1c1e22', roughness: 0.6, metalness: 0.2 });
    const stickerTex = paintTexture(512, 300, drawPsuStickerTexture);
    const stickerMat = mat({ color: '#ffffff', map: stickerTex, roughness: 0.55 });
    const honeyTex = paintTexture(512, 480, drawPsuHoneycombTexture);
    const honeyMat = mat({ color: '#ffffff', map: honeyTex, roughness: 0.6, metalness: 0.2 });

    // Face order [+x, -x, +y, -y, +z, -z]: sticker on the glass-side (-x)
    // face, honeycomb fan intake on top (+y).
    const body = new THREE.Mesh(
      new THREE.BoxGeometry(W, H, D),
      [bodyMat, stickerMat, honeyMat, bodyMat, bodyMat, bodyMat]
    );
    body.castShadow = true;
    body.receiveShadow = true;
    g.add(body);

    // Three braided modular cable stubs curving out of the front face.
    const cableMat = mat({ color: '#3a3d45', roughness: 0.85 });
    for (let i = 0; i < 3; i++) {
      const x0 = -6 + i * 6;
      const curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(x0, 2, D / 2 - 1),
        new THREE.Vector3(x0 + 1, 4.5, D / 2 + 4),
        new THREE.Vector3(x0 + 3.5, 9, D / 2 + 7)
      ]);
      const tube = new THREE.Mesh(new THREE.TubeGeometry(curve, 24, 0.9, 10), cableMat);
      tube.castShadow = true;
      g.add(tube);
    }

    registerPart(g, 'psu');
    return g;
  }

  // ---------- Cooler (AIO): pump block + tubes + radiator with two fans ----------
  function drawCoolerRingTexture(ctx, w, h) {
    ctx.fillStyle = '#000000';
    ctx.fillRect(0, 0, w, h);
    const cx = w / 2, cy = h / 2;
    for (let i = 0; i < 5; i++) {
      ctx.strokeStyle = 'rgba(255,255,255,' + (0.9 - i * 0.16) + ')';
      ctx.lineWidth = 6 - i;
      ctx.beginPath();
      ctx.arc(cx, cy, 30 + i * 18, 0, Math.PI * 2);
      ctx.stroke();
    }
  }

  function buildCooler() {
    const g = new THREE.Group();

    // Pump block (12x12x7) centred on the group origin, ring face toward +Z.
    const pumpBodyMat = mat({ color: '#2b2e34', roughness: 0.45, metalness: 0.4 });
    const ringTex = paintTexture(256, 256, drawCoolerRingTexture);
    const pumpTopMat = new THREE.MeshStandardMaterial({
      color: '#1a1c20',
      emissive: new THREE.Color('#2e6950'),
      emissiveIntensity: 1.4,
      emissiveMap: ringTex,
      roughness: 0.4,
      metalness: 0.3
    });
    rgbMats.push(pumpTopMat);
    const pump = new THREE.Mesh(
      new THREE.BoxGeometry(12, 12, 7),
      [pumpBodyMat, pumpBodyMat, pumpBodyMat, pumpBodyMat, pumpTopMat, pumpBodyMat]
    );
    pump.castShadow = true;
    pump.receiveShadow = true;
    g.add(pump);

    // Radiator against the case's right wall, positioned relative to the pump.
    const radMat = mat({ color: '#26282c', roughness: 0.6 });
    box(6, 54, 24, radMat, 38, -10, 13, g);

    // Two radiator fans on its inward (-x) face.
    const rf1 = buildFan(9);
    rf1.rotation.y = -Math.PI / 2;
    rf1.position.set(34.2, 3, 13);
    g.add(rf1);
    const rf2 = buildFan(9);
    rf2.rotation.y = -Math.PI / 2;
    rf2.position.set(34.2, -23, 13);
    g.add(rf2);

    // Two rubber coolant tubes from the pump to the radiator's lower end.
    const tubeMat = mat({ color: '#1c1e22', roughness: 0.9 });
    for (let i = 0; i < 2; i++) {
      const zOff = i * 3 - 1.5;
      const curve = new THREE.CatmullRomCurve3([
        new THREE.Vector3(4, -4, 1 + zOff),
        new THREE.Vector3(18, -16, 6 + zOff),
        new THREE.Vector3(34, -25, 10 + zOff)
      ]);
      const tube = new THREE.Mesh(new THREE.TubeGeometry(curve, 40, 0.9, 10), tubeMat);
      tube.castShadow = true;
      g.add(tube);
    }

    registerPart(g, 'cooler');
    return g;
  }

  // ---------- Assembly ----------
  // Places every part in the case, then records each group's `home` position
  // and explode direction `dir` in its userData. (Stored per group, not on the
  // shared PARTS entries, because the two RAM clones share one PARTS record.)
  function assemble() {
    const mb = buildMotherboard();
    mb.position.set(-6, 8, -17);

    const cpu = buildCpu();
    cpu.position.set(-12, 18, -15);

    const cooler = buildCooler();
    cooler.position.set(-12, 18, -10.5);

    const ram1 = buildRam();
    ram1.rotation.y = Math.PI / 2;
    ram1.position.set(4, 16, -14.6);
    const ram2 = buildRam();
    ram2.rotation.y = Math.PI / 2;
    ram2.position.set(8, 16, -14.6);

    const gpu = buildGpu();
    gpu.position.set(-4, -12, -4);

    const ssd = buildSsd();
    ssd.position.set(-4, 0, -15.6); // on the M.2 slot, above the GPU so it stays visible

    const psu = buildPsu();
    psu.position.set(10, -36, -4);

    // Case fans: three side-wall intakes stacked on the left glass panel, as
    // one registered part. Rotated to face inward (+x).
    const fans = new THREE.Group();
    for (let i = 0; i < 3; i++) {
      const cf = buildFan(9);
      cf.position.set(-6, 22 - i * 22, 0);
      fans.add(cf);
    }
    registerPart(fans, 'fans');
    fans.rotation.y = Math.PI / 2;
    fans.position.set(-29.5, 10, -6);

    world.add(mb, cpu, cooler, ram1, ram2, gpu, ssd, psu, fans);

    // Explode directions. Formula default = away from the case centre; the
    // overrides keep the layout organised so exploded silhouettes never stack
    // in front of each other from the main camera: motherboard back-left-low,
    // CPU straight up above the case, RAM sticks fan out top-right past the
    // board's edge, cooler slides level toward its radiator wall, GPU pulls
    // forward-down, PSU slides forward along the floor (straight down per the
    // spec would push it through the floor), fans pop out the front.
    const centre = new THREE.Vector3(0, 4, 0);
    const overrides = {
      motherboard: new THREE.Vector3(-0.35, -0.05, -0.93).normalize(),
      cpu: new THREE.Vector3(0, 0.95, -0.3).normalize(),
      gpu: new THREE.Vector3(0.2, -0.35, 1).normalize(),
      psu: new THREE.Vector3(0, -0.2, 0.98).normalize(),
      ssd: new THREE.Vector3(-0.6, 0.75, -0.2).normalize(),
      fans: new THREE.Vector3(-1, 0, 0),
      cooler: new THREE.Vector3(1, -0.1, 0).normalize()
    };
    let ramIndex = 0;
    partGroups.forEach(function (g) {
      if (g.userData.partKey === 'case') return;
      g.userData.home = g.position.clone();
      let dir;
      if (g.userData.partKey === 'ram') {
        dir = new THREE.Vector3(0.45 + 0.3 * ramIndex, 0.5, -0.55).normalize();
        ramIndex++;
      } else if (overrides[g.userData.partKey]) {
        dir = overrides[g.userData.partKey].clone();
      } else {
        dir = g.position.clone().sub(centre);
        if (dir.length() < 0.1) dir.set(0, 1, 0);
        dir.normalize();
      }
      g.userData.dir = dir;
      // Mirror onto the PARTS entry (first group wins) for later tasks.
      const p = PARTS.find(function (pp) { return pp.partKey === g.userData.partKey; });
      if (p && !p._placed) {
        p.home = { x: g.position.x, y: g.position.y, z: g.position.z };
        p.dir = { x: dir.x, y: dir.y, z: dir.z };
        p._placed = true;
      }
    });
  }

  // ---------- Explosion ----------
  const SPREAD = 30;
  let explodeFactor = 0;

  function ease(t) { return t * t * (3 - 2 * t); }

  function applyExplosion() {
    const f = ease(explodeFactor);
    partGroups.forEach(function (g) {
      if (g.userData.partKey === 'case' || !g.userData.home) return;
      g.position.copy(g.userData.home).addScaledVector(g.userData.dir, f * SPREAD);
    });
    // The solid case panels dissolve as the model explodes so they never
    // occlude parts that travel past them (RAM behind the right wall, etc.).
    const caseGroup = partGroups.find(function (g) { return g.userData.partKey === 'case'; });
    if (caseGroup) {
      const panelTarget = 1 - f * 0.88;
      caseGroup.traverse(function (o) {
        if (!o.isMesh || !o.userData.casePanel) return;
        const ms = Array.isArray(o.material) ? o.material : [o.material];
        ms.forEach(function (m) { fadeMaterial(m, panelTarget); });
      });
    }
    frameScene(1.25 + f * 0.15);
  }

  const explodeSlider = document.getElementById('explode');
  explodeSlider.addEventListener('input', function () {
    explodeFactor = parseFloat(explodeSlider.value);
    applyExplosion();
  });

  function setExplode(f) {
    explodeFactor = f;
    explodeSlider.value = String(f);
    applyExplosion();
  }

  // ---------- Motion: spinning fans + slow hue drift on RGB accents ----------
  tickFns.push(function () {
    const t = performance.now() / 8000;
    fanSpins.forEach(function (s) { s.rotation.z += 0.12; });
    rgbMats.forEach(function (m, i) {
      const c = m.emissive ? m.emissive : m.color;
      c.setHSL((t + i * 0.13) % 1, 0.55, 0.6);
    });
  });

  // ==================================================================
  // Task 5: hover highlight, focus glide, spec placard
  // ==================================================================

  const raycaster = new THREE.Raycaster();
  const pointerNdc = new THREE.Vector2();
  const hoverTag = document.getElementById('hoverTag');
  const card = document.getElementById('card');
  const cardName = document.getElementById('cardName');
  const cardRole = document.getElementById('cardRole');
  const cardSpecs = document.getElementById('cardSpecs');

  function resolvePartGroup(obj) {
    let o = obj;
    while (o) {
      if (o.userData && o.userData.isPart) return o;
      o = o.parent;
    }
    return null;
  }

  function pickAt(clientX, clientY) {
    pointerNdc.x = (clientX / window.innerWidth) * 2 - 1;
    pointerNdc.y = -(clientY / window.innerHeight) * 2 + 1;
    raycaster.setFromCamera(pointerNdc, camera);
    const hits = raycaster.intersectObjects(world.children, true);
    for (let i = 0; i < hits.length; i++) {
      if (hits[i].object.userData.noRay) continue;
      const g = resolvePartGroup(hits[i].object);
      if (g) return g;
    }
    return null;
  }

  // ---------- Camera target easing ----------
  const HOME_TARGET = new THREE.Vector3(0, 0, 0);
  const goalTarget = HOME_TARGET.clone();
  tickFns.push(function () {
    controls.target.lerp(goalTarget, 0.08);
  });

  // ---------- Opacity fades (hand-rolled per-frame lerp) ----------
  const fades = new Map();

  function fadeMaterial(m, target) {
    if (m.userData.origOpacity === undefined) {
      m.userData.origOpacity = m.opacity;
      m.userData.origTransparent = m.transparent;
    }
    m.transparent = true;
    fades.set(m, target);
  }

  function setGroupFade(g, dim) {
    g.traverse(function (o) {
      if (!o.isMesh) return;
      const ms = Array.isArray(o.material) ? o.material : [o.material];
      ms.forEach(function (m) {
        if (dim) fadeMaterial(m, o.userData.noRay ? 0.05 : 0.15);
        else fadeMaterial(m, m.userData.origOpacity === undefined ? 1 : m.userData.origOpacity);
      });
    });
  }

  tickFns.push(function () {
    fades.forEach(function (target, m) {
      m.opacity += (target - m.opacity) * 0.12;
      if (Math.abs(m.opacity - target) < 0.01) {
        m.opacity = target;
        if (!m.userData.origTransparent && m.opacity >= m.userData.origOpacity - 0.001) {
          m.transparent = false;
        }
        fades.delete(m);
      }
    });
  });

  // ---------- Hover ----------
  let hovered = null;
  const hoverSaved = new Map();

  function clearHover() {
    hoverSaved.forEach(function (saved, m) {
      m.emissive.setHex(saved.hex);
      m.emissiveIntensity = saved.intensity;
    });
    hoverSaved.clear();
    hovered = null;
    hoverTag.style.display = 'none';
    document.body.style.cursor = '';
  }

  function setHover(g, clientX, clientY) {
    if (g !== hovered) {
      clearHover();
      hovered = g;
      if (g) {
        g.traverse(function (o) {
          if (!o.isMesh || o.userData.noRay) return;
          const ms = Array.isArray(o.material) ? o.material : [o.material];
          ms.forEach(function (m) {
            if (!m.emissive) return; // MeshBasicMaterial fan rings have no emissive
            hoverSaved.set(m, { hex: m.emissive.getHex(), intensity: m.emissiveIntensity });
            m.emissive.set('#2e6950');
            m.emissiveIntensity = 0.18;
          });
        });
        const p = PARTS.find(function (pp) { return pp.partKey === g.userData.partKey; });
        hoverTag.textContent = p ? p.name : '';
        hoverTag.style.display = 'block';
        document.body.style.cursor = 'pointer';
      }
    }
    if (hovered) {
      hoverTag.style.left = clientX + 'px';
      hoverTag.style.top = clientY + 'px';
    }
  }

  // ---------- Live content from the HardwareComponents table (by PartKey) ----------
  (function () {
    const hq = window.HQ_PARTS || {};
    PARTS.forEach(function (p) {
      const o = hq[p.partKey];
      if (!o) return;
      if (o.name) p.name = o.name;
      if (o.desc) p.role = o.desc;
      if (o.url) p.url = o.url;
    });
  })();

  // ---------- Focus ----------
  let focused = null;
  let prevExplode = 0;

  function focusPart(g) {
    if (g === focused) return;
    if (!focused) prevExplode = explodeFactor;
    focused = g;
    clearHover();

    partGroups.forEach(function (pg) {
      setGroupFade(pg, pg !== g);
    });

    // Glide the camera to the part.
    const sphere = new THREE.Sphere();
    new THREE.Box3().setFromObject(g).getBoundingSphere(sphere);
    goalTarget.copy(sphere.center);
    goalDist = THREE.MathUtils.clamp(sphere.radius * 4.2, controls.minDistance, controls.maxDistance);

    // Fill and show the spec placard.
    const p = PARTS.find(function (pp) { return pp.partKey === g.userData.partKey; });
    if (p) {
      cardName.textContent = p.name;
      cardRole.textContent = p.role;
      cardSpecs.innerHTML = '';
      p.specs.forEach(function (s) {
        const li = document.createElement('li');
        li.textContent = s;
        cardSpecs.appendChild(li);
      });
      const learn = document.getElementById('cardLearn');
      if (p.url) { learn.href = p.url; learn.style.display = 'inline-block'; }
      else { learn.style.display = 'none'; }
    }
    card.style.display = 'block';
  }

  function clearFocus() {
    if (!focused) return;
    focused = null;
    partGroups.forEach(function (pg) { setGroupFade(pg, false); });
    goalTarget.copy(HOME_TARGET);
    explodeFactor = prevExplode;
    explodeSlider.value = String(prevExplode);
    applyExplosion();
    card.style.display = 'none';
    speechSynthesis.cancel();
  }

  document.getElementById('cardClose').addEventListener('click', clearFocus);

  document.getElementById('cardListen').addEventListener('click', function () {
    const g = focused;
    if (!g) return;
    const p = PARTS.find(function (pp) { return pp.partKey === g.userData.partKey; });
    if (!p) return;
    speechSynthesis.cancel();
    speechSynthesis.speak(new SpeechSynthesisUtterance(p.name + '. ' + p.role + ' ' + p.specs.join('. ')));
  });

  // ---------- Pointer events ----------
  renderer.domElement.addEventListener('pointermove', function (e) {
    if (focused) { setHover(null, e.clientX, e.clientY); return; }
    setHover(pickAt(e.clientX, e.clientY), e.clientX, e.clientY);
  });

  let downX = 0, downY = 0;
  renderer.domElement.addEventListener('pointerdown', function (e) {
    downX = e.clientX;
    downY = e.clientY;
  });

  renderer.domElement.addEventListener('pointerup', function (e) {
    if (Math.abs(e.clientX - downX) > 6 || Math.abs(e.clientY - downY) > 6) return; // drag, not click
    const g = pickAt(e.clientX, e.clientY);
    if (g) focusPart(g);
    else clearFocus();
  });

  // ==================================================================
  // Task 6: gallery leader-line callouts in the exploded view
  // ==================================================================

  const calloutContainer = document.getElementById('callouts');
  const calloutItems = [];

  // Build one callout (label div + SVG hairline) per DB-backed part + cooler,
  // anchored to the first registered group carrying that key. Side is chosen
  // by the part's fully-exploded x position so labels sit clear of the model.
  function buildCallouts() {
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    calloutContainer.appendChild(svg);

    ['cpu', 'cooler', 'ram', 'motherboard', 'gpu', 'ssd', 'psu'].forEach(function (key) {
      const group = partGroups.find(function (g) { return g.userData.partKey === key; });
      const p = PARTS.find(function (pp) { return pp.partKey === key; });
      if (!group || !p || !group.userData.home) return;

      const explodedX = group.userData.home.x + group.userData.dir.x * SPREAD;
      const side = explodedX >= 0 ? 'right' : 'left';

      const el = document.createElement('div');
      el.className = 'callout ' + side;
      el.textContent = p.name.split(' — ')[0];
      el.style.display = 'none';
      calloutContainer.appendChild(el);

      const line = document.createElementNS('http://www.w3.org/2000/svg', 'line');
      line.setAttribute('stroke', '#8a8a86');
      line.setAttribute('stroke-width', '1');
      svg.appendChild(line);

      calloutItems.push({ group: group, el: el, line: line, side: side });
    });
  }

  const calloutSphere = new THREE.Sphere();
  const calloutBox = new THREE.Box3();
  const calloutVec = new THREE.Vector3();

  function updateCallouts() {
    const show = explodeFactor > 0.5 && !focused;
    const alpha = show ? (explodeFactor - 0.5) * 2 : 0;
    calloutContainer.style.opacity = String(alpha);
    calloutItems.forEach(function (it) {
      if (alpha <= 0) {
        it.el.style.display = 'none';
        it.line.setAttribute('stroke-opacity', '0');
        return;
      }
      calloutBox.setFromObject(it.group).getBoundingSphere(calloutSphere);
      calloutVec.copy(calloutSphere.center).project(camera);
      if (calloutVec.z > 1) { // behind the camera
        it.el.style.display = 'none';
        it.line.setAttribute('stroke-opacity', '0');
        return;
      }
      const ax = (calloutVec.x + 1) / 2 * window.innerWidth;
      const ay = (-calloutVec.y + 1) / 2 * window.innerHeight;
      const lx = ax + (it.side === 'right' ? 70 : -70);

      it.el.style.display = 'block';
      it.el.style.top = ay + 'px';
      if (it.side === 'right') {
        it.el.style.left = lx + 'px';
        it.el.style.right = 'auto';
      } else {
        it.el.style.right = (window.innerWidth - lx) + 'px';
        it.el.style.left = 'auto';
      }

      it.line.setAttribute('x1', String(ax));
      it.line.setAttribute('y1', String(ay));
      it.line.setAttribute('x2', String(lx));
      it.line.setAttribute('y2', String(ay));
      it.line.setAttribute('stroke-opacity', '1');
    });
  }

  tickFns.push(updateCallouts);

  // ---------- Build everything ----------
  buildCase();
  assemble();
  frameScene();
  buildCallouts();

  // ==================================================================
  // Task 7: hand tracking with skeleton preview and openness meter
  // ==================================================================
  // Pipeline and thresholds ported verbatim from the user-tested
  // explorer-prototype.html: openness = mean fingertip distance from the
  // wrist normalised by hand size, mapped 0.85..1.75 with alpha-0.25
  // smoothing; pinch = thumb+index < 0.30 x hand size while the other three
  // fingers stay extended, release at 0.45, 700 ms cooldown. ANY failure
  // degrades to slider-only and can never crash the page.

  const toastEl = document.getElementById('toast');
  let toastTimer = null;

  function showToast(msg) {
    toastEl.textContent = msg;
    toastEl.style.display = 'block';
    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () { toastEl.style.display = 'none'; }, 4200);
  }

  const camBtn = document.getElementById('camBtn');
  const handPanel = document.getElementById('handPanel');
  const handVideo = document.getElementById('handVideo');
  const handOverlay = document.getElementById('handOverlay');
  const openFill = document.getElementById('openFill');
  const cursorDot = document.getElementById('cursorDot');
  const gestureGuide = document.getElementById('gestureGuide');
  const ggPick = document.getElementById('ggPick');
  const ggSpin = document.getElementById('ggSpin');

  const MP_VERSION = '0.10.14';
  const FIST_RATIO = 0.85, OPEN_RATIO = 1.75;   // raw openness calibration
  const SMOOTH_A = 0.25;                        // exponential smoothing alpha
  const PINCH_DOWN = 0.22, PINCH_UP = 0.30;     // hysteresis (x hand size)
  const PINCH_COOLDOWN_MS = 700;
  const DRAG_START_PX = 14;                     // pinch dead-zone (hands jitter more than mice)
  const ROT_SPEED = 0.008;                      // orbit radians per cursor px

  // Bone segments of MediaPipe's 21-landmark hand model.
  const HAND_BONES = [
    [0, 1], [1, 2], [2, 3], [3, 4],
    [0, 5], [5, 6], [6, 7], [7, 8],
    [5, 9], [9, 10], [10, 11], [11, 12],
    [9, 13], [13, 14], [14, 15], [15, 16],
    [13, 17], [17, 18], [18, 19], [19, 20],
    [0, 17]
  ];

  let handActive = false, landmarker = null, camStream = null;
  let smoothOpen = 0, lastVideoTime = -1;
  let cursorX = window.innerWidth / 2, cursorY = window.innerHeight / 2, cursorLive = false;
  let pinchHeld = false, lastPinchAt = 0;
  let pinchMoved = false, pinchStartX = 0, pinchStartY = 0, pinchPrevX = 0, pinchPrevY = 0;

  function resetPinch() {
    pinchHeld = false;
    pinchMoved = false;
    cursorDot.classList.remove('pinch');
    ggPick.classList.remove('active');
    ggSpin.classList.remove('active');
  }

  // Orbit the camera around the controls target, matching OrbitControls'
  // drag direction and polar clamp. Radius is left alone (the zoom tick
  // re-applies curDist every frame anyway).
  function orbitBy(dx, dy) {
    const offset = new THREE.Vector3().subVectors(camera.position, controls.target);
    const sph = new THREE.Spherical().setFromVector3(offset);
    sph.theta -= dx * ROT_SPEED;
    sph.phi = THREE.MathUtils.clamp(sph.phi - dy * ROT_SPEED, 0.05, controls.maxPolarAngle);
    offset.setFromSpherical(sph);
    camera.position.copy(controls.target).add(offset);
    camera.lookAt(controls.target);
  }

  camBtn.addEventListener('click', async function () {
    if (handActive) { stopHand(); return; }
    camBtn.disabled = true;
    camBtn.textContent = 'Starting camera…';
    try {
      await startHand();
      camBtn.textContent = 'Stop hand tracking';
      handPanel.style.display = 'block';
      gestureGuide.style.display = 'block';
      showToast('Open your hand to take the PC apart; pinch and move to spin it around.');
    } catch (err) {
      console.warn('Hand tracking unavailable:', err);
      stopHand();       // release anything half-started
      if (/timed out/.test((err && err.message) || '')) {
        // Prompt was ignored — keep the button so the user can try again.
        showToast('Camera permission was not granted. Press the button to try again.');
        camBtn.textContent = 'Enable hand tracking';
      } else {
        disableHandUI(); // denied/unavailable: hide camera UI, slider remains
      }
    } finally {
      camBtn.disabled = false;
    }
  });

  async function startHand() {
    if (!landmarker) {
      const mp = await import('https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@' + MP_VERSION + '/vision_bundle.mjs');
      const files = await mp.FilesetResolver.forVisionTasks(
        'https://cdn.jsdelivr.net/npm/@mediapipe/tasks-vision@' + MP_VERSION + '/wasm');
      landmarker = await mp.HandLandmarker.createFromOptions(files, {
        baseOptions: {
          modelAssetPath: 'https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task',
          delegate: 'GPU'
        },
        runningMode: 'VIDEO',
        numHands: 1
      });
    }
    // Guard with a timeout so an ignored permission prompt can't hang the
    // button forever — the user can always press it again.
    camStream = await Promise.race([
      navigator.mediaDevices.getUserMedia({
        video: { width: 320, height: 240, facingMode: 'user' }
      }),
      new Promise(function (_, reject) {
        setTimeout(function () { reject(new Error('camera permission timed out')); }, 20000);
      })
    ]);
    handVideo.srcObject = camStream;
    await handVideo.play();
    handOverlay.width = handVideo.videoWidth || 320;
    handOverlay.height = handVideo.videoHeight || 240;
    handActive = true;
    requestAnimationFrame(handLoop);
  }

  function stopHand() {
    handActive = false;
    if (camStream) { camStream.getTracks().forEach(function (t) { t.stop(); }); camStream = null; }
    handVideo.srcObject = null;
    handPanel.style.display = 'none';
    gestureGuide.style.display = 'none';
    cursorDot.style.display = 'none';
    cursorLive = false;
    resetPinch();
    camBtn.textContent = 'Enable hand tracking';
  }

  function disableHandUI() {
    camBtn.style.display = 'none'; // gone for this visit; slider remains
    handPanel.style.display = 'none';
    gestureGuide.style.display = 'none';
    showToast('Hand tracking is not available — the slider still works.');
  }

  function handLoop() {
    if (!handActive) return;
    if (handVideo.readyState >= 2 && handVideo.currentTime !== lastVideoTime) {
      lastVideoTime = handVideo.currentTime;
      let result = null;
      try {
        result = landmarker.detectForVideo(handVideo, performance.now());
      } catch (err) {
        console.warn('Hand detection failed:', err);
        stopHand();
        disableHandUI();
        return;
      }
      if (result && result.landmarks && result.landmarks.length > 0) {
        drawSkeleton(result.landmarks[0]);
        processHand(result.landmarks[0]);
      } else {
        handOverlay.getContext('2d').clearRect(0, 0, handOverlay.width, handOverlay.height);
        cursorLive = false;
        cursorDot.style.display = 'none';
        resetPinch(); // hand left the frame mid-pinch: never leave a drag stuck on
      }
    }
    requestAnimationFrame(handLoop);
  }

  // Landmark dots + bone segments on the preview, mirrored like the video.
  function drawSkeleton(lm) {
    const ctx = handOverlay.getContext('2d');
    const w = handOverlay.width, h = handOverlay.height;
    ctx.clearRect(0, 0, w, h);
    ctx.save();
    ctx.translate(w, 0);
    ctx.scale(-1, 1);
    ctx.strokeStyle = '#d8a657';
    ctx.lineWidth = 1.5;
    HAND_BONES.forEach(function (b) {
      ctx.beginPath();
      ctx.moveTo(lm[b[0]].x * w, lm[b[0]].y * h);
      ctx.lineTo(lm[b[1]].x * w, lm[b[1]].y * h);
      ctx.stroke();
    });
    ctx.fillStyle = '#2e6950';
    lm.forEach(function (p) {
      ctx.beginPath();
      ctx.arc(p.x * w, p.y * h, 3, 0, Math.PI * 2);
      ctx.fill();
    });
    ctx.restore();
  }

  function processHand(lm) {
    const dist3 = function (a, b) { return Math.hypot(a.x - b.x, a.y - b.y, a.z - b.z); };
    const size = dist3(lm[0], lm[9]) || 1e-6; // wrist -> middle MCP = hand size

    // --- openness -> explosion factor (drives the same path as the slider)
    const tips = [8, 12, 16, 20];
    const avg = tips.reduce(function (s, t) { return s + dist3(lm[t], lm[0]); }, 0) / tips.length;
    const raw = Math.min(1, Math.max(0, (avg / size - FIST_RATIO) / (OPEN_RATIO - FIST_RATIO)));
    smoothOpen += SMOOTH_A * (raw - smoothOpen);
    openFill.style.width = (smoothOpen * 100).toFixed(1) + '%';
    // Don't fight the focus camera; freeze the explosion while a pinch is
    // held so dragging the hand around can't jiggle it.
    if (!focused && !pinchHeld) setExplode(smoothOpen);

    // --- index fingertip -> on-screen cursor (mirrored to match preview)
    const px = (1 - lm[8].x) * window.innerWidth;
    const py = lm[8].y * window.innerHeight;
    if (!cursorLive) { cursorX = px; cursorY = py; cursorLive = true; }
    cursorX += 0.35 * (px - cursorX);
    cursorY += 0.35 * (py - cursorY);
    cursorDot.style.display = 'block';
    cursorDot.style.left = cursorX + 'px';
    cursorDot.style.top = cursorY + 'px';

    // --- pinch (thumb 4 + index 8) with hysteresis + cooldown.
    //     Require middle/ring/pinky extended so a FIST is not read as a pinch.
    //     Mirrors the mouse's drag-vs-click split: holding the pinch and
    //     moving past a dead-zone orbits the camera; a quick release picks.
    const pinchRatio = dist3(lm[4], lm[8]) / size;
    const othersOpen = (dist3(lm[12], lm[0]) + dist3(lm[16], lm[0]) + dist3(lm[20], lm[0])) / 3 / size > 1.3;
    if (!pinchHeld && pinchRatio < PINCH_DOWN && othersOpen &&
        performance.now() - lastPinchAt > PINCH_COOLDOWN_MS) {
      pinchHeld = true;
      pinchMoved = false;
      lastPinchAt = performance.now();
      pinchStartX = pinchPrevX = cursorX;
      pinchStartY = pinchPrevY = cursorY;
      cursorDot.classList.add('pinch');
      ggPick.classList.add('active');
    } else if (pinchHeld && pinchRatio > PINCH_UP) {
      const wasDrag = pinchMoved;
      resetPinch();
      if (!wasDrag) {
        const g = pickAt(cursorX, cursorY);
        if (g) focusPart(g);
        else clearFocus();
      }
    } else if (pinchHeld) {
      if (!pinchMoved &&
          Math.hypot(cursorX - pinchStartX, cursorY - pinchStartY) > DRAG_START_PX) {
        pinchMoved = true;
        ggPick.classList.remove('active');
        ggSpin.classList.add('active');
      }
      if (pinchMoved) orbitBy(cursorX - pinchPrevX, cursorY - pinchPrevY);
      pinchPrevX = cursorX;
      pinchPrevY = cursorY;
    }
  }

  // Expose for later tasks / debugging.
  window.processHand = processHand;
  window.scene = scene;
  window.camera = camera;
  window.renderer = renderer;
  window.controls = controls;
  window.envMap = envMap;
  window.world = world;
  window.frameScene = frameScene;
  window.tickFns = tickFns;
  window.mat = mat;
  window.box = box;
  window.cyl = cyl;
  window.paintTexture = paintTexture;
  window.PARTS = PARTS;
  window.partGroups = partGroups;
  window.registerPart = registerPart;
  window.buildCase = buildCase;
  window.rgbMats = rgbMats;
  window.buildMotherboard = buildMotherboard;
  window.buildCpu = buildCpu;
  window.buildRam = buildRam;
  window.buildSsd = buildSsd;
  window.buildGpu = buildGpu;
  window.buildPsu = buildPsu;
  window.buildCooler = buildCooler;
  window.buildFan = buildFan;
  window.fanSpins = fanSpins;
  window.applyExplosion = applyExplosion;
  window.setExplode = setExplode;
  window.pickAt = pickAt;
  window.focusPart = focusPart;
  window.clearFocus = clearFocus;
})();
</script>
</body>
</html>
