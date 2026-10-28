import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/expense_transaction.dart';
import '../models/monthly_summary.dart';

/// The sole persistence boundary. SQLite makes the app completely usable
/// offline and leaves a narrow seam for a later backup/sync implementation.
class ExpenseRepository {
  Database? _database;
  static final _dayFormat = DateFormat('yyyy-MM-dd');

  Future<void> open() async {
    final directory = await getDatabasesPath();
    _database = await openDatabase(
      path.join(directory, 'ember_ledger.db'),
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL CHECK(amount > 0),
            type TEXT NOT NULL CHECK(type IN ('AMOUNT_ADDED', 'SPENT')),
            date TEXT NOT NULL,
            description TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX transactions_date_idx ON transactions(date)');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final columns = await db.rawQuery('PRAGMA table_info(transactions)');
          final hasCategory = columns.any((column) => column['name'] == 'category');
          if (hasCategory) {
            await db.execute('ALTER TABLE transactions DROP COLUMN category');
          }
        }
      },
    );
  }

  Database get _db {
    final database = _database;
    if (database == null) throw StateError('The database has not been opened.');
    return database;
  }

  Future<List<ExpenseTransaction>> transactionsForDate(DateTime date) async {
    final rows = await _db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [_dayFormat.format(date)],
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(ExpenseTransaction.fromDatabase).toList(growable: false);
  }

  Future<List<ExpenseTransaction>> transactionsForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final rows = await _db.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [_dayFormat.format(start), _dayFormat.format(end)],
      orderBy: 'date DESC, created_at DESC, id DESC',
    );
    return rows.map(ExpenseTransaction.fromDatabase).toList(growable: false);
  }

  Future<Set<String>> transactionDaysForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final rows = await _db.rawQuery(
      'SELECT DISTINCT date FROM transactions WHERE date >= ? AND date < ?',
      [_dayFormat.format(start), _dayFormat.format(end)],
    );
    return rows.map((row) => row['date']! as String).toSet();
  }

  Future<MonthlySummary> summaryForMonth(DateTime month) async {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    final previousRows = await _db.rawQuery('''
      SELECT
        substr(date, 1, 7) AS month,
        COALESCE(SUM(CASE WHEN type = 'AMOUNT_ADDED' THEN amount ELSE 0 END), 0) AS amount_added,
        COALESCE(SUM(CASE WHEN type = 'SPENT' THEN amount ELSE 0 END), 0) AS spent
      FROM transactions
      WHERE date < ?
      GROUP BY month
      ORDER BY month ASC
    ''', [_dayFormat.format(start)]);
    var carryover = 0.0;
    for (final previous in previousRows) {
      carryover = (carryover +
              (previous['amount_added'] as num).toDouble() -
              (previous['spent'] as num).toDouble())
          .clamp(0, double.infinity)
          .toDouble();
    }
    final rows = await _db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'AMOUNT_ADDED' THEN amount ELSE 0 END), 0) AS amount_added,
        COALESCE(SUM(CASE WHEN type = 'SPENT' THEN amount ELSE 0 END), 0) AS spent
      FROM transactions
      WHERE date >= ? AND date < ?
    ''', [_dayFormat.format(start), _dayFormat.format(end)]);
    final row = rows.single;
    return MonthlySummary(
      amountAdded: (row['amount_added'] as num).toDouble() + carryover,
      spent: (row['spent'] as num).toDouble(),
    );
  }

  Future<ExpenseTransaction> save(ExpenseTransaction transaction) async {
    if (transaction.id == null) {
      final id = await _db.insert(
        'transactions',
        transaction.toDatabase()..remove('id'),
      );
      return transaction.copyWith(id: id);
    }
    await _db.update(
      'transactions',
      transaction.toDatabase()..remove('id'),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
    return transaction;
  }

  Future<void> delete(int id) =>
      _db.delete('transactions', where: 'id = ?', whereArgs: [id]);

  Future<List<ExpenseTransaction>> search(String query) async {
    final normalised = query.trim().toLowerCase().replaceAll('₹', '').replaceAll(',', '');
    if (normalised.isEmpty) return const [];
    final rows = await _db.query('transactions', orderBy: 'date DESC, id DESC');
    final monthFormat = DateFormat('MMMM yyyy');
    final dateFormat = DateFormat('MMMM d, yyyy');
    return rows
        .map(ExpenseTransaction.fromDatabase)
        .where((transaction) {
          final haystack = <String>[
            transaction.amount.toString(),
            transaction.description,
            transaction.type == TransactionType.spent ? 'spent expense' : 'amount added income salary',
            transaction.dayKey,
            monthFormat.format(transaction.date),
            dateFormat.format(transaction.date),
          ].join(' ').toLowerCase();
          return haystack.contains(normalised);
        })
        .toList(growable: false);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
