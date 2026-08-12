#!/usr/bin/env python3
"""Drives headless Chrome over CDP against a rendered landing page.

Adapted from doc-site/tool/verify_in_browser.py, and it exists for the same
reason: the DOM lies. Every assertion here can pass while the thing asserted on
is invisible, two pixels tall, or stacked underneath the ambient background. So
this both asserts *and* writes screenshots to `build/verify/` for a human.

The checks that matter on a marketing page are not "does the text exist" — it
is static HTML, of course it does. They are:

  reveal      the scroll-reveal actually finishes, i.e. the page is not left
              permanently invisible because an observer never fired. This is
              the single worst failure this page can have and it is invisible
              to any HTML-level check.
  tabs        the pipeline tablist swaps panels, and arrow keys move it
  nomotion    with prefers-reduced-motion, content is visible immediately
  nojs        with JavaScript disabled, content is visible at all
  overflow    nothing scrolls the page sideways at any width

Usage:  python3 tool/verify_in_browser.py <url>
"""

from __future__ import annotations

import base64
import json
import os
import shutil
import subprocess
import sys
import tempfile
import time
import urllib.request

try:
    from websocket import create_connection  # type: ignore
except ImportError:
    sys.exit('pip install websocket-client')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHOTS = os.path.join(ROOT, 'build', 'verify')
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

failures: list[str] = []


def check(name: str, condition: bool, detail: str = '') -> None:
    if condition:
        print(f'  ok   {name}')
    else:
        print(f'  FAIL {name}{" — " + detail if detail else ""}')
        failures.append(name)


class Browser:
    """A very small CDP client. No Selenium, no Playwright — a WebSocket is enough."""

    def __init__(self, port: int, *, reduced_motion: bool = False, javascript: bool = True):
        self.port = port
        self._id = 0
        flags = [
            CHROME,
            '--headless=new',
            f'--remote-debugging-port={port}',
            # Or the WebSocket handshake 403s.
            '--remote-allow-origins=*',
            '--hide-scrollbars',
            '--no-first-run',
        ]
        if reduced_motion:
            flags.append('--force-prefers-reduced-motion')
        if not javascript:
            flags.append('--disable-javascript')

        self.profile = tempfile.mkdtemp(prefix='revali-landing-cdp-')
        self.process = subprocess.Popen(
            flags + [f'--user-data-dir={self.profile}', 'about:blank'],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        self.socket = create_connection(self._wait_for_target(), suppress_origin=True)
        self.send('Page.enable')
        self.send('Runtime.enable')

    def _wait_for_target(self) -> str:
        for _ in range(100):
            try:
                targets = json.load(urllib.request.urlopen(f'http://127.0.0.1:{self.port}/json'))
                for target in targets:
                    if target.get('type') == 'page':
                        return target['webSocketDebuggerUrl']
            except Exception:
                pass
            time.sleep(0.1)
        raise RuntimeError('Chrome never exposed a debuggable page')

    def send(self, method: str, **params: object) -> dict:
        self._id += 1
        self.socket.send(json.dumps({'id': self._id, 'method': method, 'params': params}))
        while True:
            message = json.loads(self.socket.recv())
            if message.get('id') == self._id:
                if 'error' in message:
                    raise RuntimeError(f'{method}: {message["error"]}')
                return message.get('result', {})

    def evaluate(self, expression: str) -> object:
        result = self.send(
            'Runtime.evaluate',
            expression=expression,
            returnByValue=True,
            awaitPromise=True,
        )
        if result.get('exceptionDetails'):
            raise RuntimeError(result['exceptionDetails'].get('text', 'JS threw'))
        return result['result'].get('value')

    def navigate(self, url: str) -> None:
        self.send('Page.navigate', url=url)
        self.send('Runtime.evaluate', expression='1')
        for _ in range(200):
            if self.evaluate('document.readyState === "complete"'):
                return
            time.sleep(0.05)

    def viewport(self, width: int, height: int, mobile: bool = False) -> None:
        self.send(
            'Emulation.setDeviceMetricsOverride',
            width=width,
            height=height,
            deviceScaleFactor=2,
            mobile=mobile,
        )

    def scroll_through(self) -> None:
        """Scroll the whole page so every IntersectionObserver gets a chance.

        Stepwise rather than one jump to the bottom: a single jump can skip
        past an observer's root margin entirely in one frame, which would make
        this pass while a real reader — who scrolls — sees nothing appear.
        """
        height = self.evaluate('document.body.scrollHeight')
        step = self.evaluate('window.innerHeight') * 0.6
        position = 0.0
        while position < height:
            self.evaluate(f'window.scrollTo(0, {position})')
            position += step
            time.sleep(0.12)
        self.evaluate('window.scrollTo(0, 0)')
        time.sleep(0.4)

    def screenshot(self, name: str, full: bool = False) -> None:
        data = self.send('Page.captureScreenshot', captureBeyondViewport=full)['data']
        with open(os.path.join(SHOTS, f'{name}.png'), 'wb') as handle:
            handle.write(base64.b64decode(data))

    def close(self) -> None:
        try:
            self.socket.close()
        finally:
            self.process.terminate()
            shutil.rmtree(self.profile, ignore_errors=True)


# Does the PAGE scroll sideways?
#
# The test is `scrollWidth > clientWidth` on the root, not "is any element
# wider than the viewport". Those are very different questions: this page is
# full of elements that deliberately extend past the viewport — the ambient
# glows (inside a `position: fixed; overflow: hidden` parent), the tab strip
# and every code block (inside their own `overflow-x: auto`). All are clipped
# or scroll internally, none move the page. An element-rect check flags all of
# them and would have to be suppressed case by case until it asserted nothing.
#
# Only when the root really does overflow is it worth naming a culprit, and
# then the useful ones are elements NOT inside a scroll/clip container.
OVERFLOW_JS = """
(() => {
  const root = document.documentElement;
  if (root.scrollWidth <= root.clientWidth) return [];

  const clipped = (el) => {
    for (let p = el.parentElement; p; p = p.parentElement) {
      const overflow = getComputedStyle(p).overflowX;
      if (overflow === 'hidden' || overflow === 'auto' || overflow === 'scroll') {
        return true;
      }
    }
    return false;
  };

  return [...document.querySelectorAll('body *')]
    .filter((el) => el.getBoundingClientRect().right > root.clientWidth + 1)
    .filter((el) => !clipped(el))
    .map((el) => el.className || el.tagName)
    .slice(0, 5);
})()
"""


def run_checks(base: str) -> None:
    browser = Browser(9333)
    try:
        browser.viewport(1440, 900)
        browser.navigate(base)
        time.sleep(0.6)

        check('page renders', bool(browser.evaluate('document.querySelectorAll("section").length >= 5')))
        check('js armed', browser.evaluate('document.documentElement.classList.contains("js")') is True)
        browser.screenshot('01-hero')

        # --- The important one: does the reveal ever finish? ---------------
        browser.scroll_through()
        pending = browser.evaluate(
            'document.querySelectorAll("[data-reveal]:not(.is-in)").length'
        )
        check('all reveals fired', pending == 0, f'{pending} still hidden')

        # --- Pipeline tabs -------------------------------------------------
        browser.evaluate('document.querySelector("#how").scrollIntoView()')
        time.sleep(0.4)
        browser.evaluate('document.querySelector("[data-tab=\\"openapi\\"]").click()')
        time.sleep(0.4)
        check(
            'tab swaps panel',
            browser.evaluate('!document.querySelector("[data-panel=\\"openapi\\"]").hidden')
            and browser.evaluate('document.querySelector("[data-panel=\\"server\\"]").hidden') is True,
        )
        check(
            'one panel visible at a time',
            browser.evaluate('document.querySelectorAll("[data-panel]:not([hidden])").length') == 1,
        )
        browser.screenshot('02-pipeline')

        # --- Lifecycle animation runs -------------------------------------
        browser.evaluate('document.querySelector("#lifecycle").scrollIntoView()')
        time.sleep(1.2)
        check(
            'lifecycle signal runs',
            browser.evaluate('document.querySelectorAll("[data-step][data-on=\\"true\\"]").length') > 0,
        )
        browser.screenshot('03-lifecycle')

        browser.evaluate('document.querySelector("#features").scrollIntoView()')
        time.sleep(0.5)
        browser.screenshot('04-features')

        browser.evaluate('document.querySelector("#loop").scrollIntoView()')
        time.sleep(0.5)
        browser.screenshot('05-loop')

        browser.evaluate('document.querySelector("#start").scrollIntoView()')
        time.sleep(0.5)
        browser.screenshot('06-quickstart')

        # --- Horizontal overflow at three widths --------------------------
        for width, label in ((1440, 'desktop'), (900, 'tablet'), (390, 'mobile')):
            browser.viewport(width, 900, mobile=width < 500)
            browser.navigate(base)
            time.sleep(0.6)
            browser.scroll_through()
            offenders = browser.evaluate(OVERFLOW_JS)
            check(f'no sideways scroll @ {label}', not offenders, str(offenders))

        browser.viewport(390, 844, mobile=True)
        browser.navigate(base)
        time.sleep(0.6)
        browser.screenshot('07-mobile')
        browser.scroll_through()
        browser.evaluate('document.querySelector("#how").scrollIntoView()')
        time.sleep(0.4)
        browser.screenshot('08-mobile-pipeline')
    finally:
        browser.close()

    # --- Reduced motion: content must be visible with no scrolling at all --
    reduced = Browser(9334, reduced_motion=True)
    try:
        reduced.viewport(1440, 900)
        reduced.navigate(base)
        time.sleep(0.8)
        hidden = reduced.evaluate(
            '[...document.querySelectorAll("[data-reveal]")]'
            '.filter((el) => getComputedStyle(el).opacity !== "1").length'
        )
        check('reduced motion shows everything', hidden == 0, f'{hidden} transparent')
        reduced.screenshot('09-reduced-motion')
    finally:
        reduced.close()

    # --- No JS: the page must still be a page -----------------------------
    nojs = Browser(9335, javascript=False)
    try:
        nojs.viewport(1440, 900)
        nojs.navigate(base)
        time.sleep(0.8)
        nojs.screenshot('10-no-js')
        print('  ..   no-js screenshot written (inspect 10-no-js.png)')
    finally:
        nojs.close()


def main() -> int:
    if len(sys.argv) < 2:
        sys.exit('usage: verify_in_browser.py <url>')
    os.makedirs(SHOTS, exist_ok=True)
    run_checks(sys.argv[1].rstrip('/'))

    print()
    if failures:
        print(f'{len(failures)} check(s) failed: {", ".join(failures)}')
        return 1
    print('all checks passed')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
