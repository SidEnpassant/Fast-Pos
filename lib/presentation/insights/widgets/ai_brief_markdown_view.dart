import 'package:flutter/material.dart';
import 'package:inventopos/core/design/app_spacing.dart';

/// Renders Groq brief text (light markdown) as readable M3 UI — no extra package.
class AiBriefMarkdownView extends StatelessWidget {
  const AiBriefMarkdownView({
    super.key,
    required this.markdown,
    this.maxBullets = 6,
  });

  final String markdown;
  final int maxBullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = _parseBlocks(markdown);
    if (blocks.isEmpty) {
      return Text(
        markdown,
        style: theme.textTheme.bodyMedium,
      );
    }

    var bulletCount = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks)
          if (block.isBullet) ...[
            if (bulletCount++ < maxBullets)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, right: 10),
                      child: Icon(
                        Icons.circle,
                        size: 6,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: _richText(context, block.text, body: true),
                    ),
                  ],
                ),
              ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _richText(
                context,
                block.text,
                body: false,
              ),
            ),
          ],
      ],
    );
  }

  Widget _richText(
    BuildContext context,
    String text, {
    required bool body,
  }) {
    final theme = Theme.of(context);
    final style = body
        ? theme.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: theme.colorScheme.onSurface,
          )
        : theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          );

    final spans = <TextSpan>[];
    final parts = text.split(RegExp(r'\*\*'));
    for (var i = 0; i < parts.length; i++) {
      final chunk = parts[i].replaceAll('*', '').trim();
      if (chunk.isEmpty) continue;
      spans.add(
        TextSpan(
          text: chunk,
          style: i.isOdd
              ? style?.copyWith(fontWeight: FontWeight.w700)
              : style,
        ),
      );
    }

    if (spans.isEmpty) {
      return Text(text.replaceAll('*', ''), style: style);
    }
    return Text.rich(TextSpan(children: spans));
  }

  static List<_BriefBlock> _parseBlocks(String md) {
    final out = <_BriefBlock>[];
    for (final raw in md.split('\n')) {
      var line = raw.trim();
      if (line.isEmpty) continue;
      line = line.replaceFirst(RegExp(r'^#+\s*'), '');
      final isBullet = RegExp(r'^[\*\-]\s+').hasMatch(line);
      if (isBullet) {
        line = line.replaceFirst(RegExp(r'^[\*\-]\s+'), '');
      }
      out.add(_BriefBlock(text: line, isBullet: isBullet));
    }
    return out;
  }
}

class _BriefBlock {
  const _BriefBlock({required this.text, required this.isBullet});
  final String text;
  final bool isBullet;
}
