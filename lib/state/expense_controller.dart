import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../data/expense_repository.dart';
import '../models/expense_transaction.dart';
import '../models/monthly_summary.dart';

class ExpenseController extends ChangeNotifier {
  ExpenseController(this._repository, {DateTime? now})
      : _today = _dateOnly(now ?? DateTime.now()),
        _displayedMonth = _firstOfMonth(now ?? DateTime.now()),
        _selectedDate = _dateOnly(now ?? DateTime.now());

  final ExpenseRepository _repository;
  final DateTime _today;
  DateTime _displayedMonth;
  DateTime _selectedDate;
  MonthlySummary _summary = const MonthlySummary();
  List<ExpenseTransaction> _selectedTransactions = const [];
  Set<String> _transactionDays = const {};
  bool _isLoading = true;
  int _requestNumber = 0;

  DateTime get today => _today;
  DateTime get displayedMonth => _displayedMonth;
  DateTime get selectedDate => _selectedDate;
  MonthlySummary get summary => _summary;
  List<ExpenseTransaction> get selectedTransactions => _selectedTransactions;
  Set<String> get transactionDays => _transactionDays;
  bool get isLoading => _isLoading;

  Future<void> initialise() => _reload();

  bool isTransactionDay(DateTime date) =>
      _transactionDays.contains(DateFormat('yyyy-MM-dd').format(date));

  Future<void> selectDate(DateTime date) async {
    final selected = _dateOnly(date);
    if (selected == _selectedDate) return;
    _selectedDate = selected;
    notifyListeners();
    await _reload(selectedOnly: true);
  }

  /// Called by the paged calendar. It always moves the selection into the
  /// visible month, preserving its day number where possible.
  Future<void> showMonth(DateTime month) async {
    final targetMonth = _firstOfMonth(month);
    if (targetMonth == _displayedMonth) return;
    final lastDay = DateTime(targetMonth.year, targetMonth.month + 1, 0).day;
    _displayedMonth = targetMonth;
    _selectedDate = DateTime(
      targetMonth.year,
      targetMonth.month,
      math.min(_selectedDate.day, lastDay),
    );
    await _reload();
  }

  /// Used when a search result is tapped. This is intentionally separate from
  /// regular paging so that its exact original date remains selected.
  Future<void> focusDate(DateTime date) async {
    _selectedDate = _dateOnly(date);
    _displayedMonth = _firstOfMonth(date);
    await _reload();
  }

  Future<void> saveTransaction(ExpenseTransaction transaction) async {
    await _repository.save(transaction);
    // Saving to a manually changed date should immediately reveal the saved
    // record and that month's recalculated totals.
    _selectedDate = _dateOnly(transaction.date);
    _displayedMonth = _firstOfMonth(transaction.date);
    await _reload();
  }

  Future<void> deleteTransaction(ExpenseTransaction transaction) async {
    final id = transaction.id;
    if (id == null) return;
    await _repository.delete(id);
    await _reload();
  }

  Future<List<ExpenseTransaction>> search(String query) => _repository.search(query);

  Future<List<ExpenseTransaction>> transactionsForDisplayedMonth() =>
      _repository.transactionsForMonth(_displayedMonth);

  Future<void> _reload({bool selectedOnly = false}) async {
    final request = ++_requestNumber;
    _isLoading = true;
    notifyListeners();
    try {
      final dateTransactions = _repository.transactionsForDate(_selectedDate);
      if (selectedOnly) {
        final result = await dateTransactions;
        if (request != _requestNumber) return;
        _selectedTransactions = result;
      } else {
        final results = await Future.wait<Object>([
          dateTransactions,
          _repository.summaryForMonth(_displayedMonth),
          _repository.transactionDaysForMonth(_displayedMonth),
        ]);
        if (request != _requestNumber) return;
        _selectedTransactions = results[0] as List<ExpenseTransaction>;
        _summary = results[1] as MonthlySummary;
        _transactionDays = results[2] as Set<String>;
      }
    } finally {
      if (request == _requestNumber) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
  static DateTime _firstOfMonth(DateTime value) => DateTime(value.year, value.month);
}
