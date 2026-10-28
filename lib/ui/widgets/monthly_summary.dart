import 'package:flutter/material.dart';

import '../../models/monthly_summary.dart';
import '../app_theme.dart';
import '../formatters.dart';

class MonthlySummaryPanel extends StatelessWidget {
  const MonthlySummaryPanel({super.key, required this.summary, this.isLoading = false});

  final MonthlySummary summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.separator),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          _Metric(label: 'AMOUNT', value: summary.amountAdded, isLoading: isLoading),
          const _Rule(),
          _Metric(label: 'SPENT', value: summary.spent, isLoading: isLoading),
          const _Rule(),
          _Metric(label: 'REMAINING', value: summary.remaining, isLoading: isLoading),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.isLoading});
  final String label;
  final double value;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => Expanded(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: Column(
            key: ValueKey('$label-$value-$isLoading'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppPalette.secondary,
                  fontSize: 10,
                  letterSpacing: 0.9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isLoading ? '—' : formatMoney(value),
                  style: TextStyle(
                    color: label == 'SPENT' ? AppPalette.white : AppPalette.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}

class _Rule extends StatelessWidget {
  const _Rule();
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 11),
        color: AppPalette.separator,
      );
}
