#!/usr/bin/env python3
import json
import os
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import parse_qs
from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

# 簡單 HTTP 服務器

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
    def do_GET(self):
        if self.path == '/' or self.path == '/admin':
            self.send_response(200)
            self.send_header('Content-type', 'text/html; charset=utf-8')
            self.end_headers()
            with open(os.path.join(DATA_DIR, 'crm_admin.html'), 'r', encoding='utf-8') as f:
                self.wfile.write(f.read().encode('utf-8'))
        elif self.path == '/api/content/membership':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            content = load_json(CONTENT_FILE, {})
            self.wfile.write(json.dumps(content.get('membership', {})).encode())
        elif self.path == '/api/content/analysis':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            content = load_json(CONTENT_FILE, {})
            self.wfile.write(json.dumps(content.get('analysis', {})).encode())
        elif self.path == '/api/strategies/today':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            strategies = load_json(STRATEGY_FILE, {})
            if not strategies.get('morning'):
                strategies = {
                    'morning': '🎯 早盤策略\n產品：黃金XAUUSD\ncoming soon',
                    'realtime': '🎯 實時策略\ncoming soon',
                    'afternoon': '🎯 午盤策略\ncoming soon',
                    'last_update': datetime.now().strftime('%Y-%m-%d')
                }
            self.wfile.write(json.dumps(strategies).encode())
        elif self.path == '/api/health':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            self.wfile.write(b'{"status":"ok"}')
        elif self.path.startswith('/api/admin/users'):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            users = load_json(USERS_FILE, [])
            self.wfile.write(json.dumps([{
                'id': u['id'], 'phone': u['phone'], 'name': u['name'],
                'membership': u['membership']
            } for u in users]).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length).decode('utf-8')
        data = json.loads(body) if body else {}
        
        if self.path == '/api/auth/register':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            
            users = load_json(USERS_FILE, [])
            for u in users:
                if u['phone'] == data.get('phone'):
                    self.wfile.write(b'{"error":"phone exists"}')
                    return
            
            new_user = {
                'id': len(users) + 1,
                'phone': data.get('phone'),
                'password': generate_password_hash(data.get('password')),
                'name': data.get('name', ''),
                'membership': 'free',
                'created_at': datetime.now().isoformat()
            }
            users.append(new_user)
            save_json(USERS_FILE, users)
            self.wfile.write('{"message": "registered", "user_id": %d}'.format(new_user['id']).encode())
            
        elif self.path == '/api/auth/login':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            users = load_json(USERS_FILE, [])
            for u in users:
                if u['phone'] == data.get('phone'):
                    if check_password_hash(u['password'], data.get('password')):
                        self.wfile.write('{"token": "token_%d", "user": {"id": %d, "phone": "%s", "name": "%s", "membership": "%s"}}' % (
                            u['id'], u['id'], u['phone'], u['name'], u['membership']
                        ).encode())
                        return
                    self.wfile.write(b'{"error":"wrong password"}')
                    return
            self.wfile.write(b'{"error":"user not found"}')
            
        elif self.path == '/api/content/set':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            content = load_json(CONTENT_FILE, {})
            if 'membership' in data:
                content['membership'] = {'content': data['membership'], 'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')}
            if 'analysis' in data:
                content['analysis'] = {'content': data['analysis'], 'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')}
            save_json(CONTENT_FILE, content)
            self.wfile.write(b'{"status":"success"}')
            
        elif self.path == '/api/strategies/set':
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            strategies = {
                'morning': data.get('morning', ''),
                'realtime': data.get('realtime', ''),
                'afternoon': data.get('afternoon', ''),
                'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')
            }
            save_json(STRATEGY_FILE, strategies)
            self.wfile.write(b'{"status":"success"}')
            
        elif self.path.startswith('/api/admin/users/') and self.path.endswith('/membership'):
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            import re
            match = re.search(r'/api/admin/users/(\d+)/membership', self.path)
            if match:
                uid = int(match.group(1))
                users = load_json(USERS_FILE, [])
                for u in users:
                    if u['id'] == uid:
                        u['membership'] = data.get('membership', 'free')
                        save_json(USERS_FILE, users)
                        self.wfile.write(b'{"message":"updated"}')
                        return
            self.wfile.write(b'{"error":"not found"}')
        else:
            self.send_response(404)
            self.end_headers()
    
    def log_message(self, format, *args):
        pass

print("CRM Server starting...")
print("Access http://localhost:5000")
HTTPServer(('0.0.0.0', 5000), Handler).serve_forever()
