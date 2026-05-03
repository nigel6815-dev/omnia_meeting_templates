import 'package:flutter/material.dart';

import 'sections.dart';
import 'template.dart';
import 'template_section.dart';
import 'template_sync_service.dart';

/// Shared editor for creating + editing user custom templates.
/// Same widget runs in both consumer apps — what gets created on
/// web instantly appears on mobile via the TemplateSyncService
/// stream, and vice versa.
///
/// On save: writes to /users/{uid}/templates/{templateId} via the
/// supplied [sync] service. Picks a UUID-ish id from the timestamp
/// + name for new templates; reuses [existing.id] when editing.
Future<Template?> showCustomTemplateEditorSheet({
  required BuildContext context,
  required TemplateSyncService sync,
  Template? existing,
}) {
  return showModalBottomSheet<Template>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CustomTemplateEditorSheet(
      sync: sync,
      existing: existing,
    ),
  );
}

class _CustomTemplateEditorSheet extends StatefulWidget {
  const _CustomTemplateEditorSheet({
    required this.sync,
    required this.existing,
  });
  final TemplateSyncService sync;
  final Template? existing;

  @override
  State<_CustomTemplateEditorSheet> createState() =>
      _CustomTemplateEditorSheetState();
}

class _CustomTemplateEditorSheetState
    extends State<_CustomTemplateEditorSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  String _icon = 'note_alt';
  late final Set<String> _selectedSectionIds;
  bool _saving = false;

  static const List<({String id, IconData iconData})> _iconChoices = [
    (id: 'note_alt', iconData: Icons.note_alt_outlined),
    (id: 'auto_awesome', iconData: Icons.auto_awesome),
    (id: 'meeting_room', iconData: Icons.meeting_room_outlined),
    (id: 'group', iconData: Icons.group_outlined),
    (id: 'schedule', iconData: Icons.schedule),
    (id: 'history', iconData: Icons.history),
    (id: 'search', iconData: Icons.search),
    (id: 'record_voice_over', iconData: Icons.record_voice_over_outlined),
    (id: 'attach_money', iconData: Icons.attach_money),
    (id: 'lightbulb', iconData: Icons.lightbulb_outline),
    (id: 'school', iconData: Icons.school_outlined),
    (id: 'rocket_launch', iconData: Icons.rocket_launch_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final ex = widget.existing;
    _nameCtrl = TextEditingController(text: ex?.name ?? '');
    _descCtrl = TextEditingController(text: ex?.description ?? '');
    _icon = ex?.icon ?? 'note_alt';
    _selectedSectionIds = ex == null
        ? <String>{
            // Sensible defaults — covers most meetings.
            'meeting_overview',
            'action_items',
            'decisions',
            'quick_summary',
          }
        : <String>{for (final s in ex.sections) s.id};
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _selectedSectionIds.isNotEmpty &&
      !_saving;

  Future<void> _save() async {
    setState(() => _saving = true);

    final id = widget.existing?.id ??
        'custom_${DateTime.now().millisecondsSinceEpoch}';

    // Resolve sections in registry order so output ordering is
    // predictable rather than dependent on user's tick order.
    final sections = <TemplateSection>[
      for (final s in BuiltInSections.all)
        if (_selectedSectionIds.contains(s.id)) s,
    ];

    final template = Template(
      id: id,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      icon: _icon,
      sections: sections,
      isCustom: true,
      ownerUid: widget.sync.uid,
      updatedAt: DateTime.now().toUtc(),
    );

    try {
      await widget.sync.saveCustom(template);
      if (!mounted) return;
      Navigator.of(context).pop(template);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _delete() async {
    final ex = widget.existing;
    if (ex == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this template?'),
        content: Text(
          'Removes "${ex.name}" from every device signed in to '
          'your account. Cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton.tonal(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _saving = true);
    try {
      await widget.sync.deleteCustom(ex.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollCtrl) => Column(
        children: [
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
                Icon(Icons.edit_note, color: scheme.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.existing == null
                        ? 'New custom template'
                        : 'Edit "${widget.existing!.name}"',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.existing != null)
                  IconButton(
                    tooltip: 'Delete',
                    icon: Icon(Icons.delete_outline, color: scheme.error),
                    onPressed: _saving ? null : _delete,
                  ),
                IconButton(
                  tooltip: 'Cancel',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Investor pitch / Founder 1:1 / etc',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    hintText:
                        'When to use this template — shown in the picker.',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Text('Icon',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in _iconChoices)
                      _IconPick(
                        icon: c.iconData,
                        selected: _icon == c.id,
                        onTap: () => setState(() => _icon = c.id),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(children: [
                  Text('Sections',
                      style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  Text(
                    '${_selectedSectionIds.length} selected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  'Pick which sections this template will produce. '
                  'Order in the picker matches the registry order.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 8),
                for (final s in BuiltInSections.all)
                  _SectionPick(
                    section: s,
                    selected: _selectedSectionIds.contains(s.id),
                    onChanged: (v) {
                      setState(() {
                        if (v) {
                          _selectedSectionIds.add(s.id);
                        } else {
                          _selectedSectionIds.remove(s.id);
                        }
                      });
                    },
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canSave ? _save : null,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2))
                          : Text(widget.existing == null
                              ? 'Create'
                              : 'Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconPick extends StatelessWidget {
  const _IconPick({
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          border: Border.all(
            color: selected ? scheme.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20,
            color: selected ? scheme.primary : scheme.onSurfaceVariant),
      ),
    );
  }
}

class _SectionPick extends StatelessWidget {
  const _SectionPick({
    required this.section,
    required this.selected,
    required this.onChanged,
  });
  final TemplateSection section;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!selected),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: selected,
              onChanged: (v) => onChanged(v ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(section.displayName,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                    if (section.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          section.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
