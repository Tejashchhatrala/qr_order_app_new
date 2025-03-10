import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/analytics_service.dart';
import '../../../models/analytics.dart';
import '../../../services/export_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _analyticsService = AnalyticsService();
  final _exportService = ExportService();
  DateTimeRange _dateRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateRange(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportData(context),
          ),
        ],
      ),
      body: FutureBuilder<AnalyticsData>(
        future: _analyticsService.getAnalytics(
          startDate: _dateRange.start,
          endDate: _dateRange.end,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final analytics = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(analytics),
                const SizedBox(height: 24),
                _buildRevenueChart(analytics),
                const SizedBox(height: 24),
                _buildPopularItems(analytics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(AnalyticsData analytics) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Orders',
            value: analytics.totalOrders.toString(),
            icon: Icons.shopping_bag,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _SummaryCard(
            title: 'Revenue',
            value: '₹${analytics.totalRevenue.toStringAsFixed(2)}',
            icon: Icons.currency_rupee,
          ),
        ),
      ],
    );
  }

  Widget _buildRevenueChart(AnalyticsData analytics) {
    final spots = analytics.hourlyRevenue.entries
        .map((e) => FlSpot(
              double.parse(e.key),
              e.value,
            ))
        .toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString());
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(spots: spots),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItems(AnalyticsData analytics) {
    final sortedItems = analytics.itemsSold.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Popular Items',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sortedItems.length,
          itemBuilder: (context, index) {
            final item = sortedItems[index];
            return ListTile(
              title: Text(item.key),
              trailing: Text('${item.value} sold'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final newRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );

    if (newRange != null) {
      setState(() => _dateRange = newRange);
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      await _exportService.exportOrderHistory(
        _dateRange.start,
        _dateRange.end,
      );
    } catch (e) {
      if (context.mounted) {
        ErrorHandler.showError(context, 'Failed to export data: $e');
      }
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
