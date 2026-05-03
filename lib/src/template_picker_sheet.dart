import 'package:flutter/material.dart';

import 'system_templates.dart';
import 'template.dart';
import 'template_sync_service.dart';

/// Shared template picker — drop into either consumer app via
/// `showTemplatePickerSheet(context, ...)`. Lists system templates
/// first then this user's custom templates streamed from Firestore
/// via [TemplateSyncService.watchUserCustom]. Tapping a template
/// invokes [onSelected] and closes the sheet.
///
/// A "Create new template" tile at the bottom invokes [onCreateNew]
/// so the caller can show the editor sheet.
///
/// Both apps share this widget — what investors see on the phone
/// and in the browser is pixel-identical.
Future<void> showTemplatePickerSheet({
  required BuildContext context,
  required TemplateSyncService sync,
  required Template? selected,
  required ValueChanged<Template> onSelected,
  required VoidCallback onCreateNew,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TemplatePickerSheet(
      sync: sync,
      selected: selected,
      onSelected: onSelected,
      onCreateNew: onCreateNew,
    ),
  );
}

class _TemplatePickerSheet extends StatelessWidget {
  const _TemplatePickerSheet({
    required this.sync,
    required this.selected,
    required this.onSelected,
    required this.onCreateNew,
  });

  final TemplateSyncService sync;
  final Template? selected;
  final ValueChanged<Template> onSelected;
  final VoidCallback onCreateNew;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 4),
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Choose a template',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Template>>(
              stream: sync.watchUserCustom(),
              builder: (context, snap) {
                final customs = snap.data ?? const <Template>[];
                return ListView(
                  controller: scrollCtrl,
                  padding: EdgeInsets.zero,
                  children: [
                    const _SectionHeading(text: 'System templates'),
                    for (final t in SystemTemplates.all)
                      if (t.id != 'legacy_default')
                        _TemplateTile(
                          template: t,
                          selected: selected?.id == t.id,
                          onTap: () {
                            // Pop FIRST so the picker is off the
                            // navigator stack before onSelected
                            // pushes the analysis sheet — otherwise
                            // pop() removes the just-pushed analysis
                            // sheet and nothing visible happens.
                            Navigator.of(context).pop();
                            onSelected(t);
                          },
                        ),
                    const SizedBox(height: 8),
                    const _SectionHeading(text: 'Your templates'),
                    if (customs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 6, 20, 14),
                        child: Text(
                          'No custom templates yet. '
                          'Create one to make it appear on every '
                          'device signed in to your account.',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF7E8896)),
                        ),
                      ),
                    for (final t in customs)
                      _TemplateTile(
                        template: t,
                        selected: selected?.id == t.id,
                        onTap: () {
                          onSelected(t);
                          Navigator.of(context).pop();
                        },
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onCreateNew();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create new template'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    required this.template,
    required this.selected,
    required this.onTap,
  });
  final Template template;
  final bool selected;
  final VoidCallback onTap;

  IconData _iconFor(String? name) {
    switch (name) {
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'meeting_room':
        return Icons.meeting_room_outlined;
      case 'group':
        return Icons.group_outlined;
      case 'schedule':
        return Icons.schedule;
      case 'history':
        return Icons.history;
      case 'history_toggle_off':
        return Icons.history_toggle_off;
      case 'search':
        return Icons.search;
      case 'record_voice_over':
        return Icons.record_voice_over_outlined;
      case 'attach_money':
        return Icons.attach_money;
      case 'lightbulb':
        return Icons.lightbulb_outline;
      case 'school':
        return Icons.school_outlined;
      default:
        return Icons.note_alt_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Material wrapper is REQUIRED for InkWell to receive taps reliably
    // when nested inside a DraggableScrollableSheet — otherwise the
    // tap target falls back to the GestureDetector that lives on the
    // sheet's drag handle and the on-tile tap gets eaten silently.
    return Material(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                width: 3,
                color: selected ? scheme.primary : Colors.transparent,
              ),
            ),
          ),
          child: Row(
          children: [
            Icon(_iconFor(template.icon),
                size: 20,
                color: selected ? scheme.primary : scheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(
                        template.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: selected ? scheme.primary : null,
                        ),
                      ),
                    ),
                    if (template.isCustom)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: scheme.tertiaryContainer.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'CUSTOM',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w800,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                  ]),
                  if (template.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        template.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${template.sections.length} section${template.sections.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle,
                  size: 20, color: scheme.primary),
          ],
        ),
        ),
      ),
    );
  }
}
