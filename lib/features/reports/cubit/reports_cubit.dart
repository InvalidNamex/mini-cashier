import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/orders_dao.dart';

part 'reports_state.dart';

enum ReportType { daily, byCategory, byItem, dateRange, cashFlow, byCategoryDetailed }

class ReportsCubit extends Cubit<ReportsState> {
  final OrdersDao _dao;

  ReportsCubit(this._dao)
      : super(ReportsState(
          from: DateTime.now().subtract(const Duration(days: 7)),
          to: DateTime.now(),
        ));

  void setDateRange(DateTime from, DateTime to) {
    emit(state.copyWith(from: from, to: to, data: []));
  }

  void setType(ReportType type) {
    emit(state.copyWith(type: type, data: []));
  }

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    try {
      List<Map<String, dynamic>> data;
      switch (state.type) {
        case ReportType.daily:
        case ReportType.cashFlow:
          data = await _dao.dailySales(state.from, state.to);
          break;
        case ReportType.byCategory:
          data = await _dao.revenueByCategory(state.from, state.to);
          break;
        case ReportType.byItem:
          data = await _dao.revenueByItem(state.from, state.to);
          break;
        case ReportType.byCategoryDetailed:
          data = await _dao.revenueByCategoryWithItems(state.from, state.to);
          break;
        case ReportType.dateRange:
          final orders = await _dao.paidOrdersInRange(state.from, state.to);
          data = orders
              .map((o) => {
                    'id': o.id,
                    'date': o.createdAt,
                    'total': o.total,
                  })
              .toList();
          break;
      }
      emit(state.copyWith(data: data, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
