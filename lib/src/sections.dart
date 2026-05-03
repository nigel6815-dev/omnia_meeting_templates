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
// Specialised sections — each tied to a specific template's needs.
// Session 2 of the templating overhaul. These are the "moat" vs Granola:
// templates aren't just framing strings, they're compositions of sections,
// and specialised sections render their data with their own visual style.
// =============================================================================

class BantSection extends TemplateSection {
  const BantSection();
  @override
  String get id => 'bant';
  @override
  String get displayName => 'BANT qualification';
  @override
  String get description =>
      'Sales: Budget, Authority, Need, Timeline.';
  @override
  String? get icon => 'attach_money';
  @override
  String get promptInstruction => '''
Extract sales-call qualification signals using BANT. Each field one
sentence at most. If something wasn't discussed, write
"Not specified".
- budget: stated or implied spend ceiling, or "Not specified".
- authority: who can sign off the deal (name / role).
- need: the actual problem the prospect is trying to solve.
- timeline: when they need a solution by — quote dates if given.''';
  @override
  String get jsonSchemaSnippet => '''
{ "budget": "", "authority": "", "need": "", "timeline": "" }''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final m = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    if (m.isEmpty) return const _NotDiscussed();
    final rows = <(String, IconData, String)>[
      ('Budget', Icons.payments_outlined, (m['budget'] ?? '').toString()),
      ('Authority', Icons.verified_user_outlined, (m['authority'] ?? '').toString()),
      ('Need', Icons.flag_outlined, (m['need'] ?? '').toString()),
      ('Timeline', Icons.event_outlined, (m['timeline'] ?? '').toString()),
    ].where((e) => e.$3.trim().isNotEmpty && e.$3 != 'Not specified').toList();
    if (rows.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(r.$2, size: 16, color: const Color(0xFF6E63B6)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6E63B6))),
                    Text(r.$3,
                        style:
                            const TextStyle(fontSize: 13, height: 1.4)),
                  ],
                ),
              ),
            ]),
          ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------

class YesterdayTodayBlockersSection extends TemplateSection {
  const YesterdayTodayBlockersSection();
  @override
  String get id => 'yesterday_today_blockers';
  @override
  String get displayName => 'Yesterday / Today / Blockers';
  @override
  String get description =>
      'Standup: per-person updates with three columns.';
  @override
  String? get icon => 'schedule';
  @override
  String get promptInstruction => '''
Group the standup into per-person updates. For each speaker:
- person: name (or speaker label like "Speaker 1" if unnamed).
- yesterday: 1-2 short bullets of what they said about
  yesterday's work. Empty list if nothing said.
- today: 1-2 short bullets about today's plan. Empty list if
  nothing said.
- blockers: 0-2 short bullets about anything blocking them.
Skip a person entirely if they didn't speak.''';
  @override
  String get jsonSchemaSnippet => '''
[
  { "person": "", "yesterday": [""], "today": [""], "blockers": [""] }
]''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final items = data is List ? data : const [];
    if (items.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final raw in items)
          if (raw is Map) _StandupPerson(p: Map<String, dynamic>.from(raw)),
      ],
    );
  }
}

class _StandupPerson extends StatelessWidget {
  const _StandupPerson({required this.p});
  final Map<String, dynamic> p;
  @override
  Widget build(BuildContext context) {
    final name = (p['person'] ?? '').toString();
    final yesterday = (p['yesterday'] is List ? p['yesterday'] : const []) as List;
    final today = (p['today'] is List ? p['today'] : const []) as List;
    final blockers = (p['blockers'] is List ? p['blockers'] : const []) as List;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (name.isNotEmpty)
            Text(name,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          _StandupGroup(label: 'Yesterday', icon: Icons.history, items: yesterday, color: const Color(0xFF7E8896)),
          _StandupGroup(label: 'Today', icon: Icons.today, items: today, color: const Color(0xFF34C759)),
          _StandupGroup(label: 'Blockers', icon: Icons.block, items: blockers, color: const Color(0xFFB58A00)),
        ],
      ),
    );
  }
}

class _StandupGroup extends StatelessWidget {
  const _StandupGroup(
      {required this.label, required this.icon, required this.items, required this.color});
  final String label;
  final IconData icon;
  final List items;
  final Color color;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w700)),
          ]),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 16),
              child: Text('• ${item.toString()}',
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class PullQuotesSection extends TemplateSection {
  const PullQuotesSection();
  @override
  String get id => 'pull_quotes';
  @override
  String get displayName => 'Pull quotes';
  @override
  String get description =>
      'Standout verbatim quotes with attribution.';
  @override
  String? get icon => 'format_quote';
  @override
  String get promptInstruction => '''
Pick 3-7 standout quotes from the transcript that capture
particularly clear, surprising, vivid, or representative moments.
Verbatim — do not paraphrase.
- quote: the words, in quotes.
- speaker: who said it (name or speaker label).
- context: 1 short phrase on why this quote matters. Empty
  string ok.''';
  @override
  String get jsonSchemaSnippet => '''
[ { "quote": "", "speaker": "", "context": "" } ]''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final items = data is List ? data : const [];
    if (items.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final raw in items)
          if (raw is Map) _PullQuote(q: Map<String, dynamic>.from(raw)),
      ],
    );
  }
}

class _PullQuote extends StatelessWidget {
  const _PullQuote({required this.q});
  final Map<String, dynamic> q;
  @override
  Widget build(BuildContext context) {
    final quote = (q['quote'] ?? '').toString();
    final speaker = (q['speaker'] ?? '').toString();
    final context_ = (q['context'] ?? '').toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(width: 3, color: Color(0xFF6E63B6))),
        color: Color(0x086E63B6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"$quote"',
              style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontStyle: FontStyle.italic)),
          if (speaker.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('— $speaker',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7E8896),
                      fontWeight: FontWeight.w600)),
            ),
          if (context_.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(context_,
                  style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7E8896))),
            ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------

class PainPointsAndGoalsSection extends TemplateSection {
  const PainPointsAndGoalsSection();
  @override
  String get id => 'pain_points_and_goals';
  @override
  String get displayName => 'Pain points & goals';
  @override
  String get description =>
      'What hurts + what they want — for discovery and 1:1s.';
  @override
  String? get icon => 'flag';
  @override
  String get promptInstruction => '''
Two parallel lists:
- pain_points: explicit problems / frustrations / unmet needs
  the participant raised. Each a single sentence. Empty list if
  none surfaced.
- goals: what they're trying to achieve / wishing for / planning.
  Each a single sentence. Empty list if not stated.
Be specific — "wants to be more productive" is too vague unless
that's literally what they said.''';
  @override
  String get jsonSchemaSnippet => '''
{ "pain_points": [""], "goals": [""] }''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final m = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    final pains = (m['pain_points'] is List ? m['pain_points'] : const []) as List;
    final goals = (m['goals'] is List ? m['goals'] : const []) as List;
    if (pains.isEmpty && goals.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pains.isNotEmpty) ...[
          const Text('Pain points',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB04040))),
          const SizedBox(height: 4),
          for (final p in pains)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 5, color: Color(0xFFB04040)),
                ),
                Expanded(child: Text(p.toString(), style: const TextStyle(fontSize: 13, height: 1.4))),
              ]),
            ),
          const SizedBox(height: 8),
        ],
        if (goals.isNotEmpty) ...[
          const Text('Goals',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF34C759))),
          const SizedBox(height: 4),
          for (final g in goals)
            Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.only(top: 6, right: 8),
                  child: Icon(Icons.circle, size: 5, color: Color(0xFF34C759)),
                ),
                Expanded(child: Text(g.toString(), style: const TextStyle(fontSize: 13, height: 1.4))),
              ]),
            ),
        ],
      ],
    );
  }
}

// -----------------------------------------------------------------------------

class NextStepsSection extends TemplateSection {
  const NextStepsSection();
  @override
  String get id => 'next_steps';
  @override
  String get displayName => 'Next steps';
  @override
  String get description =>
      'Forward-looking commitments — distinct from action items.';
  @override
  String? get icon => 'forward';
  @override
  String get promptInstruction => '''
List the next-step commitments agreed by the end of the
conversation. Distinct from action items: next steps describe
what happens BETWEEN this meeting and the next interaction —
e.g. "send pricing", "follow up next Tuesday", "book a demo".
Each step:
- step: clear single-sentence description.
- owner: name/role of who's doing it. Empty string if it's
  the prospect's side or unspecified.
- when: stated timing ("next Tuesday", "by Friday", or empty
  if not specified).''';
  @override
  String get jsonSchemaSnippet => '''
[ { "step": "", "owner": "", "when": "" } ]''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final items = data is List ? data : const [];
    if (items.isEmpty) return const _NotDiscussed();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final raw in items)
          if (raw is Map)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.arrow_forward, size: 16, color: Color(0xFF6E63B6)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text((raw['step'] ?? '').toString(),
                          style: const TextStyle(fontSize: 14, height: 1.4)),
                      if ((raw['owner'] ?? '').toString().isNotEmpty ||
                          (raw['when'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Wrap(
                            spacing: 6,
                            children: [
                              if ((raw['owner'] ?? '').toString().isNotEmpty)
                                _Pill(label: '@${raw['owner']}'),
                              if ((raw['when'] ?? '').toString().isNotEmpty)
                                _Pill(label: raw['when'].toString(), icon: Icons.event),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ]),
            ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------

class RetroReflectionSection extends TemplateSection {
  const RetroReflectionSection();
  @override
  String get id => 'retro_reflection';
  @override
  String get displayName => 'Retro reflection';
  @override
  String get description =>
      'What went well, what didn\'t, what to improve.';
  @override
  String? get icon => 'history';
  @override
  String get promptInstruction => '''
Standard sprint-retro three-part reflection. Each list 1-5 bullets,
single sentences:
- went_well: what worked, what to keep doing.
- didnt_work: what slowed the team down, what frustrated people.
- improvements: concrete experiments / changes proposed for next
  sprint.
If the conversation didn't address one of these explicitly, leave
that list empty rather than inventing entries.''';
  @override
  String get jsonSchemaSnippet => '''
{ "went_well": [""], "didnt_work": [""], "improvements": [""] }''';
  @override
  Widget buildRenderer(BuildContext context, dynamic data) {
    final m = data is Map ? Map<String, dynamic>.from(data) : const <String, dynamic>{};
    final wentWell = (m['went_well'] is List ? m['went_well'] : const []) as List;
    final didnt = (m['didnt_work'] is List ? m['didnt_work'] : const []) as List;
    final improvements = (m['improvements'] is List ? m['improvements'] : const []) as List;
    if (wentWell.isEmpty && didnt.isEmpty && improvements.isEmpty) {
      return const _NotDiscussed();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RetroBlock(
            label: 'Went well',
            color: const Color(0xFF34C759),
            icon: Icons.thumb_up_alt_outlined,
            items: wentWell),
        _RetroBlock(
            label: 'Didn\'t work',
            color: const Color(0xFFB04040),
            icon: Icons.thumb_down_alt_outlined,
            items: didnt),
        _RetroBlock(
            label: 'Improvements',
            color: const Color(0xFF6E63B6),
            icon: Icons.trending_up,
            items: improvements),
      ],
    );
  }
}

class _RetroBlock extends StatelessWidget {
  const _RetroBlock(
      {required this.label, required this.color, required this.icon, required this.items});
  final String label;
  final Color color;
  final IconData icon;
  final List items;
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ]),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(top: 2, left: 20),
              child: Text('• ${item.toString()}',
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            ),
        ],
      ),
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
    // Universal sections (used by Comprehensive + most other templates).
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
    // Specialised sections (Session 2).
    BantSection(),
    YesterdayTodayBlockersSection(),
    PullQuotesSection(),
    PainPointsAndGoalsSection(),
    NextStepsSection(),
    RetroReflectionSection(),
  ];

  static final Map<String, TemplateSection> _byId = {
    for (final s in all) s.id: s,
  };

  /// Look up a section by ID. Returns null if no built-in matches.
  static TemplateSection? byId(String id) => _byId[id];
}
