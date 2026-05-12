// MoodTune wireframes — pan/zoom + flow arrows

(function () {
  const viewport = document.getElementById('viewport');
  const canvas = document.getElementById('canvas');
  const arrowsSvg = document.getElementById('arrows');
  const zoomReadout = document.getElementById('zoom-readout');

  const CANVAS_W = 4400;
  const CANVAS_H = 5200;

  let scale = 0.55;
  let tx = 60;
  let ty = 40;

  function applyTransform() {
    canvas.style.transform = `translate(${tx}px, ${ty}px) scale(${scale})`;
    zoomReadout.textContent = Math.round(scale * 100) + '%';
  }

  function fitToView() {
    const vw = viewport.clientWidth - 80;
    const vh = viewport.clientHeight - 80;
    const sx = vw / CANVAS_W;
    const sy = vh / CANVAS_H;
    scale = Math.min(sx, sy);
    tx = (viewport.clientWidth - CANVAS_W * scale) / 2;
    ty = (viewport.clientHeight - CANVAS_H * scale) / 2;
    applyTransform();
  }

  function reset() {
    scale = 0.55;
    tx = 60;
    ty = 40;
    applyTransform();
  }

  // Pan via drag
  let isDown = false;
  let startX = 0, startY = 0;
  let startTx = 0, startTy = 0;

  viewport.addEventListener('mousedown', (e) => {
    isDown = true;
    viewport.classList.add('grabbing');
    startX = e.clientX;
    startY = e.clientY;
    startTx = tx;
    startTy = ty;
  });
  window.addEventListener('mousemove', (e) => {
    if (!isDown) return;
    tx = startTx + (e.clientX - startX);
    ty = startTy + (e.clientY - startY);
    applyTransform();
  });
  window.addEventListener('mouseup', () => {
    isDown = false;
    viewport.classList.remove('grabbing');
  });

  // Zoom via wheel (anchored at cursor)
  viewport.addEventListener('wheel', (e) => {
    e.preventDefault();
    const rect = viewport.getBoundingClientRect();
    const cx = e.clientX - rect.left;
    const cy = e.clientY - rect.top;

    const factor = e.deltaY > 0 ? 0.9 : 1.1;
    const newScale = Math.max(0.15, Math.min(2.5, scale * factor));

    // keep point under cursor stable
    const wx = (cx - tx) / scale;
    const wy = (cy - ty) / scale;
    scale = newScale;
    tx = cx - wx * scale;
    ty = cy - wy * scale;
    applyTransform();
  }, { passive: false });

  // Zoom buttons
  document.getElementById('zoom-in').addEventListener('click', () => zoomCentered(1.2));
  document.getElementById('zoom-out').addEventListener('click', () => zoomCentered(1 / 1.2));
  document.getElementById('fit').addEventListener('click', fitToView);
  document.getElementById('reset').addEventListener('click', reset);

  function zoomCentered(factor) {
    const cx = viewport.clientWidth / 2;
    const cy = viewport.clientHeight / 2;
    const newScale = Math.max(0.15, Math.min(2.5, scale * factor));
    const wx = (cx - tx) / scale;
    const wy = (cy - ty) / scale;
    scale = newScale;
    tx = cx - wx * scale;
    ty = cy - wy * scale;
    applyTransform();
  }

  // Keyboard
  window.addEventListener('keydown', (e) => {
    if (e.key === 'f' || e.key === 'F') fitToView();
    else if (e.key === '0') reset();
    else if (e.key === '+' || e.key === '=') zoomCentered(1.2);
    else if (e.key === '-') zoomCentered(1 / 1.2);
  });

  // Touch (basic pan)
  let touchStart = null;
  viewport.addEventListener('touchstart', (e) => {
    if (e.touches.length === 1) {
      touchStart = { x: e.touches[0].clientX, y: e.touches[0].clientY, tx, ty };
    }
  }, { passive: true });
  viewport.addEventListener('touchmove', (e) => {
    if (e.touches.length === 1 && touchStart) {
      tx = touchStart.tx + (e.touches[0].clientX - touchStart.x);
      ty = touchStart.ty + (e.touches[0].clientY - touchStart.y);
      applyTransform();
    }
  }, { passive: true });

  applyTransform();

  // ====== FLOW ARROWS ======
  // Each screen artboard is 280px wide (phone) inside a wrapper that starts
  // with a small title bar. We use the screen wrapper left/top + measured size
  // to compute anchors.

  function bbox(id) {
    const el = document.getElementById(id);
    if (!el) return null;
    // Use offset within canvas
    const left = el.offsetLeft;
    const top = el.offsetTop;
    // phone is the focal element
    const phone = el.querySelector('.phone');
    const phoneLeft = left + (phone ? phone.offsetLeft : 0);
    const phoneTop = top + (phone ? phone.offsetTop : 24); // title height ~24
    const w = phone ? phone.offsetWidth : el.offsetWidth;
    const h = phone ? phone.offsetHeight : el.offsetHeight;
    return {
      left: phoneLeft,
      top: phoneTop,
      right: phoneLeft + w,
      bottom: phoneTop + h,
      cx: phoneLeft + w / 2,
      cy: phoneTop + h / 2,
      w, h,
    };
  }

  function anchor(b, side, offset = 0) {
    if (!b) return null;
    switch (side) {
      case 'right':  return { x: b.right, y: b.cy + offset };
      case 'left':   return { x: b.left,  y: b.cy + offset };
      case 'top':    return { x: b.cx + offset, y: b.top };
      case 'bottom': return { x: b.cx + offset, y: b.bottom };
    }
  }

  function drawArrow(fromId, fromSide, toId, toSide, opts = {}) {
    const a = anchor(bbox(fromId), fromSide, opts.fromOffset || 0);
    const b = anchor(bbox(toId), toSide, opts.toOffset || 0);
    if (!a || !b) return;

    const muted = opts.muted;
    const stroke = muted ? '#8a8275' : '#2d2a26';
    const marker = muted ? 'url(#arrowhead-muted)' : 'url(#arrowhead)';
    const dash = opts.dash ? '6 5' : 'none';
    const sw = opts.thick ? 2.4 : 1.8;

    // path: simple cubic, control points offset perpendicular to direction
    const dx = b.x - a.x;
    const dy = b.y - a.y;
    const horizontal = Math.abs(dx) >= Math.abs(dy);
    let c1x, c1y, c2x, c2y;
    if (horizontal) {
      const k = Math.abs(dx) * 0.45;
      c1x = a.x + Math.sign(dx) * k;
      c1y = a.y;
      c2x = b.x - Math.sign(dx) * k;
      c2y = b.y;
    } else {
      const k = Math.abs(dy) * 0.45;
      c1x = a.x;
      c1y = a.y + Math.sign(dy) * k;
      c2x = b.x;
      c2y = b.y - Math.sign(dy) * k;
    }
    const d = `M ${a.x} ${a.y} C ${c1x} ${c1y}, ${c2x} ${c2y}, ${b.x} ${b.y}`;

    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', d);
    path.setAttribute('fill', 'none');
    path.setAttribute('stroke', stroke);
    path.setAttribute('stroke-width', sw);
    path.setAttribute('stroke-dasharray', dash);
    path.setAttribute('marker-end', marker);
    path.setAttribute('stroke-linecap', 'round');
    arrowsSvg.appendChild(path);

    if (opts.label) {
      // midpoint
      const t = 0.5;
      const mx = (1 - t) ** 3 * a.x + 3 * (1 - t) ** 2 * t * c1x + 3 * (1 - t) * t ** 2 * c2x + t ** 3 * b.x;
      const my = (1 - t) ** 3 * a.y + 3 * (1 - t) ** 2 * t * c1y + 3 * (1 - t) * t ** 2 * c2y + t ** 3 * b.y;
      // background rect
      const padding = 6;
      const text = document.createElementNS('http://www.w3.org/2000/svg', 'text');
      text.setAttribute('x', mx);
      text.setAttribute('y', my);
      text.setAttribute('text-anchor', 'middle');
      text.setAttribute('dominant-baseline', 'middle');
      text.setAttribute('font-family', 'ui-sans-serif, system-ui, sans-serif');
      text.setAttribute('font-size', '12');
      text.setAttribute('font-weight', '600');
      text.setAttribute('fill', muted ? '#6b6256' : '#2d2a26');
      text.textContent = opts.label;
      // measure approx by char count
      const approxW = opts.label.length * 6.8 + padding * 2;
      const rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect');
      rect.setAttribute('x', mx - approxW / 2);
      rect.setAttribute('y', my - 10);
      rect.setAttribute('width', approxW);
      rect.setAttribute('height', 20);
      rect.setAttribute('rx', 4);
      rect.setAttribute('fill', '#efece6');
      rect.setAttribute('stroke', muted ? '#b9b1a3' : '#2d2a26');
      rect.setAttribute('stroke-width', '1');
      arrowsSvg.appendChild(rect);
      arrowsSvg.appendChild(text);
    }
  }

  // Defer until layout settles
  requestAnimationFrame(() => {
    // Row A → B: Landing → Upload(a)
    drawArrow('s-landing', 'bottom', 's-upload-a', 'top', { label: 'Try it — upload now' });
    // Landing → Sign in
    drawArrow('s-landing', 'right', 's-signin', 'left', { label: 'Sign in', muted: true });

    // Variants relationship (B): a ↔ b
    drawArrow('s-upload-a', 'right', 's-upload-b', 'left', { label: 'variant', muted: true, dash: true });

    // Upload empty → File selected
    drawArrow('s-upload-b', 'right', 's-upload-selected', 'left', { label: 'file picked' });

    // Selected → Consent
    drawArrow('s-upload-selected', 'bottom', 's-consent', 'top', { label: 'Analyze song', thick: true });

    // Upload selected → Errors (lateral)
    drawArrow('s-upload-selected', 'right', 's-upload-oversize', 'left', { label: 'file > 15 MB', muted: true });
    drawArrow('s-upload-oversize', 'right', 's-upload-format', 'left', { muted: true, dash: true, label: 'same template' });

    // Consent → Loading
    drawArrow('s-consent', 'right', 's-loading', 'left', { label: 'Yes, let\u2019s hear it', thick: true });

    // Loading → Results (Upbeat sample)
    drawArrow('s-loading', 'bottom', 's-result-upbeat', 'top', { label: 'analysis complete', thick: true });

    // Loading → error variants
    drawArrow('s-loading', 'right', 's-timeout', 'left', { muted: true, label: '> 15s' });
    drawArrow('s-timeout', 'right', 's-offline', 'left', { muted: true, dash: true });
    drawArrow('s-offline', 'right', 's-ratelimit', 'left', { muted: true, dash: true });
    drawArrow('s-ratelimit', 'right', 's-failure', 'left', { muted: true, dash: true });

    // Results moods are visual siblings
    drawArrow('s-result-upbeat', 'right', 's-result-serene', 'left', { muted: true, dash: true, label: 'palette swap' });
    drawArrow('s-result-serene', 'right', 's-result-charged', 'left', { muted: true, dash: true });
    drawArrow('s-result-charged', 'right', 's-result-reflective', 'left', { muted: true, dash: true });

    // Guest Results → Sign in (CTA strip)
    drawArrow('s-result-upbeat', 'top', 's-signin', 'bottom', { label: 'Sign up CTA', muted: true, fromOffset: -60 });

    // Auth flow: Home (Auth) ↔ Upload (same flow as guest)
    drawArrow('s-home-auth', 'top', 's-upload-a', 'bottom', { label: 'Analyze new song', muted: true, fromOffset: -40 });
    // Auth: Loading → Results (Auth)
    drawArrow('s-loading', 'bottom', 's-result-auth', 'top', { label: 'auth path', muted: true, dash: true, fromOffset: 60 });
    // Home (Auth) → Results (Auth) via history tap
    drawArrow('s-home-auth', 'right', 's-result-auth', 'left', { label: 'tap history item' });

    // Sign in → Home Auth (success)
    drawArrow('s-signin', 'bottom', 's-home-auth', 'top', { label: 'success', thick: true });
  });
})();
