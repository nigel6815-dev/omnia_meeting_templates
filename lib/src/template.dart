import 'sections.dart';
import 'template_section.dart';

/// A named composition of TemplateSections.
///
/// Templates ship as either:
///   1. Built-in system templates (defined in `system_templates.dart`,
///      shipped with the package).
///   2. User custom templates (created in-app, persisted in Firestore
///      with a list of section IDs).
///
/// Templates serialise to JSON for sync — the live `sections` list is
/// rebuilt from the registered IDs at hydrate time, so the package can
/// add new built-in sections without breaking older saved templates.
class Template {
  /// Stable machine-readable identifier. For built-in templates this
  /// is a short slug like `comprehensive`. For user customs it's a UUID.
  final String id;

  /// User-facing name (e.g. "Comprehensive", "Sales call", "Investor pitch").
  final String name;

  /// Optional 1-line description shown in the picker.
  final String description;

  /// Optional Material icon name (e.g. "summarize", "groups").
  final String? icon;

  /// Sections IN DISPLAY ORDER. Stored as ids for serialisation; the
  /// live list is materialised on construction via [BuiltInSections.byId].
  final List<TemplateSection> sections;

  /// True if this template was created by the user (vs ships with the
  /// package). Custom templates can be edited / deleted in the UI.
  final bool isCustom;

  /// Owner uid — only meaningful for custom templates synced via
  /// Firestore. Null for system templates.
  final String? ownerUid;

  /// Wall-clock when the user last edited a custom template. Null for
  /// system templates. Used by the sync layer for conflict resolution.
  final DateTime? updatedAt;

  const Template({
    required this.id,
    required this.name,
    required this.sections,
    this.description = '',
    this.icon,
    this.isCustom = false,
    this.ownerUid,
    this.updatedAt,
  });

  /// Build a template from raw JSON. Ignores any section IDs that don't
  /// match a built-in section in this version of the package — the
  /// caller can detect partial hydration via [hydrationLoss].
  factory Template.fromJson(
    Map<String, dynamic> json, {
    void Function(List<String> droppedIds)? hydrationLoss,
  }) {
    final ids = (json['section_ids'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final dropped = <String>[];
    final live = <TemplateSection>[];
    for (final id in ids) {
      final s = BuiltInSections.byId(id);
      if (s == null) {
        dropped.add(id);
      } else {
        live.add(s);
      }
    }
    if (dropped.isNotEmpty) hydrationLoss?.call(dropped);
    return Template(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      icon: json['icon']?.toString(),
      sections: live,
      isCustom: json['is_custom'] == true,
      ownerUid: json['owner_uid']?.toString(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Serialise for Firestore. Sections collapse to their IDs.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        if (icon != null) 'icon': icon,
        'section_ids': [for (final s in sections) s.id],
        'is_custom': isCustom,
        if (ownerUid != null) 'owner_uid': ownerUid,
        if (updatedAt != null) 'updated_at': updatedAt!.toUtc().toIso8601String(),
      };

  /// Build a copy with one or more fields replaced.
  Template copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    List<TemplateSection>? sections,
    bool? isCustom,
    String? ownerUid,
    DateTime? updatedAt,
  }) =>
      Template(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        icon: icon ?? this.icon,
        sections: sections ?? this.sections,
        isCustom: isCustom ?? this.isCustom,
        ownerUid: ownerUid ?? this.ownerUid,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
