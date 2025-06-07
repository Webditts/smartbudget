import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../../models/transaction_model.dart';

class CategoryTrendChart extends StatelessWidget {
  final List<Transaction> transactions;

  const CategoryTrendChart({Key? key, required this.transactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final data = transactions.map((tx) {
      return TimeSeriesData(tx.createdAt, tx.amount);
    }).toList();

    final series = [
      charts.Series<TimeSeriesData, DateTime>(
        id: 'Spending',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesData data, _) => data.time,
        measureFn: (TimeSeriesData data, _) => data.amount,
        data: data,
      )
    ];

    return charts.TimeSeriesChart(series, animate: true);
  }
}

class TimeSeriesData {
  final DateTime time;
  final double amount;

  TimeSeriesData(this.time, this.amount);
}
