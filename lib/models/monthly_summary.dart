class MonthlySummary {
  const MonthlySummary({this.amountAdded = 0, this.spent = 0});

  final double amountAdded;
  final double spent;
  double get remaining => amountAdded - spent;
}
