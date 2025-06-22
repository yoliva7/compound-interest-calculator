import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:ui';

void main() {
  runApp(const CompoundInterestApp());
}

class CompoundInterestApp extends StatelessWidget {
  const CompoundInterestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compound Interest Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF6A1B9A),
        scaffoldBackgroundColor: const Color(0xFF121212),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // --- STATE VARIABLES ---
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final _principalController = TextEditingController(text: '10000');
  final _rateController = TextEditingController(text: '7');
  final _yearsController = TextEditingController(text: '30');
  final _monthlyContributionController = TextEditingController(text: '500');
  final _stopYearController = TextEditingController(text: '20');

  // New state for stopping contributions
  bool _stopContributionsEnabled = true;

  // Dropdown value for compounding frequency
  String _compoundingFrequency = 'Annually';
  final List<String> _compoundingOptions = [
    'Annually',
    'Semiannually',
    'Quarterly',
    'Monthly',
  ];

  // Data for the chart
  List<FlSpot> _chartData = [];
  List<FlSpot> _contributionsData = [];
  double _maxValueY = 0;
  double _totalEndValue = 0;
  double _totalContributions = 0;
  double _totalInterest = 0;

  @override
  void initState() {
    super.initState();
    _simulate();
  }

  // --- CALCULATION LOGIC ---
  void _simulate() {
    if (_formKey.currentState?.validate() ?? false) {
      final double principal = double.tryParse(_principalController.text) ?? 0;
      final double annualRate =
          (double.tryParse(_rateController.text) ?? 0) / 100;
      final int years = int.tryParse(_yearsController.text) ?? 0;
      final double monthlyContribution =
          double.tryParse(_monthlyContributionController.text) ?? 0;
      final int stopYear = int.tryParse(_stopYearController.text) ?? years;

      List<FlSpot> interestDataPoints = [FlSpot(0, principal)];
      List<FlSpot> contributionDataPoints = [FlSpot(0, principal)];
      double maxVal = principal;

      double currentBalance = principal;
      double totalContributionsSoFar = principal;
      double monthlyRate = annualRate / 12.0;

      for (int m = 1; m <= years * 12; m++) {
        // Add interest for the month
        currentBalance += currentBalance * monthlyRate;

        // Check if we should add contribution for the current month
        final int currentYear = (m / 12).ceil();
        if (!_stopContributionsEnabled || currentYear <= stopYear) {
          currentBalance += monthlyContribution;
          totalContributionsSoFar += monthlyContribution;
        }

        // Add a data point at the end of each year
        if (m % 12 == 0) {
          final double year = m / 12.0;
          interestDataPoints.add(FlSpot(year, currentBalance));
          contributionDataPoints.add(FlSpot(year, totalContributionsSoFar));
          if (currentBalance > maxVal) {
            maxVal = currentBalance;
          }
        }
      }

      final calculatedTotalContributions = totalContributionsSoFar;
      final calculatedTotalInterest =
          currentBalance - calculatedTotalContributions;

      setState(() {
        _chartData = interestDataPoints;
        _contributionsData = contributionDataPoints;
        _maxValueY = maxVal * 1.1;
        _totalEndValue = currentBalance;
        _totalContributions = calculatedTotalContributions;
        _totalInterest = calculatedTotalInterest;
      });
    }
  }

  // --- WIDGET BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF121212), Color(0xFF2C1A3C), Color(0xFF121212)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Compound Interest',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                  ),
                  Text(
                    'Growth Simulator',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 28,
                      color: Colors.white54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildInputFields(),
                  const SizedBox(height: 24),
                  _buildResultsSummary(),
                  const SizedBox(height: 32),
                  _buildSimulateButton(),
                  const SizedBox(height: 32),
                  _buildChartSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPER WIDGETS ---

  Widget _buildGlassmorphicCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.1),
                Colors.white.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return _buildGlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextField(
              controller: _principalController,
              label: 'Initial Principal',
              icon: Icons.account_balance_wallet,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _monthlyContributionController,
              label: 'Monthly Contribution',
              icon: Icons.add_card,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _rateController,
                    label: 'Annual Rate (%)',
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _yearsController,
                    label: 'Years',
                    icon: Icons.calendar_today,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDropdown(),
            const SizedBox(height: 16),
            _buildStopContributionControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildStopContributionControl() {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              "Stop contributions?",
              style: TextStyle(color: Colors.white70),
            ),
            const Spacer(),
            Switch(
              value: _stopContributionsEnabled,
              onChanged: (value) =>
                  setState(() => _stopContributionsEnabled = value),
              activeColor: Colors.purpleAccent,
            ),
          ],
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              SizeTransition(sizeFactor: animation, child: child),
          child: _stopContributionsEnabled
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: _buildTextField(
                    controller: _stopYearController,
                    label: 'Stop Contributions After Year...',
                    icon: Icons.timer_off,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildResultsSummary() {
    return _buildGlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSummaryItem(
              'Contributions',
              _totalContributions,
              Colors.blueAccent,
            ),
            _buildSummaryItem(
              'Interest Earned',
              _totalInterest,
              Colors.greenAccent,
            ),
            _buildSummaryItem(
              'End Balance',
              _totalEndValue,
              Colors.purpleAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, double value, Color color) {
    final currencyFormat = NumberFormat.compactCurrency(
      locale: 'en_US',
      symbol: '\$',
    );
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          currencyFormat.format(value),
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChartSection() {
    return _buildGlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: _chartData.isEmpty
                  ? const Center(
                      child: Text('Press Simulate to see the chart.'),
                    )
                  : LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) =>
                                Colors.black.withOpacity(0.8),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final isInterestLine =
                                    spot.bar.spots == _chartData;
                                final label = isInterestLine
                                    ? 'Total: '
                                    : 'Invested: ';
                                return LineTooltipItem(
                                  label +
                                      NumberFormat.currency(
                                        locale: 'en_US',
                                        symbol: '\$',
                                      ).format(spot.y),
                                  TextStyle(
                                    color: isInterestLine
                                        ? Colors.purpleAccent
                                        : Colors.white70,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => const FlLine(
                            color: Colors.white12,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval:
                                  (double.tryParse(_yearsController.text) ??
                                      20) /
                                  4,
                              getTitlesWidget: (value, meta) => Text(
                                'Yr ${value.toInt()}',
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 60,
                              getTitlesWidget: (value, meta) {
                                if (value == meta.max || value == meta.min)
                                  return const SizedBox();
                                return Text(
                                  NumberFormat.compactSimpleCurrency(
                                    locale: 'en_US',
                                  ).format(value),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 10,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: double.tryParse(_yearsController.text) ?? 20,
                        minY: 0,
                        maxY: _maxValueY,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _contributionsData,
                            isCurved: false,
                            color: Colors.white38,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            dashArray: [5, 5],
                          ),
                          LineChartBarData(
                            spots: _chartData,
                            isCurved: true,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6A1B9A), Colors.purpleAccent],
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.withOpacity(0.3),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(Colors.purpleAccent, 'Total Value'),
        const SizedBox(width: 20),
        _legendItem(Colors.white38, 'Contributions'),
      ],
    );
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildSimulateButton() {
    return GestureDetector(
      onTap: _simulate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9B59B6), Color(0xFF8E44AD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B59B6).withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Text(
          'Simulate Growth',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purpleAccent),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty || double.tryParse(value) == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _compoundingFrequency,
      dropdownColor: const Color(0xFF2C1A3C),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Compounding Frequency',
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: const Icon(Icons.sync_alt, color: Colors.white54),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.purpleAccent),
        ),
      ),
      items: _compoundingOptions
          .map(
            (String value) =>
                DropdownMenuItem<String>(value: value, child: Text(value)),
          )
          .toList(),
      onChanged: (newValue) =>
          setState(() => _compoundingFrequency = newValue!),
    );
  }

  // --- CLEANUP ---
  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _yearsController.dispose();
    _monthlyContributionController.dispose();
    _stopYearController.dispose();
    super.dispose();
  }
}
