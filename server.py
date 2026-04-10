from flask import Flask, jsonify, request, send_from_directory
from datetime import datetime
import json
import os

app = Flask(__name__)

# 確保當前目錄是正確的路徑
basedir = os.path.dirname(os.path.abspath(__file__))

# 策略存儲文件
STRATEGY_FILE = 'strategies.json'
CONTENT_FILE = 'content.json'

def load_strategies():
    if os.path.exists(STRATEGY_FILE):
        with open(STRATEGY_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {
        'morning': '',
        'realtime': '',
        'afternoon': ''
    }

def save_strategies(data):
    with open(STRATEGY_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

def load_content():
    if os.path.exists(CONTENT_FILE):
        with open(CONTENT_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {
        'membership': {
            'content': '• 3個月：$388 USDT\n• 6個月：$688 USDT\n• 12個月：$998 USDT（最優惠）',
            'last_update': ''
        },
        'analysis': {
            'content': '請稍後刷新獲取最新行情分析',
            'last_update': ''
        }
    }

def save_content(data):
    with open(CONTENT_FILE, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

# 獲取今日策略
@app.route('/api/strategies/today')
def get_strategies():
    strategies = load_strategies()
    today = datetime.now().strftime('%Y-%m-%d')
    
    # 如果沒有設定策略，返回默認
    if not strategies.get('morning') and not strategies.get('realtime') and not strategies.get('afternoon'):
        return jsonify({
            'morning': '🎯 早盤策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
            'realtime': '🎯 實時策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
            'afternoon': '🎯 午盤策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
            'last_update': today
        })
    
    return jsonify({
        'morning': strategies.get('morning', ''),
        'realtime': strategies.get('realtime', ''),
        'afternoon': strategies.get('afternoon', ''),
        'last_update': strategies.get('last_update', today)
    })

# 設置策略 (POST)
@app.route('/api/strategies/set', methods=['POST'])
def set_strategy():
    data = request.get_json()
    
    strategies = {
        'morning': data.get('morning', ''),
        'realtime': data.get('realtime', ''),
        'afternoon': data.get('afternoon', ''),
        'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')
    }
    
    save_strategies(strategies)
    
    return jsonify({'status': 'success', 'message': '策略已更新', 'data': strategies})

# 獲取所有策略歷史
@app.route('/api/strategies/history')
def get_history():
    # 簡單實現：返回當前策略
    strategies = load_strategies()
    return jsonify(strategies)

# ============ 內容 API ============
@app.route('/api/content/membership')
def get_membership():
    content = load_content()
    return jsonify(content.get('membership', {}))

@app.route('/api/content/analysis')
def get_analysis():
    content = load_content()
    return jsonify(content.get('analysis', {}))

@app.route('/api/content/set', methods=['POST'])
def set_content():
    data = request.get_json()
    content = load_content()
    
    if 'membership' in data:
        content['membership'] = {
            'content': data['membership'],
            'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')
        }
    if 'analysis' in data:
        content['analysis'] = {
            'content': data['analysis'],
            'last_update': datetime.now().strftime('%Y-%m-%d %H:%M')
        }
    
    save_content(content)
    return jsonify({'status': 'success', 'message': '內容已更新', 'data': content})

# 健康檢查
@app.route('/api/health')
def health():
    return jsonify({'status': 'ok', 'time': datetime.now().isoformat()})

# 管理界面首頁
@app.route('/')
def admin():
    admin_path = os.path.join(basedir, 'admin.html')
    print(f"Admin route called, path: {admin_path}, exists: {os.path.exists(admin_path)}")
    with open(admin_path, 'r', encoding='utf-8') as f:
        return f.read()

# 管理界面靜態資源
@app.route('/<path:filename>')
def static_files(filename):
    # 安全檢查：只允許特定文件類型
    allowed_extensions = ['html', 'css', 'js', 'png', 'jpg', 'jpeg', 'gif', 'ico', 'svg']
    ext = filename.split('.')[-1].lower() if '.' in filename else ''
    if ext not in allowed_extensions:
        return 'Forbidden', 403
    file_path = os.path.join(basedir, filename)
    if os.path.exists(file_path):
        return send_from_directory(basedir, filename)
    return 'Not Found', 404

if __name__ == '__main__':
    print("Strategy API Server starting...")
    print("Access http://localhost:5000/api/strategies/today")
    app.run(host='0.0.0.0', port=5000, debug=False, use_reloader=False)