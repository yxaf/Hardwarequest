<%@ Page Language="C#" %>
<%--
  ============================================================================
  INSIDE THE MACHINE  —  the guided scroll-story shown to first-time visitors
  ============================================================================

  WHAT THIS PAGE IS
  -----------------
  A standalone, full-screen scrolling story that introduces a PC. It is the
  first thing an anonymous visitor sees: Default.aspx redirects here on a
  first visit (see Default.aspx.cs), then sets Session["IntroSeen"] so the
  story does not replay.

  WHY IT HAS NO CODE-BEHIND AND NO MASTER PAGE
  --------------------------------------------
  Every other content page uses MasterPageFile="~/Site.Master", which wraps
  it in the navbar + centred container. This page declares its own <html>,
  its own <style> and its own fonts instead, because a full-bleed cinematic
  scroll cannot live inside that shell. It is pure markup — there is no
  .aspx.cs and no .designer.cs file. The only server-side code on the whole
  page is the ResolveUrl() call on the back-link below.

  HOW IT WORKS (3 layers stacked on top of each other)
  ----------------------------------------------------
    Layer 1 (z-index 1) .content  — the scrolling text panels (normal HTML)
    Layer 2 (z-index 2) <canvas>  — the three.js 3D model, position:fixed
    Layer 3 (z-index 100) <svg>   — the measuring lines drawn over everything

  Scrolling does not move the 3D model. Scrolling drives a GSAP timeline,
  and that timeline rotates/scales/moves the model. See "MASTER SCROLL
  TIMELINE" at the bottom of this file.

  EXTERNAL LIBRARIES (loaded from CDN — needs internet)
  -----------------------------------------------------
    three.js       builds and renders the 3D model
    GSAP           animation engine
    ScrollTrigger  links scroll position to the animation
    DrawSVGPlugin  draws the measuring lines on (optional — see hasDraw)

  QUICK EDIT INDEX — search for these tags to find things you can change:
    [EDIT: COLOUR]    a colour value
    [EDIT: SIZE]      how big a part is
    [EDIT: POSITION]  where a part sits
    [EDIT: TEXT]      words on screen
    [EDIT: SPEED]     how fast something animates
--%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Inside the Machine - HardwareQuest</title>

  <%-- Fonts come straight from Google, not from Site.Master's bundle.
       [EDIT: TEXT] Swap the family names here to change every font. --%>
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Comfortaa:wght@500;700&family=Quicksand:wght@500;700&display=swap" />
  <style>
    /* ======================================================================
       BLOCK A — THEME VARIABLES
       The two colours and three font sizes the whole page is built from.
       Change these first; everything else follows.
       ====================================================================== */
    :root {
      --color-background: #fff8f0;   /* [EDIT: COLOUR] cream page background   */
      --color-ink: #1f1b10;          /* [EDIT: COLOUR] near-black body text     */
      /* Sizes in vw = they scale with the window on small screens.            */
      --font-large: 8vw; --font-medium: 4vw; --font-normal: 2vw;
    }
    /* Above 800px wide, stop scaling and lock to fixed pixel sizes.           */
    @media (min-width: 800px) { :root { --font-large: 64px; --font-medium: 32px; --font-normal: 17px; } }
    /* Below 500px (phones), shrink further so headings still fit.             */
    @media (max-width: 500px) { :root { --font-large: 40px; --font-medium: 20px; --font-normal: 14px; } }

    /* ======================================================================
       BLOCK B — BASE TYPOGRAPHY AND PAGE SETUP
       ====================================================================== */
    * { box-sizing: border-box; }                 /* padding counts inside width */
    html, body { margin: 0; min-height: 100%; min-width: 100%; font-family: "Quicksand", sans-serif;
      font-weight: 500; font-size: var(--font-normal); color: var(--color-ink);
      background-color: var(--color-background); overflow-x: hidden; }
    /* h1/h2 are the big headline in every panel. display:inline keeps the
       cream/white background tight to the words rather than the full row.    */
    h1, h2 { font-family: "Comfortaa", sans-serif; font-size: var(--font-large); margin: 0 0 2vmin 0; font-weight: 700; display: inline; }
    h3 { font-family: "Comfortaa", sans-serif; font-size: var(--font-medium); font-weight: 500; margin: 0; }
    a { color: #ffe9c9; }                          /* (only .site-back exists, and it overrides this) */
    ul { margin: 0; padding: 0; list-style: none; } li { margin-top: 10px; }

    /* ======================================================================
       BLOCK C — THE THREE STACKED LAYERS
       ====================================================================== */
    /* LAYER 2: the three.js canvas. position:fixed = it never scrolls, it
       just sits there while text scrolls past. pointer-events:none lets
       clicks pass through to the page. It starts hidden and is faded in by
       GSAP once the model is built (see gsap.fromTo('canvas', ...)).         */
    canvas { position: fixed; top: 0; left: 0; z-index: 2; pointer-events: none; visibility: hidden; opacity: 0; }
    /* LAYER 1: the scrolling text.                                           */
    .content { position: relative; z-index: 1; }
    /* Leftover positioning helper — the empty <div class="trigger"> in the
       body. No ScrollTrigger actually references it; harmless.               */
    .trigger { position: absolute; top: 0; height: 100%; }

    /* ONE SCROLL PANEL = exactly one full screen (100vw x 100vh).
       Every <div class="section"> is one "page" of the story, so the number
       of .section divs decides how long the whole scroll is.
       [EDIT: SIZE] --padding controls the margin around the text.            */
    .section { position: relative; --padding: 10vmin; padding: var(--padding);
      width: 100vw; height: 100vh; margin: 0 auto; z-index: 2; }
    .section.right { text-align: right; }   /* used by panel 2 only            */
    .section.dark { color: #eaf4ef; }       /* [EDIT: COLOUR] text on blueprint */
    /* The "Scroll ↓" hint on panel 1. Starts invisible; GSAP fades it in,
       then the timeline fades it back out on the first scroll.               */
    .scroll-cta { position: absolute; bottom: 10vmin; font-size: var(--font-medium); opacity: 0; }

    /* ======================================================================
       BLOCK D — THE BLUEPRINT BACKGROUND (the dark "graph paper" chapter)
       Four stacked linear-gradients fake a grid: two bright lines every
       100px (major grid) and two faint lines every 20px (minor grid).
       background-attachment:fixed keeps the grid still while text scrolls.
       [EDIT: COLOUR] background-color = the navy. The rgba() values are the
       grid line brightness. [EDIT: SIZE] background-size = grid spacing.
       ====================================================================== */
    .blueprint { position: relative; background-color: #0e2630;
      background-image:
        linear-gradient(rgba(255,255,255,0.10) 1px, transparent 1px),   /* major horizontal */
        linear-gradient(90deg, rgba(255,255,255,0.10) 1px, transparent 1px), /* major vertical */
        linear-gradient(rgba(255,255,255,0.05) 1px, transparent 1px),   /* minor horizontal */
        linear-gradient(90deg, rgba(255,255,255,0.05) 1px, transparent 1px); /* minor vertical */
      background-size: 100px 100px, 100px 100px, 20px 20px, 20px 20px;
      background-position: -2px -2px, -2px -2px, -1px -1px, -1px -1px; background-attachment: fixed; }
    /* LAYER 3: the measuring-line overlay. z-index 100 puts it above the
       canvas. [EDIT: COLOUR] stroke = the line colour.                       */
    .blueprint svg { position: fixed; top: 0; left: 0; width: 100vw; height: 100vh;
      stroke: #ffe9c9; pointer-events: none; visibility: hidden; z-index: 100; }

    /* ======================================================================
       BLOCK E — FINALE AND PAGE CHROME
       ====================================================================== */
    /* [EDIT: COLOUR] the green gradient behind the closing panel.            */
    .finale { background: linear-gradient(160deg, #2e6950, #16382b); color: #eaf4ef; }
    /* 40vh bottom margin pushes the closing headline up the screen.          */
    .end h2 { margin-bottom: 40vh; } .credits { position: absolute; bottom: 10vmin; }
    /* Covers the screen until GSAP fades it out — hides the blank frame
       while three.js builds the model.                                       */
    .loading { position: fixed; inset: 0; z-index: 50; display: flex; align-items: center; justify-content: center;
      font-family: "Comfortaa", sans-serif; font-size: var(--font-medium); background: var(--color-background); }
    /* link back to the rest of the site — the ONLY way out of this page,
       because there is no navbar here. [EDIT: COLOUR] color / background.    */
    .site-back { position: fixed; top: 16px; right: 18px; z-index: 200; text-decoration: none;
      font-family: "Comfortaa", sans-serif; font-weight: 700; color: #2e6950;
      background: rgba(255,248,240,0.88); padding: 8px 14px; border-radius: 10px; border: 1px solid #e3d9c6; }
    .site-back:hover { background: #fff; }
  </style>
</head>
<body>

  <%-- The only server-side code on this page. ResolveUrl turns "~/" into the
       correct path whatever folder/virtual directory the app runs under. --%>
  <a class="site-back" href="<%= ResolveUrl("~/Default.aspx") %>">&larr; HardwareQuest</a>

  <!-- ========================================================================
       LAYER 1 — THE SCROLLING STORY
       Each <div class="section"> below is ONE full screen. Reading them top to
       bottom gives you the whole script of the story. Add a .section here and
       the scroll gets one screen longer.
       ======================================================================== -->
  <div class="content">
    <div class="loading">Loading…</div>   <!-- [EDIT: TEXT] -->
    <div class="trigger"></div>           <!-- leftover helper, nothing uses it -->

    <!-- ---------- PANEL 1 — title card. Timeline beat 0. ------------------ -->
    <div class="section">
      <h1>The Computer.</h1>                                    <!-- [EDIT: TEXT] -->
      <h3>A beginner's guide to what's inside.</h3>             <!-- [EDIT: TEXT] -->
      <p>You use one every day — but what's actually in there?</p>
      <div class="scroll-cta">Scroll ↓</div>
    </div>

    <!-- ---------- PANEL 2 — text on the right. Timeline beat 1. ----------- -->
    <div class="section right">
      <h2>A tower full of clever parts.</h2>                    <!-- [EDIT: TEXT] -->
      <p>Liquid cooling, glowing fans, glass panels. Let's look closer.</p>
    </div>

    <!-- ====================================================================
         THE BLUEPRINT CHAPTER — panels 3 to 7.
         While this whole block is on screen the 3D model is drawn as a
         WIREFRAME instead of solid (see "SOLID <-> WIREFRAME WIPE" below).
         ==================================================================== -->
    <div class="blueprint">

      <!-- LAYER 3 — the three measuring annotations.
           viewBox="0 0 100 100" means coordinates are percentages of the
           screen: x1="40" y1="20" is 40% across, 20% down.
           Each one is hidden (drawSVG 0) until its panel scrolls in.
           [EDIT: POSITION] move a line by changing its x/y numbers.
           [EDIT: SIZE] stroke-width thickens the line; r sizes the circle. -->
      <svg width="100%" height="100%" viewBox="0 0 100 100" preserveAspectRatio="xMidYMid meet">
        <line id="line-length" x1="40" y1="20" x2="40" y2="80" stroke-width="0.4"></line>   <!-- vertical: HEIGHT -->
        <path id="line-width" d="M35 35 L65 35" stroke-width="0.4"></path>                  <!-- horizontal: COOLING -->
        <circle id="circle-socket" cx="50" cy="42" r="11" fill="transparent" stroke-width="0.4"></circle> <!-- ring: CPU -->
      </svg>

      <!-- PANEL 3 — chapter intro. Timeline beat 2 (model turns face-on). -->
      <div class="section dark">
        <h2>The facts and figures.</h2>
        <p>Let's get into the nitty-gritty…</p>
      </div>
      <!-- PANEL 4 — class "length" is the ScrollTrigger for #line-length. -->
      <div class="section dark length">
        <h2>Height.</h2>
        <p>A mid-tower case stands about 450&nbsp;mm tall.</p>
      </div>
      <!-- PANEL 5 — class "width" is the ScrollTrigger for #line-width. -->
      <div class="section dark width">
        <h2>Cooling.</h2>
        <p>Fans and heatsinks pull heat out to the radiator.</p>
      </div>
      <!-- PANEL 6 — class "socket" is the ScrollTrigger for #circle-socket. -->
      <div class="section dark socket">
        <h2>The CPU.</h2>
        <p>Hidden under the cooler — the beating heart.</p>
      </div>
      <!-- PANEL 7 — no SVG; the RGB colour cycle is the star here. -->
      <div class="section dark">
        <h2>RGB everything.</h2>
        <p>Because fast computers should look fast, too.</p>
      </div>
    </div>

    <!-- ---------- PANELS 8-9 — the green finale. Last timeline beat. ------
         The first .section is deliberately EMPTY: it gives the model a full
         screen of scroll to swing round and fly toward the camera before the
         closing headline arrives. ---------------------------------------- -->
    <div class="finale">
      <div class="section"></div>
      <div class="section end">
        <h2>Explore More In HardwareQuest.</h2>                 <!-- [EDIT: TEXT] -->
      </div>
    </div>
  </div>

  <!-- ========================================================================
       EXTERNAL LIBRARIES. All from CDN, so this page needs an internet
       connection. Offline: the text still reads, but there is no 3D model
       and no animation. (DrawSVGPlugin is a paid GSAP plugin — the code
       below checks for it and skips the line-drawing if it is missing.)
       ======================================================================== -->
  <script src="https://unpkg.com/three@0.132.2/build/three.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/gsap.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/ScrollTrigger.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/DrawSVGPlugin.min.js"></script>

  <script>
    /* ======================================================================
       PART 1 — BUILD THE 3D COMPUTER
       ======================================================================
       There is no downloaded 3D model file. Every part is assembled here out
       of plain boxes and cylinders ("primitives").

       COORDINATE SYSTEM (remember this to move anything):
           +X = right        -X = left
           +Y = up           -Y = down
           +Z = toward you   -Z = away into the screen
       The finished tower is about 72 wide, 96 tall, 38 deep, centred on 0,0,0.
       ====================================================================== */
    // ===== Build a full vertical water-cooled tower from primitives =====
    function buildComputer() {
      var group = new THREE.Group();   // one container holding every part
      group.userData.fans = [];   // spinning blade groups — the ticker rotates these
      group.userData.rgb = [];    // colour-cycled materials — the ticker recolours these

      /* ------------------------------------------------------------------
         THE MATERIAL PALETTE  <<< THIS IS THE MAIN [EDIT: COLOUR] BLOCK >>>
         Every colour in the 3D model comes from this one list. Change a hex
         here and every part using that material changes at once.
           color     = the base colour
           specular  = colour of the shiny highlight
           shininess = how tight/glossy that highlight is (higher = glossier)
         MeshPhongMaterial reacts to the lights. (MeshBasicMaterial, used for
         the RGB strips further down, ignores lights so it looks "lit up".)
         ------------------------------------------------------------------ */
      var P = THREE.MeshPhongMaterial;
      var mats = {
        board:  new P({ color: 0x20242a, specular: 0x445566, shininess: 30 }),  // motherboard PCB
        white:  new P({ color: 0xe9e9ec, specular: 0xffffff, shininess: 60 }),  // white trim / fan frames
        black:  new P({ color: 0x16181c, specular: 0x333333, shininess: 40 }),  // RAM, PSU, brackets
        metal:  new P({ color: 0xb8bdc6, specular: 0xffffff, shininess: 95 }),  // GPU backplate, SSD heatsink
        dark:   new P({ color: 0x3a3d45, specular: 0xaaaaaa, shininess: 60 }),  // CPU block, radiator, GPU body
        gold:   new P({ color: 0xd8a657, specular: 0xfff0cc, shininess: 80 }),  // circuit traces + solder pads
        orange: new P({ color: 0xff6a1a, specular: 0xffd2a0, shininess: 85 }),  // (declared, not currently used)
        frame:  new P({ color: 0x1c1e22, specular: 0x555555, shininess: 50 }),  // case edge bars + feet
        blade:  new P({ color: 0x2a2d33, specular: 0x666666, shininess: 40 }),  // fan blades
        // transparent:true + low opacity = the tempered glass panels.
        // depthWrite:false stops the glass hiding parts behind it.
        // side:DoubleSide renders both faces so it looks right from any angle.
        glass:  new P({ color: 0x9fb6c2, specular: 0xffffff, shininess: 40, transparent: true, opacity: 0.07, depthWrite: false, side: THREE.DoubleSide })
      };

      /* ------------------------------------------------------------------
         SHAPE HELPERS — every part below is made with one of these two.
         box(width, height, depth, material, x, y, z, parent)
         cyl(radius, height, material, x, y, z, parent)
         castShadow/receiveShadow let parts throw shadows on each other.
         ------------------------------------------------------------------ */
      function box(w, h, d, mat, x, y, z, parent) {
        var m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), mat);
        m.position.set(x, y, z); m.castShadow = true; m.receiveShadow = true;
        (parent || group).add(m); return m;
      }
      function cyl(r, h, mat, x, y, z, parent) {
        var m = new THREE.Mesh(new THREE.CylinderGeometry(r, r, h, 20), mat);
        m.position.set(x, y, z); m.castShadow = true; (parent || group).add(m); return m;
      }

      /* ------------------------------------------------------------------
         FAN BUILDER — used 4 times (3 radiator fans + 1 CPU fan).
         Returns a group made of: square frame, hub, glowing ring, and a
         SEPARATE inner group "spin" holding 9 blades. Only "spin" is pushed
         into userData.fans, so only the blades rotate — the frame stays put.
         [EDIT: SIZE] change the 9 in the loop for more/fewer blades.
         [EDIT: COLOUR] 0x54d6a0 is the ring's starting green, but the RGB
                        ticker overwrites it every frame anyway.
         ------------------------------------------------------------------ */
      // a fan with optional frame colour; built flat (axis +Y), caller can rotate it
      function fan(cx, cy, cz, radius, parent, frameMat) {
        frameMat = frameMat || mats.black;
        var g = new THREE.Group(); g.position.set(cx, cy, cz);
        box(radius * 2 + 3, 3, radius * 2 + 3, frameMat, 0, 0, 0, g);   // square outer frame width, height, depth, material,x,y,z,parent)
        cyl(radius, 2.6, mats.black, 0, 1.4, 0, g);                     // round body
        // Torus = the glowing RGB ring around the rim. MeshBasicMaterial so it
        // ignores lighting and always looks like it is emitting light.
        var ring = new THREE.Mesh(new THREE.TorusGeometry(radius + 0.6, 0.6, 8, 44), new THREE.MeshBasicMaterial({ color: 0x54d6a0 }));
        ring.rotation.x = Math.PI / 2; ring.position.y = 1.7; g.add(ring);  // lay the ring flat
        group.userData.rgb.push(ring.material);   // register for colour cycling
        var spin = new THREE.Group(); spin.position.set(0, 1.9, 0); g.add(spin);
        cyl(radius * 0.3, 3.2, mats.dark, 0, 0, 0, spin);               // centre hub
        for (var i = 0; i < 9; i++) {
          // geometry.translate pushes the blade OUT from the centre first, so
          // rotating the mesh sweeps it around the hub like a real blade.
          var bGeo = new THREE.BoxGeometry(radius * 0.95, 1, radius * 0.4); bGeo.translate(radius * 0.48, 0, 0);
          var b = new THREE.Mesh(bGeo, mats.blade);
          b.rotation.y = (i / 9) * Math.PI * 2;   // even spacing around the circle
          b.rotation.z = 0.34;                    // [EDIT: SIZE] blade pitch/tilt
          b.castShadow = true; spin.add(b);
        }
        group.userData.fans.push(spin);   // register for spinning
        (parent || group).add(g); return g;
      }

      /* ------------------------------------------------------------------
         CASE FRAME — an open box drawn as 12 thin bars (4 uprights,
         4 top/bottom rails, 4 depth rails) so you can see inside it.
         t = bar thickness.
         ------------------------------------------------------------------ */
      // open case frame = 12 thin edge bars
      function frameBars(w, h, d, t, mat) {
        var hx = w / 2, hy = h / 2, hz = d / 2;   // half-sizes = corner coordinates
        [[-hx, 0, -hz], [hx, 0, -hz], [-hx, 0, hz], [hx, 0, hz]].forEach(function (p) { box(t, h, t, mat, p[0], p[1], p[2]); }); // 4 vertical
        [[0, hy, -hz], [0, hy, hz], [0, -hy, -hz], [0, -hy, hz]].forEach(function (p) { box(w, t, t, mat, p[0], p[1], p[2]); }); // 4 horizontal
        [[-hx, hy, 0], [hx, hy, 0], [-hx, -hy, 0], [hx, -hy, 0]].forEach(function (p) { box(t, t, d, mat, p[0], p[1], p[2]); }); // 4 front-to-back
      }

      /* ------------------------------------------------------------------
         RGB STRIP — a glowing bar. Registered in userData.rgb so the ticker
         cycles its colour through the rainbow.
         ------------------------------------------------------------------ */
      // a glowing RGB strip (basic material so it "lights up")
      function rgbStrip(w, h, d, x, y, z) {
        var m = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), new THREE.MeshBasicMaterial({ color: 0x54d6a0 }));
        m.position.set(x, y, z); group.add(m); group.userData.rgb.push(m.material); return m;
      }

      /* ==================================================================
         MODEL ASSEMBLY — from here down, each block is one real PC part.
         To move a part, change its x/y/z. To resize it, change w/h/d.
         ================================================================== */

      // ---- motherboard (vertical, at the back) ----
      box(54, 66, 2, mats.board, -6, 6, -13);                 // the big flat green/black PCB
      box(7, 66, 3, mats.white, -30, 6, -12);                 // white I/O cover
      rgbStrip(40, 1.6, 1, -6, 39, -11.5);                    // top RGB accent

      // ---- CPU water block ---- (sits mid-board; the "socket" panel points here)
      box(15, 15, 8, mats.dark, -8, 24, -7);                  // the pump housing
      box(13, 5, 7, mats.glass, -8, 30, -7);                  // acrylic top
      rgbStrip(11, 1, 6, -8, 31.5, -6);

      // ---- RAM (RGB tops) ---- 4 sticks in a row, 4 units apart
      for (var s = 0; s < 4; s++) {
        var rx = 0 + s * 4;                                   // [EDIT: POSITION] 4 = gap between sticks
        box(3, 22, 6, mats.black, rx, 24, -7);                // the stick
        rgbStrip(3, 2, 6, rx, 35.5, -7);                      // its glowing top
      }

      // ---- radiator + three RGB fans on the right (white frames) ----
      box(8, 70, 30, mats.dark, 31, 4, 0);                    // the tall radiator slab
      [-22, 4, 30].forEach(function (fy) {                    // [EDIT: POSITION] 3 fan heights
        var f = fan(26, fy, 0, 12, group, mats.white);
        f.rotation.z = Math.PI / 2;                           // face into the case (axis = X)
      });

      // ---- GPU (clean horizontal graphics card) ----
      box(46, 10, 24, mats.dark, -6, -9, 0);        // card body
      box(46, 10, 1, mats.metal, -6, -9, 12.6);     // backplate facing the viewer
      box(40, 1.6, 1, mats.white, -6, -4, 13.1);    // accent stripe
      box(8, 10, 24, mats.black, -28, -9, 0);       // I/O bracket end

      // ---- PSU + shroud at the bottom ----
      box(60, 15, 28, mats.black, 0, -36, 0);       // power supply body
      box(64, 4, 30, mats.black, 0, -28, 0);        // shroud lid over it
      box(24, 10, 1, mats.white, 0, -36, 14.5);     // white badge on the front

      // ---- feet / stand ----
      box(68, 4, 30, mats.frame, 0, -46, 0);                                    // base plate
      box(8, 7, 30, mats.frame, -26, -50, 0); box(8, 7, 30, mats.frame, 26, -50, 0); // two feet
      rgbStrip(58, 1.4, 2, 0, -44, 15);                                         // underglow

      // ---- CPU air cooler fan (on top of the block) ----
      fan(-8, 33, -7, 8);

      /* ---- circuit traces etched on the motherboard ----
         Cosmetic gold detail. tz sits them just in FRONT of the board
         (board is at z=-13 with depth 2, so its face is -12; -11.6 is
         0.4 proud of it) — otherwise they would be buried inside it.       */
      var tz = -11.6;
      function htr(x, y, l) { box(l, 0.5, 0.3, mats.gold, x, y, tz); }   // horizontal trace
      function vtr(x, y, l) { box(0.5, l, 0.3, mats.gold, x, y, tz); }   // vertical trace
      function pad(x, y) {                                              // round solder pad
        var m = new THREE.Mesh(new THREE.CylinderGeometry(0.8, 0.8, 0.4, 12), mats.gold);
        m.rotation.x = Math.PI / 2; m.position.set(x, y, tz); m.castShadow = true; group.add(m);
      }
      htr(-22, 17, 13); htr(-22, 12, 13); vtr(-16, 14.5, 7);            // upper trace cluster
      pad(-22, 17); pad(-9, 17); pad(-22, 12);
      vtr(-25, 6, 14); htr(-25, -1, 9); pad(-25, -1); pad(-25, 13);     // left-edge cluster

      // ---- M.2 SSD with heatsink (lower board) ----
      box(24, 6, 2.5, mats.metal, -4, -21, -10.8);     // heatsink cover
      box(20, 1.5, 1, mats.white, -4, -21, -9.4);      // label strip
      for (var sg = 0; sg < 5; sg++) box(20, 0.6, 0.4, mats.dark, -4, -23.5 + sg * 0.9, -9.4); // fins

      // ---- tempered-glass case (frame + panels) ----
      // Built LAST so the transparent panels blend over everything already
      // placed inside them.
      frameBars(72, 96, 38, 1.6, mats.frame);                 // [EDIT: SIZE] whole case dimensions
      box(70, 94, 0.5, mats.glass, 0, 0, 19);                 // front glass
      box(0.5, 94, 36, mats.glass, -36, 0, 0);                // side glass

      return group;
    }

    /* ======================================================================
       PART 2 — THE DESK SETUP
       Shown beside the tower on panel 1 ("you use one every day"), then
       shrunk to nothing and slid off-screen on the first scroll beat. It is
       added straight to the scene, NOT to the tower group, so the scroll
       timeline can move it independently.
       ====================================================================== */
    // ===== A simple desk setup (monitor + keyboard + mouse) shown at the start =====
    function buildDesk() {
      var g = new THREE.Group();
      var P = THREE.MeshPhongMaterial;
      // [EDIT: COLOUR] this small palette is separate from the tower's mats.
      var black = new P({ color: 0x16181c, specular: 0x333333, shininess: 40 });
      var dark = new P({ color: 0x23262c, specular: 0x888888, shininess: 50 });
      // "emissive" makes the screen glow on its own, like a monitor that is on.
      var screen = new P({ color: 0x123b4a, specular: 0x88ccdd, shininess: 80, emissive: 0x123f4d });
      var key = new P({ color: 0x2b2f36, specular: 0x666666, shininess: 40 });
      function b(w, h, d, m, x, y, z) {   // local box helper (adds to g, not group)
        var me = new THREE.Mesh(new THREE.BoxGeometry(w, h, d), m);
        me.position.set(x, y, z); me.castShadow = true; me.receiveShadow = true; g.add(me); return me;
      }
      // monitor
      b(62, 38, 2.4, black, 0, 16, 0);     // bezel
      b(56, 32, 1, screen, 0, 16, 1.3);    // glowing screen
      b(5, 12, 4, dark, 0, -2, -1);        // neck
      b(22, 2.4, 12, dark, 0, -9, 0);      // base
      // keyboard — 4 rows x 13 keys generated in a nested loop (52 little boxes)
      b(48, 2, 15, black, 0, -12, 20);     // the keyboard slab
      for (var r = 0; r < 4; r++) for (var c = 0; c < 13; c++) b(2.6, 1.2, 2.2, key, -20 + c * 3.3, -10.6, 14.8 + r * 2.8);
      // mouse
      b(6, 3.2, 10, black, 31, -11.4, 22);
      return g;
    }

    /* ======================================================================
       PART 3 — THE SCENE (renderer, cameras, lights)
       ======================================================================
       THE CLEVER BIT — HOW SOLID BECOMES WIREFRAME:
       Two cameras look at the SAME model from the same spot. Camera 0 can
       only see objects on layer 0 (the solid meshes). Camera 1 can only see
       layer 1 (the wireframe edge lines added later). Both render to the
       same canvas, but each is restricted to a horizontal SLICE of the
       screen using a "scissor" rectangle. Scrolling animates the height of
       camera 1's slice from 0 to full screen — which reads as a wipe from
       solid to wireframe. views[i].bottom/height are the numbers that move.
       ====================================================================== */
    // ===== Scene: two cameras (solid layer 0 + wireframe layer 1), scissor split =====
    function Scene(modelGroup) {
      var self = this;
      // view 0 = solid, fills the screen. view 1 = wireframe, starts at height 0.
      this.views = [{ bottom: 0, height: 1 }, { bottom: 0, height: 0 }];
      this.renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });  // alpha = see the CSS background through it
      this.renderer.setSize(window.innerWidth, window.innerHeight);
      this.renderer.setPixelRatio(window.devicePixelRatio);   // sharp on retina screens
      this.renderer.shadowMap.enabled = true;
      this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;  // soft shadow edges
      this.renderer.outputEncoding = THREE.sRGBEncoding;
      this.renderer.toneMapping = THREE.ACESFilmicToneMapping; // filmic colour response
      this.renderer.toneMappingExposure = 1.15;                // [EDIT: COLOUR] overall brightness
      document.body.appendChild(this.renderer.domElement);     // this creates the <canvas>
      this.scene = new THREE.Scene();

      // Build the two cameras. layers.disableAll() then enable(i) is what
      // makes camera 0 solid-only and camera 1 wireframe-only.
      for (var i = 0; i < this.views.length; i++) {
        var cam = new THREE.PerspectiveCamera(45, window.innerWidth / window.innerHeight, 1, 2000); // 45 = field of view
        cam.position.set(0, 0, 180); cam.layers.disableAll(); cam.layers.enable(i);
        cam.lookAt(new THREE.Vector3(0, 0, 0)); this.views[i].camera = cam;
      }

      /* ---- LIGHTING — four lights, a standard studio setup.
             [EDIT: COLOUR] first argument = light colour.
             [EDIT: SIZE]   second argument = intensity (0-1+).            */
      var key = new THREE.DirectionalLight(0xffffff, 1.0);   // KEY: main white light, top-right-front
      key.position.set(80, 130, 120); key.castShadow = true; // only this one casts shadows
      key.shadow.mapSize.set(1024, 1024);                    // shadow resolution
      // The shadow camera box must be big enough to contain the model or
      // shadows get clipped off at the edges.
      key.shadow.camera.near = 10; key.shadow.camera.far = 600;
      key.shadow.camera.left = -110; key.shadow.camera.right = 110;
      key.shadow.camera.top = 110; key.shadow.camera.bottom = -110; key.shadow.bias = -0.0006; // bias stops shadow acne
      this.scene.add(key); this.light = key;                 // kept on `this` so the finale can move it
      var fill = new THREE.DirectionalLight(0xcfe0ff, 0.40); fill.position.set(-100, 50, 40); this.scene.add(fill); // FILL: cool blue, softens the left
      var rim = new THREE.DirectionalLight(0xffe9c9, 0.35); rim.position.set(0, 20, -140); this.scene.add(rim);     // RIM: warm, from behind, outlines the edges
      this.scene.add(new THREE.HemisphereLight(0xdfeaff, 0x202428, 0.55)); // AMBIENT: sky above / ground below
      this.scene.add(modelGroup);

      /* ---- RESIZE — recompute aspect ratio, and pull the camera back on
             narrow windows so the tall tower still fits on screen.        */
      this.onResize = function () {
        self.w = window.innerWidth; self.h = window.innerHeight;
        for (var i = 0; i < self.views.length; i++) {
          var cam = self.views[i].camera; cam.aspect = self.w / self.h;
          var camZ = (screen.width - self.w) / 3; cam.position.z = camZ < 180 ? 180 : camZ; // never closer than 180
          cam.updateProjectionMatrix();   // must be called after changing aspect/position
        }
        self.renderer.setSize(self.w, self.h); self.render();
      };

      /* ---- RENDER — draw both cameras, each clipped to its scissor slice.
             setScissor(x, bottom, width, height) in PIXELS. This runs every
             frame from the GSAP ticker.                                    */
      this.render = function () {
        for (var i = 0; i < self.views.length; i++) {
          var view = self.views[i];
          var bottom = Math.floor(self.h * view.bottom), height = Math.floor(self.h * view.height); // 0-1 -> pixels
          self.renderer.setViewport(0, 0, self.w, self.h);        // camera always covers full screen...
          self.renderer.setScissor(0, bottom, self.w, height);    // ...but only this band is actually drawn
          self.renderer.setScissorTest(true);
          view.camera.aspect = self.w / self.h; self.renderer.render(self.scene, view.camera);
        }
      };
      this.onResize(); window.addEventListener('resize', this.onResize, false);
    }

    /* ======================================================================
       PART 4 — WIRE EVERYTHING TOGETHER
       Wrapped in an IIFE — (function(){ ... })() — so none of these
       variables leak into the global page scope. Runs immediately.
       ====================================================================== */
    // ===== wire it together =====
    (function () {
      gsap.registerPlugin(ScrollTrigger);
      // DrawSVGPlugin is a premium GSAP plugin. If the CDN did not serve it,
      // hasDraw stays false and every measuring-line animation is skipped —
      // the page still works, it just has no drawn lines.
      var hasDraw = typeof DrawSVGPlugin !== 'undefined';
      if (hasDraw) gsap.registerPlugin(DrawSVGPlugin);

      /* ---- BUILD THE MODEL AND ITS WIREFRAME TWIN ----
             For every solid mesh: put it on layer 0, then generate an
             EdgesGeometry outline of the same shape, put that on layer 1,
             and parent it to the mesh so it follows every move automatically.
             [EDIT: COLOUR] wireMat colour = the wireframe line colour.     */
      var model = buildComputer();
      var meshes = []; model.traverse(function (o) { if (o.isMesh) meshes.push(o); }); // walk the whole tree
      var wireMat = new THREE.LineBasicMaterial({ color: 0xffe9c9, transparent: true, opacity: 0.55 });
      meshes.forEach(function (m) {
        m.layers.set(0);                                                        // solid -> camera 0
        var line = new THREE.LineSegments(new THREE.EdgesGeometry(m.geometry), wireMat);
        line.layers.set(1); m.add(line);                                        // outline -> camera 1
      });

      var scene = new Scene(model);
      var tau = Math.PI * 2;   // one full turn in radians. tau * 0.25 = quarter turn.

      /* ---- THE ANIMATION LOOP — runs ~60x a second, forever ----
             Three jobs: spin the fan blades, cycle the RGB colours, redraw.
             [EDIT: SPEED] 0.16 = fan speed (bigger = faster).
             [EDIT: SPEED] 5000 = milliseconds for one full rainbow cycle.
             setHSL(hue, saturation, lightness): hue 0-1 walks the rainbow,
             and "+ j * 0.11" offsets each strip so they are not all the
             same colour at once — that is the chase effect.                */
      var fans = model.userData.fans || [], rgb = model.userData.rgb || [];
      gsap.ticker.add(function () {
        for (var i = 0; i < fans.length; i++) fans[i].rotation.y += 0.16;
        var t = (performance.now() % 5000) / 5000;                 // 0 -> 1 every 5 seconds
        for (var j = 0; j < rgb.length; j++) rgb[j].color.setHSL((t + j * 0.11) % 1, 0.8, 0.55);
        scene.render();
      });

      /* ---- OPENING STATE — hide the SVG lines, fade the canvas in, drop
             the loading screen, show the scroll hint.
             autoAlpha animates opacity AND visibility together, which is why
             the CSS could set both to hidden safely.                      */
      if (hasDraw) {
        gsap.set('#line-length', { drawSVG: 0 }); gsap.set('#line-width', { drawSVG: 0 }); gsap.set('#circle-socket', { drawSVG: 0 });
      }
      gsap.fromTo('canvas', { x: '50%', autoAlpha: 0 }, { duration: 1, x: '0%', autoAlpha: 1 }); // slides in from the right
      gsap.to('.loading', { autoAlpha: 0 });
      gsap.to('.scroll-cta', { opacity: 1 });
      gsap.set('.blueprint svg', { autoAlpha: 1 });

      /* ---- STARTING POSE — where things sit before any scrolling.
             [EDIT: POSITION] desk on the left (x -12), tower on the right
             (x 26), both at 45% scale. rotation is in radians, hence tau. */
      // Start: the desk setup and the tower sit side by side.
      var desk = buildDesk();
      scene.scene.add(desk);                                       // straight to the scene, not the model group
      gsap.set(desk.scale, { x: 0.45, y: 0.45, z: 0.45 });
      gsap.set(desk.position, { x: -12, y: -2, z: 0 });
      gsap.set(desk.rotation, { x: tau * 0.02, y: tau * 0.04, z: 0 }); // slight 3/4 angle

      gsap.set(model.scale, { x: 0.45, y: 0.45, z: 0.45 });
      gsap.set(model.rotation, { x: tau * 0.03, y: -tau * 0.10, z: 0 });
      gsap.set(model.position, { x: 26, y: 0, z: 0 });
      scene.render();

      /* ==================================================================
         SOLID <-> WIREFRAME WIPE
         Two scrubbed tweens on views[1] (the wireframe camera's slice):
           1) entering .blueprint  — grow height 0 -> 1 from the bottom
           2) leaving  .blueprint  — shrink back to 0, sliding bottom 0 -> 1
         "scrub: true" ties progress directly to scroll position, so it
         moves with the wheel instead of playing on its own.
         start/end read as "trigger-edge viewport-edge".
         ================================================================== */
      // solid <-> wireframe wipe across the blueprint section
      gsap.fromTo(scene.views[1], { height: 0, bottom: 0 }, {
        height: 1, bottom: 0, ease: 'none',
        scrollTrigger: { trigger: '.blueprint', scrub: true, start: 'top bottom', end: 'top top' }
      });
      gsap.fromTo(scene.views[1], { height: 1, bottom: 0 }, {
        // immediateRender:false — otherwise this from-state (wireframe fullscreen)
        // is applied at page load, hiding the solid render until the first scroll.
        height: 0, bottom: 1, ease: 'none', immediateRender: false,
        scrollTrigger: { trigger: '.blueprint', scrub: true, start: 'bottom bottom', end: 'bottom top' }
      });

      /* ---- THE MEASURING LINES — each gets a PAIR of tweens: draw it on
             as its panel arrives (drawSVG 0 -> 100), then erase and fade it
             as the panel leaves. Trigger classes .length / .width / .socket
             are the panel divs up in the HTML.                            */
      if (hasDraw) {
        gsap.to('#line-length', { drawSVG: 100, scrollTrigger: { trigger: '.length', scrub: true, start: 'top bottom', end: 'top top' } });
        gsap.to('#line-length', { drawSVG: 0, opacity: 0, scrollTrigger: { trigger: '.length', scrub: true, start: 'top top', end: 'bottom top' } });
        gsap.to('#line-width', { drawSVG: 100, scrollTrigger: { trigger: '.width', scrub: true, start: 'top 75%', end: 'bottom 60%' } });
        gsap.to('#line-width', { drawSVG: 0, opacity: 0, scrollTrigger: { trigger: '.width', scrub: true, start: 'top top', end: 'bottom top' } });
        gsap.to('#circle-socket', { drawSVG: 100, scrollTrigger: { trigger: '.socket', scrub: true, start: 'top 60%', end: 'bottom bottom' } });
        gsap.to('#circle-socket', { drawSVG: 0, opacity: 0, scrollTrigger: { trigger: '.socket', scrub: true, start: 'top top', end: 'bottom top' } });
      }

      /* ==================================================================
         MASTER SCROLL TIMELINE  —  THE HEART OF THE PAGE
         One timeline spanning the entire .content height. "scrub: true"
         means timeline progress == scroll progress: scroll down and it
         plays forward, scroll up and it rewinds.

         `d` is the playhead. Every "d += dur" starts a new BEAT, and each
         beat lines up roughly with one scroll panel. Tweens sharing the
         same `d` run simultaneously.

         [EDIT: POSITION] change x/y/z to move the tower in a beat.
         [EDIT: SIZE]     change scale to grow/shrink it.
         Rotation is radians: tau = full turn, so tau * 0.07 is a small turn.
         ================================================================== */
      // scroll timeline: rotate the tower through the sections
      var dur = 1;                                    // [EDIT: SPEED] length of every beat
      var tl = gsap.timeline({
        onUpdate: scene.render,                       // redraw whenever the timeline moves
        scrollTrigger: { trigger: '.content', scrub: true, start: 'top top', end: 'bottom bottom' },
        defaults: { duration: dur, ease: 'power2.inOut' }   // [EDIT: SPEED] easing curve
      });
      var d = 0;
      /* BEAT 0 — PANEL 1 "The Computer."
         The desk shrinks away and slides left while the tower grows and
         moves toward centre. This is the hand-off from "what you use" to
         "what is inside". */
      tl.to('.scroll-cta', { duration: 0.25, opacity: 0 }, d);                   // hide "Scroll ↓"
      tl.to(desk.scale, { x: 0, y: 0, z: 0, ease: 'power2.in' }, d);             // monitor set leaves
      tl.to(desk.position, { x: -46, y: -4 }, d);
      tl.to(model.scale, { x: 0.62, y: 0.62, z: 0.62, ease: 'power2.out' }, d);  // tower grows + centres
      tl.to(model.position, { x: 8, y: 0 }, d);
      tl.to(model.rotation, { y: -tau * 0.02, x: tau * 0.03 }, d);

      d += dur; // a tower full of parts
      /* BEAT 1 — PANEL 2 "A tower full of clever parts."
         Text is right-aligned, so the tower swings LEFT (x: -6) to sit
         opposite the words. */
      tl.to(model.rotation, { y: tau * 0.07, x: tau * 0.02 }, d);
      tl.to(model.position, { x: -6 }, d);

      d += dur; // blueprint intro — face on
      /* BEAT 2 — PANEL 3 "The facts and figures."
         All rotation resets to 0 = dead flat, straight at the camera. This
         matters: the SVG measuring lines are drawn in FIXED screen space,
         so the model must be face-on for them to line up with it. */
      tl.to(model.rotation, { x: 0, y: 0, z: 0 }, d);
      tl.to(model.position, { x: 0, y: 0 }, d);

      d += dur; // height
      /* BEAT 3 — PANEL 4 "Height." Held face-on for the vertical line. */
      tl.to(model.rotation, { y: 0 }, d);

      d += dur; // cooling
      /* BEAT 4 — PANEL 5 "Cooling." Small turn left to show the radiator
         and its three fans on the right-hand side of the case. */
      tl.to(model.rotation, { y: -tau * 0.04 }, d);

      d += dur; // cpu
      /* BEAT 5 — PANEL 6 "The CPU." Turns back toward centre so the circle
         annotation sits over the CPU water block. */
      tl.to(model.rotation, { y: tau * 0.02 }, d);

      d += dur; // rgb
      /* BEAT 6 — PANEL 7 "RGB everything." The biggest turn of the story
         (tau * 0.12) so the glowing strips and fan rings catch the light. */
      tl.to(model.rotation, { y: -tau * 0.12, x: tau * 0.03 }, d);
      tl.to(model.position, { x: 6 }, d);

      d += dur; // finale — face straight at the camera
      /* BEAT 7 — PANELS 8-9, the green finale.
         Squares up, drops slightly, and flies TOWARD the viewer (z: 45).
         The key light swings to front-and-above at the same time so the
         face of the tower is lit for the closing shot. */
      tl.to(model.rotation, { x: 0, y: 0, z: 0 }, d);
      tl.to(model.position, { x: 0, y: -8, z: 45 }, d);
      tl.to(scene.light.position, { x: 0, y: 60, z: 80 }, d);
    })();
  </script>
</body>
</html>
