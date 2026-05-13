part of 'reports_cubit.dart';

class ReportsState extends Equatable {
  final ReportType type;
  final DateTime from;
  final DateTime to;
  final List<Map<String, dynamic>> data;
  final bool isLoading;
  final String? error;

  const ReportsState({
    this.type = ReportType.daily,
    required this.from,
    required this.to,
    this.data = const [],
    this.isLoading = false,
    this.error,
  });

  ReportsState copyWith({
    ReportType? type,
    DateTime? from,
    DateTime? to,
    List<Map<String, dynamic>>? data,
    bool? isLoading,
    String? error,
  }) =>
      ReportsState(
        type: type ?? this.type,
        from: from ?? this.from,
        to: to ?? this.to,
        data: data ?? this.data,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  @override
  List<Object?> get props => [type, from, to, data, isLoading, error];
}
