import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../providers/focus_provider.dart';
import '../../widgets/custom_app_bar.dart';

class StatsView extends StatefulWidget {
  const StatsView({super.key});

  @override
  State<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends State<StatsView> {
  String _chartView = 'Daily';
  int _timeRange = 7;

  @override
  Widget build(BuildContext context) {
    final focusProvider = Provider.of<FocusProvider>(context);
    final weeklyProgress = focusProvider.weeklyProgress;

    final dailyData = focusProvider.getDailyFocusMinutes(days: _timeRange);
    final weeklyData = focusProvider.getWeeklyFocusMinutes(weeks: _timeRange);

    final chartData = _chartView == 'Daily'
        ? dailyData.entries
        .map((entry) => _ChartData(
      entry.key.toString().substring(5, 10),
      entry.value.toDouble(),
    ))
        .toList()
        : weeklyData.entries
        .map((entry) => _ChartData(
      entry.key.substring(5),
      entry.value.toDouble(),
    ))
        .toList();

    return Scaffold(
      appBar: CustomAppBar(title: "Focus Stats"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Weekly Progress: ${weeklyProgress.toStringAsFixed(1)}%",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _chartView,
                hint: const Text('Select Chart View'),
                items: ['Daily', 'Weekly'].map((view) {
                  return DropdownMenuItem<String>(
                    value: view,
                    child: Text(view),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _chartView = value ?? 'Daily';
                    _timeRange = _chartView == 'Daily' ? 7 : 4;
                  });
                },
              ),
              const SizedBox(height: 8),
              DropdownButton<int>(
                value: _timeRange,
                hint: const Text('Select Time Range'),
                items: (_chartView == 'Daily' ? [7, 14, 30] : [4, 8, 12]).map((range) {
                  return DropdownMenuItem<int>(
                    value: range,
                    child: Text(_chartView == 'Daily' ? '$range Days' : '$range Weeks'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _timeRange = value ?? (_chartView == 'Daily' ? 7 : 4);
                  });
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(
                    title: AxisTitle(text: _chartView == 'Daily' ? 'Date' : 'Week Start'),
                    labelRotation: 45,
                    labelStyle: const TextStyle(fontSize: 10),
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(text: 'Focus Minutes'),
                    minimum: 0,
                  ),
                  series: <CartesianSeries<_ChartData, String>>[
                    _chartView == 'Daily'
                        ? LineSeries<_ChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (_ChartData data, _) => data.x,
                      yValueMapper: (_ChartData data, _) => data.y,
                      color: Colors.blue,
                      markerSettings: const MarkerSettings(isVisible: true),
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.top,
                        textStyle: TextStyle(fontSize: 10),
                      ),
                    )
                        : ColumnSeries<_ChartData, String>(
                      dataSource: chartData,
                      xValueMapper: (_ChartData data, _) => data.x,
                      yValueMapper: (_ChartData data, _) => data.y,
                      color: Colors.deepPurple,
                      dataLabelSettings: const DataLabelSettings(
                        isVisible: true,
                        labelAlignment: ChartDataLabelAlignment.top,
                        textStyle: TextStyle(fontSize: 10),
                      ),
                    ),
                  ],
                  tooltipBehavior: TooltipBehavior(enable: true),
                  annotations: <CartesianChartAnnotation>[
                    CartesianChartAnnotation(
                      widget: Container(),
                      coordinateUnit: CoordinateUnit.point,
                      x: chartData.isNotEmpty ? chartData.first.x : 0,
                      y: _chartView == 'Daily' ? 71 : 500,
                      region: AnnotationRegion.chart,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildStatCard("This Week (min)", focusProvider.weekMinutes.toString()),
              _buildStatCard("Sessions", focusProvider.sessionCount.toString()),
              _buildStatCard("Streak Days", focusProvider.streakDays.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  _ChartData(this.x, this.y);
  final String x;
  final double y;
}