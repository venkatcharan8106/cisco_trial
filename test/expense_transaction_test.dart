import 'package:flutter_test/flutter_test.dart';

import 'package:ember_ledger/models/expense_transaction.dart';
import 'package:ember_ledger/models/monthly_summary.dart';

void main() {
  test('transaction serialisation preserves a local calendar day', () {
    final transaction = ExpenseTransaction(
      id: 7,
      amount: 450,
      type: TransactionType.spent,
      date: DateTime(2026, 9, 14, 23, 59),
      description: 'Dinner',
      createdAt: DateTime(2026, 9, 14, 23, 59),
    );

    final row = transaction.toDatabase();
    expect(row['date'], '2026-09-14');
    expect(ExpenseTransaction.fromDatabase(row).dayKey, '2026-09-14');
  });

  test('remaining is dynamically derived rather than stored', () {
    const summary = MonthlySummary(amountAdded: 50000, spent: 18500);
    expect(summary.remaining, 31500);
  });
}
