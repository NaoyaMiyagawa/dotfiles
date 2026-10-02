// Draws a fake mouse cursor for headless flow recordings, which have no OS cursor.
// It moves like a hand: curved paths with a fast start and long slowdown, a slight overshoot,
// an idle drift while the page is being read, and a ripple on mousedown.
// window.__flowCursorGlideTo(x, y) glides the arrow while the real pointer stays put, so hover states only
// appear once the script moves the real pointer onto the arrow. window.__flowCursorBusyUntil marks when the
// current motion ends, and window.__flowCursorAt is where the arrow is drawn.
(() => {
  if (window.__flowCursorInstalled) return;
  window.__flowCursorInstalled = true;
  window.__flowCursorBusyUntil = 0;

  const SETTLE_MS = 120; // pause on the target before a click
  const IDLE_AFTER_MS = 350; // stillness before the idle drift starts
  const clamp = (value, min, max) => Math.min(max, Math.max(min, value));
  const random = (min, max) => min + Math.random() * (max - min);
  const easeOut = (t) => 1 - Math.pow(1 - t, 3);
  const easeInOut = (t) => (t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2);
  const cubic = (a, b, c, d, t) => {
    const u = 1 - t;
    return u * u * u * a + 3 * u * u * t * b + 3 * u * t * t * c + t * t * t * d;
  };

  const install = () => {
    const cursor = document.createElement("div");
    cursor.id = "__flow-cursor";
    cursor.innerHTML =
      '<svg width="24" height="24" viewBox="0 0 24 24"><path d="M3 2l7 19 2.6-7.4L20 11z" fill="#111" stroke="#fff" stroke-width="1.5" stroke-linejoin="round"/></svg>';
    Object.assign(cursor.style, {
      position: "fixed",
      left: "0",
      top: "0",
      zIndex: "2147483647",
      pointerEvents: "none",
      willChange: "transform",
    });
    document.documentElement.appendChild(cursor);

    let position = { x: window.innerWidth / 2, y: window.innerHeight * 0.6 };
    let rest = { ...position }; // where the hand settled; the idle drift wanders around it
    let motion = null; // { from, c1, c2, to, startedAt, duration, overshoot?, onDone? }
    let lastActivity = performance.now();
    let nextDriftAt = 0;

    const draw = () => {
      window.__flowCursorAt = { ...position };
      cursor.style.transform = `translate(${position.x - 3}px, ${position.y - 2}px)`;
    };

    // Moves along a cubic curve whose two control points bow by independent amounts,
    // so long paths sometimes wobble into a gentle S instead of a perfect arc.
    const startMotion = (to, { duration, bowScale, overshoot = 0, onDone = null }) => {
      const from = { ...position };
      const dx = to.x - from.x;
      const dy = to.y - from.y;
      const distance = Math.max(1, Math.hypot(dx, dy));
      const normal = { x: -dy / distance, y: dx / distance };
      const side = Math.random() < 0.5 ? -1 : 1;
      const bow1 = side * distance * bowScale * random(0.6, 1.4);
      const bow2 = (Math.random() < 0.3 ? -side : side) * distance * bowScale * random(0.2, 1.0);
      const landing = { x: to.x + (dx / distance) * overshoot, y: to.y + (dy / distance) * overshoot };
      motion = {
        from,
        c1: { x: from.x + dx * 0.3 + normal.x * bow1, y: from.y + dy * 0.3 + normal.y * bow1 },
        c2: { x: from.x + dx * 0.75 + normal.x * bow2, y: from.y + dy * 0.75 + normal.y * bow2 },
        landing,
        to,
        startedAt: performance.now(),
        duration,
        onDone,
      };
    };

    const glideTo = (target) => {
      const distance = Math.hypot(target.x - position.x, target.y - position.y);
      if (distance < 1) return;
      // longer moves take longer, like a hand (Fitts's law), with some variation per move
      const duration = clamp((260 + distance * 0.5) * random(0.9, 1.15), 280, 1000);
      startMotion(target, {
        duration,
        bowScale: random(0.06, 0.14),
        overshoot: Math.min(10, distance * 0.04),
      });
      rest = { ...target };
      window.__flowCursorBusyUntil = motion.startedAt + duration + SETTLE_MS;
      lastActivity = window.__flowCursorBusyUntil;
    };

    const tick = (now) => {
      if (motion) {
        const t = clamp((now - motion.startedAt) / motion.duration, 0, 1);
        const glideShare = motion.landing.x === motion.to.x && motion.landing.y === motion.to.y ? 1 : 0.85;
        if (t >= 1) {
          position = { ...motion.to };
        } else if (t < glideShare) {
          const p = easeOut(t / glideShare);
          position = {
            x: cubic(motion.from.x, motion.c1.x, motion.c2.x, motion.landing.x, p),
            y: cubic(motion.from.y, motion.c1.y, motion.c2.y, motion.landing.y, p),
          };
        } else {
          const p = easeInOut((t - glideShare) / (1 - glideShare));
          position = {
            x: motion.landing.x + (motion.to.x - motion.landing.x) * p,
            y: motion.landing.y + (motion.to.y - motion.landing.y) * p,
          };
        }
        if (t >= 1) {
          const done = motion.onDone;
          motion = null;
          done?.();
        }
        draw();
      } else if (now - lastActivity > IDLE_AFTER_MS && now >= nextDriftAt) {
        // idle drift: a slow few-pixel wander around the resting point, as while reading
        const radius = random(6, 22);
        const angle = random(0, Math.PI * 2);
        const target = {
          x: clamp(rest.x + Math.cos(angle) * radius, 4, window.innerWidth - 4),
          y: clamp(rest.y + Math.sin(angle) * radius, 4, window.innerHeight - 4),
        };
        const duration = random(500, 1100);
        startMotion(target, { duration, bowScale: random(0.1, 0.3) });
        nextDriftAt = now + duration + random(150, 700);
      }
      requestAnimationFrame(tick);
    };

    draw();
    requestAnimationFrame(tick);
    window.__flowCursorGlideTo = (x, y) => glideTo({ x, y });

    window.addEventListener("mousemove", (event) => glideTo({ x: event.clientX, y: event.clientY }), {
      capture: true,
      passive: true,
    });

    window.addEventListener(
      "mousedown",
      (event) => {
        // the drawn arrow may be mid-drift; put it where the real click lands
        motion = null;
        position = { x: event.clientX, y: event.clientY };
        rest = { ...position };
        draw();
        // after the click the hand eases off the control a little
        lastActivity = performance.now() + 250;
        nextDriftAt = 0;

        const ripple = document.createElement("div");
        Object.assign(ripple.style, {
          position: "fixed",
          left: `${event.clientX - 14}px`,
          top: `${event.clientY - 14}px`,
          width: "28px",
          height: "28px",
          borderRadius: "50%",
          background: "rgba(79, 70, 229, 0.35)",
          zIndex: "2147483646",
          pointerEvents: "none",
          transition: "transform 400ms ease-out, opacity 400ms ease-out",
        });
        document.documentElement.appendChild(ripple);
        requestAnimationFrame(() => {
          ripple.style.transform = "scale(2)";
          ripple.style.opacity = "0";
        });
        setTimeout(() => ripple.remove(), 450);
      },
      { capture: true, passive: true },
    );

    window.addEventListener(
      "mouseup",
      () => {
        const away = { x: position.x + random(-30, 30), y: position.y + random(12, 40) };
        rest = away;
        const duration = random(450, 750);
        startMotion(away, { duration, bowScale: random(0.1, 0.25) });
        window.__flowCursorBusyUntil = performance.now() + duration;
        lastActivity = performance.now() + 750;
        nextDriftAt = lastActivity + random(300, 800);
      },
      { capture: true, passive: true },
    );
  };

  if (document.documentElement) install();
  else document.addEventListener("DOMContentLoaded", install);
})();
