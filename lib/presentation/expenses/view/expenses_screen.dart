import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/domain/entities/expense.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/expense_repository.dart';
import 'package:intl/intl.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthRepository>().currentSession?.userId ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addExpense(context, uid),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Expense>>(
        stream: context.read<ExpenseRepository>().watchExpensesForUser(uid),
        builder: (context, snap) {
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No expenses logged'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final e = list[i];
              return ListTile(
                title: Text(e.category),
                subtitle: Text(DateFormat.yMMMd().format(e.expenseDate)),
                trailing: Text('₹${e.amount.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _addExpense(BuildContext context, String uid) async {
    final categoryCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<ExpenseRepository>().createExpense(
            userId: uid,
            category: categoryCtrl.text.trim(),
            amount: double.tryParse(amountCtrl.text) ?? 0,
            expenseDate: DateTime.now(),
          );
    }
  }
}
