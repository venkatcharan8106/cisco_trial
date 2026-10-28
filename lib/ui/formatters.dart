import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatMoney(double amount) => _currency.format(amount);

String formatMoneyInput(double amount) =>
    amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
