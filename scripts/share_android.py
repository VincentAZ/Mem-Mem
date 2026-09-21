#!/usr/bin/env python3
"""Serve a phone-friendly install page and the debug APK for testers."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import re
import shutil
import socket
import subprocess
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / '.tools'
APK = ROOT / 'build/mem-mem-debug.apk'
CLOUDFLARED = TOOLS / 'cloudflared'
CLOUDFLARED_URL = (
    'https://github.com/cloudflare/cloudflared/releases/latest/download/'
    'cloudflared-linux-amd64'
)
PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Install Mem-Mem</title>
<style>
:root {{
  --ink: #244c43;
  --muted: #637367;
  --paper: #f8f4ec;
  --card: #fffdf8;
  --gold: #8b541d;
  --gold-soft: #cc974c;
}}
* {{ box-sizing: border-box; }}
body {{
  margin: 0;
  min-height: 100dvh;
  font-family: ui-sans-serif, system-ui, sans-serif;
  background: var(--paper);
  color: var(--ink);
}}
main {{
  max-width: 28rem;
  margin: 0 auto;
  padding: 2.4rem 1.3rem 3rem;
}}
.icon {{ width: 5.5rem; height: 5.5rem; display: block; margin: 0 auto 1.1rem; }}
h1 {{ text-align: center; font-size: 2rem; letter-spacing: .02em; margin: 0 0 .35rem; }}
.lede {{ text-align: center; color: var(--muted); margin: 0 0 1.5rem; line-height: 1.45; }}
.card {{
  background: var(--card);
  border-radius: 1.15rem;
  padding: 1.15rem 1.15rem 1.25rem;
  box-shadow: 0 10px 28px rgba(36, 76, 67, .08);
}}
a.install {{
  display: block;
  text-align: center;
  text-decoration: none;
  background: var(--gold);
  color: #fffdf8;
  font-weight: 700;
  font-size: 1.15rem;
  padding: 1rem 1.1rem;
  border-radius: .9rem;
}}
.meta {{ text-align: center; color: var(--muted); font-size: .92rem; margin: .7rem 0 0; }}
ol {{ margin: 1.2rem 0 0; padding-left: 1.2rem; line-height: 1.55; }}
li {{ margin: .55rem 0; }}
.note {{
  margin-top: 1.15rem;
  color: var(--muted);
  font-size: .9rem;
  line-height: 1.45;
}}
</style>
</head>
<body>
<main>
<svg class="icon" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 432 432" aria-hidden="true">
  <rect width="432" height="432" rx="100" fill="#244C43"/>
  <g fill="none" stroke="#F8F4EC" stroke-width="26" stroke-linecap="round">
    <path d="M99 277V164q0-45 39-45t39 45v70"/>
    <path d="M177 234v-70q0-45 39-45t39 45v70"/>
    <path d="M255 234v-70q0-45 39-45t39 45v113"/>
  </g>
  <circle cx="216" cy="304" r="12" fill="#DEA789"/>
</svg>
<h1>Mem-Mem</h1>
<p class="lede">A test build. Not from the Play Store.</p>
<div class="card">
  <a class="install" href="/Mem-Mem.apk" download="Mem-Mem.apk">Download and install</a>
  <p class="meta">About {size} &middot; Android 8+</p>
  <ol>
    <li>Tap <strong>Download and install</strong>.</li>
    <li>If Chrome warns that the file might be harmful, choose <strong>Download anyway</strong>.</li>
    <li>Open the downloaded file.</li>
    <li>When Android asks, allow this browser to install unknown apps, then tap <strong>Install</strong>.</li>
    <li>Open <strong>Mem-Mem</strong>.</li>
  </ol>
  <p class="note">Use Wi-Fi. This debug build is only for testing; do not publish it.</p>
</div>
</main>
</body>
</html>
"""


def lan_ip() -> str:
    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        sock.connect(('1.1.1.1', 80))
        return sock.getsockname()[0]
    except OSError:
        return '127.0.0.1'
    finally:
        sock.close()


def apk_size_label(path: Path) -> str:
    mib = path.stat().st_size / (1024 * 1024)
    return f'{mib:.0f} MB'


def ensure_cloudflared() -> Path:
    if CLOUDFLARED.exists() and os.access(CLOUDFLARED, os.X_OK):
        return CLOUDFLARED
    TOOLS.mkdir(parents=True, exist_ok=True)
    partial = CLOUDFLARED.with_suffix('.partial')
    print('Downloading a local Cloudflare tunnel helper…', flush=True)
    subprocess.run(
        ['curl', '-fL', '--retry', '3', '--silent', '--show-error', CLOUDFLARED_URL, '-o', str(partial)],
        check=True,
    )
    partial.chmod(0o755)
    partial.replace(CLOUDFLARED)
    return CLOUDFLARED


def start_tunnel(port: int) -> subprocess.Popen:
    binary = ensure_cloudflared()
    return subprocess.Popen(
        [str(binary), 'tunnel', '--url', f'http://127.0.0.1:{port}', '--no-autoupdate'],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
    )


def wait_for_public_url(proc: subprocess.Popen, timeout: float = 40.0) -> str:
    pattern = re.compile(r'https://[a-z0-9-]+\.trycloudflare\.com')
    assert proc.stdout is not None
    deadline = time.time() + timeout
    while time.time() < deadline:
        line = proc.stdout.readline()
        if not line and proc.poll() is not None:
            break
        match = pattern.search(line)
        if match:
            return match.group(0)
    raise RuntimeError('Public install link was not ready')


def handler_for(apk: Path, html: bytes) -> type[BaseHTTPRequestHandler]:
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, format: str, *args) -> None:
            sys.stderr.write('%s - %s\n' % (self.address_string(), format % args))

        def do_HEAD(self) -> None:
            self._route(body=False)

        def do_GET(self) -> None:
            self._route(body=True)

        def _route(self, body: bool) -> None:
            path = self.path.split('?', 1)[0]
            if path in ('/', '/index.html'):
                self._send(200, 'text/html; charset=utf-8', html, body)
                return
            if path in ('/Mem-Mem.apk', '/mem-mem-debug.apk'):
                size = apk.stat().st_size
                self.send_response(200)
                self.send_header('Content-Type', 'application/vnd.android.package-archive')
                self.send_header('Content-Disposition', 'attachment; filename="Mem-Mem.apk"')
                self.send_header('Content-Length', str(size))
                self.end_headers()
                if body:
                    with apk.open('rb') as src:
                        shutil.copyfileobj(src, self.wfile, length=1024 * 1024)
                return
            self.send_error(404)

        def _send(self, status: int, content_type: str, payload: bytes, body: bool = True) -> None:
            self.send_response(status)
            self.send_header('Content-Type', content_type)
            self.send_header('Content-Length', str(len(payload)))
            self.end_headers()
            if body:
                self.wfile.write(payload)

    return Handler


def write_qr(url: str) -> Path | None:
    dest = ROOT / 'build/share/qr.png'
    dest.parent.mkdir(parents=True, exist_ok=True)
    try:
        subprocess.run(
            [
                'curl', '-fL', '--silent', '--show-error',
                f'https://api.qrserver.com/v1/create-qr-code/?size=360x360&data={url}',
                '-o', str(dest),
            ],
            check=True,
        )
    except subprocess.CalledProcessError:
        return None
    return dest


def main() -> int:
    parser = argparse.ArgumentParser(description='Share the Mem-Mem APK with testers.')
    parser.add_argument('--port', type=int, default=8765)
    parser.add_argument('--lan-only', action='store_true', help='Skip the public install link.')
    args = parser.parse_args()
    if not APK.is_file() or APK.stat().st_size == 0:
        print('Build the APK first: ./scripts/build_android.sh', file=sys.stderr)
        return 1
    html = PAGE.format(size=apk_size_label(APK)).encode()
    server = ThreadingHTTPServer(('0.0.0.0', args.port), handler_for(APK, html))
    lan = f'http://{lan_ip()}:{args.port}/'
    print('Keep this running until testers have installed the app.', flush=True)
    print(f'Same Wi-Fi: {lan}', flush=True)
    tunnel = None
    public = None
    if not args.lan_only:
        try:
            tunnel = start_tunnel(args.port)
            public = wait_for_public_url(tunnel)
            print(f'Send testers this link:\n  {public}', flush=True)
            qr = write_qr(public)
            if qr:
                print(f'QR image: {qr}', flush=True)
        except Exception as error:
            print(f'Public link unavailable ({error}). Use the same-Wi-Fi address.', flush=True)
            if tunnel and tunnel.poll() is None:
                tunnel.terminate()
            tunnel = None
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print('\nStopped sharing.', flush=True)
    finally:
        server.server_close()
        if tunnel and tunnel.poll() is None:
            tunnel.terminate()
            tunnel.wait(timeout=5)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
