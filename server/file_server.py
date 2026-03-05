"""Simple file upload/serve API for avatars and other assets.
Runs alongside the main F1 Tipp server services.
Uses Flask for simplicity - serves files from /root/f1-tipp-server/uploads/
"""
import os
import logging
from http.server import HTTPServer, SimpleHTTPRequestHandler
import json
import uuid
from urllib.parse import parse_qs, urlparse
import threading

logger = logging.getLogger(__name__)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
UPLOAD_DIR = os.path.join(SCRIPT_DIR, "uploads")
AVATARS_DIR = os.path.join(UPLOAD_DIR, "avatars")
RELEASES_DIR = os.path.join(SCRIPT_DIR, "releases")
VERSION_FILE = os.path.join(RELEASES_DIR, "version.json")
PORT = 8421

os.makedirs(AVATARS_DIR, exist_ok=True)
os.makedirs(RELEASES_DIR, exist_ok=True)


class FileHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=UPLOAD_DIR, **kwargs)

    def do_POST(self):
        if self.path.startswith("/upload/avatar"):
            self._handle_avatar_upload()
        else:
            self.send_error(404)

    def _handle_avatar_upload(self):
        try:
            content_length = int(self.headers.get("Content-Length", 0))
            if content_length > 5 * 1024 * 1024:  # 5MB limit
                self.send_error(413, "File too large (max 5MB)")
                return

            parsed = urlparse(self.path)
            params = parse_qs(parsed.query)
            uid = params.get("uid", [None])[0]
            if not uid:
                logger.warning("Avatar upload: missing uid parameter")
                self.send_error(400, "Missing uid parameter")
                return

            content_type = self.headers.get("Content-Type", "")

            if "multipart/form-data" in content_type:
                body = self.rfile.read(content_length)
                boundary_str = content_type.split("boundary=")[1].split(";")[0].strip().strip('"')
                boundary = boundary_str.encode()
                end_marker = b"\r\n--" + boundary
                parts = body.split(b"--" + boundary)
                file_data = None
                for part in parts:
                    if b"Content-Type: image/" in part or b"content-type: image/" in part:
                        header_end = part.find(b"\r\n\r\n")
                        if header_end != -1:
                            raw = part[header_end + 4:]
                            end_idx = raw.rfind(b"\r\n--")
                            if end_idx != -1:
                                file_data = raw[:end_idx]
                            else:
                                file_data = raw.rstrip(b"\r\n-")
                            break
                if not file_data:
                    logger.warning("Avatar upload: no image part found in multipart body (%d bytes, boundary=%s)", len(body), boundary_str)
                    self.send_error(400, "No image file found")
                    return
            else:
                file_data = self.rfile.read(content_length)

            ext = "png"
            if b"\xff\xd8\xff" in file_data[:4]:
                ext = "jpg"
            elif b"WEBP" in file_data[:16]:
                ext = "webp"

            filename = f"{uid}.{ext}"
            filepath = os.path.join(AVATARS_DIR, filename)

            for old in os.listdir(AVATARS_DIR):
                if old.startswith(f"{uid}."):
                    os.remove(os.path.join(AVATARS_DIR, old))

            with open(filepath, "wb") as f:
                f.write(file_data)

            url = f"/avatars/{filename}"
            logger.info(f"Avatar uploaded: {url} ({len(file_data)} bytes)")

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"url": url, "filename": filename}).encode())

        except Exception as e:
            logger.error(f"Upload error: {e}")
            self.send_error(500, str(e))

    def do_GET(self):
        parsed = urlparse(self.path)
        clean_path = parsed.path

        if clean_path == "/health":
            self._json_response({"status": "ok"})
            return

        if clean_path == "/api/version":
            self._handle_version()
            return

        if clean_path.startswith("/releases/"):
            self._serve_release_file()
            return

        if clean_path.startswith("/landing"):
            self._serve_landing()
            return

        if clean_path == "/" or clean_path == "":
            self._serve_landing()
            return

        super().do_GET()

    def _json_response(self, data, status=200):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def _handle_version(self):
        if os.path.exists(VERSION_FILE):
            with open(VERSION_FILE, "r") as f:
                data = json.load(f)
        else:
            data = {"version": "2.0.0", "build": 1, "apk_url": "/releases/f1tippmix.apk"}
            with open(VERSION_FILE, "w") as f:
                json.dump(data, f, indent=2)
        self._json_response(data)

    def _serve_release_file(self):
        filename = self.path.split("/releases/")[-1]
        filepath = os.path.join(RELEASES_DIR, filename)
        if not os.path.exists(filepath):
            self.send_error(404, "Release file not found")
            return
        file_size = os.path.getsize(filepath)
        self.send_response(200)
        self.send_header("Content-Type", "application/vnd.android.package-archive")
        self.send_header("Content-Disposition", f'attachment; filename="{filename}"')
        self.send_header("Content-Length", str(file_size))
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        with open(filepath, "rb") as f:
            while True:
                chunk = f.read(65536)
                if not chunk:
                    break
                self.wfile.write(chunk)

    def _serve_landing(self):
        landing_dir = os.path.join(SCRIPT_DIR, "landing")
        clean = urlparse(self.path).path
        req_path = clean.replace("/landing", "", 1).lstrip("/") or "index.html"
        filepath = os.path.join(landing_dir, req_path)
        if not os.path.exists(filepath):
            self.send_error(404, "Not found")
            return
        mime_map = {".html": "text/html", ".css": "text/css", ".js": "application/javascript",
                    ".png": "image/png", ".jpg": "image/jpeg", ".svg": "image/svg+xml", ".ico": "image/x-icon"}
        ext = os.path.splitext(filepath)[1].lower()
        content_type = mime_map.get(ext, "application/octet-stream")
        if ext in (".html", ".css", ".js"):
            with open(filepath, "r", encoding="utf-8") as f:
                data = f.read().encode("utf-8")
            content_type += "; charset=utf-8"
        else:
            with open(filepath, "rb") as f:
                data = f.read()
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, format, *args):
        logger.info(format % args)


def start_file_server(port=PORT):
    server = HTTPServer(("0.0.0.0", port), FileHandler)
    logger.info(f"File server listening on port {port}")
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    server = HTTPServer(("0.0.0.0", PORT), FileHandler)
    logger.info(f"File server on port {PORT}, uploads dir: {UPLOAD_DIR}")
    server.serve_forever()
