<%@ Page Title="Home Page" Language="C#" MasterPageFile="~/Site.Master" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="Hardwarequest._Default" %>

<asp:Content ID="BodyContent" ContentPlaceHolderID="MainContent" runat="server">
  <%-- Internal CSS: page-specific styling (demonstrates internal stylesheet usage) --%>
  <style>
    .home section { margin-bottom: 44px; }
    .section-head { text-align: center; margin-bottom: 26px; }
    .section-head h2 { font-family: "Comfortaa", sans-serif; }
    .section-sub { color: #5b6b60; max-width: 580px; margin: 6px auto 0; }

    /* ---------- hero ---------- */
    .hq-hero-anim {
      display: grid;
      grid-template-columns: 1.1fr 1fr;
      gap: 24px;
      align-items: center;
    }
    .hq-hero-anim .hero-copy { min-width: 0; }
    .hq-board { width: 100%; height: auto; max-width: 500px; }
    .hq-board .flow { opacity: 0; }     /* hidden until GSAP animates it */
    @media (max-width: 768px) {
      .hq-hero-anim { grid-template-columns: 1fr; text-align: center; }
      .hq-board { margin: 0 auto; }
    }

    /* ---------- "what you can do" feature cards ---------- */
    .features-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 18px; }
    .feature-card {
      background: #fff;
      border: 1px solid #e3d9c6;
      border-radius: 16px;
      padding: 22px 18px;
      text-align: center;
      box-shadow: 0 12px 24px -14px rgba(60, 40, 10, .3);
      display: flex;
      flex-direction: column;
      transition: transform .15s ease, box-shadow .15s ease;
    }
    .feature-card:hover { transform: translateY(-4px); box-shadow: 0 18px 30px -14px rgba(60, 40, 10, .38); }
    .feature-card h3 { font-family: "Comfortaa", sans-serif; font-size: 1.05rem; margin: 12px 0 6px; }
    .feature-card p { color: #5b6b60; font-size: .95rem; flex: 1; margin-bottom: 14px; }
    .ficon { width: 86px; height: 86px; margin: 0 auto; display: block; }
    @media (max-width: 992px) { .features-grid { grid-template-columns: repeat(2, 1fr); } }
    @media (max-width: 540px) { .features-grid { grid-template-columns: 1fr; } }

    /* ---------- closing call to action ---------- */
    .home-cta {
      background: linear-gradient(135deg, #2e6950, #21503c);
      color: #fff;
      border-radius: 18px;
      padding: 34px 24px;
      text-align: center;
    }
    .home-cta h2 { color: #fff; font-family: "Comfortaa", sans-serif; }
    .home-cta p { color: #dceee6; max-width: 520px; margin: 8px auto 0; }
    .home-cta .btn-cta {
      display: inline-block; margin-top: 16px;
      background: #fff; color: #2e6950; font-weight: 700;
      border: none; border-radius: 10px; padding: 11px 26px;
      box-shadow: 0 3px 0 0 rgba(0, 0, 0, .18);
    }
    .home-cta .btn-cta:hover { background: #f3fbf7; }

    /* svg transform helpers so rotations/scales pivot correctly */
    .cube, .bar, .pin, .bubble, .star { transform-box: fill-box; transform-origin: center; }
  </style>

  <div class="home">

    <%-- ===================== HERO ===================== --%>
    <section class="hq-hero hq-hero-anim">
      <div class="hero-copy">
        <h1>Welcome to HardwareQuest!</h1>
        <%-- Inline CSS: a one-off style applied directly to this element --%>
        <p style="font-size:1.2rem;">Learn what's inside a computer — the fun way!</p>
        <a class="btn hq-btn" href="<%= ResolveUrl("~/Explore/InsideTheMachine") %>">Explore in 3D</a>
      </div>
      <div class="hero-art">
        <svg class="hq-board" viewBox="0 0 460 280" role="img" aria-label="A computer motherboard coming to life">
          <!-- board -->
          <rect x="8" y="8" width="444" height="264" rx="16" fill="#20503d" stroke="#143329" stroke-width="3" />
          <circle cx="28" cy="28" r="6" fill="#143329" />
          <circle cx="432" cy="28" r="6" fill="#143329" />
          <circle cx="28" cy="252" r="6" fill="#143329" />
          <circle cx="432" cy="252" r="6" fill="#143329" />

          <!-- circuit traces (draw themselves) -->
          <path class="trace" d="M40 200 H150 V150" fill="none" stroke="#d8a657" stroke-width="3" stroke-linecap="round" />
          <path class="trace" d="M430 70 V104 H266" fill="none" stroke="#d8a657" stroke-width="3" stroke-linecap="round" />
          <path class="trace" d="M60 64 V120 H150" fill="none" stroke="#d8a657" stroke-width="3" stroke-linecap="round" />
          <path class="trace" d="M210 190 V232 H250" fill="none" stroke="#d8a657" stroke-width="3" stroke-linecap="round" />
          <path class="trace" d="M298 120 H274" fill="none" stroke="#d8a657" stroke-width="3" stroke-linecap="round" />
          <!-- flowing current overlay (same path as the first trace) -->
          <path class="flow" d="M40 200 H150 V150" fill="none" stroke="#fff2cf" stroke-width="3" stroke-linecap="round" />

          <!-- solder pads -->
          <circle cx="150" cy="150" r="3.5" fill="#caa35a" />
          <circle cx="266" cy="104" r="3.5" fill="#caa35a" />
          <circle cx="150" cy="120" r="3.5" fill="#caa35a" />

          <!-- I/O ports (left edge) -->
          <g data-anim="part">
            <rect x="12" y="120" width="18" height="12" rx="2" fill="#8893a0" />
            <rect x="12" y="136" width="18" height="12" rx="2" fill="#8893a0" />
            <rect x="12" y="152" width="18" height="12" rx="2" fill="#8893a0" />
          </g>

          <!-- GPU / expansion card -->
          <g data-anim="part">
            <rect x="40" y="214" width="180" height="34" rx="5" fill="#8a5021" />
            <rect x="50" y="222" width="120" height="6" rx="3" fill="#c98a4e" />
            <text x="190" y="236" font-family="Quicksand,sans-serif" font-size="12" font-weight="700" fill="#ffe9c9" text-anchor="middle">GPU</text>
          </g>

          <!-- RAM sticks -->
          <g data-anim="part">
            <rect x="300" y="36" width="20" height="150" rx="3" fill="#2e6950" />
            <rect x="326" y="36" width="20" height="150" rx="3" fill="#2e6950" />
            <rect x="300" y="150" width="20" height="6" fill="#143329" />
            <rect x="326" y="150" width="20" height="6" fill="#143329" />
            <text x="323" y="204" font-family="Quicksand,sans-serif" font-size="12" font-weight="700" fill="#bfe6d5" text-anchor="middle">RAM</text>
          </g>

          <!-- capacitors -->
          <g data-anim="part">
            <g><rect x="266" y="92" width="16" height="26" rx="3" fill="#1a2b3a" /><ellipse cx="274" cy="92" rx="8" ry="3" fill="#2f4a63" /></g>
            <g><rect x="266" y="124" width="16" height="26" rx="3" fill="#1a2b3a" /><ellipse cx="274" cy="124" rx="8" ry="3" fill="#2f4a63" /></g>
            <g><rect x="266" y="156" width="16" height="26" rx="3" fill="#1a2b3a" /><ellipse cx="274" cy="156" rx="8" ry="3" fill="#2f4a63" /></g>
          </g>

          <!-- CPU with heatsink fins -->
          <g data-anim="part">
            <rect x="160" y="96" width="92" height="92" rx="8" fill="#2b2d33" />
            <rect x="174" y="110" width="64" height="64" rx="4" fill="#3a3d45" />
            <line x1="184" y1="112" x2="184" y2="172" stroke="#50535c" stroke-width="3" />
            <line x1="196" y1="112" x2="196" y2="172" stroke="#50535c" stroke-width="3" />
            <line x1="208" y1="112" x2="208" y2="172" stroke="#50535c" stroke-width="3" />
            <line x1="220" y1="112" x2="220" y2="172" stroke="#50535c" stroke-width="3" />
            <line x1="232" y1="112" x2="232" y2="172" stroke="#50535c" stroke-width="3" />
            <rect x="186" y="132" width="40" height="18" rx="9" fill="#1f2127" opacity=".85" />
            <text x="206" y="145" font-family="Quicksand,sans-serif" font-size="13" font-weight="700" fill="#d8a657" text-anchor="middle">CPU</text>
          </g>

          <!-- chipset / PCH -->
          <g data-anim="part">
            <rect x="250" y="214" width="48" height="48" rx="6" fill="#2b2d33" />
            <line x1="256" y1="220" x2="292" y2="256" stroke="#3f4148" stroke-width="3" />
            <line x1="292" y1="220" x2="256" y2="256" stroke="#3f4148" stroke-width="3" />
            <text x="274" y="242" font-family="Quicksand,sans-serif" font-size="10" font-weight="700" fill="#9aa0ab" text-anchor="middle">PCH</text>
          </g>

          <!-- SSD (M.2) -->
          <g data-anim="part">
            <rect x="356" y="218" width="74" height="22" rx="3" fill="#34607a" />
            <text x="393" y="233" font-family="Quicksand,sans-serif" font-size="11" font-weight="700" fill="#dff0f7" text-anchor="middle">SSD</text>
          </g>

          <!-- case fan (outer pops in, inner blades spin) -->
          <g data-anim="part">
            <circle cx="95" cy="72" r="34" fill="#1b3f30" stroke="#143329" stroke-width="2" />
            <g class="fan">
              <line x1="95" y1="72" x2="95" y2="46" stroke="#54d6a0" stroke-width="6" stroke-linecap="round" transform="rotate(0 95 72)" />
              <line x1="95" y1="72" x2="95" y2="46" stroke="#54d6a0" stroke-width="6" stroke-linecap="round" transform="rotate(60 95 72)" />
              <line x1="95" y1="72" x2="95" y2="46" stroke="#54d6a0" stroke-width="6" stroke-linecap="round" transform="rotate(120 95 72)" />
              <line x1="95" y1="72" x2="95" y2="46" stroke="#54d6a0" stroke-width="6" stroke-linecap="round" transform="rotate(180 95 72)" />
              <line x1="95" y1="72" x2="95" y2="46" stroke="#54d6a0" stroke-width="6" stroke-linecap="round" transform="rotate(240 95 72)" />
              <line x1="95" y1="72" x2="95" y2="46" stroke="#54d6a0" stroke-width="6" stroke-linecap="round" transform="rotate(300 95 72)" />
              <circle cx="95" cy="72" r="7" fill="#d8a657" />
            </g>
          </g>

          <!-- status LED -->
          <circle class="led" data-anim="part" cx="430" cy="40" r="7" fill="#54d6a0" />
        </svg>
      </div>
    </section>

    <%-- ===================== WHAT YOU CAN DO (each card has its own animation) ===================== --%>
    <section>
      <div class="section-head">
        <h2 class="hq-title">What you can do</h2>
        <p class="section-sub">Four fun ways to discover how a computer works.</p>
      </div>
      <div class="features-grid">

        <!-- 1) Explore in 3D — a floating, wobbling cube -->
        <div class="feature-card">
          <svg class="ficon" data-icon="cube" viewBox="0 0 80 80" aria-hidden="true">
            <g class="cube">
              <polygon points="40,12 64,26 40,40 16,26" fill="#54d6a0" />
              <polygon points="16,26 40,40 40,68 16,54" fill="#2e6950" />
              <polygon points="64,26 40,40 40,68 64,54" fill="#21503c" />
            </g>
          </svg>
          <h3>Explore in 3D</h3>
          <p>Spin a real computer around and pull it apart, piece by piece.</p>
          <a class="btn hq-btn btn-sm" href="<%= ResolveUrl("~/Explore/InsideTheMachine") %>">Open Explorer</a>
        </div>

        <!-- 2) Learn the parts — CPU with pins lighting up in a wave -->
        <div class="feature-card">
          <svg class="ficon" data-icon="cpu" viewBox="0 0 80 80" aria-hidden="true">
            <rect x="24" y="24" width="32" height="32" rx="5" fill="#2b2d33" />
            <rect x="31" y="31" width="18" height="18" rx="3" fill="#3a3d45" />
            <rect class="pin" x="28" y="16" width="4" height="8" rx="1" fill="#d8a657" />
            <rect class="pin" x="38" y="16" width="4" height="8" rx="1" fill="#d8a657" />
            <rect class="pin" x="48" y="16" width="4" height="8" rx="1" fill="#d8a657" />
            <rect class="pin" x="28" y="56" width="4" height="8" rx="1" fill="#d8a657" />
            <rect class="pin" x="38" y="56" width="4" height="8" rx="1" fill="#d8a657" />
            <rect class="pin" x="48" y="56" width="4" height="8" rx="1" fill="#d8a657" />
            <rect class="pin" x="16" y="28" width="8" height="4" rx="1" fill="#d8a657" />
            <rect class="pin" x="16" y="38" width="8" height="4" rx="1" fill="#d8a657" />
            <rect class="pin" x="16" y="48" width="8" height="4" rx="1" fill="#d8a657" />
            <rect class="pin" x="56" y="28" width="8" height="4" rx="1" fill="#d8a657" />
            <rect class="pin" x="56" y="38" width="8" height="4" rx="1" fill="#d8a657" />
            <rect class="pin" x="56" y="48" width="8" height="4" rx="1" fill="#d8a657" />
          </svg>
          <h3>Learn the parts</h3>
          <p>Meet the CPU, RAM, GPU and friends with kid-friendly explanations.</p>
          <a class="btn hq-btn btn-sm" href="<%= ResolveUrl("~/Hardware/List") %>">Browse parts</a>
        </div>

        <!-- 3) Take quizzes — leaderboard bars rising + a twinkling star -->
        <div class="feature-card">
          <svg class="ficon" data-icon="quiz" viewBox="0 0 80 80" aria-hidden="true">
            <rect class="bar" x="14" y="40" width="13" height="26" rx="2" fill="#2e6950" />
            <rect class="bar" x="33" y="30" width="13" height="36" rx="2" fill="#54d6a0" />
            <rect class="bar" x="52" y="22" width="13" height="44" rx="2" fill="#8a5021" />
            <path class="star" d="M58 6 l2.4 4.9 5.4 .8 -3.9 3.8 .9 5.4 -4.8 -2.5 -4.8 2.5 .9 -5.4 -3.9 -3.8 5.4 -.8 z" fill="#ffd166" />
          </svg>
          <h3>Take quizzes</h3>
          <p>Test what you know, earn points and climb the leaderboard.</p>
          <a class="btn hq-btn btn-sm" href="<%= ResolveUrl("~/Quiz/List") %>">Start a quiz</a>
        </div>

        <!-- 4) Join the forum — chat bubbles gently pulsing -->
        <div class="feature-card">
          <svg class="ficon" data-icon="forum" viewBox="0 0 80 80" aria-hidden="true">
            <g class="bubble">
              <rect x="10" y="16" width="42" height="28" rx="9" fill="#2e6950" />
              <polygon points="18,44 18,54 30,44" fill="#2e6950" />
              <circle cx="22" cy="30" r="2.5" fill="#bfe6d5" />
              <circle cx="31" cy="30" r="2.5" fill="#bfe6d5" />
              <circle cx="40" cy="30" r="2.5" fill="#bfe6d5" />
            </g>
            <g class="bubble">
              <rect x="34" y="38" width="36" height="24" rx="8" fill="#54d6a0" />
              <polygon points="62,62 62,70 50,62" fill="#54d6a0" />
            </g>
          </svg>
          <h3>Join the forum</h3>
          <p>Ask questions, share what you learned and help other explorers.</p>
          <a class="btn hq-btn btn-sm" href="<%= ResolveUrl("~/Forum/List") %>">Visit the forum</a>
        </div>

      </div>
    </section>

    <%-- ===================== CALL TO ACTION ===================== --%>
    <section>
      <div class="home-cta">
        <h2>Ready to start your quest?</h2>
        <p>Jump into the 3D Explorer, or browse the parts library and take your first quiz today.</p>
        <a class="btn-cta" href="<%= ResolveUrl("~/Explore/InsideTheMachine") %>">Start exploring</a>
      </div>
    </section>

  </div>

  <%-- GSAP (free incl. DrawSVG + ScrollTrigger since 2025), loaded from CDN like the site's other libs --%>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/gsap.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/DrawSVGPlugin.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/gsap@3/dist/ScrollTrigger.min.js"></script>
  <script>
    (function () {
      // Degrade gracefully: if GSAP failed to load, everything stays static & visible.
      if (!window.gsap) return;
      // Respect users who prefer reduced motion — leave the page fully drawn & still.
      if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return;

      var hasDraw = typeof DrawSVGPlugin !== 'undefined';
      var hasST = typeof ScrollTrigger !== 'undefined';
      if (hasDraw) gsap.registerPlugin(DrawSVGPlugin);
      if (hasST) gsap.registerPlugin(ScrollTrigger);

      /* ---------- HERO motherboard ---------- */
      var tl = gsap.timeline({ defaults: { ease: 'power2.out' } });
      if (hasDraw) {
        tl.from('.hq-board .trace', { drawSVG: 0, duration: 1.2, stagger: 0.18, ease: 'power1.inOut' });
      }
      tl.from('.hq-board [data-anim="part"]', {
        opacity: 0, scale: 0, transformOrigin: '50% 50%',
        duration: 0.5, stagger: 0.12, ease: 'back.out(1.7)'
      }, hasDraw ? '-=0.6' : 0);

      gsap.to('.hq-board .fan', { rotation: 360, duration: 2.4, repeat: -1, ease: 'none', transformOrigin: '50% 50%' });
      gsap.to('.hq-board .led', { opacity: 0.25, duration: 0.7, repeat: -1, yoyo: true, delay: 2 });
      if (hasDraw) {
        gsap.set('.hq-board .flow', { opacity: 1 });
        gsap.fromTo('.hq-board .flow', { drawSVG: '0% 0%' },
          { drawSVG: '88% 100%', duration: 1.6, repeat: -1, ease: 'sine.inOut', delay: 1.8 });
      }

      /* ---------- FEATURE ICONS (one animation each) ---------- */
      // 1) cube: gentle float + wobble
      gsap.to('[data-icon="cube"] .cube', {
        y: -6, rotation: 8, duration: 1.8, repeat: -1, yoyo: true, ease: 'sine.inOut', transformOrigin: '50% 50%'
      });
      // 2) cpu: pins light up in a travelling wave
      gsap.fromTo('[data-icon="cpu"] .pin', { opacity: 0.25 },
        { opacity: 1, duration: 0.5, repeat: -1, yoyo: true, ease: 'sine.inOut', stagger: { each: 0.1 } });
      // 3) quiz: star twinkles always; bars rise when scrolled into view
      gsap.to('[data-icon="quiz"] .star', { rotation: 360, duration: 6, repeat: -1, ease: 'none', transformOrigin: '50% 50%' });
      var barTween = { scaleY: 0, transformOrigin: '50% 100%', duration: 0.6, stagger: 0.12, ease: 'back.out(2)' };
      if (hasST) {
        barTween.scrollTrigger = { trigger: '[data-icon="quiz"]', start: 'top 90%' };
      }
      gsap.from('[data-icon="quiz"] .bar', barTween);
      // 4) forum: chat bubbles gently pulse
      gsap.to('[data-icon="forum"] .bubble', {
        scale: 1.08, duration: 0.9, repeat: -1, yoyo: true, ease: 'sine.inOut',
        stagger: 0.25, transformOrigin: '50% 50%'
      });

      /* ---------- SCROLL REVEALS ---------- */
      if (hasST) {
        gsap.utils.toArray('.feature-card').forEach(function (card) {
          gsap.from(card, {
            opacity: 0, y: 40, duration: 0.6, ease: 'power2.out',
            scrollTrigger: { trigger: card, start: 'top 88%' }
          });
        });
        gsap.from('.home-cta', {
          opacity: 0, y: 40, duration: 0.7, ease: 'power2.out',
          scrollTrigger: { trigger: '.home-cta', start: 'top 90%' }
        });
      }
    })();
  </script>
</asp:Content>
