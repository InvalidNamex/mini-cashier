#!/bin/bash
# Serves the Flutter web build locally and opens it in the browser.
# Requires Python 3 (pre-installed on macOS/Linux).
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEB_DIR="$SCRIPT_DIR/build/web"

if [ ! -d "$WEB_DIR" ]; then
  echo "Web build not found. Building now..."
  cd "$SCRIPT_DIR"
  flutter build web --wasm
fi

PORT=8080
echo "Starting local server on http://localhost:$PORT"

# Open browser (macOS: open, Linux: xdg-open)
if command -v open &>/dev/null; then
  sleep 1 && open "http://localhost:$PORT" &
elif command -v xdg-open &>/dev/null; then
  sleep 1 && xdg-open "http://localhost:$PORT" &
fi

# Python 3 HTTP server (handles COOP/COEP headers required for SharedArrayBuffer/WASM)
cd "$WEB_DIR"
python3 - <<'EOF'
import http.server
import socketserver

PORT = 8080

class CoopCoepHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        super().end_headers()

    def log_message(self, format, *args):
        pass  # suppress request logs

with socketserver.TCPServer(("", PORT), CoopCoepHandler) as httpd:
    print(f"Serving at http://localhost:{PORT}  — Press Ctrl+C to stop")
    httpd.serve_forever()
EOF
