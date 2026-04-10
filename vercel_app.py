from flask import Flask, jsonify, request, send_file
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import json
import os

app = Flask(__name__)
app.static_folder = None

# 環境變量或使用雲端存儲
DATA_DIR = os.environ.get('DATA_DIR', '/tmp')

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

@app.route('/')
def index():
    return send_file('crm_admin.html')

@app.route('/api/health')
def health():
    return jsonify({'status': 'ok'})

@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    users = load_json(USERS_FILE, [])
    for u in users:
        if u['phone'] == data.get('phone'):
            return jsonify({'error': 'exists'})
    new_user = {'id': len(users)+1, 'phone': data.get('phone'), 'password': generate_password_hash(data.get('password')), 'name': data.get('name', ''), 'membership': 'free', 'created_at': datetime.now().isoformat()}
    users.append(new_user)
    save_json(USERS_FILE, users)
    return jsonify({'message': 'ok', 'user_id': new_user['id']})

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    users = load_json(USERS_FILE, [])
    for u in users:
        if u['phone'] == data.get('phone'):
            if check_password_hash(u['password'], data.get('password')):
                return jsonify({'token': 'token_%d' % u['id'], 'user': {'id': u['id'], 'phone': u['phone'], 'name': u['name'], 'membership': u['membership']}})
            return jsonify({'error': 'wrong_password'})
    return jsonify({'error': 'not_found'})

@app.route('/api/content/membership')
def get_membership():
    content = load_json(CONTENT_FILE, {})
    return jsonify(content.get('membership', {}))

@app.route('/api/content/analysis')
def get_analysis():
    content = load_json(CONTENT_FILE, {})
    return jsonify(content.get('analysis', {}))

@app.route('/api/content/set', methods=['POST'])
def set_content():
    data = request.get_json()
    content = load_json(CONTENT_FILE, {})
    if 'membership' in data:
        content['membership'] = {'content': data['membership'], 'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')}
    if 'analysis' in data:
        content['analysis'] = {'content': data['analysis'], 'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')}
    save_json(CONTENT_FILE, content)
    return jsonify({'status': 'ok'})

@app.route('/api/strategies/today')
def get_strategies():
    strategies = load_json(STRATEGY_FILE, {})
    if not strategies.get('morning'):
        strategies = {'morning': 'Gold XAUUSD morning strategy', 'realtime': 'Gold XAUUSD realtime strategy', 'afternoon': 'Gold XAUUSD afternoon strategy', 'last_update': '2026-04-10'}
    return jsonify(strategies)

@app.route('/api/strategies/set', methods=['POST'])
def set_strategy():
    data = request.get_json()
    strategies = {'morning': data.get('morning', ''), 'realtime': data.get('realtime', ''), 'afternoon': data.get('afternoon', ''), 'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')}
    save_json(STRATEGY_FILE, strategies)
    return jsonify({'status': 'ok'})

@app.route('/api/admin/users')
def get_users():
    users = load_json(USERS_FILE, [])
    return jsonify([{'id': u['id'], 'phone': u['phone'], 'name': u['name'], 'membership': u['membership']} for u in users])

@app.route('/api/admin/users/<int:uid>/membership', methods=['PUT'])
def update_membership(uid):
    data = request.get_json()
    users = load_json(USERS_FILE, [])
    for u in users:
        if u['id'] == uid:
            u['membership'] = data.get('membership', 'free')
            save_json(USERS_FILE, users)
            return jsonify({'message': 'ok'})
    return jsonify({'error': 'not_found'}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))