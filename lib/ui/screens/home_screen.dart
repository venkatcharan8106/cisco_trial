import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense_transaction.dart';
import '../../state/expense_controller.dart';
import '../app_theme.dart';
import '../widgets/month_calendar.dart';
import '../widgets/monthly_summary.dart';
import '../widgets/transaction_search.dart';
import '../widgets/transaction_sheets.dart';
import '../widgets/transaction_tile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});
  final ExpenseController controller;

  Future<void> _openSearch(BuildContext context) async {
    final found = await showSearch<ExpenseTransaction?>(
      context: context,
      delegate: TransactionSearchDelegate(controller),
    );
    if (found != null) await controller.focusDate(found.date);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => LayoutBuilder(
              builder: (context, constraints) {
                final calendarHeight = math
                    .max(245.0, math.min(370.0, constraints.maxHeight * 0.415))
                    .toDouble();
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 12, 2),
                      child: _Header(
                        month: controller.displayedMonth,
                        onSearch: () => _openSearch(context),
                      ),
                    ),
                    SizedBox(
                      height: calendarHeight,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: MonthCalendar(
                          month: controller.displayedMonth,
                          selectedDate: controller.selectedDate,
                          today: controller.today,
                          hasTransactions: controller.isTransactionDay,
                          onDateSelected: controller.selectDate,
                          onMonthChanged: controller.showMonth,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 13),
                      child: MonthlySummaryPanel(
                        summary: controller.summary,
                        isLoading: controller.isLoading,
                      ),
                    ),
                    const Divider(height: 1, indent: 20, endIndent: 20),
                    Expanded(
                      child: _SelectedDateSection(controller: controller),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.month, required this.onSearch});
  final DateTime month;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
                      .animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                DateFormat('MMMM yyyy').format(month),
                key: ValueKey('${month.year}-${month.month}'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search transactions',
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      );
}

class _SelectedDateSection extends StatelessWidget {
  const _SelectedDateSection({required this.controller});
  final ExpenseController controller;

  @override
  Widget build(BuildContext context) {
    final date = controller.selectedDate;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 11, 20, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(DateFormat('MMMM d').format(date),
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                tooltip: 'Add transaction for ${DateFormat.yMMMMd().format(date)}',
                onPressed: () => showAddTransactionSheet(context, controller, date),
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppPalette.accent,
              ),
              IconButton(
                tooltip: 'Show all transactions for ${DateFormat.yMMMM().format(controller.displayedMonth)}',
                onPressed: () => showMonthTransactionsSheet(context, controller),
                icon: const Icon(Icons.list_alt_rounded),
                color: AppPalette.accent,
              ),
            ],
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: _TransactionsBody(
                key: ValueKey('${date.year}-${date.month}-${date.day}-${controller.selectedTransactions.length}'),
                controller: controller,
                date: date,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsBody extends StatelessWidget {
  const _TransactionsBody({super.key, required this.controller, required this.date});
  final ExpenseController controller;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    if (controller.isLoading) {
      return const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final transactions = controller.selectedTransactions;
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined, color: AppPalette.secondary, size: 30),
              const SizedBox(height: 10),
              const Text('No transactions for this date.',
                  style: TextStyle(color: AppPalette.secondary)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => showAddTransactionSheet(context, controller, date),
                style: TextButton.styleFrom(foregroundColor: AppPalette.accent),
                child: const Text('Add one'),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return TransactionTile(
          transaction: transaction,
          onTap: () => showTransactionDetailsSheet(context, controller, transaction),
        );
      },
    );
  }
}
