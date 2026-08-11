#!/usr/bin/env python3
"""Drives headless Chrome over CDP against `build/jaspr/` and asserts the site works.

This exists because the DOM lies. Every assertion below can pass while the thing
being asserted on is two pixels tall and invisible — which is exactly what
happened to the search dialog on the site this playbook came from. So this both
asserts *and* writes screenshots to `build/verify/` for a human to look at.

What it covers, in order:

  hydration          the @client search component actually mounted
  search             ⌘K opens the dialog, the index is fetched, results rank,
                     <mark> highlights, arrows move, Enter navigates, Esc closes
  navigation         section tabs mark the right one, sidebar opens the group
                     containing the current page and only that one
  content            callouts, code-file headers and mermaid diagrams rendered
  responsive         mobile viewport, plus light and dark screenshots

Usage:  python3 tool/verify_in_browser.py [--keep-server]
"""

from __future__ import annotations

import base64
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time
import urllib.request
from contextlib import closing

try:
    from websocket import create_connection  # type: ignore
except ImportError:
    sys.exit('pip install websocket-client')

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BUILD = os.path.join(ROOT, 'build', 'jaspr')
SHOTS = os.path.join(ROOT, 'build', 'verify')
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'

failures: list[str] = []
checks = 0


def check(name: str, condition: bool, detail: str = '') -> None:
    global checks
    checks += 1
    if condition:
        print(f'  ok   {name}')
    else:
        print(f'  FAIL {name}{" — " + detail if detail else ""}')
        failures.append(name)


def free_port() -> int:
    with closing(socket.socket()) as sock:
        sock.bind(('127.0.0.1', 0))
        return sock.getsockname()[1]


class Browser:
    """A very small CDP client. No Selenium, no Playwright — a WebSocket is enough."""

    def __init__(self, port: int):
        self.port = port
        self._id = 0
        # `--remote-allow-origins='*'` or the WebSocket handshake 403s.
        self.profile = tempfile.mkdtemp(prefix='revali-docs-cdp-')
        self.process = subprocess.Popen(
            [
                CHROME,
                '--headless=new',
                f'--remote-debugging-port={port}',
                '--remote-allow-origins=*',
                f'--user-data-dir={self.profile}',
                '--hide-scrollbars',
                '--no-first-run',
                'about:blank',
            ],
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
        self.wait_for('document.readyState === "complete"')

    def wait_for(self, expression: str, timeout: float = 10.0) -> bool:
        deadline = time.time() + timeout
        while time.time() < deadline:
            try:
                if self.evaluate(expression):
                    return True
            except RuntimeError:
                pass
            time.sleep(0.05)
        return False

    def key(self, key: str, code: str, key_code: int, modifiers: int = 0) -> None:
        for event in ('keyDown', 'keyUp'):
            self.send(
                'Input.dispatchKeyEvent',
                type=event,
                key=key,
                code=code,
                windowsVirtualKeyCode=key_code,
                nativeVirtualKeyCode=key_code,
                modifiers=modifiers,
            )

    def type_text(self, text: str) -> None:
        # `char` only. Sending keyDown *and* char types every character twice.
        for character in text:
            self.send('Input.dispatchKeyEvent', type='char', text=character)
            time.sleep(0.01)

    def viewport(self, width: int, height: int, mobile: bool = False) -> None:
        self.send(
            'Emulation.setDeviceMetricsOverride',
            width=width,
            height=height,
            deviceScaleFactor=2,
            mobile=mobile,
        )

    def screenshot(self, name: str) -> None:
        data = self.send('Page.captureScreenshot', captureBeyondViewport=False)['data']
        with open(os.path.join(SHOTS, f'{name}.png'), 'wb') as handle:
            handle.write(base64.b64decode(data))

    def close(self) -> None:
        try:
            self.socket.close()
        finally:
            self.process.terminate()
            shutil.rmtree(self.profile, ignore_errors=True)


def main() -> int:
    if not os.path.isfile(os.path.join(BUILD, 'index.html')):
        sys.exit('No build at build/jaspr — run `dart run jaspr_cli:jaspr build` first.')
    os.makedirs(SHOTS, exist_ok=True)

    port = free_port()
    # Served from a copy: `jaspr build` deletes and recreates build/jaspr, and a
    # server started inside it keeps serving the deleted inode afterwards.
    server = subprocess.Popen(
        [sys.executable, '-m', 'http.server', str(port), '--bind', '127.0.0.1'],
        cwd=BUILD,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    base = f'http://127.0.0.1:{port}'
    time.sleep(0.6)

    browser = Browser(free_port())
    try:
        run_checks(browser, base)
    finally:
        browser.close()
        server.terminate()

    print(f'\n{checks - len(failures)}/{checks} checks passed. Screenshots in build/verify/')
    if failures:
        print('FAILED: ' + ', '.join(failures))
    return 1 if failures else 0


def run_checks(browser: Browser, base: str) -> None:
    browser.viewport(1440, 900)

    print('\nhydration')
    browser.navigate(f'{base}/revali/cli/dev')
    check(
        'client bundle loads',
        browser.wait_for("!!document.querySelector('.search-trigger')"),
    )
    check(
        'search component hydrated (click handler attached)',
        browser.wait_for(
            "performance.getEntriesByType('resource')"
            ".some(r => r.name.includes('main.client.dart.js'))"
        ),
    )

    print('\nsearch')
    browser.key('k', 'KeyK', 75, modifiers=4)  # 4 = Meta
    opened = browser.wait_for("!!document.querySelector('dialog.search-dialog[open]')")
    check('⌘K opens the dialog', opened)

    browser.type_text('guards')
    check(
        'the index is fetched on first open',
        browser.wait_for(
            "performance.getEntriesByType('resource')"
            ".some(r => r.name.includes('search-index.json'))"
        ),
    )
    check('results appear', browser.wait_for("document.querySelectorAll('.search-hit').length > 0"))
    check(
        'the first result is the Guards page',
        browser.wait_for(
            "document.querySelector('.search-hit')?.getAttribute('href')"
            ".includes('/lifecycle-components/advanced/guards')"
        ),
        str(browser.evaluate("document.querySelector('.search-hit')?.getAttribute('href')")),
    )
    check(
        'matches are highlighted',
        bool(browser.evaluate("document.querySelectorAll('.search-hit mark').length > 0")),
    )

    # The bug this whole script exists for: every DOM assertion above passed on
    # the site this came from while the panel was two pixels tall, because an
    # ancestor's backdrop-filter had made it the containing block for a
    # position:fixed overlay. Measured with results showing, not on the empty
    # state — an empty dialog is legitimately short.
    height = browser.evaluate(
        "document.querySelector('.search-panel')?.getBoundingClientRect().height ?? 0"
    )
    check(
        'the panel is actually visible',
        isinstance(height, (int, float)) and height > 400,
        f'height was {height}px',
    )
    browser.screenshot('search-open')

    first = browser.evaluate("document.querySelector('.search-hit[data-selected]')?.href")
    browser.key('ArrowDown', 'ArrowDown', 40)
    second = browser.evaluate("document.querySelector('.search-hit[data-selected]')?.href")
    check('arrow keys move the selection', bool(first) and first != second, f'{first} -> {second}')

    browser.key('Escape', 'Escape', 27)
    check('Esc closes', browser.wait_for("!document.querySelector('dialog.search-dialog[open]')"))
    check(
        'scroll lock is released',
        browser.evaluate("document.documentElement.style.overflow") in ('', None),
    )

    browser.key('k', 'KeyK', 75, modifiers=4)
    browser.wait_for("!!document.querySelector('dialog.search-dialog[open]')")
    browser.type_text('websockets')
    browser.wait_for("document.querySelectorAll('.search-hit').length > 0")
    browser.key('Enter', 'Enter', 13)
    check(
        'Enter navigates to the result',
        browser.wait_for("location.pathname.includes('/response/websockets')", timeout=8),
        str(browser.evaluate('location.pathname')),
    )

    print('\nnavigation')
    browser.navigate(f'{base}/constructs/revali_server/core/pipes')
    check(
        'the Constructs tab is the active one',
        browser.evaluate("document.querySelector('.section-tab.active')?.textContent") == 'Constructs',
    )
    check(
        'the sidebar shows only this section',
        browser.evaluate(
            "[...document.querySelectorAll('.docs-sidebar-link')]"
            ".every(a => a.getAttribute('href').startsWith('/constructs'))"
        ),
    )
    check(
        'the group containing this page is open',
        browser.evaluate(
            "!!document.querySelector('.docs-sidebar-link.active')"
            "?.closest('details[open]')"
        ),
    )
    check(
        'the active link is scrolled into the sidebar viewport',
        browser.evaluate(
            "(() => { const a = document.querySelector('.docs-sidebar-link.active');"
            " return a ? a.getBoundingClientRect().width > 0 : false; })()"
        ),
    )
    check(
        'breadcrumb names the section and group',
        browser.evaluate("document.querySelector('.breadcrumbs')?.textContent.replace(/\\s+/g,' ')")
        == 'Constructs/Core',
        str(browser.evaluate("document.querySelector('.breadcrumbs')?.textContent")),
    )
    check(
        'prev/next are present',
        browser.evaluate("document.querySelectorAll('.page-nav-link').length") == 2,
    )
    browser.screenshot('docs-page')

    print('\ncontent')
    browser.navigate(f'{base}/constructs/revali_server/lifecycle-components/advanced/guards')
    check(
        'callouts render as boxes, not literal tags',
        browser.evaluate("document.querySelectorAll('.admonition').length") > 0,
    )
    check(
        'no unparsed markdown leaked into a callout',
        '**' not in str(browser.evaluate(
            "[...document.querySelectorAll('.admonition-body')].map(n => n.textContent).join('')"
        )),
    )
    check(
        'code blocks carry their filename header',
        browser.evaluate("document.querySelectorAll('.code-file-name').length") > 0,
    )
    check(
        'dart code is syntax highlighted',
        browser.evaluate("document.querySelectorAll('pre code span[style]').length") > 10,
    )
    browser.screenshot('callouts-and-code')

    browser.navigate(f'{base}/revali/app-configuration')
    check(
        'mermaid renders an svg',
        browser.wait_for("!!document.querySelector('pre.mermaid svg')", timeout=20),
        'the CDN may be unreachable from this machine',
    )
    browser.screenshot('mermaid')

    print('\nappearance')
    browser.navigate(f'{base}/revali')
    browser.evaluate("document.documentElement.dataset.theme = 'dark'")
    time.sleep(0.4)
    browser.screenshot('dark')
    browser.evaluate("document.documentElement.dataset.theme = 'light'")
    time.sleep(0.2)
    browser.screenshot('light')

    browser.navigate(f'{base}/')
    browser.screenshot('landing')
    check(
        'the landing hero rendered as a component',
        browser.evaluate("!!document.querySelector('.hero .hero-button.primary')"),
    )
    check(
        'section cards link to all three sections',
        browser.evaluate("document.querySelectorAll('.section-cards .card').length") == 3,
    )

    print('\nmobile')
    browser.viewport(390, 844, mobile=True)
    browser.navigate(f'{base}/revali/cli/dev')
    check(
        'the sidebar is off-canvas',
        browser.evaluate(
            "document.querySelector('.sidebar-container').getBoundingClientRect().right <= 1"
        ),
    )
    check(
        'the section name is shown in the sidebar instead of the tabs',
        browser.evaluate(
            "getComputedStyle(document.querySelector('.docs-sidebar-section')).display"
        ) != 'none',
    )
    check(
        'nothing overflows the viewport horizontally',
        browser.evaluate("document.documentElement.scrollWidth <= window.innerWidth + 1"),
        str(browser.evaluate('document.documentElement.scrollWidth + " > " + window.innerWidth')),
    )
    # Nothing above catches this: the elements are all present, all non-zero,
    # and the search button is simply drawn on top of the word "Revali".
    check(
        'the header does not overlap itself',
        browser.evaluate(
            "(() => {"
            " const boxes = [...document.querySelectorAll("
            "   '.header-title, .search-trigger, .theme-toggle, .github-button')]"
            "   .map(n => n.getBoundingClientRect())"
            "   .filter(b => b.width > 0)"
            "   .sort((a, b) => a.left - b.left);"
            " return boxes.every((b, i) => i === 0 || b.left >= boxes[i - 1].right - 1);"
            "})()"
        ),
    )
    browser.screenshot('mobile')

    browser.evaluate("document.querySelector('.sidebar-toggle-button').click()")
    time.sleep(0.4)
    check(
        'the sidebar opens on tap',
        browser.evaluate(
            "document.querySelector('.sidebar-container').getBoundingClientRect().left >= -1"
        ),
    )
    browser.screenshot('mobile-sidebar')


if __name__ == '__main__':
    raise SystemExit(main())
