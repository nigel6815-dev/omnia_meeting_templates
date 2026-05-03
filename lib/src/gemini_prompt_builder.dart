import 'dart:convert';

import 'meeting_analysis.dart';
import 'template.dart';

/// Assembles a Gemini prompt from a Template + a transcript, then
/// parses Gemini's JSON response back into a MeetingAnalysis.
///
/// One central rules block is shared across every section. Each
/// section contributes its own instruction sub-block + JSON schema
/// snippet under its id. Gemini returns a single JSON document we
/// decompose into the sectionData map.
///
/// Pure Dart — no Flutter, no http. The caller wires the actual
/// Gemini HTTP call and passes the response JSON to [parse].
class GeminiPromptBuilder {
  GeminiPromptBuilder._();

  /// Universal rules block that prefaces every assembled prompt.
  /// Lifted directly from Nigel's master prompt.
  static const String universalRules = '''
You are generating high-clarity, structured meeting notes from a raw
transcript. The transcript may contain interruptions, filler words,
tangents, and overlapping speakers. Your job is to extract meaning,
not repeat dialogue.

GENERAL RULES (apply to every section below)
- Focus on what other participants said, not the note-taker.
- Remove filler, repetition, and irrelevant chatter.
- Preserve intent, not verbatim speech.
- Convert vague statements into clear summaries without changing meaning.
- Highlight decisions, blockers, risks, and next steps.
- If a section has no information, return an empty value (empty string,
  empty list, empty object) for that section. Do NOT invent details.
- If a fact is unclear, write "Unclear" or "Not specified" verbatim.
- Use bullet points within long-form fields, never paragraphs.
- Include quotes, numbers, and metrics when actually mentioned.
- Be concise. No hallucinations. Only use information present in
  the transcript.
''';

  /// Build the full Gemini prompt for [template] running against
  /// [transcript]. Optional [attendees] for context-injection sections
  /// (e.g. follow-up email).
  static String buildPrompt({
    required Template template,
    required String transcript,
    String attendees = '',
  }) {
    final buf = StringBuffer();
    buf.writeln(universalRules);
    buf.writeln();

    if (attendees.isNotEmpty) {
      buf.writeln('Attendees: $attendees');
      buf.writeln();
    }

    buf.writeln('Template: ${template.name}');
    if (template.description.isNotEmpty) {
      buf.writeln('Template purpose: ${template.description}');
    }
    buf.writeln();

    // Per-section instructions.
    buf.writeln('SECTIONS TO PRODUCE');
    buf.writeln('-------------------');
    for (final section in template.sections) {
      buf.writeln();
      buf.writeln('## ${section.displayName}  (key: ${section.id})');
      buf.writeln(section.promptInstruction.trim());
    }
    buf.writeln();

    // Transcript.
    buf.writeln('TRANSCRIPT');
    buf.writeln('----------');
    buf.writeln(transcript);
    buf.writeln();

    // Output schema.
    buf.writeln('Return JSON in EXACTLY this shape, with one top-level key');
    buf.writeln('per section. Do not nest, do not wrap in code fences,');
    buf.writeln('do not add prose before or after the JSON:');
    buf.writeln();
    buf.write('{');
    for (var i = 0; i < template.sections.length; i++) {
      final s = template.sections[i];
      buf.write('\n  "${s.id}": ${s.jsonSchemaSnippet}');
      if (i < template.sections.length - 1) buf.write(',');
    }
    buf.writeln('\n}');

    return buf.toString();
  }

  /// Parse Gemini's response text into a MeetingAnalysis.
  ///
  /// Tolerant of:
  /// - Code fences (```json ... ```)
  /// - Leading / trailing prose
  /// - Missing top-level keys (defaults to empty section data)
  /// - Extra unknown top-level keys (preserved in sectionData,
  ///   ignored by renderers)
  static MeetingAnalysis parse({
    required String geminiResponseText,
    required Template template,
    DateTime? analysedAt,
  }) {
    final stripped = _stripJsonFences(geminiResponseText.trim());
    final decoded = _safeDecodeMap(stripped);
    return MeetingAnalysis(
      sectionData: decoded,
      templateId: template.id,
      analysedAt: analysedAt ?? DateTime.now(),
    );
  }

  // ── Internals ─────────────────────────────────────────────────────

  static String _stripJsonFences(String s) {
    // ```json ... ```
    final fence = RegExp(r'```(?:json)?\s*\n([\s\S]*?)\n```',
        caseSensitive: false);
    final m = fence.firstMatch(s);
    if (m != null) return m.group(1)!.trim();
    return s;
  }

  static Map<String, dynamic> _safeDecodeMap(String s) {
    // Find first { and last } — Gemini sometimes preludes JSON with
    // a one-liner like "Here are the meeting notes:"
    final firstBrace = s.indexOf('{');
    final lastBrace = s.lastIndexOf('}');
    if (firstBrace == -1 || lastBrace <= firstBrace) {
      return const {};
    }
    final candidate = s.substring(firstBrace, lastBrace + 1);
    try {
      final raw = jsonDecode(candidate);
      if (raw is Map) return Map<String, dynamic>.from(raw);
      return const {};
    } catch (_) {
      return const {};
    }
  }
}
