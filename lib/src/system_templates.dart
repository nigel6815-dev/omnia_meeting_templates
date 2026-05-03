import 'sections.dart';
import 'template.dart';

/// Templates that ship with the package as defaults. User custom
/// templates are stored separately (Firestore via TemplateSyncService)
/// and resolved by section id at hydrate time.
class SystemTemplates {
  SystemTemplates._();

  // ── Flagship ─────────────────────────────────────────────────────

  /// Comprehensive — Nigel's master prompt as a 7-section composition.
  /// The investor-demo flagship: every section the master prompt
  /// defines.
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

  // ── General-purpose ──────────────────────────────────────────────

  /// Default — sensible balanced output for any meeting type.
  static const Template general = Template(
    id: 'general',
    name: 'General meeting',
    description: 'Balanced notes for any meeting that doesn\'t fit a '
        'more specific template.',
    icon: 'meeting_room',
    sections: [
      MeetingOverviewSection(),
      SimpleSummarySection(),
      ActionItemsSection(),
      DecisionsSection(),
      RisksSection(),
      FollowUpEmailSection(),
    ],
  );

  // ── Conversational / 1-to-1 ──────────────────────────────────────

  /// 1:1 — manager / report sync.
  static const Template oneOnOne = Template(
    id: 'one_on_one',
    name: '1:1',
    description:
        'Manager / report sync — pain points, goals, next steps, '
        'follow-up questions.',
    icon: 'group',
    sections: [
      MeetingOverviewSection(),
      SimpleSummarySection(),
      PainPointsAndGoalsSection(),
      NextStepsSection(),
      ActionItemsSection(),
      FollowUpQuestionsSection(),
    ],
  );

  // ── Engineering ──────────────────────────────────────────────────

  /// Standup — daily team sync, Yesterday/Today/Blockers per person.
  static const Template standup = Template(
    id: 'standup',
    name: 'Standup',
    description:
        'Yesterday / Today / Blockers per person, plus shared action '
        'items.',
    icon: 'schedule',
    sections: [
      MeetingOverviewSection(),
      YesterdayTodayBlockersSection(),
      ActionItemsSection(),
    ],
  );

  /// Retro — sprint retrospective.
  static const Template retro = Template(
    id: 'retro',
    name: 'Retro',
    description:
        'What went well / didn\'t / improvements + decisions and '
        'action items.',
    icon: 'history',
    sections: [
      MeetingOverviewSection(),
      RetroReflectionSection(),
      DecisionsSection(),
      ActionItemsSection(),
    ],
  );

  // ── Research ─────────────────────────────────────────────────────

  /// Customer Discovery — pain hunting, goal mapping, buying signals.
  static const Template customerDiscovery = Template(
    id: 'customer_discovery',
    name: 'Customer discovery',
    description:
        'Pain points, goals, pull quotes, insights — find what to '
        'build next.',
    icon: 'search',
    sections: [
      MeetingOverviewSection(),
      PainPointsAndGoalsSection(),
      PullQuotesSection(),
      InsightsSection(),
      FollowUpQuestionsSection(),
      ActionItemsSection(),
    ],
  );

  /// User Interview — research call, themes + quotes.
  static const Template userInterview = Template(
    id: 'user_interview',
    name: 'User interview',
    description:
        'Pain points, goals, pull quotes, insights, quick summary — '
        'lighter than discovery.',
    icon: 'record_voice_over',
    sections: [
      MeetingOverviewSection(),
      PainPointsAndGoalsSection(),
      PullQuotesSection(),
      InsightsSection(),
      QuickSummarySection(),
    ],
  );

  // ── Sales ────────────────────────────────────────────────────────

  /// Sales call — BANT, objections, next steps, follow-up email.
  static const Template salesCall = Template(
    id: 'sales_call',
    name: 'Sales call',
    description:
        'BANT qualification, objections / risks, next steps, plus a '
        'follow-up email draft.',
    icon: 'attach_money',
    sections: [
      MeetingOverviewSection(),
      BantSection(),
      RisksSection(),
      NextStepsSection(),
      ActionItemsSection(),
      FollowUpEmailSection(),
    ],
  );

  // ── Creative ─────────────────────────────────────────────────────

  /// Brainstorm — generative session, capture ideas + decisions.
  static const Template brainstorm = Template(
    id: 'brainstorm',
    name: 'Brainstorm',
    description:
        'Topic-by-topic discussion, decisions, action items, open '
        'questions.',
    icon: 'lightbulb',
    sections: [
      MeetingOverviewSection(),
      DiscussionPointsSection(),
      DecisionsSection(),
      ActionItemsSection(),
      FollowUpQuestionsSection(),
    ],
  );

  // ── Educational ──────────────────────────────────────────────────

  /// Lecture — knowledge transfer, key points + standout quotes.
  static const Template lecture = Template(
    id: 'lecture',
    name: 'Lecture',
    description:
        'Quick summary, topic-by-topic notes, pull quotes, follow-up '
        'questions.',
    icon: 'school',
    sections: [
      MeetingOverviewSection(),
      QuickSummarySection(),
      DiscussionPointsSection(),
      PullQuotesSection(),
      FollowUpQuestionsSection(),
    ],
  );

  // ── Compatibility ────────────────────────────────────────────────

  /// legacyDefault — pre-refactor 5-section shape so existing
  /// meetings still render without surprise.
  static const Template legacyDefault = Template(
    id: 'legacy_default',
    name: 'Default (legacy)',
    description: 'The pre-refactor analysis shape — used for older '
        'meetings recorded before the section system landed.',
    icon: 'history_toggle_off',
    sections: [
      SimpleSummarySection(),
      ActionItemsSection(),
      DecisionsSection(),
      RisksSection(),
      FollowUpEmailSection(),
    ],
  );

  // ── Catalogue ────────────────────────────────────────────────────

  /// Every system template, in display order for a picker. The
  /// flagship Comprehensive comes first (default for new meetings),
  /// then general-purpose, then specialised by domain.
  static const List<Template> all = [
    comprehensive,
    general,
    oneOnOne,
    standup,
    retro,
    customerDiscovery,
    userInterview,
    salesCall,
    brainstorm,
    lecture,
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
