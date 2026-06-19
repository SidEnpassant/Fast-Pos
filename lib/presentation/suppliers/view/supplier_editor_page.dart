import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_screen_scaffold.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:inventopos/domain/entities/supplier.dart';
import 'package:inventopos/domain/repositories/auth_repository.dart';
import 'package:inventopos/domain/repositories/supplier_repository.dart';

class SupplierEditorPage extends StatefulWidget {
  const SupplierEditorPage({super.key, this.supplierId});

  final String? supplierId;

  @override
  State<SupplierEditorPage> createState() => _SupplierEditorPageState();
}

class _SupplierEditorPageState extends State<SupplierEditorPage> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _gstinController = TextEditingController();
  final _addressController = TextEditingController();

  bool _saving = false;
  Supplier? _existing;

  static const _fieldDecoration = InputDecoration(
    border: OutlineInputBorder(),
  );

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.supplierId == null) return;
    final repo = context.read<SupplierRepository>();
    final s = await repo.findById(widget.supplierId!);
    if (s == null || !mounted) return;
    setState(() {
      _existing = s;
      _nameController.text = s.name;
      _phoneController.text = s.phone ?? '';
      _emailController.text = s.email ?? '';
      _gstinController.text = s.gstin ?? '';
      _addressController.text = s.address ?? '';
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _gstinController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final uid = context.read<AuthRepository>().currentSession?.userId;
    if (uid == null) return;
    
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }

    setState(() => _saving = true);
    final repo = context.read<SupplierRepository>();
    try {
      final supplier = Supplier(
        id: _existing?.id ?? '',
        userId: uid,
        name: name,
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        gstin: _gstinController.text.trim().isEmpty ? null : _gstinController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        updatedAt: DateTime.now(),
      );

      if (_existing != null) {
        await repo.updateSupplier(supplier);
      } else {
        await repo.createSupplier(supplier);
      }
      if (mounted) context.pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.supplierId != null;
    return AppScreenScaffold(
      title: isEdit ? 'Edit supplier' : 'Add supplier',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          AppSectionCard(
            title: 'Basic Info',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'Supplier Name *',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'Phone',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'Email',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppSectionCard(
            title: 'Tax & Address',
            child: Column(
              children: [
                TextField(
                  controller: _gstinController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'GSTIN',
                    hintText: '22AAAAA0000A1Z5',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: _fieldDecoration.copyWith(
                    labelText: 'Address',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save supplier'),
          ),
        ),
      ),
    );
  }
}
