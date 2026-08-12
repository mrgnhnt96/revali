/* ==========================================================================
   Revali — interaction layer
   --------------------------------------------------------------------------
   Five small behaviours, no framework, no dependencies. Everything here is
   PROGRESSIVE: the page is complete and readable with this file blocked, and
   nothing below ever hides content that it is then responsible for revealing.

   The one thing this script does before anything else is add `.js` to <html>,
   which is what arms the reveal styles in styles.css. That ordering is the
   whole contract — if the script fails to load, those rules never match and
   every section is simply visible.
   ========================================================================== */

(() => {
  'use strict';

  const root = document.documentElement;
  root.classList.add('js');

  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

  /* ---------------------------------------------------------------------
     1. Header — frost it once the page has scrolled off the hero.
     --------------------------------------------------------------------- */

  const header = document.querySelector('[data-header]');
  if (header) {
    // rAF-throttled: scroll fires far more often than the screen repaints,
    // and this only ever flips one attribute.
    let ticking = false;
    const sync = () => {
      header.dataset.stuck = String(window.scrollY > 12);
      ticking = false;
    };
    addEventListener(
      'scroll',
      () => {
        if (!ticking) {
          ticking = true;
          requestAnimationFrame(sync);
        }
      },
      { passive: true },
    );
    sync();
  }

  /* ---------------------------------------------------------------------
     2. Scroll reveal.
     --------------------------------------------------------------------- */

  const revealables = document.querySelectorAll('[data-reveal]');

  if (reduced || !('IntersectionObserver' in window)) {
    // No observer, or the visitor asked for less motion: show everything now.
    // The CSS also covers the reduced-motion case, but an old browser without
    // IntersectionObserver would otherwise be left with an invisible page.
    revealables.forEach((el) => el.classList.add('is-in'));
  } else {
    const io = new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (!entry.isIntersecting) continue;
          entry.target.classList.add('is-in');
          // One-shot. Re-animating on the way back up is a tic, not a feature.
          io.unobserve(entry.target);
        }
      },
      // A negative bottom margin holds the reveal until the element is
      // properly on screen rather than one pixel into it.
      { rootMargin: '0px 0px -12% 0px', threshold: 0.08 },
    );

    revealables.forEach((el) => {
      // Anything already in view at load has no entrance to play — animating
      // it would mean showing the visitor a blank hero and then fading it in.
      if (el.getBoundingClientRect().top < innerHeight * 0.9) {
        el.classList.add('is-in');
      } else {
        io.observe(el);
      }
    });
  }

  /* ---------------------------------------------------------------------
     3. Pipeline tabs.
     --------------------------------------------------------------------- */

  const pipeline = document.querySelector('[data-pipeline]');
  if (pipeline) {
    const tabs = [...pipeline.querySelectorAll('[data-tab]')];
    const panels = [...pipeline.querySelectorAll('[data-panel]')];

    const select = (id, { focus = false } = {}) => {
      for (const tab of tabs) {
        const on = tab.dataset.tab === id;
        tab.setAttribute('aria-selected', String(on));
        // Roving tabindex: only the selected tab is a tab stop, so the
        // tablist is one stop in the page order and arrows move within it.
        tab.tabIndex = on ? 0 : -1;
        if (on && focus) tab.focus();
      }
      for (const panel of panels) {
        panel.hidden = panel.dataset.panel !== id;
      }
    };

    tabs.forEach((tab, index) => {
      tab.addEventListener('click', () => select(tab.dataset.tab));

      tab.addEventListener('keydown', (event) => {
        const delta =
          { ArrowDown: 1, ArrowRight: 1, ArrowUp: -1, ArrowLeft: -1 }[event.key] ??
          0;

        if (delta) {
          event.preventDefault();
          // Wraps at both ends — the expected behaviour for a tablist.
          const next = tabs[(index + delta + tabs.length) % tabs.length];
          select(next.dataset.tab, { focus: true });
        } else if (event.key === 'Home' || event.key === 'End') {
          event.preventDefault();
          const edge = event.key === 'Home' ? tabs[0] : tabs[tabs.length - 1];
          select(edge.dataset.tab, { focus: true });
        }
      });
    });
  }

  /* ---------------------------------------------------------------------
     4. Lifecycle — run a signal down the track while it is on screen.
     --------------------------------------------------------------------- */

  const track = document.querySelector('[data-lifecycle]');
  if (track && !reduced && 'IntersectionObserver' in window) {
    const steps = [...track.querySelectorAll('[data-step]')];
    let timer = null;
    let index = 0;

    const tick = () => {
      steps.forEach((step, i) => {
        // A short trailing comet rather than a single lit dot: three steps
        // stay on, so the eye reads a direction of travel.
        step.dataset.on = String(i <= index && i > index - 3);
      });
      index = (index + 1) % (steps.length + 3);
    };

    // Only runs while visible. An off-screen setInterval is a battery drain
    // that also keeps the tab from ever going idle.
    new IntersectionObserver(
      (entries) => {
        for (const entry of entries) {
          if (entry.isIntersecting && timer === null) {
            timer = setInterval(tick, 420);
            tick();
          } else if (!entry.isIntersecting && timer !== null) {
            clearInterval(timer);
            timer = null;
          }
        }
      },
      { threshold: 0.25 },
    ).observe(track);
  }

  /* ---------------------------------------------------------------------
     5. Copy buttons.
     --------------------------------------------------------------------- */

  // Delegated, so it costs one listener regardless of how many buttons the
  // page grows.
  document.addEventListener('click', async (event) => {
    const button = event.target.closest('[data-copy]');
    if (!button) return;

    const label = button.querySelector('span');
    const original = label ? label.textContent : '';

    try {
      // Requires a secure context; the catch below is the http:// path, not
      // just a theoretical failure.
      await navigator.clipboard.writeText(button.dataset.copy);
      button.dataset.copied = 'true';
      if (label) label.textContent = 'copied';
    } catch {
      if (label) label.textContent = 'press ⌘C';
      return;
    }

    setTimeout(() => {
      delete button.dataset.copied;
      if (label) label.textContent = original;
    }, 1600);
  });

  /* ---------------------------------------------------------------------
     6. Pointer-tracked card highlight.
     --------------------------------------------------------------------- */

  // Skipped entirely on touch and for reduced motion: `hover: hover` keeps
  // this off phones, where the highlight would be stuck wherever the last tap
  // landed.
  if (!reduced && matchMedia('(hover: hover) and (pointer: fine)').matches) {
    for (const card of document.querySelectorAll('.card')) {
      card.addEventListener(
        'pointermove',
        (event) => {
          const rect = card.getBoundingClientRect();
          card.style.setProperty('--mx', `${event.clientX - rect.left}px`);
          card.style.setProperty('--my', `${event.clientY - rect.top}px`);
        },
        { passive: true },
      );
    }
  }
})();
