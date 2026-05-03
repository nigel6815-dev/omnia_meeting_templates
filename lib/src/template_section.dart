import 'package:flutter/widgets.dart';

/// A self-contained chunk of a meeting analysis.
///
/// Each section knows three things:
///   1. How to ask Gemini for its data (`promptInstruction`)
///   2. The JSON shape Gemini will return for it (`jsonSchemaSnippet`)
///   3. How to render its data on screen (`buildRenderer`)
///
/// Sections are composed into Templates. A Template is a list of sections
/// in display order. Two templates can share sections (every template
/// includes ActionItems and Decisions, for instance), and sections can
/// be used standalone for re-analysis.
abstract class TemplateSection {
  const TemplateSection();

  /// Stable machine-readable identifier. Persisted in Firestore template
  /// documents and used as the key in MeetingAnalysis.sectionData.
  /// Snake_case. Never localised — it's an ID, not a label.
  String get id;

  /// User-facing section title. Localisable, but the english source is
  /// what's shipped today.
  String get displayName;

  /// One-line description shown in the custom-template section picker.
  String get description;

  /// Optional Material icon name (resolved by [TemplateRenderer]).
  /// Implementers can leave null for "no icon".
  String? get icon => null;

  /// The instruction block this section contributes to the assembled
  /// Gemini prompt. Should be self-contained markdown bullet rules —
  /// no headings, no transcript reference, no JSON schema (those are
  /// added by [GeminiPromptBuilder]).
  String get promptInstruction;

  /// JSON schema fragment that this section claims under its [id] key
  /// in Gemini's overall response. Embedded in the prompt's
  /// "Return JSON in this shape:" block.
  ///
  /// Example for an "action_items" section:
  ///   `[{ "task": "", "owner": "", "due_date": "", "dependencies": "" }]`
  /// Example for a "summary" section:
  ///   `""`
  /// Example for an "insights" section (object with sub-fields):
  ///   `{ "user_sentiment": "", "pain_points": "", "opportunities": "" }`
  String get jsonSchemaSnippet;

  /// Build the Flutter widget that renders this section's data.
  ///
  /// [data] is the raw decoded JSON returned by Gemini for this section's
  /// [id] key. May be `null`, an empty list/map, a string, etc. — the
  /// renderer should handle all of those gracefully.
  ///
  /// Renderers SHOULD NOT wrap themselves in a Card / Padding / heading —
  /// that's the job of the orchestrating [TemplateRenderer]. Just return
  /// the inner content.
  Widget buildRenderer(BuildContext context, dynamic data);
}
