// 3D component models for Hardware/Details.aspx, extracted from
// prototype/component-workshop.html (which stays frozen as reference).
// Requires the three@0.132.2 global build + OrbitControls to be loaded first.
//
//   HQPartModels.has(key)               -> true when key has a model
//   HQPartModels.mount(containerId,key) -> builds the viewer, false on failure
//
// One viewer per page: mount() resets module state, so call it once.
var HQPartModels = (function () {
  'use strict';

  // ---------------------------------------------------------------------------
  // Shared modelling helpers
  // ---------------------------------------------------------------------------
  function mat(color, opts) {
    return new THREE.MeshStandardMaterial(Object.assign({ color: color, roughness: 0.6, metalness: 0.1 }, opts));
  }
  function metalMat(color, r) {
    return mat(color, { metalness: 0.85, roughness: r === undefined ? 0.3 : r });
  }
  function box(w, h, d, material) {
    var m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d),
      material instanceof THREE.Material ? material : mat(material));
    m.castShadow = true; m.receiveShadow = true; return m;
  }
  function cyl(r, h, material, seg) {
    var m = new THREE.Mesh(new THREE.CylinderGeometry(r, r, h, seg || 24),
      material instanceof THREE.Material ? material : mat(material));
    m.castShadow = true; m.receiveShadow = true; return m;
  }

  // paint a texture on a runtime <canvas> (no external image files)
  function paintTexture(w, h, draw) {
    var c = document.createElement('canvas'); c.width = w; c.height = h;
    draw(c.getContext('2d'), w, h);
    var t = new THREE.CanvasTexture(c);
    t.anisotropy = 4;
    return t;
  }
  // BoxGeometry face order: +x,-x,+y,-y,+z,-z. Build a 6-material array where
  // only `faceIndex` gets the textured material; the rest use `base`.
  function facedMats(faceIndex, texturedMat, base) {
    var out = [];
    for (var i = 0; i < 6; i++) out.push(i === faceIndex ? texturedMat : base);
    return out;
  }

  var spinners = []; // fan blade groups, spun in the animation loop (reset per mount)

  // a cooling fan facing +Z (ring + hub + n pitched blades). Spun in the loop
  // via blades.rotation.z. Callers that need it facing up set fan.rotation.x.
  function makeFan(r, frameColor, bladeColor, n) {
    n = n || 7;
    var fan = new THREE.Group();
    var ring = new THREE.Mesh(new THREE.TorusGeometry(r, r * 0.08, 8, 30), mat(frameColor, { roughness: 0.5 }));
    ring.castShadow = true; fan.add(ring);
    var hub = cyl(r * 0.24, 0.12, 0x0c0e12, 16); hub.rotation.x = Math.PI / 2; fan.add(hub);
    var blades = new THREE.Group();
    for (var i = 0; i < n; i++) {
      var blade = box(r * 0.78, r * 0.5, 0.04, mat(bladeColor, { roughness: 0.45 }));
      blade.position.x = r * 0.48; blade.rotation.x = 0.45; blade.rotation.z = 0.2; // pitch + sweep
      var arm = new THREE.Group(); arm.rotation.z = i * (Math.PI * 2 / n); arm.add(blade);
      blades.add(arm);
    }
    // outer barrier ring tying the blade tips together (axial-tech look)
    var barrier = new THREE.Mesh(new THREE.TorusGeometry(r * 0.88, r * 0.03, 6, 30), mat(bladeColor, { roughness: 0.5 }));
    blades.add(barrier);
    fan.add(blades); fan.userData.blades = blades; spinners.push(fan);
    return fan;
  }

  // a finned metal heatsink (base + parallel fins) — used by VRM/chipset/M.2
  function finnedHeatsink(w, d, fins, color, finAxisZ) {
    var g = new THREE.Group();
    g.add(box(w, 0.1, d, metalMat(color, 0.4)));
    var n = fins, span = (finAxisZ ? d : w) * 0.86, step = span / (n - 1), start = -span / 2;
    for (var i = 0; i < n; i++) {
      var fin = finAxisZ ? box(w * 0.9, 0.34, 0.05, metalMat(color, 0.35))
                         : box(0.05, 0.34, d * 0.9, metalMat(color, 0.35));
      fin.position.set(finAxisZ ? 0 : start + i * step, 0.22, finAxisZ ? start + i * step : 0);
      g.add(fin);
    }
    return g;
  }

  // ---------------------------------------------------------------------------
  // CPU  (chip with metal heat-spreader, engraved lid, gold pads)
  // ---------------------------------------------------------------------------
  function buildCpu() {
    var g = new THREE.Group();
    var TOP = 2, BOT = 3; // +y face index, -y face index

    // --- green substrate (PCB) with a faint solder-mask texture on top ---
    var subTopTex = paintTexture(512, 512, function (ctx, w, h) {
      ctx.fillStyle = '#176b2f'; ctx.fillRect(0, 0, w, h);
      // subtle darker speckle so it isn't flat
      for (var i = 0; i < 1400; i++) {
        ctx.fillStyle = 'rgba(0,0,0,' + (Math.random() * 0.06) + ')';
        ctx.fillRect(Math.random() * w, Math.random() * h, 2, 2);
      }
      // a few faint gold micro-traces near the edges
      ctx.strokeStyle = 'rgba(210,180,90,0.45)'; ctx.lineWidth = 2;
      for (var j = 0; j < 40; j++) {
        var e = 30 + Math.random() * 40, side = j % 4;
        ctx.beginPath();
        if (side === 0) { ctx.moveTo(e, 60 + j * 10); ctx.lineTo(e + 50, 60 + j * 10); }
        else if (side === 1) { ctx.moveTo(w - e, 60 + j * 10); ctx.lineTo(w - e - 50, 60 + j * 10); }
        else if (side === 2) { ctx.moveTo(60 + j * 10, e); ctx.lineTo(60 + j * 10, e + 50); }
        else { ctx.moveTo(60 + j * 10, h - e); ctx.lineTo(60 + j * 10, h - e - 50); }
        ctx.stroke();
      }
      // gold orientation triangle in one corner
      ctx.fillStyle = '#e7c45a';
      ctx.beginPath(); ctx.moveTo(40, 40); ctx.lineTo(95, 40); ctx.lineTo(40, 95); ctx.closePath(); ctx.fill();
    });
    // gold LGA contact pads grid on the underside
    var padsTex = paintTexture(512, 512, function (ctx, w, h) {
      ctx.fillStyle = '#0f4f22'; ctx.fillRect(0, 0, w, h);
      var n = 30, m = 26, gx = w / (n + 2), gy = h / (m + 2);
      for (var i = 0; i < n; i++) for (var j = 0; j < m; j++) {
        ctx.fillStyle = '#d9b24a';
        ctx.beginPath(); ctx.arc((i + 1.5) * gx, (j + 1.5) * gy, gx * 0.28, 0, Math.PI * 2); ctx.fill();
      }
    });
    var subMats = [];
    for (var i = 0; i < 6; i++) {
      subMats.push(i === TOP ? new THREE.MeshStandardMaterial({ map: subTopTex, roughness: 0.7 })
                 : i === BOT ? new THREE.MeshStandardMaterial({ map: padsTex, roughness: 0.5, metalness: 0.3 })
                 : mat(0x176b2f, { roughness: 0.7 }));
    }
    var substrate = new THREE.Mesh(new THREE.BoxGeometry(2.6, 0.16, 2.6), subMats);
    substrate.castShadow = true; substrate.receiveShadow = true; g.add(substrate);

    // --- metal heat-spreader (IHS): stepped shape = low shoulders + raised top ---
    var ihsMetal = metalMat(0xc9d2da, 0.28);
    var shoulders = box(2.32, 0.12, 2.32, ihsMetal); shoulders.position.y = 0.14; g.add(shoulders);

    var lidTex = paintTexture(512, 512, function (ctx, w, h) {
      var grd = ctx.createLinearGradient(0, 0, w, h);
      grd.addColorStop(0, '#d7dee5'); grd.addColorStop(0.5, '#eef2f6'); grd.addColorStop(1, '#c4ccd4');
      ctx.fillStyle = grd; ctx.fillRect(0, 0, w, h);
      // engraved-look text (slightly darker than the metal)
      ctx.fillStyle = 'rgba(70,80,92,0.85)';
      ctx.textAlign = 'center';
      ctx.font = 'bold 52px "Segoe UI", sans-serif';
      ctx.fillText('HARDWAREQUEST', w / 2, h * 0.32);
      ctx.font = 'bold 72px "Segoe UI", sans-serif';
      ctx.fillText('HQ-CORE', w / 2, h * 0.52);
      ctx.font = '600 40px "Segoe UI", sans-serif';
      ctx.fillText('i7  -  8 CORES', w / 2, h * 0.66);
      ctx.font = '500 26px "Segoe UI", sans-serif';
      ctx.fillStyle = 'rgba(70,80,92,0.6)';
      ctx.fillText('SR-HQ  3.8GHz  MALAYSIA', w / 2, h * 0.80);
      // diagonal sheen
      ctx.strokeStyle = 'rgba(255,255,255,0.5)'; ctx.lineWidth = 22;
      ctx.beginPath(); ctx.moveTo(-20, 120); ctx.lineTo(w * 0.6, -20); ctx.stroke();
    });
    var lidMats = facedMats(TOP,
      new THREE.MeshStandardMaterial({ map: lidTex, metalness: 0.8, roughness: 0.32 }),
      metalMat(0xd2dae1, 0.3));
    var lid = new THREE.Mesh(new THREE.BoxGeometry(1.9, 0.2, 1.9), lidMats);
    lid.position.y = 0.28; lid.castShadow = true; lid.receiveShadow = true; g.add(lid);

    // tiny chamfer ring (a slightly larger dark plate just under the lid)
    var chamfer = box(2.0, 0.04, 2.0, metalMat(0x9aa4ad, 0.4));
    chamfer.position.y = 0.18; g.add(chamfer);

    // --- surface-mount capacitors scattered on the substrate around the IHS ---
    var capBrown = mat(0x6b4a1f, { roughness: 0.5 });
    var capBlack = mat(0x222831, { roughness: 0.5 });
    var capPositions = [];
    for (var a = 0; a < 7; a++) capPositions.push([1.05, -1.05 + a * 0.35]);
    for (var b = 0; b < 7; b++) capPositions.push([-1.05, -1.05 + b * 0.35]);
    for (var c = 0; c < 5; c++) capPositions.push([-0.8 + c * 0.4, 1.08]);
    capPositions.forEach(function (p, idx) {
      var cap = box(0.16, 0.12, 0.1, idx % 3 === 0 ? capBlack : capBrown);
      cap.position.set(p[0], 0.12, p[1]); g.add(cap);
    });

    return g;
  }

  // ---------------------------------------------------------------------------
  // MOTHERBOARD  (ATX board laid flat: socket, RAM, VRM, PCIe, chipset, M.2,
  //   rear I/O, 24-pin ATX, SATA, caps, CMOS battery)
  // ---------------------------------------------------------------------------
  function buildMotherboard() {
    var g = new THREE.Group();
    var TOP = 2, Y = 0.07;
    var add = function (mesh, x, y, z) { mesh.position.set(x, y, z); g.add(mesh); return mesh; };
    // Bigger board (5.6 x 5.2) so everything has breathing room between it.
    var BW = 5.6, BD = 5.2;

    // --- PCB with painted traces + silkscreen labels (top face only) ---
    var pcbTex = paintTexture(1024, 940, function (ctx, w, h) {
      ctx.fillStyle = '#15592c'; ctx.fillRect(0, 0, w, h);
      for (var i = 0; i < 700; i++) { ctx.fillStyle = 'rgba(0,0,0,' + (Math.random() * 0.05) + ')'; ctx.fillRect(Math.random() * w, Math.random() * h, 6, 6); }
      ctx.strokeStyle = 'rgba(213,178,74,0.4)'; ctx.lineWidth = 2;
      for (var j = 0; j < 110; j++) {
        var x = Math.random() * w, y = Math.random() * h; ctx.beginPath(); ctx.moveTo(x, y);
        for (var s = 0; s < 4; s++) { if (Math.random() < 0.5) x += (Math.random() < 0.5 ? -1 : 1) * (20 + Math.random() * 120); else y += (Math.random() < 0.5 ? -1 : 1) * (20 + Math.random() * 120); ctx.lineTo(x, y); }
        ctx.stroke();
        ctx.fillStyle = 'rgba(213,178,74,0.55)'; ctx.beginPath(); ctx.arc(x, y, 3, 0, 7); ctx.fill();
      }
      ctx.fillStyle = 'rgba(255,255,255,0.85)'; ctx.font = 'bold 24px "Segoe UI"'; ctx.textAlign = 'left';
      ctx.fillText('HARDWAREQUEST  HQ-B650', 60, 70);
    });
    var board = new THREE.Mesh(new THREE.BoxGeometry(BW, 0.12, BD),
      facedMats(TOP, new THREE.MeshStandardMaterial({ map: pcbTex, roughness: 0.65 }), mat(0x10401f, { roughness: 0.7 })));
    board.castShadow = true; board.receiveShadow = true; g.add(board);

    // --- CPU socket: metal retention frame + dark LGA bed + tension lever ---
    var sockX = -0.2, sockZ = -1.15;
    add(box(1.6, 0.12, 1.6, metalMat(0x9aa4ad, 0.4)), sockX, Y + 0.06, sockZ);
    var lgaTex = paintTexture(256, 256, function (ctx, w, h) {
      ctx.fillStyle = '#0c0f12'; ctx.fillRect(0, 0, w, h);
      var n = 22, gx = w / (n + 1);
      for (var i = 0; i < n; i++) for (var j = 0; j < n; j++) { ctx.fillStyle = '#caa64a'; ctx.fillRect(i * gx + gx * 0.5, j * gx + gx * 0.5, gx * 0.4, gx * 0.4); }
    });
    add(new THREE.Mesh(new THREE.BoxGeometry(1.2, 0.14, 1.2), facedMats(TOP, new THREE.MeshStandardMaterial({ map: lgaTex, roughness: 0.5, metalness: 0.4 }), mat(0x0c0f12))), sockX, Y + 0.07, sockZ);
    add(box(0.08, 0.18, 1.4, metalMat(0x70797f, 0.4)), sockX - 0.9, Y + 0.09, sockZ); // lever bar

    // --- VRM heatsinks: one along the top edge, one down the left of the socket
    var vTop = finnedHeatsink(1.5, 0.55, 9, 0x3b424a, false); g.add(vTop); vTop.position.set(-0.2, Y + 0.05, -2.35);
    var vLeft = finnedHeatsink(0.55, 1.3, 7, 0x3b424a, true); g.add(vLeft); vLeft.position.set(-1.45, Y + 0.05, -1.15);

    // --- 4 RAM (DIMM) slots, well spaced, to the right of the socket ---
    for (var d = 0; d < 4; d++) {
      var x = 1.0 + d * 0.46;
      add(box(0.24, 0.34, 2.5, mat(0x1c1f24)), x, Y + 0.17, -0.3);
      add(box(0.24, 0.06, 2.5, mat(d % 2 ? 0x3a86ff : 0xff5d8f)), x, Y + 0.36, -0.3); // colour accent
      [-1.55, 0.95].forEach(function (z) { add(box(0.28, 0.4, 0.2, mat(0xdfe4ea)), x, Y + 0.2, z); }); // end clips
    }

    // --- rear I/O: plastic shroud + metal port block along the left edge ---
    add(box(0.5, 0.7, 2.4, mat(0x16191c)), -2.45, Y + 0.35, -0.7);              // shroud cap
    add(box(0.46, 0.55, 2.4, metalMat(0xaeb6bf, 0.4)), -2.35, Y + 0.3, -0.7);   // port plate
    for (var p = 0; p < 5; p++) add(box(0.12, 0.18, 0.3, mat(0x0d0f12)), -2.27, Y + 0.3, -1.6 + p * 0.45); // port holes

    // --- 24-pin ATX power connector on the right edge (clear of the RAM) ---
    add(box(0.42, 0.62, 1.4, mat(0xf2f3f5)), 2.55, Y + 0.31, 1.6);
    for (var r = 0; r < 2; r++) for (var cc = 0; cc < 11; cc++) add(box(0.07, 0.1, 0.07, mat(0xcaa64a)), 2.49 + r * 0.12, Y + 0.6, 1.0 + cc * 0.11);

    // --- PCIe slots (armored x16 + a short x1) in the lower half ---
    add(box(2.4, 0.22, 0.34, metalMat(0xaeb6bf, 0.4)), -0.55, Y + 0.13, 0.5); // armored x16
    add(box(2.4, 0.05, 0.12, mat(0x3a86ff)), -0.55, Y + 0.26, 0.5);
    add(box(1.2, 0.2, 0.3, mat(0x14181d)), -1.15, Y + 0.12, 2.1);             // short x1

    // --- M.2 SSD heatsink between the PCIe slots (branded strip) ---
    var m2Tex = paintTexture(512, 128, function (ctx, w, h) { var gd = ctx.createLinearGradient(0, 0, w, 0); gd.addColorStop(0, '#3a424b'); gd.addColorStop(1, '#1f242a'); ctx.fillStyle = gd; ctx.fillRect(0, 0, w, h); ctx.fillStyle = '#cfd6dd'; ctx.font = 'bold 34px "Segoe UI"'; ctx.textAlign = 'center'; ctx.fillText('M.2  SHIELD', w / 2, h * 0.62); });
    add(new THREE.Mesh(new THREE.BoxGeometry(2.2, 0.12, 0.55), facedMats(TOP, new THREE.MeshStandardMaterial({ map: m2Tex, metalness: 0.6, roughness: 0.4 }), metalMat(0x2a3036, 0.4))), -0.6, Y + 0.06, 1.35);

    // --- chipset heatsink (branded) lower-right ---
    var chipTex = paintTexture(256, 256, function (ctx, w, h) { ctx.fillStyle = '#2c333b'; ctx.fillRect(0, 0, w, h); ctx.fillStyle = '#3a86ff'; ctx.font = 'bold 40px "Segoe UI"'; ctx.textAlign = 'center'; ctx.fillText('HQ', w / 2, h * 0.55); });
    add(new THREE.Mesh(new THREE.BoxGeometry(1.0, 0.2, 1.0), facedMats(TOP, new THREE.MeshStandardMaterial({ map: chipTex, metalness: 0.6, roughness: 0.4 }), metalMat(0x2c333b, 0.4))), 1.05, Y + 0.1, 2.0);

    // --- SATA ports (right edge, between RAM and ATX) ---
    for (var s2 = 0; s2 < 4; s2++) add(box(0.3, 0.26, 0.16, mat(s2 < 2 ? 0xff5d8f : 0x14181d)), 2.55, Y + 0.13, -0.9 + s2 * 0.3);

    // --- CMOS coin battery + a few electrolytic capacitors in clear spots ---
    var bat = cyl(0.24, 0.06, metalMat(0xdfe4ea, 0.25), 24); bat.rotation.x = Math.PI / 2; add(bat, 0.4, Y + 0.08, 2.1);
    [[-2.2, 2.1], [-1.7, 2.2], [2.1, -2.1], [0.3, -2.1]].forEach(function (pos) {
      var cap = cyl(0.14, 0.42, mat(0x14181d), 16); add(cap, pos[0], Y + 0.21, pos[1]);
      add(box(0.2, 0.02, 0.2, mat(0xaeb6bf)), pos[0], Y + 0.43, pos[1]);
    });

    return g;
  }

  // ---------------------------------------------------------------------------
  // RAM  (DIMM standing on its gold pins: PCB, heat spreader with brand,
  //   glowing RGB diffuser bar on top, notched gold edge connector)
  // ---------------------------------------------------------------------------
  function buildRam() {
    var g = new THREE.Group();
    var add = function (mesh, x, y, z) { mesh.position.set(x, y, z); g.add(mesh); return mesh; };

    add(box(4, 1.2, 0.1, mat(0x125e2c, { roughness: 0.6 })), 0, 0.7, 0); // PCB
    // notched gold edge connector along the bottom
    add(box(1.6, 0.24, 0.13, mat(0xcaa64a)), -1.05, 0.07, 0);
    add(box(1.9, 0.24, 0.13, mat(0xcaa64a)), 1.0, 0.07, 0);
    // heat spreaders on both sides (brand on the front face = +z, index 4)
    var spTex = paintTexture(512, 160, function (ctx, w, h) {
      var gd = ctx.createLinearGradient(0, 0, 0, h); gd.addColorStop(0, '#3a414a'); gd.addColorStop(1, '#22272d');
      ctx.fillStyle = gd; ctx.fillRect(0, 0, w, h); ctx.textAlign = 'center';
      ctx.fillStyle = '#e9edf2'; ctx.font = 'bold 42px "Segoe UI"'; ctx.fillText('HARDWAREQUEST', w / 2, h * 0.4);
      ctx.fillStyle = '#ff5d8f'; ctx.font = 'bold 38px "Segoe UI"'; ctx.fillText('FURY RGB  16GB', w / 2, h * 0.82);
    });
    add(new THREE.Mesh(new THREE.BoxGeometry(3.9, 1.05, 0.09),
      facedMats(4, new THREE.MeshStandardMaterial({ map: spTex, metalness: 0.6, roughness: 0.4 }), metalMat(0x2a2f37, 0.45))), 0, 0.78, 0.1);
    add(box(3.9, 1.05, 0.09, metalMat(0x2a2f37, 0.45)), 0, 0.78, -0.1);
    // top frame + glowing RGB diffuser bar
    add(box(3.95, 0.14, 0.32, mat(0x16191c)), 0, 1.25, 0);
    add(box(3.8, 0.18, 0.26, new THREE.MeshStandardMaterial({ color: 0xffffff, emissive: 0x8fb6ff, emissiveIntensity: 0.85 })), 0, 1.37, 0);
    return g;
  }

  // ---------------------------------------------------------------------------
  // GPU  (graphics card laid flat, fans up: PCB, backplate brand, shroud,
  //   three spinning fans, fin row, RGB strip, I/O bracket, gold PCIe tab)
  // ---------------------------------------------------------------------------
  function buildGpu() {
    var g = new THREE.Group();
    var add = function (mesh, x, y, z) { mesh.position.set(x, y, z); g.add(mesh); return mesh; };

    var D = 2.4, HF = D / 2, W = 6.0; // long triple-fan card

    // --- PCB + branded backplate underneath ---
    add(box(W, 0.12, D, mat(0x14181d, { roughness: 0.6 })), 0, 0, 0);
    var bpTex = paintTexture(640, 220, function (ctx, w, h) {
      ctx.fillStyle = '#1c2026'; ctx.fillRect(0, 0, w, h);
      ctx.textAlign = 'center'; ctx.fillStyle = '#e9edf2'; ctx.font = 'bold 46px "Segoe UI"';
      ctx.fillText('HARDWAREQUEST', w / 2, h * 0.42);
      ctx.fillStyle = '#ffae3a'; ctx.font = 'bold 40px "Segoe UI"';
      ctx.fillText('TUF  HQ-RTX 5080', w / 2, h * 0.78);
    });
    add(new THREE.Mesh(new THREE.BoxGeometry(W, 0.06, D),
      facedMats(3, new THREE.MeshStandardMaterial({ map: bpTex, metalness: 0.5, roughness: 0.5 }), metalMat(0x1c2026, 0.5))), 0, -0.1, 0);

    // --- dark shroud ---
    add(box(W, 0.5, D, mat(0x14171c, { roughness: 0.55 })), 0, 0.31, 0);

    // --- exposed heatsink fin row along the very back edge ---
    for (var i = 0; i < 46; i++) add(box(0.05, 0.4, 0.14, metalMat(0xb8c0c8, 0.4)), -2.9 + i * 0.13, 0.32, -HF + 0.07);

    // --- gunmetal top accent band + glowing RGB corner ---
    add(box(W, 0.1, 0.2, metalMat(0x4a525c, 0.4)), 0, 0.54, -HF + 0.4);
    add(box(0.7, 0.12, 0.22, new THREE.MeshStandardMaterial({ color: 0xff7b00, emissive: 0xff5a00, emissiveIntensity: 0.8 })), W / 2 - 0.6, 0.56, -HF + 0.4);

    // --- three axial-tech fans (11 blades + barrier ring) with hub logos ---
    var fanZ = 0.28;
    [-2.0, 0, 2.0].forEach(function (x, idx) {
      add(cyl(0.95, 0.06, 0x0c0e12, 32), x, 0.57, fanZ);            // recessed rim
      var f = makeFan(0.9, 0x20242b, 0x2b3038, 11);
      f.rotation.x = -Math.PI / 2; f.position.set(x, 0.62, fanZ); g.add(f);
      var capTex = paintTexture(128, 128, function (ctx, w, h) {
        ctx.fillStyle = '#15181d'; ctx.beginPath(); ctx.arc(w / 2, h / 2, w / 2 - 4, 0, 7); ctx.fill();
        ctx.fillStyle = idx === 1 ? '#ffae3a' : '#cfd6dd'; ctx.font = 'bold 46px "Segoe UI"';
        ctx.textAlign = 'center'; ctx.textBaseline = 'middle'; ctx.fillText('HQ', w / 2, h / 2);
      });
      var cap = new THREE.Mesh(new THREE.CircleGeometry(0.27, 24), new THREE.MeshStandardMaterial({ map: capTex, roughness: 0.5 }));
      cap.rotation.x = -Math.PI / 2; add(cap, x, 0.72, fanZ);
    });

    // --- I/O bracket with display ports at the left end ---
    add(box(0.12, 1.1, D, metalMat(0xb0bec5, 0.4)), -W / 2 - 0.05, 0.2, 0);
    [-0.7, 0.0, 0.7].forEach(function (z) { add(box(0.14, 0.24, 0.42, mat(0x0d0f12)), -W / 2 - 0.12, 0.2, z); });

    // --- gold PCIe connector tab on the bottom front edge ---
    add(box(2.6, 0.16, 0.1, mat(0xcaa64a)), -0.6, -0.12, HF - 0.06);

    return g;
  }

  // ---------------------------------------------------------------------------
  // PSU  (metal box: top fan + wire grille, side spec label, back AC inlet +
  //   switch + honeycomb vent, front modular cable sockets)
  // ---------------------------------------------------------------------------
  function buildPsu() {
    var g = new THREE.Group();
    var add = function (mesh, x, y, z) { mesh.position.set(x, y, z); g.add(mesh); return mesh; };
    var W = 2.6, H = 1.5, D = 2.4;

    // --- body with a spec label on the +x side (face index 0) ---
    var labelTex = paintTexture(512, 300, function (ctx, w, h) {
      ctx.fillStyle = '#1b1f26'; ctx.fillRect(0, 0, w, h);
      ctx.strokeStyle = '#3a86ff'; ctx.lineWidth = 10; ctx.strokeRect(14, 14, w - 28, h - 28);
      ctx.textAlign = 'center';
      ctx.fillStyle = '#e9edf2'; ctx.font = 'bold 50px "Segoe UI"'; ctx.fillText('HARDWAREQUEST', w / 2, h * 0.28);
      ctx.fillStyle = '#ffd166'; ctx.font = 'bold 80px "Segoe UI"'; ctx.fillText('750W', w / 2, h * 0.58);
      ctx.fillStyle = '#e9edf2'; ctx.font = 'bold 40px "Segoe UI"'; ctx.fillText('80+ GOLD', w / 2, h * 0.82);
    });
    var body = new THREE.Mesh(new THREE.BoxGeometry(W, H, D),
      facedMats(0, new THREE.MeshStandardMaterial({ map: labelTex, metalness: 0.5, roughness: 0.5 }), metalMat(0x2a2f37, 0.5)));
    body.castShadow = true; body.receiveShadow = true; body.position.y = H / 2; g.add(body);

    // --- top fan: recess + spinning fan + wire grille (rings + spokes) ---
    var fy = H;
    add(cyl(0.95, 0.06, 0x0c0e12, 32), 0, fy, 0);
    var f = makeFan(0.9, 0x2a2f37, 0xe9edf2); f.rotation.x = -Math.PI / 2; f.position.set(0, fy + 0.05, 0); g.add(f);
    var grille = mat(0x16191c, { metalness: 0.6, roughness: 0.4 });
    [0.32, 0.6, 0.88].forEach(function (r) { var ring = new THREE.Mesh(new THREE.TorusGeometry(r, 0.02, 6, 32), grille); ring.rotation.x = Math.PI / 2; add(ring, 0, fy + 0.12, 0); });
    for (var i = 0; i < 6; i++) { var spoke = box(0.03, 0.02, 1.86, grille); spoke.rotation.y = i * Math.PI / 6; add(spoke, 0, fy + 0.12, 0); }

    // --- back panel (-z): honeycomb exhaust vent + AC inlet + red switch ---
    var ventTex = paintTexture(256, 160, function (ctx, w, h) {
      ctx.fillStyle = '#1b1f26'; ctx.fillRect(0, 0, w, h); ctx.fillStyle = '#0c0e12';
      for (var y = 8; y < h; y += 16) for (var x = ((y / 16) % 2) * 9 + 6; x < w; x += 18) { ctx.beginPath(); ctx.arc(x, y, 5, 0, 7); ctx.fill(); }
    });
    add(new THREE.Mesh(new THREE.BoxGeometry(W - 0.1, H - 0.1, 0.06),
      facedMats(5, new THREE.MeshStandardMaterial({ map: ventTex, roughness: 0.6 }), metalMat(0x22262d, 0.5))), 0, H / 2, -D / 2 - 0.02);
    add(box(0.45, 0.4, 0.14, mat(0x0c0e12)), -0.7, H * 0.42, -D / 2 - 0.06);   // IEC AC inlet
    add(box(0.3, 0.3, 0.12, mat(0xe63946)), -0.12, H * 0.42, -D / 2 - 0.06);   // power switch

    // --- front (+z): modular cable sockets ---
    for (var a = 0; a < 3; a++) for (var b = 0; b < 2; b++) add(box(0.5, 0.22, 0.1, mat(0x0c0e12)), -0.65 + a * 0.65, 0.42 + b * 0.42, D / 2 + 0.02);

    return g;
  }

  // ---------------------------------------------------------------------------
  // SSD  (M.2 NVMe gumstick: PCB, gold edge connector with M-key notch,
  //   printed black label, mounting notch)
  // ---------------------------------------------------------------------------
  function buildSsd() {
    var g = new THREE.Group();
    var add = function (mesh, x, y, z) { mesh.position.set(x, y, z); g.add(mesh); return mesh; };
    var W = 4.2, H = 0.1, D = 1.1;

    // --- green PCB board ---
    var body = box(W, H, D, mat(0x123a22, { roughness: 0.6 }));
    body.position.y = H / 2; g.add(body);

    // --- gold edge connector at the -x end, split by the M-key notch ---
    var goldMat = mat(0xd9b24a, { metalness: 0.6, roughness: 0.35 });
    var gy = H + 0.001;
    add(box(0.5, 0.02, 0.6, goldMat), -W / 2 + 0.27, gy, -0.22);  // long finger block
    add(box(0.5, 0.02, 0.26, goldMat), -W / 2 + 0.27, gy, 0.34);  // short finger block (M-key gap between)
    for (var i = 0; i < 9; i++) add(box(0.52, 0.025, 0.012, mat(0x123a22)), -W / 2 + 0.27, gy, -0.45 + i * 0.1); // finger separations

    // --- printed black label on top (+y face = index 2) ---
    var labelTex = paintTexture(1024, 280, function (ctx, w, h) {
      var gd = ctx.createLinearGradient(0, 0, 0, h); gd.addColorStop(0, '#0e1014'); gd.addColorStop(1, '#1b1f26');
      ctx.fillStyle = gd; ctx.fillRect(0, 0, w, h);
      ctx.textAlign = 'left';
      ctx.fillStyle = 'rgba(255,255,255,0.45)'; ctx.font = '600 16px "Segoe UI"';
      ctx.fillText('WARRANTY VOID IF ANY LABEL OR SCREW IS REMOVED OR BROKEN', 28, 28);
      ctx.fillStyle = '#eef3fb'; ctx.font = 'italic bold 44px "Segoe UI"'; ctx.fillText('HARDWAREQUEST', 24, 110);
      ctx.fillStyle = 'rgba(255,255,255,0.5)'; ctx.font = '600 18px "Segoe UI"';
      ctx.fillText('CE   FCC   RoHS', 28, 152);
      ctx.fillText('P/N: HQ-GM7-1TB', 28, 187);
      ctx.fillText('S/N: 0000 0000 0000 0000', 28, 217);
      ctx.fillText('DC: 2026', 28, 247);
      ctx.textAlign = 'right'; ctx.fillStyle = '#cfe3ff'; ctx.font = 'bold 76px "Segoe UI"'; ctx.fillText('GM7', w - 40, 112);
      ctx.fillStyle = '#ffffff'; ctx.fillRect(w - 330, 150, 300, 80);
      ctx.fillStyle = '#000'; for (var x = w - 322; x < w - 44; x += 4 + Math.random() * 5) ctx.fillRect(x, 158, 2 + Math.random() * 3, 56);
      ctx.font = '600 15px "Segoe UI"'; ctx.textAlign = 'center'; ctx.fillText('HQ GM7 1TB NVMe', w - 180, 250);
    });
    var label = new THREE.Mesh(new THREE.BoxGeometry(3.4, 0.04, 0.98),
      facedMats(2, new THREE.MeshStandardMaterial({ map: labelTex, roughness: 0.55 }), mat(0x14181d)));
    label.castShadow = true; add(label, 0.32, H + 0.02, 0);

    // --- semicircular mounting notch hint at the +x end ---
    add(cyl(0.12, 0.12, mat(0x0d0f12), 16), W / 2 - 0.05, H / 2, 0);

    return g;
  }

  // ---------------------------------------------------------------------------
  // CASE  (mid-tower: steel shell, glass side panel, front mesh + RGB strip +
  //   power button/USB, rear I/O + PCI slots + PSU cutout, feet)
  // ---------------------------------------------------------------------------
  function buildCase() {
    var g = new THREE.Group();
    var add = function (mesh, x, y, z) { mesh.position.set(x, y, z); g.add(mesh); return mesh; };
    var W = 2.0, H = 3.2, D = 2.6;
    var steel = metalMat(0x2a2f37, 0.5);
    var dark = mat(0x16191c, { roughness: 0.6 });
    var glassMat = new THREE.MeshStandardMaterial({ color: 0x9fd0ff, transparent: true, opacity: 0.18, roughness: 0.05, side: THREE.DoubleSide });

    // --- steel shell (open on the +x side for the glass) ---
    add(box(W, 0.12, D, steel), 0, 0.06, 0);          // bottom
    add(box(W, 0.12, D, steel), 0, H - 0.06, 0);      // top
    add(box(W, H, 0.12, steel), 0, H / 2, -D / 2 + 0.06);   // back
    add(box(0.12, H, D, steel), -W / 2 + 0.06, H / 2, 0);   // left side

    // --- tempered-glass side panel (+x) ---
    add(new THREE.Mesh(new THREE.BoxGeometry(0.05, H - 0.4, D - 0.4), glassMat), W / 2 - 0.06, H / 2, 0);

    // --- front mesh panel (+z = index 4) + RGB strip + power button + USB ---
    var meshTex = paintTexture(256, 384, function (ctx, w, h) {
      ctx.fillStyle = '#1b1f26'; ctx.fillRect(0, 0, w, h); ctx.fillStyle = '#0c0e12';
      for (var y = 10; y < h; y += 14) for (var x = ((y / 14) % 2) * 7 + 5; x < w; x += 14) { ctx.beginPath(); ctx.arc(x, y, 4, 0, 7); ctx.fill(); }
    });
    add(new THREE.Mesh(new THREE.BoxGeometry(W, H, 0.12), facedMats(4, new THREE.MeshStandardMaterial({ map: meshTex, roughness: 0.6 }), dark)), 0, H / 2, D / 2 - 0.06);
    add(box(0.1, H - 0.5, 0.05, new THREE.MeshStandardMaterial({ color: 0x54d6a0, emissive: 0x2fae82, emissiveIntensity: 0.7 })), -W / 2 + 0.22, H / 2, D / 2 - 0.01);
    var pwr = cyl(0.09, 0.1, new THREE.MeshStandardMaterial({ color: 0x06d6a0, emissive: 0x06d6a0, emissiveIntensity: 0.8 }), 16);
    pwr.rotation.x = Math.PI / 2; add(pwr, 0.3, H - 0.35, D / 2 - 0.01);
    for (var i = 0; i < 2; i++) add(box(0.16, 0.09, 0.05, mat(0xb0bec5, { metalness: 0.6 })), -0.1 + i * 0.26, H - 0.35, D / 2 - 0.01);

    // --- rear details: I/O cutout, PCI slot covers, PSU cutout ---
    add(box(0.7, 0.5, 0.05, dark), -0.45, H - 0.55, -D / 2);
    for (var j = 0; j < 4; j++) add(box(0.7, 0.14, 0.05, metalMat(0xaeb6bf, 0.4)), 0.25, H - 1.15 - j * 0.2, -D / 2);
    add(box(1.1, 0.6, 0.05, dark), 0, 0.55, -D / 2);

    // --- four feet ---
    [-1, 1].forEach(function (fx) { [-1, 1].forEach(function (fz) { add(box(0.3, 0.12, 0.3, dark), fx * (W / 2 - 0.25), -0.06, fz * (D / 2 - 0.25)); }); });

    return g;
  }

  // ---------------------------------------------------------------------------
  // Registry + viewer
  // ---------------------------------------------------------------------------
  var BUILDERS = {
    cpu: buildCpu,
    motherboard: buildMotherboard,
    ram: buildRam,
    gpu: buildGpu,
    psu: buildPsu,
    ssd: buildSsd,
    'case': buildCase
  };

  function has(key) {
    return !!(key && BUILDERS[String(key).trim().toLowerCase()]);
  }

  var VIEW_HEIGHT = 420;

  // Builds the whole viewer (renderer, lights, floor, controls, model, loop)
  // inside the given container div. Returns false on any failure so the page
  // can fall back to the static photo.
  function mount(containerId, key) {
    try {
      var builder = key && BUILDERS[String(key).trim().toLowerCase()];
      var container = document.getElementById(containerId);
      if (!builder || !container || typeof THREE === 'undefined') return false;

      spinners.length = 0;

      var canvas = document.createElement('canvas');
      container.appendChild(canvas);
      var renderer = new THREE.WebGLRenderer({ canvas: canvas, antialias: true });
      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
      renderer.setSize(container.clientWidth, VIEW_HEIGHT);
      renderer.shadowMap.enabled = true;
      renderer.shadowMap.type = THREE.PCFSoftShadowMap;
      renderer.outputEncoding = THREE.sRGBEncoding;
      renderer.toneMapping = THREE.ACESFilmicToneMapping;
      renderer.toneMappingExposure = 1.05;

      var scene = new THREE.Scene();

      // vertical gradient backdrop (painted on a canvas, no files needed)
      scene.background = (function () {
        var c = document.createElement('canvas'); c.width = 2; c.height = 256;
        var g = c.getContext('2d').createLinearGradient(0, 0, 0, 256);
        g.addColorStop(0, '#eef5ff'); g.addColorStop(1, '#bcd0e8');
        var ctx = c.getContext('2d'); ctx.fillStyle = g; ctx.fillRect(0, 0, 2, 256);
        return new THREE.CanvasTexture(c);
      })();

      var camera = new THREE.PerspectiveCamera(45, container.clientWidth / VIEW_HEIGHT, 0.1, 100);
      camera.position.set(3.4, 2.8, 4.6);

      var controls = new THREE.OrbitControls(camera, renderer.domElement);
      controls.enableDamping = true;
      controls.target.set(0, 0.25, 0);
      controls.autoRotate = true;
      controls.autoRotateSpeed = 0.9;
      controls.minDistance = 2;
      controls.maxDistance = 14;

      // resume the gentle spin a few seconds after the child stops interacting
      var idleTimer = null;
      controls.addEventListener('start', function () {
        controls.autoRotate = false;
        clearTimeout(idleTimer);
      });
      controls.addEventListener('end', function () {
        clearTimeout(idleTimer);
        idleTimer = setTimeout(function () { controls.autoRotate = true; }, 4000);
      });

      // ---- lights: key (shadow) + fill + warm rim + sky/ground hemisphere ----
      var keyLight = new THREE.DirectionalLight(0xffffff, 1.15);
      keyLight.position.set(5, 9, 6); keyLight.castShadow = true;
      keyLight.shadow.mapSize.set(2048, 2048);
      keyLight.shadow.camera.near = 1; keyLight.shadow.camera.far = 40;
      keyLight.shadow.camera.left = -8; keyLight.shadow.camera.right = 8;
      keyLight.shadow.camera.top = 8; keyLight.shadow.camera.bottom = -8;
      keyLight.shadow.bias = -0.0004;
      scene.add(keyLight);
      var fill = new THREE.DirectionalLight(0xcfe0ff, 0.45); fill.position.set(-6, 3, 4); scene.add(fill);
      var rim = new THREE.DirectionalLight(0xffe6c2, 0.55); rim.position.set(-3, 4, -7); scene.add(rim);
      scene.add(new THREE.HemisphereLight(0xeaf2ff, 0x3a4250, 0.55));

      // ---- ground: soft circular floor that catches the shadow ----
      var floor = new THREE.Mesh(
        new THREE.CircleGeometry(16, 48),
        new THREE.MeshStandardMaterial({ color: 0xe8eef7, roughness: 0.95, metalness: 0 })
      );
      floor.rotation.x = -Math.PI / 2;
      floor.position.y = -0.12;
      floor.receiveShadow = true;
      scene.add(floor);

      scene.add(builder());

      window.addEventListener('resize', function () {
        camera.aspect = container.clientWidth / VIEW_HEIGHT;
        camera.updateProjectionMatrix();
        renderer.setSize(container.clientWidth, VIEW_HEIGHT);
      });

      (function animate() {
        requestAnimationFrame(animate);
        for (var i = 0; i < spinners.length; i++) spinners[i].userData.blades.rotation.z += 0.12;
        controls.update();
        renderer.render(scene, camera);
      })();

      return true;
    } catch (e) {
      if (window.console && console.error) console.error('HQPartModels.mount failed:', e);
      return false;
    }
  }

  return { has: has, mount: mount };
})();
