import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bellezapp/utils/utils.dart';

class FinancialChartPage extends StatelessWidget {
  final List<Map<String, dynamic>> financialData;

  const FinancialChartPage({super.key, required this.financialData});

  Widget _buildModernBarChart() {
    final List<BarChartGroupData> barGroups = financialData.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
      final int index = entry.key;
      final Map<String, dynamic> data = entry.value;
      final int month = int.tryParse(data['month']?.toString() ?? '0') ?? (index + 1);
      final totalIncome = (data['totalIncome'] ?? 0).toDouble();
      final totalExpense = (data['totalExpense'] ?? 0).toDouble();

      return BarChartGroupData(
        x: month,
        barRods: <BarChartRodData>[
          BarChartRodData(
            toY: totalIncome,
            color: Colors.green.shade600,
            width: 12,
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.green.shade800, width: 1),
          ),
          BarChartRodData(
            toY: totalExpense,
            color: Colors.red.shade600,
            width: 12,
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.red.shade800, width: 1),
          ),
        ],
      );
    }).toList();

    return Container(
      height: 400,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    '\$${(value / 1000).toStringAsFixed(0)}K',
                    style: TextStyle(
                      color: Utils.colorTexto.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const TextStyle style = TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  );
                  final String text = _getMonthName(value.toInt(), short: true);
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(text, style: style),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 10000,
            getDrawingHorizontalLine: (double value) {
              return FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
                dashArray: <int>[5, 5],
              );
            },
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (BarChartGroupData group) => Utils.colorGnav.withValues(alpha: 0.9),
              tooltipPadding: const EdgeInsets.all(12),
              getTooltipItem: (BarChartGroupData group, int groupIndex, BarChartRodData rod, int rodIndex) {
                final String month = _getMonthName(group.x.toInt());
                final String type = rodIndex == 0 ? 'Ingresos' : 'Gastos';
                return BarTooltipItem(
                  '$month\n$type: \$${rod.toY.toStringAsFixed(0)}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          maxY: _getMaxValue() * 1.2,
        ),
      ),
    );
  }

  Widget _buildModernLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _buildLegendItem('Ingresos', Colors.green.shade600, Icons.trending_up),
          Container(width: 1, height: 30, color: Colors.grey.shade300),
          _buildLegendItem('Gastos', Colors.red.shade600, Icons.trending_down),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Utils.colorTexto,
          ),
        ),
      ],
    );
  }

  Widget _buildInsights() {
    if (financialData.isEmpty) return const SizedBox.shrink();

    // Calculate insights
    double totalIncome = 0;
    double totalExpenses = 0;
    String bestMonth = '';
    double bestBalance = double.negativeInfinity;
    
    for (Map<String, dynamic> data in financialData) {
      final double income = (data['totalIncome'] ?? 0).toDouble();
      final double expense = (data['totalExpense'] ?? 0).toDouble();
      final double balance = income - expense;
      
      totalIncome += income;
      totalExpenses += expense;
      
      if (balance > bestBalance) {
        bestBalance = balance;
        bestMonth = _getMonthName(int.tryParse(data['month']?.toString() ?? '0') ?? 0);
      }
    }

    final double averageIncome = totalIncome / financialData.length;
    final double averageExpenses = totalExpenses / financialData.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Utils.colorFondoCards,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.lightbulb_outline, color: Utils.colorGnav, size: 24),
              const SizedBox(width: 12),
              Text(
                'Insights Financieros',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Utils.colorTexto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            'Mejor Mes',
            bestMonth,
            'Mayor balance positivo',
            Icons.star,
            Colors.amber,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Promedio Ingresos',
            '\$${averageIncome.toStringAsFixed(0)}',
            'Por mes en el período',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            'Promedio Gastos',
            '\$${averageExpenses.toStringAsFixed(0)}',
            'Por mes en el período',
            Icons.trending_down,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Utils.colorTexto.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorTexto,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Utils.colorTexto.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month, {bool short = false}) {
    const List<String> months = <String>[
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    const List<String> shortMonths = <String>[
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    
    if (month < 1 || month > 12) return '';
    return short ? shortMonths[month - 1] : months[month - 1];
  }

  double _getMaxValue() {
    double max = 0;
    for (Map<String, dynamic> data in financialData) {
      final double income = (data['totalIncome'] ?? 0).toDouble();
      final double expense = (data['totalExpense'] ?? 0).toDouble();
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: const Text(
          'Análisis Financiero',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: financialData.isEmpty
          ? _buildEmptyChartState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildChartHeader(),
                  const SizedBox(height: 24),
                  _buildChartContainer(),
                  const SizedBox(height: 24),
                  _buildInsights(),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyChartState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Utils.colorFondoCards,
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.show_chart,
              size: 64,
              color: Utils.colorGnav.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin datos para mostrar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Utils.colorTexto,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El gráfico aparecerá cuando\ntengas datos financieros',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Utils.colorTexto.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartHeader() {
    double totalIncome = 0;
    double totalExpenses = 0;
    
    for (Map<String, dynamic> data in financialData) {
      totalIncome += (data['totalIncome'] ?? 0).toDouble();
      totalExpenses += (data['totalExpense'] ?? 0).toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Utils.colorGnav, Utils.colorBotones],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Utils.colorGnav.withValues(alpha: 0.3),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.trending_up, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Text(
                'Resumen del Período',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildHeaderMetric(
                  'Total Ingresos',
                  '\$${totalIncome.toStringAsFixed(0)}',
                  Icons.arrow_upward,
                  Colors.green.shade300,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildHeaderMetric(
                  'Total Gastos',
                  '\$${totalExpenses.toStringAsFixed(0)}',
                  Icons.arrow_downward,
                  Colors.red.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartContainer() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Utils.colorFondoCards,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: <Widget>[
                Icon(Icons.bar_chart, color: Utils.colorGnav, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Comparativa Mensual',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Utils.colorTexto,
                  ),
                ),
              ],
            ),
          ),
          _buildModernBarChart(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildModernLegend(),
          ),
        ],
      ),
    );
  }
}
