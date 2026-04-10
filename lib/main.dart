import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// API URL - Flask server runs on port 5000, not /api path
const String _apiBaseUrl = 'http://172.17.44.87:5000';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: AppTheme.primaryDark, primaryColor: AppTheme.goldAccent),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: isLoggedIn ? const HomePage() : const LoginPage(),
    );
  }
}

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

    setState(() { _isLoading = true; _error = null; });

    try {
      final endpoint = _isRegister ? '/auth/register' : '/auth/login';
      final body = _isRegister
        ? {'phone': _phoneController.text, 'password': _passwordController.text, 'name': _nameController.text}
        : {'phone': _phoneController.text, 'password': _passwordController.text};

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
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomePage()));
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
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppTheme.primaryDark, AppTheme.secondaryDark])),
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
                  if (_error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: AppTheme.negativeRed.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(_error!, style: const TextStyle(color: AppTheme.negativeRed))),
                  if (_isRegister) TextField(controller: _nameController, decoration: InputDecoration(labelText: '姓名', filled: true, fillColor: AppTheme.secondaryDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: '手機號', filled: true, fillColor: AppTheme.secondaryDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, obscureText: true, decoration: InputDecoration(labelText: '密碼', filled: true, fillColor: AppTheme.secondaryDark, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                  const SizedBox(height: 24),
                  SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const CircularProgressIndicator(color: AppTheme.primaryDark) : Text(_isRegister ? '註冊' : '登入', style: const TextStyle(fontSize: 18, color: AppTheme.primaryDark, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 16),
                  TextButton(onPressed: () => setState(() { _isRegister = !_isRegister; _error = null; }), child: Text(_isRegister ? '已有帳號？登入' : '沒有帳號？註冊', style: const TextStyle(color: AppTheme.goldAccent))),
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
  factory MembershipPlans.defaultPlans() => MembershipPlans(plansContent: '• 3個月：\$388 USDT\n• 6個月：\$688 USDT\n• 12個月：\$998 USDT（最優惠）');
}

class MarketAnalysis {
  String content;
  String lastUpdate;
  MarketAnalysis({required this.content, required this.lastUpdate});
  factory MarketAnalysis.empty() => MarketAnalysis(content: '請先登入查看行情分析', lastUpdate: '');
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
    for (int i = 29; i >= 0; i--) { basePrice += (DateTime.now().millisecond % 20 - 10) * 0.5 + (i % 3 - 1) * 5; history.add(basePrice); }
    final currentPrice = history.last;
    final open = history.first;
    final change = currentPrice - open;
    final changePercent = (change / open) * 100;
    final high = history.reduce((a, b) => a > b ? a : b);
    final low = history.reduce((a, b) => a < b ? a : b);
    return GoldPrice(price: currentPrice, change: change, changePercent: changePercent, open: open, high: high, low: low, indicators: {'rsi': 55.0, 'macd': 5.0, 'signal': 3.0, 'ma20': basePrice - 10, 'ma50': basePrice - 20}, priceHistory: history);
  }
}

// ============ Home Page ============
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  GoldPrice? _currentPrice;
  bool _isLoading = true;
  bool _isDemoMode = false;
  MembershipPlans? _membershipPlans;
  MarketAnalysis? _marketAnalysis;
  
  // 自動刷新計時器
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPrice();
    _loadDynamicContent();
    // 每10秒自動刷新
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadDynamicContent();
      _loadPrice();
    });
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDynamicContent() async {
    try {
      final plansRes = await http.get(Uri.parse('$_apiBaseUrl/content/membership')).timeout(const Duration(seconds: 10));
      final analysisRes = await http.get(Uri.parse('$_apiBaseUrl/content/analysis')).timeout(const Duration(seconds: 10));
      setState(() {
        if (plansRes.statusCode == 200) _membershipPlans = MembershipPlans(plansContent: json.decode(plansRes.body)['content'] ?? '');
        if (analysisRes.statusCode == 200) _marketAnalysis = MarketAnalysis(content: json.decode(analysisRes.body)['content'] ?? '', lastUpdate: json.decode(analysisRes.body)['last_update'] ?? '');
      });
    } catch (e) {
      setState(() { _membershipPlans = MembershipPlans.defaultPlans(); _marketAnalysis = MarketAnalysis.empty(); });
    }
  }

  Future<void> _loadPrice() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('https://api.exchangerate.host/latest?base=USD&symbols=XAU')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final xauRate = data['rates']?['XAU'] ?? 0.0;
        if (xauRate > 0) {
          setState(() { _currentPrice = GoldPrice(price: xauRate * 1000, change: 0, changePercent: 0, open: xauRate * 1000, high: xauRate * 1000, low: xauRate * 1000, indicators: {'rsi': 50}, priceHistory: List.generate(30, (i) => xauRate * 1000 + i * 2)); _isLoading = false; });
          return;
        }
      }
    } catch (e) {}
    setState(() { _currentPrice = GoldPrice.demo(); _isDemoMode = true; _isLoading = false; });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_phone');
    if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GoldTradingApp(isLoggedIn: false)));
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_selectedIndex == 0) return _buildMembershipTab(l10n);
    if (_selectedIndex == 1) return _buildAnalysisTab(l10n);
    return _buildPriceTab(l10n);
  }

  Widget _buildMembershipTab(AppLocalizations l10n) {
    final plans = _membershipPlans ?? MembershipPlans.defaultPlans();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.membershipPlans, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3))), child: Text(plans.plansContent, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, height: 1.6))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('立即購買', style: TextStyle(color: AppTheme.primaryDark, fontSize: 16, fontWeight: FontWeight.bold)))),
      ]),
    );
  }

  Widget _buildAnalysisTab(AppLocalizations l10n) {
    final analysis = _marketAnalysis ?? MarketAnalysis.empty();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.marketAnalysis, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(analysis.content, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5)),
          if (analysis.lastUpdate.isNotEmpty) ...[const SizedBox(height: 8), Text('更新時間：${analysis.lastUpdate}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))],
        ])),
        const SizedBox(height: 8),
        Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _loadDynamicContent, icon: const Icon(Icons.refresh, size: 16, color: AppTheme.goldAccent), label: const Text('刷新', style: TextStyle(color: AppTheme.goldAccent)))),
      ]),
    );
  }

  Widget _buildPriceTab(AppLocalizations l10n) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent));
    final price = _currentPrice ?? GoldPrice.demo();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l10n.xauusd, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
          if (_isDemoMode) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.negativeRed.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: const Text('Demo', style: TextStyle(color: AppTheme.negativeRed, fontSize: 12))),
        ]),
        const SizedBox(height: 8),
        Text('\$${price.price.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.goldAccent, fontSize: 36, fontWeight: FontWeight.bold)),
        Text('${price.change >= 0 ? '+' : ''}${price.change.toStringAsFixed(2)} (${price.changePercent.toStringAsFixed(2)}%)', style: TextStyle(color: price.change >= 0 ? AppTheme.positiveGreen : AppTheme.negativeRed, fontSize: 16)),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_buildPriceItem(l10n.open, price.open.toStringAsFixed(2)), _buildPriceItem(l10n.high, price.high.toStringAsFixed(2)), _buildPriceItem(l10n.low, price.low.toStringAsFixed(2))]),
        const SizedBox(height: 24),
        Text(l10n.dayChart, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(height: 200, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(12)), child: LineChart(_buildChartData(price.priceHistory))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _loadPrice, icon: const Icon(Icons.refresh), label: Text(l10n.tapToRetry), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryDark))),
      ]),
    );
  }

  Widget _buildPriceItem(String label, String value) => Column(children: [Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))]);

  LineChartData _buildChartData(List<double> history) {
    final spots = history.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppTheme.goldAccent,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: AppTheme.goldAccent.withOpacity(0.1)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(backgroundColor: AppTheme.primaryDark, title: const Text('3M Capital', style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)), actions: [IconButton(icon: const Icon(Icons.logout, color: AppTheme.textSecondary), onPressed: _logout)]),
      body: _buildBody(l10n),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.primaryDark, selectedItemColor: AppTheme.goldAccent, unselectedItemColor: AppTheme.textSecondary,
        currentIndex: _selectedIndex, onTap: (i) => setState(() => _selectedIndex = i),
        items: [BottomNavigationBarItem(icon: const Icon(Icons.card_membership), label: l10n.membershipPlans), BottomNavigationBarItem(icon: const Icon(Icons.analytics), label: l10n.marketAnalysis), BottomNavigationBarItem(icon: const Icon(Icons.show_chart), label: l10n.priceTab)],
      ),
    );
  }
}