import 'package:flutter/material.dart';

import 'meeting_analysis.dart';
import 'template.dart';
import 'template_section.dart';

/// Renders a [MeetingAnalysis] using its [Template]'s section list,
/// each section getting its own card with the section's title + its
/// rendered widget.
///
/// Both Omnia Voice mobile and Omnia Voice Companion drop this widget
/// into their meeting-detail / summary screens. Layout is intentionally
/// neutral so each app's surrounding theme dominates.
class TemplateRenderer extends StatelessWidget {
  const TemplateRenderer({
    super.key,
    required this.template,
    required this.analysis,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.cardBackgroundColor,
    this.cardBorderColor,
    this.headingColor,
  });

  final Template template;
  final MeetingAnalysis analysis;
  final EdgeInsetsGeometry padding;
  final Color? cardBackgroundColor;
  final Color? cardBorderColor;
  final Color? headingColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBg = theme.colorScheme.surface;
    final defaultBorder = theme.colorScheme.outlineVariant;
    final defaultHeading = theme.colorScheme.primary;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final section in template.sections)
            _SectionCard(
              section: section,
              data: analysis.sectionData[section.id],
              backgroundColor: cardBackgroundColor ?? defaultBg,
              borderColor: cardBorderColor ?? defaultBorder,
              headingColor: headingColor ?? defaultHeading,
            ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.section,
    required this.data,
    required this.backgroundColor,
    required this.borderColor,
    required this.headingColor,
  });

  final TemplateSection section;
  final dynamic data;
  final Color backgroundColor;
  final Color borderColor;
  final Color headingColor;

  IconData? _iconFor(String? name) {
    switch (name) {
      case 'info':
        return Icons.info_outline;
      case 'forum':
        return Icons.forum_outlined;
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'task_alt':
        return Icons.task_alt;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'help':
        return Icons.help_outline;
      case 'list':
        return Icons.list_alt;
      case 'short_text':
        return Icons.short_text;
      case 'warning':
        return Icons.warning_amber_outlined;
      case 'mail':
        return Icons.mail_outline;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'history':
        return Icons.history;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _iconFor(section.icon);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: headingColor),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                section.displayName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: headingColor,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 10),
          section.buildRenderer(context, data),
        ],
      ),
    );
  }
}
