import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventopos/presentation/account/bloc/account_bloc.dart';
import 'package:inventopos/presentation/account/bloc/account_event.dart';

Future<void> showAccountFieldEditDialog(
  BuildContext context, {
  required String label,
  required String fieldKey,
  required String initialValue,
}) async {
  final bloc = context.read<AccountBloc>();
  final controller = TextEditingController(text: initialValue);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text('Edit $label'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: fieldKey == 'businessAddress' ? 3 : 1,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'Enter $label',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(
                AccountPatchFieldRequested(
                  fieldKey: fieldKey,
                  value: controller.text,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
