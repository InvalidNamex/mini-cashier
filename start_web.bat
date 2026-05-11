@echo off
REM Serves the Flutter web build locally and opens it in the browser.
REM Python 3 must be installed (https://python.org) OR use the desktop build instead.

setlocal
set "SCRIPT_DIR=%~dp0"
set "WEB_DIR=%SCRIPT_DIR%build\web"
set PORT=8080

if not exist "%WEB_DIR%" (
    echo Web build not found. Building now...
    cd /d "%SCRIPT_DIR%"
    flutter build web --wasm
)

echo Starting local server on http://localhost:%PORT%
start "" http://localhost:%PORT%

cd /d "%WEB_DIR%"
python -c "
import http.server, socketserver, sys

PORT = %PORT%

class CoopCoepHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()
    def log_message(self, f, *a):
        pass

print(f'Serving at http://localhost:{PORT}  -- Press Ctrl+C to stop')
with socketserver.TCPServer(('', PORT), CoopCoepHandler) as httpd:
    httpd.serve_forever()
"
