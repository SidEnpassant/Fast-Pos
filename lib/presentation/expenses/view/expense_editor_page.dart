import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';

class ExpenseEditorPage extends StatefulWidget {
  const ExpenseEditorPage({super.key, this.expense});

  final Expense? expense;

  @override
  State<ExpenseEditorPage> createState() => _ExpenseEditorPageState();
}

class _ExpenseEditorPageState extends State<ExpenseEditorPage> {
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late DateTime _date;
  static const _presets = [
    'Rent',
    'Utilities',
    'Supplies',
    'Transport',
    'Salary',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _amountCtrl = TextEditingController(
      text: e != null ? e.amount.toStringAsFixed(2) : '',
    );
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _date = e?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid == null) return;
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (_categoryCtrl.text.trim().isEmpty || amount <= 0) return;

    await context.read<ExpenseRepository>().createExpense(
          userId: uid,
          category: _categoryCtrl.text.trim(),
          amount: amount,
          expenseDate: _date,
          note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Add expense' : 'Edit expense'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            children: _presets
                .map(
                  (c) => FilterChip(
                    label: Text(c),
                    selected: _categoryCtrl.text == c,
                    onSelected: (_) => setState(() => _categoryCtrl.text = c),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _categoryCtrl,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _date = picked);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save expense')),
        ],
      ),
    );
  }
}
