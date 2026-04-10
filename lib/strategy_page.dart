import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'main.dart' show AppTheme;

// 自定義後端 API URL
// 手機測試：使用電腦的本地 IP 地址
// const String _apiBaseUrl = 'http://10.0.2.2:5000/api';  // Android 模擬器訪問本機
// const String _apiBaseUrl = 'http://localhost:5000/api';  // iOS 模擬器用
const String _apiBaseUrl = 'http://172.17.44.87:5000/api';  // 真機測試用（需要手機和電腦在同一 WiFi）
// 生產環境使用正式伺服器
// const String _apiBaseUrl = 'https://your-api-server.com/api';

class StrategyPage extends StatefulWidget {
  const StrategyPage({super.key});

  @override
  State<StrategyPage> createState() => _StrategyPageState();
}

class _StrategyPageState extends State<StrategyPage> {
  Map<String, String>? _strategies;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStrategies();
  }

  Future<void> _loadStrategies() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/strategies/today'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _strategies = {
            'morning': data['morning'] ?? '',
            'realtime': data['realtime'] ?? '',
            'afternoon': data['afternoon'] ?? '',
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _strategies = {
            'morning': '無法加載策略',
            'realtime': '無法加載策略',
            'afternoon': '無法加載策略',
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      // 離線模式：顯示預設策略
      setState(() {
        _strategies = {
          'morning': '🎯 早盤策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
          'realtime': '🎯 實時策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
          'afternoon': '🎯 午盤策略\n產品：黃金XAUUSD\n請稍後刷新獲取最新策略',
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日策略'),
        backgroundColor: AppTheme.primaryDark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _isLoading = true; });
              _loadStrategies();
            },
          ),
        ],
      ),
      backgroundColor: AppTheme.primaryDark,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStrategyCard('早盤(10:00-10:05)', _strategies?['morning'] ?? ''),
                  const SizedBox(height: 12),
                  _buildStrategyCard('實時(16:00-16:05)', _strategies?['realtime'] ?? ''),
                  const SizedBox(height: 12),
                  _buildStrategyCard('午盤(17:00-17:05)', _strategies?['afternoon'] ?? ''),
                ],
              ),
            ),
    );
  }

  Widget _buildStrategyCard(String title, String content) {
    final lines = content.isNotEmpty ? content.split('\n') : ['暫無策略'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppTheme.goldAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...lines.map((line) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: TextStyle(
                color: line.contains('止損') ? AppTheme.negativeRed : line.contains('止盈') ? AppTheme.positiveGreen : AppTheme.textSecondary,
                fontWeight: line.startsWith('🎯') ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          )),
        ],
      ),
    );
  }
}