import 'package:flutter/material.dart';

import '../../models/expense_transaction.dart';
import '../app_theme.dart';
import '../formatters.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction, required this.onTap});

  final ExpenseTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSpent = transaction.type == TransactionType.spent;
    final heading = transaction.description.trim().isEmpty
      ? (isSpent ? 'Spent' : 'Amount added')
        : transaction.description.trim();
    return Semantics(
      button: true,
      label: '$heading, ${isSpent ? 'spent' : 'amount added'}, ${formatMoney(transaction.amount)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSpent ? AppPalette.elevatedSurface : AppPalette.accentMuted,
                ),
                child: Icon(
                  isSpent ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isSpent ? AppPalette.secondary : AppPalette.accent,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isSpent ? 'Spent' : 'Amount added',
                      style: const TextStyle(color: AppPalette.secondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${isSpent ? '-' : '+'}${formatMoney(transaction.amount)}',
                style: const TextStyle(
                  color: AppPalette.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
