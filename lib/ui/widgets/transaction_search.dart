import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/expense_transaction.dart';
import '../../state/expense_controller.dart';
import '../app_theme.dart';
import '../formatters.dart';

class TransactionSearchDelegate extends SearchDelegate<ExpenseTransaction?> {
  TransactionSearchDelegate(this.controller)
      : super(
          searchFieldLabel: 'Search transactions',
          searchFieldStyle: const TextStyle(color: AppPalette.white, fontSize: 17),
        );

  final ExpenseController controller;

  @override
  ThemeData appBarTheme(BuildContext context) => Theme.of(context).copyWith(
        scaffoldBackgroundColor: AppPalette.background,
        appBarTheme: const AppBarTheme(backgroundColor: AppPalette.background),
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          border: InputBorder.none,
          hintStyle: TextStyle(color: AppPalette.secondary),
        ),
      );

  @override
  List<Widget>? buildActions(BuildContext context) => [
        if (query.isNotEmpty)
          IconButton(
            tooltip: 'Clear search',
            onPressed: () => query = '',
            icon: const Icon(Icons.close),
          ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        tooltip: 'Close search',
        onPressed: () => close(context, null),
        icon: const Icon(Icons.arrow_back),
      );

  @override
  Widget buildResults(BuildContext context) => _SearchResults(
        query: query,
        controller: controller,
        onSelected: (transaction) => close(context, transaction),
      );

  @override
  Widget buildSuggestions(BuildContext context) => _SearchResults(
        query: query,
        controller: controller,
        onSelected: (transaction) => close(context, transaction),
      );
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({
    required this.query,
    required this.controller,
    required this.onSelected,
  });
  final String query;
  final ExpenseController controller;
  final ValueChanged<ExpenseTransaction> onSelected;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Search descriptions, categories, amounts, or months.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppPalette.secondary),
          ),
        ),
      );
    }
    return FutureBuilder<List<ExpenseTransaction>>(
      future: controller.search(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Search is temporarily unavailable.'));
        }
        final results = snapshot.data ?? const [];
        if (results.isEmpty) {
          return const Center(
            child: Text('No matching transactions.', style: TextStyle(color: AppPalette.secondary)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          itemCount: results.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final transaction = results[index];
            final isSpent = transaction.type == TransactionType.spent;
            final title = transaction.description.isEmpty
              ? (isSpent ? 'Spent' : 'Amount added')
              : transaction.description;
            return ListTile(
              onTap: () => onSelected(transaction),
              contentPadding: const EdgeInsets.symmetric(vertical: 5),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                DateFormat.MMMd().format(transaction.date),
                style: const TextStyle(color: AppPalette.secondary),
              ),
              trailing: Text(
                '${isSpent ? '-' : '+'}${formatMoney(transaction.amount)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            );
          },
        );
      },
    );
  }
}
