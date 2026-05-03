import 'sections.dart';
import 'template.dart';

/// Templates that ship with the package as defaults. Custom user
/// templates are stored separately (Firestore from Session 3).
///
/// Session 1: only `comprehensive` is fully migrated to the section
/// architecture. Other system templates (1:1, Standup, Sales, etc.)
/// arrive in Session 2 alongside their specialised sections (BANT,
/// yesterday/today/blockers, customer-discovery quotes etc.).
class SystemTemplates {
  SystemTemplates._();

  /// The "Comprehensive" template — Nigel's master prompt as a
  /// composition of seven sections. The investor-demo flagship.
  static const Template comprehensive = Template(
    id: 'comprehensive',
    name: 'Comprehensive',
    description:
        'Full structured notes — overview, discussion, decisions, '
        'actions, insights, follow-ups, and a quick summary.',
    icon: 'auto_awesome',
    sections: [
      MeetingOverviewSection(),
      DiscussionPointsSection(),
      DecisionsSection(),
      ActionItemsSection(),
      InsightsSection(),
      FollowUpQuestionsSection(),
      QuickSummarySection(),
    ],
  );

  /// Compatibility template that mirrors the OLD shape both apps used
  /// before the section refactor. Lets the consuming apps continue
  /// rendering legacy meetings without surprise. Migrated away from in
  /// Session 2.
  static const Template legacyDefault = Template(
    id: 'legacy_default',
    name: 'Default (legacy)',
    description: 'The pre-refactor analysis shape.',
    icon: 'history',
    sections: [
      SimpleSummarySection(),
      ActionItemsSection(),
      DecisionsSection(),
      RisksSection(),
      FollowUpEmailSection(),
    ],
  );

  /// Every system template, in display order for a picker.
  static const List<Template> all = [
    comprehensive,
    legacyDefault,
  ];

  /// Look up a system template by id. Returns null if not found —
  /// the caller may then check user-custom templates from Firestore.
  static Template? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
