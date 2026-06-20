import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_radii.dart';
import 'package:inventopos/core/design/app_spacing.dart';
import 'package:inventopos/core/widgets/m3/app_section_card.dart';
import 'package:shimmer/shimmer.dart';

class AccountProfileHeaderSection extends StatelessWidget {
  const AccountProfileHeaderSection({
    super.key,
    required this.fields,
    required this.onChangeSignature,
  });

  final Map<String, dynamic> fields;
  final VoidCallback onChangeSignature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final signatureUrl = fields['signatureUrl'] as String?;
    final name = fields['name']?.toString().trim() ?? '';
    final email = fields['email']?.toString().trim() ?? '';

    return AppSectionCard(
      title: 'Your profile',
      child: Column(
        children: [
          Center(
            child: _Avatar(
              signatureUrl: signatureUrl,
              onEdit: onChangeSignature,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            name.isNotEmpty ? name : 'Your name',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadii.xl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.email_outlined,
                  size: 16,
                  color: scheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    email.isNotEmpty ? email : 'your.email@example.com',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'Tap the camera to update your bill signature image',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.signatureUrl, required this.onEdit});

  final String? signatureUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.35),
                width: 3,
              ),
            ),
            child: ClipOval(
              child: signatureUrl != null && signatureUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: signatureUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: scheme.surfaceContainerHighest,
                        highlightColor: scheme.surfaceContainerLow,
                        child:
                            ColoredBox(color: scheme.surfaceContainerHighest),
                      ),
                      errorWidget: (context, url, error) =>
                          _placeholder(scheme),
                    )
                  : _placeholder(scheme),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: scheme.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: onEdit,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    size: 18,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Icon(
        Icons.person_outline,
        size: 48,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
