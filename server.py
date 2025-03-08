import http.server
import socketserver
import json

PORT = 5000  # Port for the server

class Handler(http.server.SimpleHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        post_data = self.rfile.read(content_length)
        
        try:
            data = json.loads(post_data)
            print(f"X: {data['x']:.2f}, Y: {data['y']:.2f}, Z: {data['z']:.2f}")
        except Exception as e:
            print("Error parsing JSON:", e)

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"status": "received"}).encode())

# Start server
with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving at http://0.0.0.0:{PORT}")
    httpd.serve_forever()
