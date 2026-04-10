from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import os
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

DATA_DIR = os.path.dirname(os.path.abspath(__file__))
USERS_FILE = os.path.join(DATA_DIR, 'users.json')
CONTENT_FILE = os.path.join(DATA_DIR, 'content.json')
STRATEGY_FILE = os.path.join(DATA_DIR, 'strategies.json')

def load_json(path, default):
    if os.path.exists(path):
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    return default

def save_json(path, data):
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

class Handler(BaseHTTPRequestHandler):
    def send_cors_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, PUT, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
    
    def do_OPTIONS(self):
        self.send_response(200)
        self.send_cors_headers()
        self.end_headers()
    
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_cors_headers()
        self.end_headers()
        
        if self.path == '/api/health':
            self.wfile.write(b'{"status":"ok"}')
        elif self.path == '/api/content/membership':
            content = load_json(CONTENT_FILE, {})
            self.wfile.write(json.dumps(content.get('membership', {})).encode())
        elif self.path == '/api/content/analysis':
            content = load_json(CONTENT_FILE, {})
            self.wfile.write(json.dumps(content.get('analysis', {})).encode())
        elif self.path == '/api/strategies/today':
            strategies = load_json(STRATEGY_FILE, {})
            if not strategies.get('morning'):
                strategies = {'morning': 'Gold XAUUSD morning strategy', 'realtime': 'Gold XAUUSD realtime strategy', 'afternoon': 'Gold XAUUSD afternoon strategy', 'last_update': '2026-04-10'}
            self.wfile.write(json.dumps(strategies).encode())
        elif self.path == '/api/admin/users':
            users = load_json(USERS_FILE, [])
            self.wfile.write(json.dumps([{'id':u['id'], 'phone':u['phone'], 'name':u['name'], 'membership':u['membership']} for u in users]).encode())
        elif self.path == '/':
            with open(os.path.join(DATA_DIR, 'crm_admin.html'), 'r', encoding='utf-8') as f:
                html_content = f.read()
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.send_header('Content-Length', str(len(html_content.encode('utf-8'))))
                self.send_header('X-Content-Type-Options', 'nosniff')
                self.send_header('Cache-Control', 'no-cache, no-store, must-revalidate')
                self.end_headers()
                self.wfile.write(html_content.encode('utf-8'))
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(length).decode('utf-8')
        try:
            data = json.loads(body) if body else {}
        except:
            data = {}
        
        self.send_response(200)
        self.send_header('Content-Type', 'application/json')
        self.send_cors_headers()
        self.end_headers()
        
        if self.path == '/api/auth/register':
            users = load_json(USERS_FILE, [])
            for u in users:
                if u['phone'] == data.get('phone'):
                    self.wfile.write(b'{"error":"exists"}')
                    return
            new_user = {'id': len(users)+1, 'phone': data.get('phone'), 'password': generate_password_hash(data.get('password')), 'name': data.get('name', ''), 'membership': 'free', 'created_at': datetime.now().isoformat()}
            users.append(new_user)
            save_json(USERS_FILE, users)
            self.wfile.write('{"message":"ok","user_id":%d}'.format(new_user['id']).encode())
            
        elif self.path == '/api/auth/login':
            users = load_json(USERS_FILE, [])
            for u in users:
                if u['phone'] == data.get('phone'):
                    if check_password_hash(u['password'], data.get('password')):
                        self.wfile.write('{"token":"token_%d","user":{"id":%d,"phone":"%s","name":"%s","membership":"%s"}}' % (u['id'], u['id'], u['phone'], u['name'], u['membership']).encode())
                        return
                    self.wfile.write(b'{"error":"wrong_password"}')
                    return
            self.wfile.write(b'{"error":"not_found"}')
            
        elif self.path == '/api/content/set':
            content = load_json(CONTENT_FILE, {})
            if 'membership' in data:
                content['membership'] = {'content': data['membership'], 'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')}
            if 'analysis' in data:
                content['analysis'] = {'content': data['analysis'], 'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')}
            save_json(CONTENT_FILE, content)
            self.wfile.write(b'{"status":"ok"}')
            
        elif self.path == '/api/strategies/set':
            strategies = {'morning': data.get('morning', ''), 'realtime': data.get('realtime', ''), 'afternoon': data.get('afternoon', ''), 'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')}
            save_json(STRATEGY_FILE, strategies)
            self.wfile.write(b'{"status":"ok"}')
            
        elif '/api/admin/users/' in self.path and '/membership' in self.path:
            import re
            m = re.search(r'/api/admin/users/(\d+)/membership', self.path)
            if m:
                uid = int(m.group(1))
                users = load_json(USERS_FILE, [])
                for u in users:
                    if u['id'] == uid:
                        u['membership'] = data.get('membership', 'free')
                        save_json(USERS_FILE, users)
                        self.wfile.write(b'{"message":"ok"}')
                        return
            self.wfile.write(b'{"error":"not_found"}')
        else:
            self.send_response(404)
            self.end_headers()

print("CRM Server starting on http://localhost:5000")
HTTPServer(('0.0.0.0', 5000), Handler).serve_forever()