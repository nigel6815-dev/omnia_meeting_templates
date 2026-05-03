# omnia_meeting_templates

Composable meeting-note templates and section renderers shared between the
Omnia Voice mobile app (`omnia_voice`) and the Omnia Voice Companion web
app (`omnia_voice_companion`).

## Concepts

- **TemplateSection** — atomic unit. Has an `id`, a Gemini prompt
  instruction, a JSON schema for the section's data, and a Flutter widget
  that renders the data. Examples: `meeting_overview`, `action_items`,
  `decisions`, `bant`, `yesterday_today_blockers`.
- **Template** — a named composition of sections, optionally with an
  icon. Examples: `Comprehensive` (all the master-prompt sections), `1:1`,
  `Standup`, `Sales call`. Templates are user-creatable too.
- **MeetingAnalysis** — what Gemini returns. Stored as
  `Map<sectionId, sectionData>` so any template can inspect any section's
  output.
- **GeminiPromptBuilder** — turns a `Template` + a transcript into a
  single Gemini call. Combines all the section instructions and schemas
  into one well-formed prompt and parses the JSON response back into a
  `MeetingAnalysis`.
- **TemplateRenderer** — Flutter widget that renders a complete
  `MeetingAnalysis` against its `Template`, iterating through sections.

## Import

```dart
import 'package:omnia_meeting_templates/omnia_meeting_templates.dart';
```

## Status

v0.1.0 — Session 1 scaffolding. Currently ships the **Comprehensive**
system template (master prompt covering Meeting Overview, Discussion
Points, Decisions, Action Items, Insights, Follow-Up Questions, Quick
Summary). Other system templates (1:1, Standup, Sales, etc.) and
specialized sections (BANT, Yesterday/Today/Blockers) follow in Session 2.
Firestore sync of user-created custom templates is Session 3.

## Versioning

This package is consumed by both apps via `git:` dependency on a
specific ref. Bump the version + tag a release here when shipping
breaking schema changes; consumer apps explicitly point at the new ref.
