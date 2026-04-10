from flask import Flask, jsonify, request
from flask_cors import CORS
from datetime import datetime

app = Flask(__name__)
CORS(app)

# 模擬策略數據（實際應從數據庫讀取）
strategies = {
    "morning": "",
    "realtime": "",
    "afternoon": ""
}

@app.route('/api/strategies/today', methods=['GET'])
def get_today_strategies():
    return jsonify({
        "date": datetime.now().strftime("%Y-%m-%d"),
        "morning": strategies["morning"],
        "realtime": strategies["realtime"],
        "afternoon": strategies["afternoon"]
    })

@app.route('/api/strategies/update', methods=['POST'])
def update_strategy():
    data = request.json
    session = data.get('session', '')
    content = data.get('content', '')
    
    if session in strategies:
        strategies[session] = content
        return jsonify({"success": True, "message": f"{session} 策略已更新"})
    return jsonify({"success": False, "message": "無效的時段"})

@app.route('/api/strategies/set_all', methods=['POST'])
def set_all_strategies():
    global strategies
    data = request.json
    strategies = {
        "morning": data.get('morning', ''),
        "realtime": data.get('realtime', ''),
        "afternoon": data.get('afternoon', '')
    }
    return jsonify({"success": True, "message": "全部策略已更新"})

if __name__ == '__main__':
    print("3M Strategy API Server")
    print("http://localhost:5000")
    app.run(host='0.0.0.0', port=5000, debug=True)