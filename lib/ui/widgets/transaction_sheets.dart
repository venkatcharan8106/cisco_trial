import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/expense_transaction.dart';
import '../../state/expense_controller.dart';
import '../app_theme.dart';
import '../formatters.dart';
import 'transaction_tile.dart';

Future<void> showAddTransactionSheet(
  BuildContext context,
  ExpenseController controller,
  DateTime selectedDate, {
  ExpenseTransaction? transaction,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _TransactionEditorSheet(
      controller: controller,
      initialDate: selectedDate,
      transaction: transaction,
    ),
  );
}

class _TransactionEditorSheet extends StatefulWidget {
  const _TransactionEditorSheet({
    required this.controller,
    required this.initialDate,
    this.transaction,
  });

  final ExpenseController controller;
  final DateTime initialDate;
  final ExpenseTransaction? transaction;

  @override
  State<_TransactionEditorSheet> createState() => _TransactionEditorSheetState();
}

class _TransactionEditorSheetState extends State<_TransactionEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late TransactionType _type;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.transaction;
    _amountController = TextEditingController(
      text: initial == null ? '' : formatMoneyInput(initial.amount),
    );
    _descriptionController = TextEditingController(text: initial?.description ?? '');
    _type = initial?.type ?? TransactionType.spent;
    _date = initial?.date ?? widget.initialDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 150, now.month),
      lastDate: DateTime(now.year + 150, now.month),
      helpText: 'SELECT TRANSACTION DATE',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppPalette.accent,
                surface: AppPalette.surface,
                onSurface: AppPalette.white,
              ),
        ),
        child: child!,
      ),
    );
    if (date != null && mounted) setState(() => _date = date);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final amount = double.parse(_amountController.text.trim());
    try {
      await widget.controller.saveTransaction(
        ExpenseTransaction(
          id: widget.transaction?.id,
          amount: amount,
          type: _type,
          date: _date,
          description: _descriptionController.text.trim(),
          createdAt: widget.transaction?.createdAt ?? DateTime.now(),
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save the transaction. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.transaction != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.separator,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 21),
              Text(editing ? 'EDIT TRANSACTION' : 'ADD TRANSACTION',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 22),
              const _FieldLabel('TRANSACTION TYPE'),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _TypeOption(
                      label: 'Amount Added',
                      icon: Icons.add_rounded,
                      selected: _type == TransactionType.amountAdded,
                      onTap: () => setState(() => _type = TransactionType.amountAdded),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeOption(
                      label: 'Spent',
                      icon: Icons.remove_rounded,
                      selected: _type == TransactionType.spent,
                      onTap: () => setState(() => _type = TransactionType.spent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const _FieldLabel('AMOUNT'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _amountController,
                autofocus: !editing,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                decoration: const InputDecoration(prefixText: '₹  ', hintText: '0'),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) return 'Enter an amount greater than zero.';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const _FieldLabel('WHAT WAS THIS FOR?'),
              const SizedBox(height: 9),
              TextFormField(
                controller: _descriptionController,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 120,
                decoration: const InputDecoration(hintText: 'Dinner, coffee, salary...'),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('DATE'),
              const SizedBox(height: 9),
              Semantics(
                button: true,
                label: 'Transaction date ${DateFormat.yMMMMd().format(_date)}',
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(
                      color: AppPalette.elevatedSurface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppPalette.separator),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_outlined, size: 20, color: AppPalette.accent),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(DateFormat.yMMMMd().format(_date),
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                        ),
                        const Icon(Icons.edit_outlined, size: 18, color: AppPalette.secondary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.accent,
                  foregroundColor: AppPalette.white,
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppPalette.white),
                      )
                    : Text(editing ? 'SAVE CHANGES' : 'SAVE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: AppPalette.secondary,
          letterSpacing: 0.8,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
            decoration: BoxDecoration(
              color: selected ? AppPalette.accent : AppPalette.elevatedSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppPalette.accent : AppPalette.separator),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(label, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
}

Future<void> showTransactionDetailsSheet(
  BuildContext context,
  ExpenseController controller,
  ExpenseTransaction transaction,
) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    builder: (sheetContext) => _TransactionDetailsSheet(
      controller: controller,
      transaction: transaction,
    ),
  );
}

class _TransactionDetailsSheet extends StatelessWidget {
  const _TransactionDetailsSheet({required this.controller, required this.transaction});
  final ExpenseController controller;
  final ExpenseTransaction transaction;

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppPalette.elevatedSurface,
        title: const Text('Delete this transaction?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppPalette.accent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.deleteTransaction(transaction);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSpent = transaction.type == TransactionType.spent;
    final title = transaction.description.isEmpty
      ? (isSpent ? 'Spent' : 'Amount added')
      : transaction.description;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(width: 36, height: 4, decoration: BoxDecoration(
              color: AppPalette.separator, borderRadius: BorderRadius.circular(99))),
          ),
          const SizedBox(height: 22),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(DateFormat.yMMMMd().format(transaction.date),
              style: const TextStyle(color: AppPalette.secondary)),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(
              color: AppPalette.elevatedSurface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppPalette.separator),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${isSpent ? '-' : '+'}${formatMoney(transaction.amount)}',
                    style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(isSpent ? 'Spent' : 'Amount added',
                  style: const TextStyle(color: AppPalette.secondary)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              await showAddTransactionSheet(context, controller, transaction.date, transaction: transaction);
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit transaction'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppPalette.white,
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppPalette.separator),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete transaction'),
            style: TextButton.styleFrom(foregroundColor: AppPalette.accent),
          ),
        ],
      ),
    );
  }
}

Future<void> showMonthTransactionsSheet(
  BuildContext context,
  ExpenseController controller,
) {
  final month = controller.displayedMonth;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => _MonthTransactionsSheet(
      controller: controller,
      month: month,
    ),
  );
}

class _MonthTransactionsSheet extends StatelessWidget {
  const _MonthTransactionsSheet({required this.controller, required this.month});

  final ExpenseController controller;
  final DateTime month;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.78,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppPalette.separator,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 21),
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Text(
                'All transactions for this month',
                style: TextStyle(color: AppPalette.secondary),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<ExpenseTransaction>>(
                  future: controller.transactionsForDisplayedMonth(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Could not load this month.',
                            style: TextStyle(color: AppPalette.secondary)),
                      );
                    }
                    final transactions = snapshot.data ?? const [];
                    if (transactions.isEmpty) {
                      return const Center(
                        child: Text('No transactions for this month.',
                            style: TextStyle(color: AppPalette.secondary)),
                      );
                    }
                    return ListView.separated(
                      itemCount: transactions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return TransactionTile(
                          transaction: transaction,
                          onTap: () async {
                            Navigator.of(context).pop();
                            await showTransactionDetailsSheet(
                              context,
                              controller,
                              transaction,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
}
