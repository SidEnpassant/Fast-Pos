import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/presentation/account/bloc/account_bloc.dart';
import 'package:inventopos/presentation/account/bloc/account_event.dart';
import 'package:inventopos/presentation/account/bloc/account_state.dart';
import 'package:inventopos/presentation/account/widgets/account_editable_field_tile.dart';
import 'package:inventopos/presentation/account/widgets/account_field_edit_dialog.dart';
import 'package:inventopos/presentation/account/widgets/account_mutation_overlay.dart';
import 'package:inventopos/presentation/account/widgets/account_profile_header_section.dart';
import 'package:go_router/go_router.dart';
import 'package:inventopos/presentation/auth_login/bloc/auth_bloc.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAndReplaceSignature() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    context.read<AccountBloc>().add(
          AccountReplaceSignatureRequested(image.path),
        );
  }

  String _str(Map<String, dynamic> fields, String key) =>
      fields[key]?.toString() ?? '';

  Widget _animatedTile({
    required Widget child,
  }) {
    return AnimationConfiguration.synchronized(
      duration: const Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 30,
        child: FadeInAnimation(child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountBloc, AccountState>(
      listenWhen: (p, c) =>
          c.feedbackMessage != null && c.feedbackMessage != p.feedbackMessage,
      listener: (context, state) {
        final msg = state.feedbackMessage;
        if (msg == null) return;
        final error = state.feedbackIsError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  error ? Icons.close : Icons.check,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(msg)),
              ],
            ),
            backgroundColor:
                error ? const Color(0xFFFF5252) : const Color(0xFF00C896),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.read<AccountBloc>().add(const AccountUiFeedbackConsumed());
      },
      builder: (context, accountState) {
        final fields = accountState.fields;
        final busy = accountState.loading || accountState.mutationBusy;

        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'My Account',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => context.read<AuthBloc>().signOut(),
                    tooltip: 'Logout',
                  ),
                ],
                backgroundColor: Colors.white,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
              ),
              Expanded(
                child: Stack(
                  children: [
                    SafeArea(
                      child: FadeTransition(
                        opacity: _animation,
                        child: RefreshIndicator(
                          onRefresh: () async {
                            await Future<void>.delayed(
                              const Duration(milliseconds: 200),
                            );
                          },
                          color: const Color(0xFF3B82F6),
                          backgroundColor: Colors.white,
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: AnimationLimiter(
                              child: Column(
                                children: [
                                  AccountProfileHeaderSection(
                                    fields: fields,
                                    onChangeSignature: _pickAndReplaceSignature,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const _SectionTitle(
                                          'Personal Information',
                                        ),
                                        const SizedBox(height: 16),
                                        _animatedTile(
                                          child: AccountEditableFieldTile(
                                            label: 'Name',
                                            fieldKey: 'name',
                                            icon: Icons.person_outline,
                                            valueText: _str(fields, 'name'),
                                            onTap: () => showAccountFieldEditDialog(
                                              context,
                                              label: 'Name',
                                              fieldKey: 'name',
                                              initialValue: _str(fields, 'name'),
                                            ),
                                          ),
                                        ),
                                        _animatedTile(
                                          child: AccountEditableFieldTile(
                                            label: 'Phone Number',
                                            fieldKey: 'phoneNumber',
                                            icon: Icons.phone_outlined,
                                            valueText:
                                                _str(fields, 'phoneNumber'),
                                            onTap: () =>
                                                showAccountFieldEditDialog(
                                              context,
                                              label: 'Phone Number',
                                              fieldKey: 'phoneNumber',
                                              initialValue: _str(
                                                fields,
                                                'phoneNumber',
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        const _SectionTitle(
                                          'Business Information',
                                        ),
                                        const SizedBox(height: 16),
                                        _animatedTile(
                                          child: AccountEditableFieldTile(
                                            label: 'Business Name',
                                            fieldKey: 'businessName',
                                            icon: Icons.business_outlined,
                                            valueText:
                                                _str(fields, 'businessName'),
                                            onTap: () =>
                                                showAccountFieldEditDialog(
                                              context,
                                              label: 'Business Name',
                                              fieldKey: 'businessName',
                                              initialValue: _str(
                                                fields,
                                                'businessName',
                                              ),
                                            ),
                                          ),
                                        ),
                                        _animatedTile(
                                          child: AccountEditableFieldTile(
                                            label: 'Business Address',
                                            fieldKey: 'businessAddress',
                                            icon: Icons.location_on_outlined,
                                            valueText:
                                                _str(fields, 'businessAddress'),
                                            onTap: () =>
                                                showAccountFieldEditDialog(
                                              context,
                                              label: 'Business Address',
                                              fieldKey: 'businessAddress',
                                              initialValue: _str(
                                                fields,
                                                'businessAddress',
                                              ),
                                            ),
                                          ),
                                        ),
                                        _animatedTile(
                                          child: AccountEditableFieldTile(
                                            label: 'GST Number',
                                            fieldKey: 'gstNumber',
                                            icon: Icons.receipt_long_outlined,
                                            valueText: _str(fields, 'gstNumber'),
                                            onTap: () =>
                                                showAccountFieldEditDialog(
                                              context,
                                              label: 'GST Number',
                                              fieldKey: 'gstNumber',
                                              initialValue: _str(
                                                fields,
                                                'gstNumber',
                                              ),
                                            ),
                                          ),
                                        ),
                                        _animatedTile(
                                          child: AccountEditableFieldTile(
                                            label: 'Bill Rules',
                                            fieldKey: 'billRules',
                                            icon: Icons.rule_outlined,
                                            valueText: _str(fields, 'billRules'),
                                            onTap: () =>
                                                showAccountFieldEditDialog(
                                              context,
                                              label: 'Bill Rules',
                                              fieldKey: 'billRules',
                                              initialValue: _str(
                                                fields,
                                                'billRules',
                                              ),
                                            ),
                                          ),
                                        ),
                                        _animatedTile(
                                          child: ListTile(
                                            leading: const Icon(Icons.print),
                                            title: const Text('Printer setup'),
                                            subtitle: const Text(
                                              'Business tools are on the Dashboard',
                                            ),
                                            onTap: () => context.push('/printer-setup'),
                                          ),
                                        ),
                                        const SizedBox(height: 40),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    AccountMutationOverlay(visible: busy),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1D29),
      ),
    );
  }
}
