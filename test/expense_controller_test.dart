import 'package:flutter_test/flutter_test.dart';

import 'package:ember_ledger/data/expense_repository.dart';
import 'package:ember_ledger/models/expense_transaction.dart';
import 'package:ember_ledger/models/monthly_summary.dart';
import 'package:ember_ledger/state/expense_controller.dart';

void main() {
  test('controller saves, edits, deletes, and filters by local calendar day', () async {
    final repository = _MemoryExpenseRepository([
      _transaction(
        id: 1,
        amount: 1000,
        type: TransactionType.amountAdded,
        date: DateTime(2026, 8, 31),
        description: 'Carryover',
      ),
      _transaction(
        id: 2,
        amount: 250,
        type: TransactionType.spent,
        date: DateTime(2026, 8, 31),
        description: 'Old expense',
      ),
    ]);
    final controller = ExpenseController(repository, now: DateTime(2026, 9, 14, 23, 59));

    await controller.initialise();
    expect(controller.selectedTransactions, isEmpty);
    expect(controller.summary.amountAdded, 750);
    expect(controller.summary.spent, 0);

    await controller.saveTransaction(_transaction(
      amount: 100,
      type: TransactionType.spent,
      date: DateTime(2026, 9, 14),
      description: 'Lunch',
    ));
    expect(controller.selectedTransactions.single.description, 'Lunch');
    expect(controller.summary.spent, 100);
    expect(controller.summary.remaining, 650);
    expect(controller.isTransactionDay(DateTime(2026, 9, 14, 23, 59)), isTrue);

    var saved = controller.selectedTransactions.single;
    await controller.saveTransaction(saved.copyWith(amount: 125));
    expect(controller.selectedTransactions.single.amount, 125);
    expect(controller.summary.spent, 125);

    await controller.selectDate(DateTime(2026, 9, 15));
    expect(controller.selectedTransactions, isEmpty);
    await controller.selectDate(DateTime(2026, 9, 14));
    saved = controller.selectedTransactions.single;
    await controller.deleteTransaction(saved);
    expect(controller.selectedTransactions, isEmpty);
    expect(controller.isTransactionDay(DateTime(2026, 9, 14)), isFalse);
  });

  test('controller keeps future dates selectable', () async {
    final repository = _MemoryExpenseRepository();
    final controller = ExpenseController(repository, now: DateTime(2026, 9, 14));

    await controller.initialise();
    await controller.focusDate(DateTime(2030, 2, 28, 23, 59));

    expect(controller.selectedDate, DateTime(2030, 2, 28));
    expect(controller.displayedMonth, DateTime(2030, 2));
    expect(controller.selectedTransactions, isEmpty);
  });
}

ExpenseTransaction _transaction({
  int? id,
  required double amount,
  required TransactionType type,
  required DateTime date,
  required String description,
}) => ExpenseTransaction(
      id: id,
      amount: amount,
      type: type,
      date: date,
      description: description,
      createdAt: DateTime(2026, 9, 14),
    );

class _MemoryExpenseRepository extends ExpenseRepository {
  _MemoryExpenseRepository([List<ExpenseTransaction>? initial])
      : _transactions = [...?initial];

  final List<ExpenseTransaction> _transactions;
  int _nextId = 10;

  @override
  Future<List<ExpenseTransaction>> transactionsForDate(DateTime date) async => _transactions
      .where((transaction) => transaction.dayKey == ExpenseTransaction(
            amount: 1,
            type: TransactionType.spent,
            date: date,
            description: '',
            createdAt: date,
          ).dayKey)
      .toList();

  @override
  Future<Set<String>> transactionDaysForMonth(DateTime month) async => _transactions
      .where((transaction) =>
          transaction.date.year == month.year && transaction.date.month == month.month)
      .map((transaction) => transaction.dayKey)
      .toSet();

  @override
  Future<MonthlySummary> summaryForMonth(DateTime month) async {
    final currentMonth = '${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}';
    final months = _transactions.map((transaction) => transaction.dayKey.substring(0, 7)).toSet()
      ..removeWhere((value) => value.compareTo(currentMonth) >= 0);
    var carryover = 0.0;
    for (final previousMonth in months.toList()..sort()) {
      for (final transaction in _transactions.where(
        (transaction) => transaction.dayKey.startsWith(previousMonth),
      )) {
        carryover += transaction.type == TransactionType.amountAdded
            ? transaction.amount
            : -transaction.amount;
      }
      carryover = carryover.clamp(0, double.infinity).toDouble();
    }
    final current = _transactions.where(
      (transaction) => transaction.dayKey.startsWith(currentMonth),
    );
    return MonthlySummary(
      amountAdded: carryover + _sum(current, TransactionType.amountAdded),
      spent: _sum(current, TransactionType.spent),
    );
  }

  @override
  Future<ExpenseTransaction> save(ExpenseTransaction transaction) async {
    if (transaction.id == null) {
      final saved = transaction.copyWith(id: _nextId++);
      _transactions.add(saved);
      return saved;
    }
    final index = _transactions.indexWhere((value) => value.id == transaction.id);
    _transactions[index] = transaction;
    return transaction;
  }

  @override
  Future<void> delete(int id) async => _transactions.removeWhere((value) => value.id == id);

  double _sum(Iterable<ExpenseTransaction> transactions, TransactionType type) => transactions
      .where((transaction) => transaction.type == type)
      .fold(0, (total, transaction) => total + transaction.amount);
}