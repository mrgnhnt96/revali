/* ==========================================================================
   Revali — analytics
   --------------------------------------------------------------------------
   Everything this site does with PostHog and Amplitude is in this file, and
   the privacy page describes it. Change one, change the other.

   Analytics stay off when the visitor turned them off on /privacy/, or when
   their browser sends Global Privacy Control. While they are off nothing loads
   and any IDs left from an earlier visit are removed.

   Both keys are public, write-only and made to ship in client source.
   ========================================================================== */

(() => {
  'use strict';

  const POSTHOG_KEY = 'phc_JvQSPxWXO7nPNdqPEp1i1341AblCBRWZRpS0kKWRheu';
  const AMPLITUDE_KEY = '15288b16e4a64d54978fa9d86adddad1';

  // Amplitude's plain SDK, pinned. Do not swap in the `script/<key>.js` loader:
  // it also bundles Experiment and starts Session Replay from the project's
  // remote config, whatever this file says.
  const AMPLITUDE_SDK =
    'https://cdn.amplitude.com/libs/analytics-browser-2.42.4-min.js.gz';

  const PREFERENCE = 'revali-analytics';
  const ANALYTICS_IDS = /^(ph_|__ph|AMP|EXP_)/;

  const privacySignal = navigator.globalPrivacyControl === true;

  const turnedOff = () => {
    try {
      return localStorage.getItem(PREFERENCE) === 'off';
    } catch {
      return false;
    }
  };

  const load = (src, onload) => {
    const tag = document.createElement('script');
    tag.src = src;
    tag.async = true;
    tag.crossOrigin = 'anonymous';
    // The visitor may have turned analytics off while this was downloading.
    tag.onload = () => {
      if (!turnedOff()) onload();
    };
    document.head.appendChild(tag);
  };

  const start = () => {
    load('https://us-assets.i.posthog.com/static/array.js', () => {
      window.posthog.init(POSTHOG_KEY, {
        api_host: 'https://us.i.posthog.com',
        // Off deliberately: the free plan's 5k/month session-recording budget
        // is shared across every Revali site.
        disable_session_recording: true,
      });
    });

    load(AMPLITUDE_SDK, () => {
      window.amplitude.init(AMPLITUDE_KEY, {
        serverZone: 'US',
        autocapture: true,
      });
    });
  };

  // PostHog scopes its cookie to the parent domain, so a cookie can only be
  // expired by naming the domain it was set on.
  const cookieDomains = () => {
    const labels = location.hostname.split('.');
    const suffixes = labels.slice(0, -1).map((_, i) => labels.slice(i).join('.'));
    return ['', ...suffixes.flatMap((host) => [host, `.${host}`])];
  };

  const removeIds = () => {
    for (const cookie of document.cookie.split('; ')) {
      const name = cookie.split('=')[0];
      if (!ANALYTICS_IDS.test(name)) continue;
      for (const domain of cookieDomains()) {
        const scope = domain ? `; domain=${domain}` : '';
        document.cookie = `${name}=; path=/; max-age=0${scope}`;
      }
    }

    for (const store of [localStorage, sessionStorage]) {
      for (const key of Object.keys(store)) {
        if (ANALYTICS_IDS.test(key)) store.removeItem(key);
      }
    }
  };

  const clearIds = () => {
    try {
      removeIds();
    } catch {
      // Storage blocked: nothing was stored there to remove.
    }
  };

  const stop = () => {
    window.posthog?.opt_out_capturing?.();
    window.amplitude?.setOptOut?.(true);
    clearIds();
    // Amplitude saves its opt-out to a cookie a moment later.
    setTimeout(clearIds, 1000);
    addEventListener('pagehide', clearIds);
  };

  /* The control on /privacy/. It ships `hidden`, so it only appears when this
     script is running and can act on it. */
  const control = document.querySelector('[data-analytics]');
  if (control) {
    const status = control.querySelector('[data-analytics-status]');
    const toggle = control.querySelector('[data-analytics-toggle]');

    const render = (message) => {
      const off = turnedOff();
      toggle.textContent = off ? 'Turn analytics on' : 'Turn analytics off';
      status.textContent =
        message ??
        (off
          ? 'Analytics are off in this browser.'
          : 'Analytics are on in this browser.');
    };

    control.hidden = false;

    if (privacySignal) {
      toggle.hidden = true;
      status.textContent =
        'Your browser sends Global Privacy Control, so analytics are off.';
    } else {
      render();
      toggle.addEventListener('click', () => {
        const turningOn = turnedOff();
        try {
          if (turningOn) {
            localStorage.removeItem(PREFERENCE);
          } else {
            localStorage.setItem(PREFERENCE, 'off');
          }
        } catch {
          render('Your browser blocked this setting, so it was not saved.');
          return;
        }

        if (turningOn) {
          render('Analytics are on from the next page you load.');
        } else {
          stop();
          render('Analytics are off, and their IDs are gone from this browser.');
        }
      });
    }
  }

  if (privacySignal || turnedOff()) {
    clearIds();
  } else {
    start();
  }
})();
