import 'package:intl/intl.dart';

enum TransactionType {
  amountAdded('AMOUNT_ADDED'),
  spent('SPENT');

  const TransactionType(this.databaseValue);
  final String databaseValue;

  static TransactionType fromDatabase(String value) =>
      value == amountAdded.databaseValue ? amountAdded : spent;
}

/// A calendar date is stored independently of a time/zone as `yyyy-MM-dd`.
/// This deliberately prevents a transaction from shifting day after travel.
class ExpenseTransaction {
  const ExpenseTransaction({
    this.id,
    required this.amount,
    required this.type,
    required this.date,
    required this.description,
    required this.createdAt,
  });

  final int? id;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String description;
  final DateTime createdAt;

  static final _dayFormat = DateFormat('yyyy-MM-dd');

  String get dayKey => _dayFormat.format(date);

  ExpenseTransaction copyWith({
    int? id,
    double? amount,
    TransactionType? type,
    DateTime? date,
    String? description,
    DateTime? createdAt,
  }) =>
      ExpenseTransaction(
        id: id ?? this.id,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        date: date ?? this.date,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
      );

  Map<String, Object?> toDatabase() => {
        'id': id,
        'amount': amount,
        'type': type.databaseValue,
        'date': dayKey,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  factory ExpenseTransaction.fromDatabase(Map<String, Object?> row) {
    return ExpenseTransaction(
      id: row['id'] as int,
      amount: (row['amount'] as num).toDouble(),
      type: TransactionType.fromDatabase(row['type'] as String),
      date: DateTime.parse(row['date'] as String),
      description: row['description'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
