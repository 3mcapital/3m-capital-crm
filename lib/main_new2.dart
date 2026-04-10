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
  bool _isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _loadPrice();
    _loadDynamicContent();
  }

  Future<void> _loadDynamicContent() async {
    setState(() => _isLoadingContent = true);
    try {
      final plansRes = await http.get(Uri.parse('$_apiBaseUrl/content/membership')).timeout(const Duration(seconds: 10));
      final analysisRes = await http.get(Uri.parse('$_apiBaseUrl/content/analysis')).timeout(const Duration(seconds: 10));

      setState(() {
        if (plansRes.statusCode == 200) {
          final data = json.decode(plansRes.body);
          _membershipPlans = MembershipPlans(plansContent: data['content'] ?? '');
        }
        if (analysisRes.statusCode == 200) {
          final data = json.decode(analysisRes.body);
          _marketAnalysis = MarketAnalysis(content: data['content'] ?? '', lastUpdate: data['last_update'] ?? '');
        }
        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _membershipPlans = MembershipPlans.defaultPlans();
        _marketAnalysis = MarketAnalysis.empty();
        _isLoadingContent = false;
      });
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
          setState(() {
            _currentPrice = GoldPrice(price: xauRate * 1000, change: 0, changePercent: 0, open: xauRate * 1000, high: xauRate * 1000, low: xauRate * 1000, indicators: {'rsi': 50}, priceHistory: List.generate(30, (i) => xauRate * 1000 + i * 2));
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _currentPrice = GoldPrice.demo();
        _isDemoMode = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    await prefs.remove('user_phone');
    if (mounted) {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => GoldTradingApp(isLoggedIn: false)));
    }
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.membershipPlans, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.goldAccent.withOpacity(0.3))),
            child: Text(plans.plansContent, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, height: 1.6)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('立即購買', style: TextStyle(color: AppTheme.primaryDark, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(AppLocalizations l10n) {
    final analysis = _marketAnalysis ?? MarketAnalysis.empty();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.marketAnalysis, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(analysis.content, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, height: 1.5)),
                if (analysis.lastUpdate.isNotEmpty) ...[const SizedBox(height: 8), Text('更新時間：${analysis.lastUpdate}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerRight, child: TextButton.icon(onPressed: _loadDynamicContent, icon: const Icon(Icons.refresh, size: 16, color: AppTheme.goldAccent), label: const Text('刷新', style: TextStyle(color: AppTheme.goldAccent)))),
        ],
      ),
    );
  }

  Widget _buildPriceTab(AppLocalizations l10n) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: AppTheme.goldAccent));
    final price = _currentPrice ?? GoldPrice.demo();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.xauusd, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
              if (_isDemoMode) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppTheme.negativeRed.withOpacity(0.2), borderRadius: BorderRadius.circular(4)), child: const Text('Demo', style: TextStyle(color: AppTheme.negativeRed, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 8),
          Text('\$${price.price.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.goldAccent, fontSize: 36, fontWeight: FontWeight.bold)),
          Text('${price.change >= 0 ? '+' : ''}${price.change.toStringAsFixed(2)} (${price.changePercent.toStringAsFixed(2)}%)', style: TextStyle(color: price.change >= 0 ? AppTheme.positiveGreen : AppTheme.negativeRed, fontSize: 16)),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _buildPriceItem(l10n.open, price.open.toStringAsFixed(2)),
            _buildPriceItem(l10n.high, price.high.toStringAsFixed(2)),
            _buildPriceItem(l10n.low, price.low.toStringAsFixed(2)),
          ]),
          const SizedBox(height: 24),
          Text(l10n.dayChart, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(height: 200, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(12)), child: LineChart(LineChartData(gridData: const FlGridData(show: false), titlesData: const FlTitlesData(show: false), borderData: FlBorderData(show: false), lineBarsData: [LineChartBarData(spots: price.priceHistory.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(), isCurved: true, color: AppTheme.goldAccent, barWidth: 2, isStrokeCapRound: true, dotData: const FlDotData(show: false), belowBarData: BarAreaData(show: true, color: AppTheme.goldAccent.withOpacity(0.1))))))),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: _loadPrice, icon: const Icon(Icons.refresh), label: Text(l10n.tapToRetry), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondaryDark))),
        ],
      ),
    );
  }

  Widget _buildPriceItem(String label, String value) {
    return Column(children: [Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)), const SizedBox(height: 4), Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold))]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        title: const Text('3M Capital', style: TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: AppTheme.textSecondary), onPressed: _logout),
        ],
      ),
      body: _buildBody(l10n),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.primaryDark,
        selectedItemColor: AppTheme.goldAccent,
        unselectedItemColor: AppTheme.textSecondary,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.card_membership), label: l10n.membershipPlans),
          BottomNavigationBarItem(icon: const Icon(Icons.analytics), label: l10n.marketAnalysis),
          BottomNavigationBarItem(icon: const Icon(Icons.show_chart), label: l10n.priceTab),
        ],
      ),
    );
  }
}

// ============ Keep original functions ============
Widget _buildIndicatorCard(String title, double? value, double overbought, double oversold, AppLocalizations l10n) {
  String signal = l10n.neutral;
  Color color = AppTheme.textSecondary;
  if (value != null) {
    if (value >= overbought) { signal = l10n.overbought; color = AppTheme.negativeRed; }
    else if (value <= oversold) { signal = l10n.oversold; color = AppTheme.positiveGreen; }
    else { signal = l10n.neutral; color = AppTheme.goldAccent; }
  }
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
      Column(children: [Text(value?.toStringAsFixed(2) ?? '--', style: const TextStyle(color: AppTheme.goldAccent, fontSize: 20, fontWeight: FontWeight.bold)), Text(signal, style: TextStyle(color: color, fontSize: 12))]),
    ]),
  );
}

Widget _buildMACard(Map<String, double?> ind, AppLocalizations l10n) {
  final ma20 = ind['ma20'] ?? 0;
  final ma50 = ind['ma50'] ?? 0;
  String signal = l10n.neutral;
  if (ma20 > ma50) signal = l10n.bullish;
  else if (ma20 < ma50) signal = l10n.bearish;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.movingAverages, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [Text(l10n.ma20, style: const TextStyle(color: AppTheme.textSecondary)), Text(ma20.toStringAsFixed(2), style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold))]),
        Column(children: [Text(l10n.ma50, style: const TextStyle(color: AppTheme.textSecondary)), Text(ma50.toStringAsFixed(2), style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold))]),
        Column(children: [Text(signal, style: TextStyle(color: signal == l10n.bullish ? AppTheme.positiveGreen : signal == l10n.bearish ? AppTheme.negativeRed : AppTheme.goldAccent))]),
      ]),
    ]),
  );
}

Widget _buildMACDCard(Map<String, double?> ind, AppLocalizations l10n) {
  final macd = ind['macd'] ?? 0;
  final signal = ind['signal'] ?? 0;
  String signalText = l10n.neutral;
  if (macd > signal) signalText = l10n.bullish;
  else if (macd < signal) signalText = l10n.bearish;
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.secondaryDark, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.macd, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        Column(children: [Text(l10n.macd, style: const TextStyle(color: AppTheme.textSecondary)), Text(macd.toStringAsFixed(2), style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold))]),
        Column(children: [Text(l10n.signal, style: const TextStyle(color: AppTheme.textSecondary)), Text(signal.toStringAsFixed(2), style: const TextStyle(color: AppTheme.goldAccent, fontWeight: FontWeight.bold))]),
        Column(children: [Text(signalText, style: TextStyle(color: signalText == l10n.bullish ? AppTheme.positiveGreen : signalText == l10n.bearish ? AppTheme.negativeRed : AppTheme.goldAccent))]),
      ]),
    ]),
  );
}