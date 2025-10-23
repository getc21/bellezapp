import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:bellezapp/utils/utils.dart';

class FinancialChartPage extends StatelessWidget {
  final List<Map<String, dynamic>> financialData;

  FinancialChartPage({required this.financialData});

  Widget _buildBarChart() {
    List<BarChartGroupData> barGroups = financialData.map((data) {
      final month = int.tryParse(data['month']) ?? 0;
      final totalIncome = data['totalIncome'] ?? 0.0;
      final totalExpense = data['totalExpense'] ?? 0.0;

      return BarChartGroupData(
        x: month,
        barRods: [
          BarChartRodData(
            toY: totalIncome,
            color: Colors.blue,
            width: 15,
          ),
          BarChartRodData(
            toY: totalExpense,
            color: Colors.red,
            width: 15,
          ),
        ],
      );
    }).toList();
    return Padding(
      padding: EdgeInsets.only(top:50),
      child: Container(
        height: 500,  
        color: Colors.white,
        padding: EdgeInsets.all(10),
        child: BarChart(
          BarChartData(
            barGroups: barGroups,
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Ocultar títulos del eje izquierdo
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 50), // Mostrar títulos del eje derecho
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false), // Ocultar títulos del eje superior
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    const style = TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    );
                    String text;
                    switch (value.toInt()) {
                      case 1:
                        text = 'Ene';
                        break;
                      case 2:
                        text = 'Feb';
                        break;
                      case 3:
                        text = 'Mar';
                        break;
                      case 4:
                        text = 'Abr';
                        break;
                      case 5:
                        text = 'May';
                        break;
                      case 6:
                        text = 'Jun';
                        break;
                      case 7:
                        text = 'Jul';
                        break;
                      case 8:
                        text = 'Ago';
                        break;
                      case 9:
                        text = 'Sep';
                        break;
                      case 10:
                        text = 'Oct';
                        break;
                      case 11:
                        text = 'Nov';
                        break;
                      case 12:
                        text = 'Dic';
                        break;
                      default:
                        text = '';
                        break;
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: Text(text, style: style),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(show: false),
             barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (tooltipItem) => const Color.fromARGB(255, 243, 243, 243),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String month;
                switch (group.x.toInt()) {
                  case 1:
                    month = 'Enero';
                    break;
                  case 2:
                    month = 'Febrero';
                    break;
                  case 3:
                    month = 'Marzo';
                    break;
                  case 4:
                    month = 'Abril';
                    break;
                  case 5:
                    month = 'Mayo';
                    break;
                  case 6:
                    month = 'Junio';
                    break;
                  case 7:
                    month = 'Julio';
                    break;
                  case 8:
                    month = 'Agosto';
                    break;
                  case 9:
                    month = 'Septiembre';
                    break;
                  case 10:
                    month = 'Octubre';
                    break;
                  case 11:
                    month = 'Noviembre';
                    break;
                  case 12:
                    month = 'Diciembre';
                    break;
                  default:
                    month = '';
                    break;
                }
                return BarTooltipItem(
                  '$month\n',
                  TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '${rod.toY}Bs.',
                      style: TextStyle(
                        color: rod.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: Colors.blue,
            ),
            SizedBox(width: 4),
            Text('Entradas', style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(width: 16),
        Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: Colors.red,
            ),
            SizedBox(width: 4),
            Text('Salidas', style: TextStyle(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Utils.colorFondo,
      appBar: AppBar(
        title: Text('Gráfico Financiero'),
        backgroundColor: Utils.colorGnav,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildBarChart(),
            SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
      ),
    );
  }
}