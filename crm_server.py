from flask import Flask, jsonify, request, send_file
from flask_cors import CORS
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime
import json
import os

app = Flask(__name__)
app.static_folder = None

# 啟用 CORS - 允許所有
CORS(app, supports_credentials=True)

# 數據文件
DATA_DIR = os.path.dirname(os.path.abspath(__file__))
USERS_FILE = os.path.join(DATA_DIR, 'users.json')
CONTENT_FILE = os.path.join(DATA_DIR, 'content.json')
STRATEGY_FILE = os.path.join(DATA_DIR, 'strategies.json')

def load_json(filepath, default):
    if os.path.exists(filepath):
        with open(filepath, 'r', encoding='utf-8') as f:
            return json.load(f)
    return default

def save_json(filepath, data):
    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# ============ 用戶 ============
@app.route('/api/auth/register', methods=['POST'])
def register():
    data = request.get_json()
    users = load_json(USERS_FILE, [])
    
    for u in users:
        if u['phone'] == data.get('phone'):
            return jsonify({'error': '手機號已註冊'}), 400
    
    new_user = {
        'id': len(users) + 1,
        'phone': data.get('phone'),
        'password': generate_password_hash(data.get('password')),
        'name': data.get('name', ''),
        'created_at': datetime.now().isoformat(),
        'membership': 'free',
        'membership_expire': None
    }
    users.append(new_user)
    save_json(USERS_FILE, users)
    return jsonify({'message': '註冊成功', 'user_id': new_user['id']})

@app.route('/api/auth/login', methods=['POST'])
def login():
    data = request.get_json()
    users = load_json(USERS_FILE, [])
    
    for u in users:
        if u['phone'] == data.get('phone'):
            if check_password_hash(u['password'], data.get('password')):
                return jsonify({
                    'token': f"token_{u['id']}_{u['phone']}",
                    'user': {
                        'id': u['id'],
                        'phone': u['phone'],
                        'name': u['name'],
                        'membership': u['membership']
                    }
                })
            return jsonify({'error': '密碼錯誤'}), 401
    return jsonify({'error': '用戶不存在'}), 404

# ============ 內容 ============
@app.route('/api/content/membership')
def get_membership():
    content = load_json(CONTENT_FILE, {'membership': {'content': ''}})
    return jsonify(content.get('membership', {}))

@app.route('/api/content/analysis')
def get_analysis():
    content = load_json(CONTENT_FILE, {'analysis': {'content': ''}})
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
    return jsonify({'status': 'success'})

# ============ 策略 ============
@app.route('/api/strategies/today')
def get_strategies():
    strategies = load_json(STRATEGY_FILE, {})
    today = datetime.now().strftime('%Y-%m-%d')
    
    if not strategies.get('morning'):
        return jsonify({
            'morning': '🎯 早盤策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
            'realtime': '🎯 實時策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
            'afternoon': '🎯 午盤策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
            'last_update': today
        })
    return jsonify(strategies)

@app.route('/api/strategies/set', methods=['POST'])
def set_strategy():
    data = request.get_json()
    strategies = {
        'morning': data.get('morning', ''),
        'realtime': data.get('realtime', ''),
        'afternoon': data.get('afternoon', ''),
        'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')
    }
    save_json(STRATEGY_FILE, strategies)
    return jsonify({'status': 'success'})

# ============ 管理 ============
@app.route('/api/admin/users')
def get_users():
    users = load_json(USERS_FILE, [])
    return jsonify([{
        'id': u['id'], 'phone': u['phone'], 'name': u['name'],
        'membership': u['membership'], 'membership_expire': u.get('membership_expire')
    } for u in users])

@app.route('/api/admin/users/<int:uid>/membership', methods=['PUT'])
def update_membership(uid):
    data = request.get_json()
    users = load_json(USERS_FILE, [])
    for u in users:
        if u['id'] == uid:
            u['membership'] = data.get('membership', 'free')
            u['membership_expire'] = data.get('membership_expire')
            save_json(USERS_FILE, users)
            return jsonify({'message': '已更新'})
    return jsonify({'error': '用戶不存在'}), 404

@app.route('/api/health')
def health():
    return jsonify({'status': 'ok'})

# ============ 前端 ============
@app.route('/')
def admin():
    return send_file('crm_admin.html')

if __name__ == '__main__':
    print("CRM Server starting...")
    print("Access http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=False)