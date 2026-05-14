import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventopos/presentation/account/bloc/account_bloc.dart';
import 'package:inventopos/presentation/account/bloc/account_event.dart';
import 'package:inventopos/presentation/account/bloc/account_state.dart';
import 'package:inventopos/supabase_mappers.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;

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

  Future<void> _updateUserData(String field, String value) async {
    setState(() => _isLoading = true);
    try {
      final user = _supabase.auth.currentUser;
      final column = SupabaseMappers.profileColumnForField(field);
      if (user != null && column != null) {
        await _supabase
            .from('profiles')
            .update({column: value}).eq('id', user.id);
        if (mounted) {
          context.read<AccountBloc>().add(AccountFieldPatched(field, value));
        }
        _showSuccessSnackbar('Updated successfully');
      }
    } catch (e) {
      _showErrorSnackbar('Update failed');
    }
    setState(() => _isLoading = false);
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: Colors.white, size: 16),
            ),
            SizedBox(width: 12),
            Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Color(0xFF00C896),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
        elevation: 8,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: Colors.white, size: 16),
            ),
            SizedBox(width: 12),
            Text(message, style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(16),
        elevation: 8,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _updateSignature() async {
    final ImagePicker _picker = ImagePicker();
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isLoading = true);
        final user = _supabase.auth.currentUser;
        if (user != null) {
          final path =
              '${user.id}/signature_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await _supabase.storage.from('signatures').upload(
                path,
                File(image.path),
                fileOptions: const FileOptions(upsert: true),
              );
          final downloadURL =
              _supabase.storage.from('signatures').getPublicUrl(path);

          await _supabase
              .from('profiles')
              .update({'signature_url': downloadURL}).eq('id', user.id);
          if (mounted) {
            context.read<AccountBloc>().add(
                  AccountFieldPatched('signatureUrl', downloadURL.toString()),
                );
          }
          _showSuccessSnackbar('Profile picture updated successfully');
        }
      }
    } catch (e) {
      _showErrorSnackbar('Failed to update profile picture');
    }
    setState(() => _isLoading = false);
  }

  void _showEditDialog(String label, String field, dynamic initialValue) {
    final controller = TextEditingController(
      text: initialValue?.toString() ?? '',
    );
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit $label',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1D29),
                ),
              ),
              SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE5E7EB)),
                ),
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Enter $label',
                    hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                  ),
                  style: TextStyle(color: Color(0xFF1A1D29), fontSize: 16),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      child: TextButton(
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 48,
                      child: ElevatedButton(
                        child: Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: () {
                          _updateUserData(field, controller.text);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditableField(
    String label,
    String field,
    IconData icon,
    Map<String, dynamic> fields,
  ) {
    return AnimationConfiguration.synchronized(
      duration: Duration(milliseconds: 500),
      child: SlideAnimation(
        verticalOffset: 30.0,
        child: FadeInAnimation(
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showEditDialog(label, field, fields[field]),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              fields[field]?.isNotEmpty == true
                                  ? fields[field].toString()
                                  : 'Not set',
                              style: TextStyle(
                                fontSize: 16,
                                color: fields[field]?.isNotEmpty == true
                                    ? Color(0xFF1A1D29)
                                    : Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          color: Color(0xFF9CA3AF),
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(Map<String, dynamic> fields) {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3B82F6),
                Color(0xFF1D4ED8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF3B82F6).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: fields['signatureUrl'] ??
                      'https://via.placeholder.com/150',
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Color(0xFFF3F4F6),
                    highlightColor: Color(0xFFE5E7EB),
                    child: Container(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _updateSignature,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF10B981),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> fields) {
    return Container(
      padding: EdgeInsets.all(24),
      margin: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileImage(fields),
          SizedBox(height: 20),
          Text(
            fields['name']?.toString().isNotEmpty == true
                ? fields['name'].toString()
                : 'Your Name',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1D29),
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              fields['email']?.toString().isNotEmpty == true
                  ? fields['email'].toString()
                  : 'your.email@example.com',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, accountState) {
        final fields = accountState.fields;
        final busy = accountState.loading || _isLoading;

        return Material(
          color: const Color(0xFFF8F9FB),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppBar(
                title: Text(
                  'My Account',
                  style: TextStyle(
                    color: Color(0xFF1A1D29),
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
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
                          color: Color(0xFF3B82F6),
                          backgroundColor: Colors.white,
                          child: SingleChildScrollView(
                            physics: BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                _buildProfileHeader(fields),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Personal Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1D29),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      _buildEditableField(
                                        'Name',
                                        'name',
                                        Icons.person_outline,
                                        fields,
                                      ),
                                      _buildEditableField(
                                        'Phone Number',
                                        'phoneNumber',
                                        Icons.phone_outlined,
                                        fields,
                                      ),
                                      SizedBox(height: 24),
                                      Text(
                                        'Business Information',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1D29),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      _buildEditableField(
                                        'Business Name',
                                        'businessName',
                                        Icons.business_outlined,
                                        fields,
                                      ),
                                      _buildEditableField(
                                        'Business Address',
                                        'businessAddress',
                                        Icons.location_on_outlined,
                                        fields,
                                      ),
                                      _buildEditableField(
                                        'GST Number',
                                        'gstNumber',
                                        Icons.receipt_long_outlined,
                                        fields,
                                      ),
                                      _buildEditableField(
                                        'Bill Rules',
                                        'billRules',
                                        Icons.rule_outlined,
                                        fields,
                                      ),
                                      SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (busy)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: LoadingAnimationWidget.staggeredDotsWave(
                              color: Color(0xFF3B82F6),
                              size: 40,
                            ),
                          ),
                        ),
                      ),
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
