import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'template_section.dart';

// =============================================================================
// Section catalogue — the universal sections derived from Nigel's master prompt.
// Specialised sections (BANT, yesterday/today/blockers, customer-discovery
// quotes etc.) follow in Session 2.
// =============================================================================

class MeetingOverviewSection extends TemplateSection {
  const MeetingOverviewSection();
  @override
  String get id => 'meeting_overview';
  @override
  String get displayName => 'Meeting Overview';
  @override
  String get description =>
      'Type, purpose, participants, date/time, and context.';
  @override
  String? get icon => 'info';
  @override
  String get promptInstruction => '''
Capture the meta of the meeting. Each field one sentence at most.
- type: e.g. "1:1", "standup", "customer interview", "sales call",
  "all-hands". Infer from content if not stated.
- purpose: why this meeting happened — the trigger.
- participants: comma-separated names or roles. If only roles are
  evident, use roles.
- date_time: as referenced in the transcript (e.g. "Tuesday morning",
  "10:30 BST"). Empty string if not specified.
- context: relevant history / background mentioned (one sentence).
If something is not in the transcript, write "Not specified".''';
  @override
  String get jsonSchemaSnippet => '''
{ "type": "", "purpose": "", "participants": "",
  "date_time": "", "context": "" }''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) =>
      _MeetingOverviewWidget(data: data is Map ? Map<String, dynamic>.from(data) : const {});
}

class _MeetingOverviewWidget extends StatelessWidget {
  const _MeetingOverviewWidget({required this.data});
  final Map<String, dynamic> data;
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _NotDiscussed();
    final rows = <(String, String)>[
      ('Type', (data['type'] ?? '').toString()),
      ('Purpose', (data['purpose'] ?? '').toString()),
      ('Participants', (data['participants'] ?? '').toString()),
      ('Date/time', (data['date_time'] ?? '').toString()),
      ('Context', (data['context'] ?? '').toString()),
    ].where((e) => e.$2.trim().isNotEmpty && e.$2 != 'Not specified').toList();
    if (rows.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: '${r.$1}: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: r.$2),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------

class DiscussionPointsSection extends TemplateSection {
  const DiscussionPointsSection();
  @override
  String get id => 'discussion_points';
  @override
  String get displayName => 'Key Discussion Points';
  @override
  String get description =>
      'Topic-by-topic breakdown with quotes, data, and concerns.';
  @override
  String? get icon => 'forum';
  @override
  String get promptInstruction => '''
List each major topic discussed. Group related dialogue under one topic.
For each topic provide:
- topic: short label.
- summary: 1-3 bullets of what was said. Bullets, not paragraphs.
- quotes: 0-3 short verbatim quotes that capture intent. Empty list ok.
- data_numbers: 0-N numbers, percentages, dates, dollar amounts cited.
  Strings (e.g. "30%", "Q3 2026", "£200k").
- concerns: any risks/objections raised on this topic, or empty string.
Skip the topic entirely if there's nothing meaningful — never invent.''';
  @override
  String get jsonSchemaSnippet => '''
[
  { "topic": "", "summary": [""],
    "quotes": [""], "data_numbers": [""], "concerns": "" }
]''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final topics = data is List ? data : const [];
    if (topics.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final raw in topics)
          if (raw is Map) _DiscussionTopic(topic: Map<String, dynamic>.from(raw)),
      ],
    );
  }
}

class _DiscussionTopic extends StatelessWidget {
  const _DiscussionTopic({required this.topic});
  final Map<String, dynamic> topic;
  @override
  Widget build(BuildContext context) {
    final title = (topic['topic'] ?? '').toString();
    final summary = (topic['summary'] is List ? topic['summary'] : const []) as List;
    final quotes = (topic['quotes'] is List ? topic['quotes'] : const []) as List;
    final data = (topic['data_numbers'] is List ? topic['data_numbers'] : const []) as List;
    final concerns = (topic['concerns'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Text(title,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          for (final s in summary)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6),
              child: Text('• ${s.toString()}',
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
          for (final q in quotes)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12),
              child: Text('"${q.toString()}"',
                  style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF7E8896))),
            ),
          if (data.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final d in data) _Pill(label: d.toString()),
                ],
              ),
            ),
          if (concerns.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 6),
              child: Text('Concerns: $concerns',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFB04040))),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class DecisionsSection extends TemplateSection {
  const DecisionsSection();
  @override
  String get id => 'decisions';
  @override
  String get displayName => 'Decisions Made';
  @override
  String get description =>
      'Each agreed decision with who made it and the rationale.';
  @override
  String? get icon => 'check_circle';
  @override
  String get promptInstruction => '''
List ONLY decisions reached during the meeting (not proposals, not "we
should consider", not open debate).
For each:
- decision: clearly worded outcome.
- made_by: name or role of who made/owned the decision. Empty string if
  collective.
- rationale: 1 sentence on why. Empty string if not stated.''';
  @override
  String get jsonSchemaSnippet => '''
[ { "decision": "", "made_by": "", "rationale": "" } ]''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final items = data is List ? data : const [];
    if (items.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final raw in items)
          if (raw is Map) _DecisionRow(d: Map<String, dynamic>.from(raw)),
      ],
    );
  }
}

class _DecisionRow extends StatelessWidget {
  const _DecisionRow({required this.d});
  final Map<String, dynamic> d;
  @override
  Widget build(BuildContext context) {
    final decision = (d['decision'] ?? '').toString();
    final madeBy = (d['made_by'] ?? '').toString();
    final rationale = (d['rationale'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.check, size: 16, color: Color(0xFF34C759)),
            const SizedBox(width: 6),
            Expanded(child: Text(decision, style: const TextStyle(fontSize: 14, height: 1.4))),
          ]),
          if (madeBy.isNotEmpty || rationale.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 2),
              child: Text(
                [
                  if (madeBy.isNotEmpty) 'By: $madeBy',
                  if (rationale.isNotEmpty) 'Rationale: $rationale',
                ].join('   ·   '),
                style: const TextStyle(fontSize: 12, color: Color(0xFF7E8896)),
              ),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class ActionItemsSection extends TemplateSection {
  const ActionItemsSection();
  @override
  String get id => 'action_items';
  @override
  String get displayName => 'Action Items';
  @override
  String get description =>
      'Tasks owned by someone with deadline + dependencies.';
  @override
  String? get icon => 'task_alt';
  @override
  String get promptInstruction => '''
List ONLY actionable tasks committed to or assigned in the meeting.
Each item must be a standalone task someone can pick up.
For each:
- task: clear single-sentence description.
- owner: name/role if specified, empty string otherwise.
- deadline: ISO-8601 date OR a relative phrase exactly as said
  ("by Friday", "next sprint"). Empty string if not specified.
- dependencies: free-text of what this is blocked on or what blocks
  it. Empty string if standalone.''';
  @override
  String get jsonSchemaSnippet => '''
[ { "task": "", "owner": "", "deadline": "", "dependencies": "" } ]''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final items = data is List ? data : const [];
    if (items.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final raw in items)
          if (raw is Map) _ActionItemRow(a: Map<String, dynamic>.from(raw)),
      ],
    );
  }
}

class _ActionItemRow extends StatelessWidget {
  const _ActionItemRow({required this.a});
  final Map<String, dynamic> a;
  @override
  Widget build(BuildContext context) {
    final task = (a['task'] ?? '').toString();
    final owner = (a['owner'] ?? '').toString();
    final deadline = (a['deadline'] ?? '').toString();
    final deps = (a['dependencies'] ?? '').toString();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.radio_button_unchecked, size: 16, color: Color(0xFFE76F51)),
            const SizedBox(width: 6),
            Expanded(child: Text(task, style: const TextStyle(fontSize: 14, height: 1.4))),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 2),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (owner.isNotEmpty) _Pill(label: '@$owner'),
                if (deadline.isNotEmpty) _Pill(label: deadline, icon: Icons.event),
                if (deps.isNotEmpty) _Pill(label: 'Deps: $deps'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class InsightsSection extends TemplateSection {
  const InsightsSection();
  @override
  String get id => 'insights';
  @override
  String get displayName => 'Insights & Observations';
  @override
  String get description =>
      'Sentiment, pain points, opportunities, surprises, patterns.';
  @override
  String? get icon => 'lightbulb';
  @override
  String get promptInstruction => '''
Higher-level reading of the meeting. ONLY include observations
clearly supported by the transcript. If a sub-field has nothing
worth saying, write "Not specified".
- user_sentiment: overall mood (e.g. "frustrated but engaged").
- pain_points: what's bothering / blocking participants.
- opportunities: openings to pursue.
- surprises_contradictions: anything unexpected or self-contradictory.
- behavioural_patterns: recurring tics / habits worth flagging.
- strategic_implications: what this means for the bigger picture.''';
  @override
  String get jsonSchemaSnippet => '''
{ "user_sentiment": "", "pain_points": "", "opportunities": "",
  "surprises_contradictions": "", "behavioural_patterns": "",
  "strategic_implications": "" }''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final m = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    if (m.isEmpty) return const _NotDiscussed();
    final rows = <(String, String)>[
      ('User sentiment', (m['user_sentiment'] ?? '').toString()),
      ('Pain points', (m['pain_points'] ?? '').toString()),
      ('Opportunities', (m['opportunities'] ?? '').toString()),
      ('Surprises / contradictions', (m['surprises_contradictions'] ?? '').toString()),
      ('Behavioural patterns', (m['behavioural_patterns'] ?? '').toString()),
      ('Strategic implications', (m['strategic_implications'] ?? '').toString()),
    ].where((e) => e.$2.trim().isNotEmpty && e.$2 != 'Not specified').toList();
    if (rows.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.$1,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6E63B6))),
                Text(r.$2,
                    style: const TextStyle(fontSize: 13, height: 1.45)),
              ],
            ),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------

class FollowUpQuestionsSection extends TemplateSection {
  const FollowUpQuestionsSection();
  @override
  String get id => 'follow_up_questions';
  @override
  String get displayName => 'Follow-Up Questions';
  @override
  String get description =>
      'Open questions worth asking after this meeting.';
  @override
  String? get icon => 'help';
  @override
  String get promptInstruction => '''
List 3-7 follow-up questions that would clarify, deepen, or unblock
what was discussed. Phrase them as actual questions someone could ask
next time. No fluff.''';
  @override
  String get jsonSchemaSnippet => '[""]';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final items = data is List ? data : const [];
    if (items.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final q in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('? ${q.toString()}',
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------

class QuickSummarySection extends TemplateSection {
  const QuickSummarySection();
  @override
  String get id => 'quick_summary';
  @override
  String get displayName => 'Quick Summary';
  @override
  String get description => '5-8 short bullets, the executive read.';
  @override
  String? get icon => 'list';
  @override
  String get promptInstruction => '''
Produce 5-8 short bullets capturing the meeting's most important
takeaways. Each bullet stand-alone, no transcript references, no
opening "we ...". A reader who skips everything else should still
understand what happened.''';
  @override
  String get jsonSchemaSnippet => '[""]';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final items = data is List ? data : const [];
    if (items.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final b in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 5, color: Color(0xFF6E63B6)),
              ),
              Expanded(
                child: Text(b.toString(),
                    style: const TextStyle(fontSize: 14, height: 1.45)),
              ),
            ]),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Existing-app-compat sections — kept so old-style templates keep working
// while we migrate the rest in Session 2.

class SimpleSummarySection extends TemplateSection {
  const SimpleSummarySection();
  @override
  String get id => 'summary';
  @override
  String get displayName => 'Summary';
  @override
  String get description => 'One-paragraph summary of the meeting.';
  @override
  String? get icon => 'short_text';
  @override
  String get promptInstruction => '''
Produce one paragraph (3-5 sentences) summarising the meeting. Plain
prose, no bullets, no lists.''';
  @override
  String get jsonSchemaSnippet => '""';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final s = data?.toString() ?? '';
    if (s.trim().isEmpty) return const _NotDiscussed();
    return MarkdownBody(data: s, selectable: true);
  }
}

class RisksSection extends TemplateSection {
  const RisksSection();
  @override
  String get id => 'risks';
  @override
  String get displayName => 'Risks & Objections';
  @override
  String get description =>
      'Concerns, blockers, or open challenges raised.';
  @override
  String? get icon => 'warning';
  @override
  String get promptInstruction => '''
List risks, objections, or open issues raised during the meeting that
weren't resolved. Each as a single bullet, no rationalisation.''';
  @override
  String get jsonSchemaSnippet => '[""]';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final items = data is List ? data : const [];
    if (items.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber, size: 16, color: Color(0xFFB58A00)),
              const SizedBox(width: 6),
              Expanded(child: Text(r.toString(), style: const TextStyle(fontSize: 14, height: 1.4))),
            ]),
          ),
      ],
    );
  }
}

class FollowUpEmailSection extends TemplateSection {
  const FollowUpEmailSection();
  @override
  String get id => 'follow_up_email';
  @override
  String get displayName => 'Follow-up Email';
  @override
  String get description =>
      'Plain-text email body recapping the meeting.';
  @override
  String? get icon => 'mail';
  @override
  String get promptInstruction => '''
Draft a polite, concise plain-text follow-up email body for attendees.
Open with a thanks line (skip if attendees not specified). Then a one-
paragraph summary. Then a list of decisions. Then action items with
owner / deadline. Sign off with "[Your name]". No subject line, no
markdown.''';
  @override
  String get jsonSchemaSnippet => '""';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final s = data?.toString() ?? '';
    if (s.trim().isEmpty) return const _NotDiscussed();
    return SelectableText(s,
        style: const TextStyle(fontSize: 13, height: 1.5));
  }
}

// -----------------------------------------------------------------------------
// Internal small helpers shared across renderers.

class _NotDiscussed extends StatelessWidget {
  const _NotDiscussed();
  @override
  Widget build(BuildContext context) => const Text(
        'Not discussed.',
        style: TextStyle(
            fontSize: 13,
            color: Color(0xFF7E8896),
            fontStyle: FontStyle.italic),
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.icon});
  final String label;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x1A6E63B6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x336E63B6)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: const Color(0xFF6E63B6)),
          const SizedBox(width: 4),
        ],
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6E63B6),
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// =============================================================================
// Section registry — code-defined catalogue of every built-in section.
// User custom templates ship a list of section IDs; we resolve them through
// this registry to get the live TemplateSection instance.
// =============================================================================

class BuiltInSections {
  BuiltInSections._();

  /// All built-in sections. Order doesn't matter — templates pick by id.
  static const List<TemplateSection> all = [
    MeetingOverviewSection(),
    DiscussionPointsSection(),
    DecisionsSection(),
    ActionItemsSection(),
    InsightsSection(),
    FollowUpQuestionsSection(),
    QuickSummarySection(),
    SimpleSummarySection(),
    RisksSection(),
    FollowUpEmailSection(),
  ];

  static final Map<String, TemplateSection> _byId = {
    for (final s in all) s.id: s,
  };

  /// Look up a section by ID. Returns null if no built-in matches.
  static TemplateSection? byId(String id) => _byId[id];
}
