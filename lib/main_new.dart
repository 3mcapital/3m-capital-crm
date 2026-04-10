import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'strategy_page.dart';

// API URL
const String _apiBaseUrl = 'http://172.17.44.87:5000/api';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 檢查是否已登入
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('user_token');
  runApp(GoldTradingApp(isLoggedIn: token != null));
}

class GoldTradingApp extends StatelessWidget {
  final bool isLoggedIn;
  const GoldTradingApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gold Trading',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppTheme.primaryDark,
        primaryColor: AppTheme.goldAccent,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}

// ============ Theme ============
class AppTheme {
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color secondaryDark = Color(0xFF16213E);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE5C37B);
  static const Color positiveGreen = Color(0xFF00C853);
  static const Color negativeRed = Color(0xFFFF5252);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
}

// ============ User Model ============
class User {
  final int id;
  final String phone;
  final String name;
  final String membership;
  
  User({required this.id, required this.phone, required this.name, required this.membership});
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      phone: json['phone'] ?? '',
      name: json['name'] ?? '',
      membership: json['membership'] ?? 'free',
    );
  }
}

// ============ Login Page ============
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isRegister = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = '請填寫所有欄位');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final endpoint = _isRegister ? '/auth/register' : '/auth/login';
      final body = _isRegister ? {
        'phone': _phoneController.text,
        'password': _passwordController.text,
        'name': _nameController.text,
      } : {
        'phone': _phoneController.text,
        'password': _passwordController.text,
      };

      final res = await http.post(
        Uri.parse('$_apiBaseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      final data = json.decode(res.body);

      if (res.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', data['token'] ?? '');
        await prefs.setString('user_phone', _phoneController.text);
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        }
      } else {
        setState(() => _error = data['error'] ?? '操作失敗');
      }
    } catch (e) {
      setState(() => _error = '網絡錯誤，請檢查連接');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.secondaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.trending_up, size: 80, color: AppTheme.goldAccent),
                  const SizedBox(height: 16),
                  const Text('3M Capital', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.goldAccent)),
                  const SizedBox(height: 8),
                  Text(_isRegister ? '註冊會員' : '會員登入', style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                  const SizedBox(height: 32),
                  
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: AppTheme.negativeRed.withOpacity(0.2), borderRadius: 8),
                      child: Text(_error!, style: const TextStyle(color: AppTheme.negativeRed)),
                    ),
                  
                  if (_isRegister)
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: '姓名',
                        filled: true,
                        fillColor: AppTheme.secondaryDark,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: '手機號',
                      filled: true,
                      fillColor: AppTheme.secondaryDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '密碼',
                      filled: true,
                      fillColor: AppTheme.secondaryDark,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.goldAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isLoading
                        ? const CircularProgressIndicator(color: AppTheme.primaryDark)
                        : Text(_isRegister ? '註冊' : '登入', style: const TextStyle(fontSize: 18, color: AppTheme.primaryDark, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  TextButton(
                    onPressed: () => setState(() {
                      _isRegister = !_isRegister;
                      _error = null;
                    }),
                    child: Text(_isRegister ? '已有帳號？登入' : '沒有帳號？註冊', style: const TextStyle(color: AppTheme.goldAccent)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============ Models ============
class MembershipPlans {
  String plansContent;
  MembershipPlans({required this.plansContent});
  factory MembershipPlans.defaultPlans() {
    return MembershipPlans(plansContent: '• 3個月：\$388 USDT\n• 6個月：\$688 USDT\n• 12個月：\$998 USDT（最優惠）');
  }
}

class MarketAnalysis {
  String content;
  String lastUpdate;
  MarketAnalysis({required this.content, required this.lastUpdate});
  factory MarketAnalysis.empty() {
    return MarketAnalysis(content: '請先登入查看行情分析', lastUpdate: '');
  }
}

class GoldPrice {
  double price;
  double change;
  double changePercent;
  double open;
  double high;
  double low;
  Map<String, double?> indicators;
  List<double> priceHistory;

  GoldPrice({required this.price, required this.change, required this.changePercent, required this.open, required this.high, required this.low, required this.indicators, required this.priceHistory});

  factory GoldPrice.demo() {
    final List<double> history = [];
    double basePrice = 3320.0;
    for (int i = 29; i >= 0; i--) {
      basePrice += (DateTime.now().millisecond % 20 - 10) * 0.5;
      basePrice += (i % 3 - 1) * 5;
      history.add(basePrice);
    }
    final currentPrice = history.last;
    final open = history.first;
    final change = currentPrice - open;
    final changePercent = (change / open) * 100;
    final high = history.reduce((a, b) => a > b ? a : b);
    final low = history.reduce((a, b) => a < b ? a : b);

    return GoldPrice(
      price: currentPrice,
      change: change,
      changePercent: changePercent,
      open: open,
      high: high,
      low: low,
      indicators: {'rsi': 55.0, 'macd': 5.0, 'signal': 3.0, 'ma20': basePrice - 10, 'ma50': basePrice - 20},
      priceHistory: history,
    );
  }
}