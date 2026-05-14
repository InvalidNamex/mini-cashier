import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../cubit/reports_cubit.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  static const _typeLabels = {
    ReportType.daily: 'ملخص يومي',
    ReportType.byCategory: 'مبيعات حسب الفئة',
    ReportType.byCategoryDetailed: 'مبيعات مفصّلة حسب الفئة',
    ReportType.byItem: 'مبيعات حسب الصنف',
    ReportType.dateRange: 'تقرير تاريخي',
    ReportType.cashFlow: 'تدفق نقدي',
  };

  final _dateFmt = DateFormat('yyyy/MM/dd');

  Future<void> _pickDateRange(BuildContext ctx) async {
    final cubit = ctx.read<ReportsCubit>();
    final state = cubit.state;
    final picked = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: state.from, end: state.to),
      locale: const Locale('ar'),
    );
    if (picked != null) {
      cubit.setDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التقارير')),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (ctx, state) {
          final cubit = ctx.read<ReportsCubit>();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Controls
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFFF5F7FA),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Report type
                    DropdownButton<ReportType>(
                      value: state.type,
                      items: ReportType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(_typeLabels[t]!),
                              ))
                          .toList(),
                      onChanged: (t) {
                        if (t != null) cubit.setType(t);
                      },
                    ),
                    // Date range
                    OutlinedButton.icon(
                      icon: const Icon(Icons.date_range_outlined),
                      label: Text(
                          '${_dateFmt.format(state.from)} – ${_dateFmt.format(state.to)}'),
                      onPressed: () => _pickDateRange(ctx),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('عرض'),
                      onPressed: cubit.load,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Data
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.data.isEmpty
                        ? const Center(
                            child: Text('لا توجد بيانات للفترة المحددة'))
                        : _buildTable(state),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailedCategoryTable(List<Map<String, dynamic>> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: data.map((row) {
          if (row['rowType'] == 'category') {
            final revenue = (row['revenue'] as double).toStringAsFixed(2);
            return Container(
              color: const Color(0xFFE8F5E9),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              margin: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.folder_outlined,
                      size: 18, color: Color(0xFF1B6B4A)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      row['categoryName'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Text(
                    '$revenue ج.م',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1B6B4A)),
                  ),
                ],
              ),
            );
          } else {
            final qty = row['quantity'] as int;
            final revenue = (row['revenue'] as double).toStringAsFixed(2);
            return Container(
              padding: const EdgeInsets.only(
                  right: 40, left: 16, top: 6, bottom: 6),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(row['itemName'] as String,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text('الكمية: $qty',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                  ),
                  SizedBox(
                    width: 110,
                    child: Text('$revenue ج.م',
                        style: const TextStyle(fontSize: 13),
                        textAlign: TextAlign.end),
                  ),
                ],
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _buildTable(ReportsState state) {
    switch (state.type) {
      case ReportType.daily:
      case ReportType.cashFlow:
        return _dataTable(
          columns: const ['التاريخ', 'عدد الطلبات', 'الإجمالي'],
          rows: state.data.map((r) {
            return [
              r['day'] as String,
              (r['count'] as int).toString(),
              '${(r['total'] as double).toStringAsFixed(2)} ج.م',
            ];
          }).toList(),
        );
      case ReportType.byCategory:
        return _dataTable(
          columns: const ['الفئة', 'الإيراد'],
          rows: state.data.map((r) {
            return [
              r['categoryName'] as String,
              '${(r['revenue'] as double).toStringAsFixed(2)} ج.م',
            ];
          }).toList(),
        );
      case ReportType.byCategoryDetailed:
        return _buildDetailedCategoryTable(state.data);
      case ReportType.byItem:
        return _dataTable(
          columns: const ['الصنف', 'الكمية المباعة', 'الإيراد'],
          rows: state.data.map((r) {
            return [
              r['itemName'] as String,
              (r['quantity'] as int).toString(),
              '${(r['revenue'] as double).toStringAsFixed(2)} ج.م',
            ];
          }).toList(),
        );
      case ReportType.dateRange:
        return _dataTable(
          columns: const ['رقم الطلب', 'التاريخ', 'الإجمالي'],
          rows: state.data.map((r) {
            return [
              (r['id'] as int).toString(),
              DateFormat('yyyy/MM/dd HH:mm')
                  .format((r['date'] as DateTime).toLocal()),
              '${(r['total'] as double).toStringAsFixed(2)} ج.م',
            ];
          }).toList(),
        );
    }
  }

  Widget _dataTable(
      {required List<String> columns, required List<List<String>> rows}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: DataTable(
        columns:
            columns.map((c) => DataColumn(label: Text(c))).toList(),
        rows: rows
            .map((r) => DataRow(
                  cells: r.map((c) => DataCell(Text(c))).toList(),
                ))
            .toList(),
      ),
    );
  }
}
